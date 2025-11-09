import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/import/m3u_importer.dart';
import 'package:openiptv/data/import/stalker_importer.dart';
import 'package:openiptv/data/import/xtream_importer.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_client.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_http_client.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_session.dart';
import 'package:openiptv/src/protocols/xtream/xtream_http_client.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';
import 'package:openiptv/src/providers/protocol_auth_providers.dart';
import 'package:openiptv/src/providers/telemetry_service.dart';
import 'package:openiptv/src/utils/url_redaction.dart';

final providerImportServiceProvider = Provider<ProviderImportService>((ref) {
  return ProviderImportService(ref);
});

/// Coordinates the first-time database seeding for newly-onboarded providers.
///
/// Login flows still run through their legacy probes so we keep this service
/// focused on taking a fully-resolved profile (with secrets) and populating
/// the Drift database via the importers. Each protocol implementation lives
/// behind a small helper so we can extend coverage incrementally.
class ProviderImportService {
  ProviderImportService(this._ref);

  final Ref _ref;

  final XtreamHttpClient _xtreamHttpClient = XtreamHttpClient();
  final M3uXmlClient _m3uClient = M3uXmlClient();
  final StalkerHttpClient _stalkerHttpClient = StalkerHttpClient();
  final Map<int, Future<void>> _inFlightImports = {};

  /// Runs the initial import job for the supplied [profile]. The work happens
  /// synchronously, so callers typically trigger it in a fire-and-forget
  /// manner (e.g. `unawaited(runInitialImport(...))`).
  Future<void> runInitialImport(ResolvedProviderProfile profile) {
    final providerId = profile.providerDbId;
    if (providerId == null) {
      return Future.value();
    }
    final existing = _inFlightImports[providerId];
    if (existing != null) {
      return existing;
    }
    final future = _runImportJob(profile, providerId);
    _inFlightImports[providerId] = future.whenComplete(() {
      _inFlightImports.remove(providerId);
    });
    return future;
  }

  Future<void> _runImportJob(
    ResolvedProviderProfile profile,
    int providerId,
  ) async {
    final kind = profile.record.kind.name;
    unawaited(
      _logImportMetric(
        providerId: providerId,
        kind: kind,
        phase: 'started',
        metadata: {'providerName': profile.record.displayName},
      ),
    );
    try {
      switch (profile.record.kind) {
        case ProviderKind.xtream:
          await _importXtream(providerId, profile);
          break;
        case ProviderKind.m3u:
          await _importM3u(providerId, profile);
          break;
        case ProviderKind.stalker:
          await _importStalker(providerId, profile);
          break;
      }
      unawaited(
        _logImportMetric(
          providerId: providerId,
          kind: kind,
          phase: 'completed',
        ),
      );
    } catch (error, stackTrace) {
      _logError(
        'Initial import failed for ${profile.record.displayName}',
        error,
        stackTrace,
      );
      unawaited(
        _logCrashSafeError(
          category: 'import',
          message:
              'Import failed for ${profile.record.displayName} (${profile.record.kind.name})',
          metadata: {
            'providerId': providerId,
            'providerKind': kind,
            'error': error.toString(),
          },
        ),
      );
    }
  }

