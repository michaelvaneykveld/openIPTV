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
import 'package:openiptv/src/protocols/xtream/xtream_http_client.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';
import 'package:openiptv/src/providers/protocol_auth_providers.dart';
import 'package:openiptv/src/providers/telemetry_service.dart';

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

  /// Runs the initial import job for the supplied [profile]. The work happens
  /// synchronously, so callers typically trigger it in a fire-and-forget
  /// manner (e.g. `unawaited(runInitialImport(...))`).
  Future<void> runInitialImport(ResolvedProviderProfile profile) async {
    final providerId = profile.providerDbId;
    if (providerId == null) {
      return;
    }

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
              xmltvUrl: profile.secrets['epgUrl'] ??
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
        _debug(
          'Parsed playlist for ${profile.record.displayName} is empty.',
        );
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
      final session =
          await _ref.read(stalkerSessionProvider(configuration).future);
      final headers = session.buildAuthenticatedHeaders();
      final live = await _fetchStalkerCategories(
        configuration,
        headers,
        module: 'itv',
      );
      final vod = await _fetchStalkerCategories(
        configuration,
        headers,
        module: 'vod',
      );
      final series = await _fetchStalkerCategories(
        configuration,
        headers,
        module: 'series',
      );
      final radio = await _fetchStalkerCategories(
        configuration,
        headers,
        module: 'radio',
      );

      final importer = _ref.read(stalkerImporterProvider);
      await importer.importCategories(
        providerId: providerId,
        live: live,
        vod: vod,
        series: series,
        radio: radio,
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
        _logQueryLatency(
          source: 'xtream.$action',
          duration: stopwatch.elapsed,
        ),
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
    Map<String, String> baseHeaders, {
    required String module,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final envelope = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: {
          'type': module,
          'action': 'get_categories',
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
      final decoded = _maybeDecodeJson(envelope.body);
      if (decoded is Map) {
        final categories = decoded['js'] ?? decoded['categories'];
        if (categories is List) {
          return categories
              .whereType<Map>()
              .map(
                (entry) => entry.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              )
              .toList();
        }
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

  List<Map<String, dynamic>> _normalizeXtreamPayload(dynamic payload) {
    final decoded = _maybeDecodeJson(payload);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (entry) => entry.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
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
              (entry) => entry.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
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

  String _decodePlaylistBytes(
    Uint8List bytes, {
    String? preferredEncoding,
  }) {
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
          logo: _extractAttribute(line, 'tvg-logo') ??
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
    final regex = RegExp(
      '$attribute="([^"]*)"',
      caseSensitive: false,
    );
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
  const _M3uMetadata({
    this.name,
    this.group,
    this.logo,
    this.isRadio = false,
  });

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