  Future<void> _importXtream(
    int providerId,
    ResolvedProviderProfile profile,
  ) async {
    final username = profile.secrets['username'] ?? '';
    final password = profile.secrets['password'] ?? '';
    if (username.isEmpty || password.isEmpty) {
      _debug(
        'Xtream import skipped for ${profile.record.displayName}: '
        'missing credentials.',
      );
      return;
    }

    final userAgent = profile.record.configuration['userAgent'];
    final config = XtreamPortalConfiguration(
      baseUri: profile.lockedBase,
      username: username,
      password: password,
      userAgent: userAgent == null || userAgent.isEmpty ? null : userAgent,
      allowSelfSignedTls: profile.record.allowSelfSignedTls,
      extraHeaders: _decodeCustomHeaders(profile),
    );

    final results = await Future.wait<List<Map<String, dynamic>>>([
      _fetchXtreamList(config, 'get_live_categories'),
      _fetchXtreamList(config, 'get_vod_categories'),
      _fetchXtreamList(config, 'get_series_categories'),
      _fetchXtreamList(config, 'get_live_streams'),
      _fetchXtreamList(config, 'get_vod_streams'),
      _fetchXtreamList(config, 'get_series'),
    ]);

    final liveCategories = results[0];
    final vodCategories = results[1];
    final seriesCategories = results[2];
    final liveStreams = results[3];
    final vodStreams = results[4];
    final seriesStreams = results[5];

    if (liveStreams.isEmpty && vodStreams.isEmpty && seriesStreams.isEmpty) {
      _debug(
        'Xtream import produced no streams for ${profile.record.displayName}.',
      );
    }

    final importer = _ref.read(xtreamImporterProvider);
    await importer.importAll(
      providerId: providerId,
      live: liveStreams,
      vod: vodStreams,
      series: seriesStreams,
      liveCategories: liveCategories,
      vodCategories: vodCategories,
      seriesCategories: seriesCategories,
    );
  }

  Future<void> _importM3u(
    int providerId,
    ResolvedProviderProfile profile,
  ) async {
    final playlistUrl = profile.secrets['playlistUrl'];
    final playlistPath = profile.record.configuration['playlistFilePath'];
    if ((playlistUrl == null || playlistUrl.isEmpty) &&
        (playlistPath == null || playlistPath.isEmpty)) {
      _debug(
        'M3U import skipped for ${profile.record.displayName}: '
        'no playlist source available.',
      );
      return;
    }

    try {
      final configuration = playlistUrl != null && playlistUrl.isNotEmpty
          ? M3uXmlPortalConfiguration.fromUrls(
              portalId: profile.record.id,
              playlistUrl: playlistUrl,
              xmltvUrl:
                  profile.secrets['epgUrl'] ??
                  profile.record.configuration['lockedEpg'],
              displayName: profile.record.displayName,
              playlistHeaders: _decodeCustomHeaders(profile),
              defaultHeaders: _decodeCustomHeaders(profile),
              allowSelfSignedTls: profile.record.allowSelfSignedTls,
              defaultUserAgent: profile.record.configuration['userAgent'],
              followRedirects: profile.record.followRedirects,
            )
          : M3uXmlPortalConfiguration.fromFiles(
              portalId: profile.record.id,
              playlistPath: playlistPath!,
              xmltvPath: profile.record.configuration['lockedEpg'],
              displayName: profile.record.displayName,
              allowSelfSignedTls: profile.record.allowSelfSignedTls,
              followRedirects: profile.record.followRedirects,
            );

      final playlistEnvelope = await _m3uClient.fetchPlaylist(configuration);
      final playlistText = _decodePlaylistBytes(
        playlistEnvelope.bytes,
        preferredEncoding: configuration.preferredEncoding,
      );
      final entries = ProviderImportService.parseM3uEntries(playlistText);
      if (entries.isEmpty) {
        _debug('Parsed playlist for ${profile.record.displayName} is empty.');
        return;
      }

      final importer = _ref.read(m3uImporterProvider);
      await importer.importEntries(
        providerId: providerId,
        entries: Stream<M3uEntry>.fromIterable(entries),
      );
    } catch (error, stackTrace) {
      _logError(
        'M3U import failed for ${profile.record.displayName}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _importStalker(
    int providerId,
    ResolvedProviderProfile profile,
  ) async {
    final mac = profile.record.configuration['macAddress'];
    if (mac == null || mac.isEmpty) {
      _debug(
        'Stalker import skipped for ${profile.record.displayName}: '
        'missing MAC address.',
      );
      return;
    }

    final configuration = StalkerPortalConfiguration(
      baseUri: profile.lockedBase,
      macAddress: mac,
      userAgent: profile.record.configuration['userAgent'],
      allowSelfSignedTls: profile.record.allowSelfSignedTls,
      extraHeaders: _decodeCustomHeaders(profile),
    );

    try {
      final session = await _ref.read(
        stalkerSessionProvider(configuration).future,
      );
      final headers = session.buildAuthenticatedHeaders();
      final live = await _fetchStalkerCategories(
        configuration,
        session,
        headers,
        module: 'itv',
      );
      var vod = await _fetchStalkerCategories(
        configuration,
        session,
        headers,
        module: 'vod',
      );
      var series = await _fetchStalkerCategories(
        configuration,
        session,
        headers,
        module: 'series',
      );
      var radio = await _fetchStalkerCategories(
        configuration,
        session,
        headers,
        module: 'radio',
      );

      if (_needsDerivedCategories(vod)) {
        final derived = await _deriveCategoriesFromGlobal(
          configuration: configuration,
          headers: headers,
          session: session,
          module: 'vod',
        );
        if (derived.isNotEmpty) {
          vod = derived;
        }
      }
      if (_needsDerivedCategories(series)) {
        final derived = await _deriveCategoriesFromGlobal(
          configuration: configuration,
          headers: headers,
          session: session,
          module: 'series',
        );
        if (derived.isNotEmpty) {
          series = derived;
        }
      }
      if (_needsDerivedCategories(radio)) {
        final derived = await _deriveCategoriesFromGlobal(
          configuration: configuration,
          headers: headers,
          session: session,
          module: 'radio',
        );
        if (derived.isNotEmpty) {
          radio = derived;
        }
      }
      final liveItems = await _fetchStalkerItems(
        configuration: configuration,
        headers: headers,
        session: session,
        module: 'itv',
        categories: live,
        enableCategoryPaging: false,
      );
      final vodItems = await _fetchStalkerItems(
        configuration: configuration,
        headers: headers,
        session: session,
        module: 'vod',
        categories: vod,
        enableCategoryPaging: true,
      );
      final seriesItems = await _fetchStalkerItems(
        configuration: configuration,
        headers: headers,
        session: session,
        module: 'series',
        categories: series,
        enableCategoryPaging: true,
      );
      final radioItems = await _fetchStalkerItems(
        configuration: configuration,
        headers: headers,
        session: session,
        module: 'radio',
        categories: radio,
        enableCategoryPaging: true,
      );
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker categories fetched: '
            'live=${live.length}, vod=${vod.length}, '
            'series=${series.length}, radio=${radio.length}',
          ),
        );
        debugPrint(
          redactSensitiveText(
            'Stalker listing counts: '
            'live=${liveItems.length}, vod=${vodItems.length}, '
            'series=${seriesItems.length}, radio=${radioItems.length}',
          ),
        );
      }

      final importer = _ref.read(stalkerImporterProvider);
      await importer.importCatalog(
        providerId: providerId,
        liveCategories: live,
        vodCategories: vod,
        seriesCategories: series,
        radioCategories: radio,
        liveItems: liveItems,
        vodItems: vodItems,
        seriesItems: seriesItems,
        radioItems: radioItems,
      );
    } catch (error, stackTrace) {
      _logError(
        'Stalker import failed for ${profile.record.displayName}',
        error,
        stackTrace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchXtreamList(
    XtreamPortalConfiguration config,
    String action,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await _xtreamHttpClient.getPlayerApi(
        config,
        queryParameters: {'action': action},
      );
      stopwatch.stop();
      unawaited(
        _logQueryLatency(source: 'xtream.$action', duration: stopwatch.elapsed),
      );
      return _normalizeXtreamPayload(response.body);
    } catch (error, stackTrace) {
      _logError('Xtream action $action failed', error, stackTrace);
      unawaited(
        _logQueryLatency(
          source: 'xtream.$action',
          duration: Duration.zero,
          success: false,
          metadata: {'error': error.toString()},
        ),
      );
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStalkerCategories(
    StalkerPortalConfiguration config,
    StalkerSession session,
    Map<String, String> baseHeaders, {
    required String module,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      for (final includeJs in [true, false]) {
        final envelope = await _stalkerHttpClient.getPortal(
          config,
          queryParameters: {
            'type': module,
            'action': 'get_categories',
            'token': session.token,
            'mac': config.macAddress.toLowerCase(),
            if (includeJs) 'JsHttpRequest': '1-xml',
          },
          headers: baseHeaders,
        );
        stopwatch.stop();
        unawaited(
          _logQueryLatency(
            source: 'stalker.$module',
            duration: stopwatch.elapsed,
          ),
        );
        final decoded = _decodePortalMap(envelope.body);
        final categories =
            decoded['js'] ?? decoded['categories'] ?? decoded['data'];
        if (categories is List && categories.isNotEmpty) {
          return categories
              .whereType<Map>()
              .map(
                (entry) =>
                    entry.map((key, value) => MapEntry(key.toString(), value)),
              )
              .toList();
        }
        if (!includeJs) {
          break;
        }
      }
      final genreFallback = await _fetchStalkerGenres(
        config,
        session,
        baseHeaders,
        module: module,
      );
      if (genreFallback.isNotEmpty) {
        return genreFallback;
      }
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker categories module=$module returned 0 entries '
            '(all attempts exhausted)',
          ),
        );
      }
    } catch (error, stackTrace) {
      _logError(
        'Stalker categories fetch failed for module $module',
        error,
        stackTrace,
      );
      unawaited(
        _logQueryLatency(
          source: 'stalker.$module',
          duration: Duration.zero,
          success: false,
          metadata: {'error': error.toString()},
        ),
      );
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> _fetchStalkerItems({
    required StalkerPortalConfiguration configuration,
    required Map<String, String> headers,
    required StalkerSession session,
    required String module,
    required List<Map<String, dynamic>> categories,
    bool enableCategoryPaging = true,
  }) async {
    final allowPerCategory =
        enableCategoryPaging &&
        categories.isNotEmpty &&
        module != 'itv' &&
        !_needsDerivedCategories(categories);
    if (allowPerCategory) {
      final perCategory = await _fetchStalkerItemsForCategories(
        configuration: configuration,
        headers: headers,
        session: session,
        module: module,
        categories: categories,
      );
      if (perCategory.isNotEmpty) {
        return perCategory;
      }
    }

    for (final action in _bulkActionsForModule(module)) {
      final bulk = await _fetchStalkerBulk(
        configuration: configuration,
        headers: headers,
        session: session,
        module: module,
        action: action,
      );
      if (bulk.isNotEmpty) {
        return bulk;
      }
    }
    return _fetchStalkerListing(
      configuration: configuration,
      headers: headers,
      session: session,
      module: module,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStalkerListing({
    required StalkerPortalConfiguration configuration,
    required Map<String, String> headers,
    required StalkerSession session,
    required String module,
    int maxPages = 25,
    String? categoryId,
  }) async {
    final results = <Map<String, dynamic>>[];
    int? expectedPages;
    for (var page = 1; page <= maxPages; page += 1) {
      try {
        final response = await _stalkerHttpClient.getPortal(
          configuration,
          queryParameters: {
            'type': module,
            'action': 'get_ordered_list',
            'p': '${page - 1}',
            'JsHttpRequest': '1-xml',
            'token': session.token,
            'mac': configuration.macAddress.toLowerCase(),
            if (categoryId != null) 'genre': categoryId,
          },
          headers: headers,
        );
        final envelope = _decodePortalMap(response.body);
        final entries = _extractPortalItems(envelope);
        final pageSize = _extractMaxPageItems(envelope);
        final totalItems = _extractTotalItems(envelope);
        if (entries.isEmpty) {
          if (kDebugMode) {
            debugPrint(
              redactSensitiveText(
                'Stalker listing module=$module page=$page returned 0 items. '
                'Payload preview: ${_previewBody(response.body)}',
              ),
            );
          }
          break;
        }
        results.addAll(entries);
        if (kDebugMode) {
          final genreSuffix = categoryId == null ? '' : ', genre=$categoryId';
          debugPrint(
            redactSensitiveText(
              'Stalker listing module=$module page=$page '
              'items=${entries.length} (pageSize=${pageSize ?? 'n/a'}, '
              'total=${totalItems ?? 'n/a'}$genreSuffix)',
            ),
          );
        }
        if (pageSize != null && entries.length < pageSize) {
          break;
        }
        if (totalItems != null && pageSize != null && pageSize > 0) {
          expectedPages ??= ((totalItems + pageSize - 1) ~/ pageSize)
              .clamp(1, maxPages)
              .toInt();
        }
        if (totalItems != null && results.length >= totalItems) {
          break;
        }
        if (expectedPages != null && page >= expectedPages) {
          break;
        }
      } catch (error, stackTrace) {
        _logError(
          'Stalker listing fetch failed for module $module page $page',
          error,
          stackTrace,
        );
        break;
      }
    }
    return results;
  }

  List<Map<String, dynamic>> _extractPortalItems(Map<String, dynamic> parsed) {
    final candidates = <dynamic>[
      parsed['data'],
      parsed['js'],
      parsed['results'],
    ];
    for (final candidate in candidates) {
      if (candidate is List && candidate.isNotEmpty) {
        return candidate
            .whereType<Map>()
            .map(
              (entry) =>
                  entry.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
      }
      if (candidate is Map && candidate['data'] is List) {
        final nested = candidate['data'] as List;
        if (nested.isNotEmpty) {
          return nested
              .whereType<Map>()
              .map(
                (entry) =>
                    entry.map((key, value) => MapEntry(key.toString(), value)),
              )
              .toList();
        }
      }
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> _fetchStalkerGenres(
    StalkerPortalConfiguration config,
    StalkerSession session,
    Map<String, String> headers, {
    required String module,
  }) async {
    try {
      final response = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: {
          'type': module,
          'action': 'get_genres',
          'JsHttpRequest': '1-xml',
          'token': session.token,
          'mac': config.macAddress.toLowerCase(),
        },
        headers: headers,
      );
      final decoded = _decodePortalMap(response.body);
      final data = decoded['js'] ?? decoded['genres'] ?? decoded['data'];
      if (data is List && data.isNotEmpty) {
        return data
            .whereType<Map>()
            .map(
              (entry) =>
                  entry.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
      }
    } catch (error, stackTrace) {
      _logError(
        'Stalker genres fetch failed for module $module',
        error,
        stackTrace,
      );
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> _fetchStalkerItemsForCategories({
    required StalkerPortalConfiguration configuration,
    required Map<String, String> headers,
    required StalkerSession session,
    required String module,
    required List<Map<String, dynamic>> categories,
  }) async {
    const maxPagesPerCategory = 200;
    final seenKeys = <String>{};
    final aggregated = <Map<String, dynamic>>[];

    for (final category in categories) {
      final categoryId = _coerceString(
        category['id'] ??
            category['category_id'] ??
            category['tv_genre_id'] ??
            category['alias'],
      );
      if (categoryId == null || categoryId.isEmpty) {
        continue;
      }
      if (_isCategoryLocked(category)) {
        if (kDebugMode) {
          debugPrint(
            redactSensitiveText(
              'Stalker skipping locked/censored category $categoryId '
              'for module=$module',
            ),
          );
        }
        continue;
      }

      int? expectedPages;
      for (var page = 1; page <= maxPagesPerCategory; page += 1) {
        try {
          final response = await _stalkerHttpClient.getPortal(
            configuration,
            queryParameters: {
              'type': module,
              'action': 'get_ordered_list',
              'p': '${page - 1}',
              'genre': categoryId,
              'JsHttpRequest': '1-xml',
              'token': session.token,
              'mac': configuration.macAddress.toLowerCase(),
            },
            headers: headers,
          );
          final envelope = _decodePortalMap(response.body);
          final entries = _extractPortalItems(envelope);
          final pageSize = _extractMaxPageItems(envelope);
          final totalItems =
              _extractTotalItems(envelope) ??
              _coerceInt(category['items'] ?? category['movies_count']);

          if (kDebugMode) {
            debugPrint(
              redactSensitiveText(
                'Stalker cat=$categoryId module=$module page=$page '
                'items=${entries.length} total=${totalItems ?? 'n/a'}',
              ),
            );
          }

          if (entries.isEmpty) {
            break;
          }

          for (final entry in entries) {
            final idKey =
                _coerceString(entry['id'] ?? entry['cmd'] ?? entry['name']) ??
                '${categoryId}_${entry.hashCode}';
            if (seenKeys.add('$module:$idKey')) {
              entry.putIfAbsent('category_id', () => categoryId);
              aggregated.add(entry);
            }
          }

          if (pageSize != null && entries.length < pageSize) {
            break;
          }
          if (totalItems != null && aggregated.length >= totalItems) {
            break;
          }
          if (totalItems != null &&
              pageSize != null &&
              pageSize > 0 &&
              expectedPages == null) {
            expectedPages = ((totalItems + pageSize - 1) ~/ pageSize).clamp(
              1,
              maxPagesPerCategory,
            );
          }
          if (expectedPages != null && page >= expectedPages) {
            break;
          }
        } catch (error, stackTrace) {
          _logError(
            'Stalker category $categoryId fetch failed',
            error,
            stackTrace,
          );
          break;
        }
      }
    }

    return aggregated;
  }

  Future<List<Map<String, dynamic>>> _deriveCategoriesFromGlobal({
    required StalkerPortalConfiguration configuration,
    required Map<String, String> headers,
    required StalkerSession session,
    required String module,
  }) async {
    const samplePages = 5;
    final seeds = await _fetchStalkerListing(
      configuration: configuration,
      headers: headers,
      session: session,
      module: module,
      maxPages: samplePages,
    );
    if (seeds.isEmpty) {
      return const [];
    }

    final derived = <String, _DerivedCategory>{};
    for (final entry in seeds) {
      final id = _coerceString(
        entry['category_id'] ??
            entry['genre_id'] ??
            entry['tv_genre_id'] ??
            entry['genre'],
      );
      final title = _coerceString(
        entry['category_title'] ??
            entry['genre_title'] ??
            entry['genre_name'] ??
            entry['genre'] ??
            entry['tv_genre_title'],
      );
      if (title == null || title.isEmpty) {
        continue;
      }
      final resolvedId = (id == null || id.isEmpty || id == '*')
          ? 'derived:${title.toLowerCase().hashCode}'
          : id;
      derived.putIfAbsent(
        resolvedId,
        () => _DerivedCategory(id: resolvedId, title: title),
      );
    }

    return derived.values
        .map((cat) => {'id': cat.id, 'title': cat.title, 'name': cat.title})
        .toList();
  }

  bool _needsDerivedCategories(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) {
      return true;
    }
    final hasRealCategory = categories.any((category) {
      final id = _coerceString(
        category['id'] ??
            category['category_id'] ??
            category['tv_genre_id'] ??
            category['alias'],
      );
      if (id == null || id.isEmpty || id == '*') {
        return false;
      }
      return true;
    });
    return !hasRealCategory;
  }

  Future<List<Map<String, dynamic>>> _fetchStalkerBulk({
    required StalkerPortalConfiguration configuration,
    required Map<String, String> headers,
    required StalkerSession session,
    required String module,
    required String action,
  }) async {
    try {
      final response = await _stalkerHttpClient.getPortal(
        configuration,
        queryParameters: {
          'type': module,
          'action': action,
          'JsHttpRequest': '1-xml',
          'token': session.token,
          'mac': configuration.macAddress.toLowerCase(),
        },
        headers: headers,
      );
      final parsed = _decodePortalMap(response.body);
      final items = _extractPortalItems(parsed);
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker bulk action=$action module=$module items=${items.length}',
          ),
        );
      }
      return items;
    } catch (error, stackTrace) {
      _logError('Stalker $action failed for module $module', error, stackTrace);
      return const [];
    }
  }

  List<String> _bulkActionsForModule(String module) {
    switch (module) {
      case 'itv':
      case 'radio':
        return const ['get_all_channels'];
      case 'vod':
        return const ['get_all_movies', 'get_all_vod'];
      case 'series':
        return const ['get_all_series', 'get_all_video_clubs'];
      default:
        return const [];
    }
  }

  bool _isCategoryLocked(Map<String, dynamic> category) {
    final locked = _coerceInt(category['locked']);
    if (locked == 1) {
      return true;
    }
    final censored = _coerceInt(category['censored']);
    final allowChildren = _coerceInt(category['allow_children']);
    if (censored == 1 && (allowChildren == null || allowChildren == 0)) {
      return true;
    }
    final adult = _coerceString(category['adult']);
    if (adult == '1' || adult?.toLowerCase() == 'true') {
      return true;
    }
    return false;
  }

  Map<String, dynamic> _decodePortalMap(dynamic body) {
    if (body is Map) {
      return body.map((key, value) => MapEntry(key.toString(), value));
    }
    if (body is String) {
      final cleaned = _stripHtmlComments(body.trim());
      if (cleaned.isEmpty) return const {};
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }

  String _stripHtmlComments(String input) {
    return input.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '').trim();
  }

  int? _extractMaxPageItems(Map<String, dynamic> parsed) {
    final scopes = [
      parsed,
      if (parsed['js'] is Map) parsed['js'],
      if (parsed['data'] is Map) parsed['data'],
    ];
    for (final scope in scopes) {
      if (scope is Map) {
        final value = scope['max_page_items'] ?? scope['maxPageItems'];
        if (value is int) return value;
        if (value is String) {
          final asInt = int.tryParse(value);
          if (asInt != null) return asInt;
        }
      }
    }
    return null;
  }

  int? _extractTotalItems(Map<String, dynamic> parsed) {
    final scopes = [
      parsed,
      if (parsed['js'] is Map) parsed['js'],
      if (parsed['data'] is Map) parsed['data'],
    ];
    for (final scope in scopes) {
      if (scope is Map) {
        final value = scope['total_items'] ?? scope['totalItems'];
        if (value is int) return value;
        if (value is String) {
          final asInt = int.tryParse(value);
          if (asInt != null) return asInt;
        }
      }
    }
    return null;
  }

  String _previewBody(dynamic body) {
    final text = body is String ? body : jsonEncode(body ?? const {});
    if (text.length > 200) {
      return '${text.substring(0, 200)}…';
    }
    return text;
  }

  String? _coerceString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  int? _coerceInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = _coerceString(value);
    return text == null ? null : int.tryParse(text);
  }

  List<Map<String, dynamic>> _normalizeXtreamPayload(dynamic payload) {
    final decoded = _maybeDecodeJson(payload);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    }
    if (decoded is Map) {
      const candidateKeys = <String>[
        'data',
        'results',
        'streams',
        'movie_data',
        'series',
        'categories',
      ];
      for (final key in candidateKeys) {
        final nested = decoded[key];
        final normalized = _normalizeXtreamPayload(nested);
        if (normalized.isNotEmpty) {
          return normalized;
        }
      }
      if (decoded.values.isNotEmpty) {
        final flattened = decoded.values
            .whereType<Map>()
            .map(
              (entry) =>
                  entry.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
        if (flattened.isNotEmpty) {
          return flattened;
        }
      }
    }
    return const [];
  }

  dynamic _maybeDecodeJson(dynamic body) {
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) {
        return const [];
      }
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return body;
      }
    }
    return body;
  }

  Map<String, String> _decodeCustomHeaders(ResolvedProviderProfile profile) {
    final encoded = profile.secrets['customHeaders'];
    if (encoded == null || encoded.isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } catch (_) {
      // Ignore malformed payloads.
    }
    return const {};
  }

  String _decodePlaylistBytes(Uint8List bytes, {String? preferredEncoding}) {
    // Attempt UTF-8 first; fall back to latin-1 for legacy playlists.
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      try {
        return latin1.decode(bytes, allowInvalid: true);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('$message: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _logImportMetric({
    required int providerId,
    required String kind,
    required String phase,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final telemetry = await _ref.read(telemetryServiceProvider.future);
      await telemetry.logImportMetric(
        providerId: providerId,
        providerKind: kind,
        phase: phase,
        metadata: metadata,
      );
    } catch (_) {}
  }

  Future<void> _logQueryLatency({
    required String source,
    required Duration duration,
    bool success = true,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final telemetry = await _ref.read(telemetryServiceProvider.future);
      await telemetry.logQueryLatency(
        source: source,
        duration: duration,
        success: success,
        metadata: metadata,
      );
    } catch (_) {}
  }

  Future<void> _logCrashSafeError({
    required String category,
    required String message,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final telemetry = await _ref.read(telemetryServiceProvider.future);
      await telemetry.logCrashSafeError(
        category: category,
        message: message,
        metadata: metadata,
      );
    } catch (_) {}
  }

  void _debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Exposed for unit tests to validate the playlist parser.
  @visibleForTesting
  static List<M3uEntry> parseM3uEntries(String contents) {
    final upper = contents.toUpperCase();
    if (!upper.contains('#EXTM3U')) {
      return const [];
    }

    final lines = const LineSplitter().convert(contents);
    final entries = <M3uEntry>[];
    var metadata = const _M3uMetadata();

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF')) {
        metadata = _M3uMetadata(
          name: _extractTitle(line),
          group: _extractAttribute(line, 'group-title') ?? metadata.group,
          logo:
              _extractAttribute(line, 'tvg-logo') ??
              _extractAttribute(line, 'logo'),
          isRadio: (_extractAttribute(line, 'radio') ?? '')
              .toLowerCase()
              .contains('true'),
        );
        continue;
      }

      if (line.toUpperCase().startsWith('#EXTGRP')) {
        final value = line.split(':').skip(1).join(':').trim();
        metadata = metadata.copyWith(
          group: value.isEmpty ? metadata.group : value,
        );
        continue;
      }

      if (line.startsWith('#')) {
        continue;
      }

      final name = metadata.name ?? line;
      final group = metadata.group?.isEmpty ?? true ? 'Other' : metadata.group!;
      entries.add(
        M3uEntry(
          key: line,
          name: name,
          group: group,
          isRadio: metadata.isRadio,
          logoUrl: metadata.logo?.isEmpty ?? true ? null : metadata.logo,
        ),
      );
      metadata = const _M3uMetadata();
    }
    return entries;
  }

  static String? _extractAttribute(String line, String attribute) {
    final regex = RegExp('$attribute="([^"]*)"', caseSensitive: false);
    final match = regex.firstMatch(line);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String? _extractTitle(String line) {
    final index = line.indexOf(',');
    if (index == -1 || index == line.length - 1) {
      return null;
    }
    final title = line.substring(index + 1).trim();
    return title.isEmpty ? null : title;
  }
}

class _M3uMetadata {
  const _M3uMetadata({this.name, this.group, this.logo, this.isRadio = false});

  final String? name;
  final String? group;
  final String? logo;
  final bool isRadio;

  _M3uMetadata copyWith({
    String? name,
    String? group,
    String? logo,
    bool? isRadio,
  }) {
    return _M3uMetadata(
      name: name ?? this.name,
      group: group ?? this.group,
      logo: logo ?? this.logo,
      isRadio: isRadio ?? this.isRadio,
    );
  }
}

class _DerivedCategory {
  _DerivedCategory({required this.id, required this.title});

  final String id;
  final String title;
}
