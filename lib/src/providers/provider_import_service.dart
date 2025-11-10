import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/db/database_flags.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/import/import_context.dart';
import 'package:openiptv/data/import/m3u_importer.dart';
import 'package:openiptv/data/import/stalker_importer.dart';
import 'package:openiptv/data/import/xtream_importer.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_client.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_http_client.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_session.dart';
import 'package:openiptv/src/protocols/xtream/xtream_http_client.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';
import 'package:openiptv/src/providers/import_resume_store.dart';
import 'package:openiptv/src/providers/protocol_auth_providers.dart';
import 'package:openiptv/src/providers/telemetry_service.dart';
import 'package:openiptv/src/utils/url_redaction.dart';

final providerImportReporterProvider =
    Provider<ProviderImportReporter?>((ref) => null);

final providerImportOffloadProvider = Provider<bool>((ref) => true);

final importResumeStoreFutureProvider =
    Provider<Future<ImportResumeStore>>((ref) {
  return ImportResumeStore.openDefault();
});

final providerImportServiceProvider = Provider<ProviderImportService>((ref) {
  final reporter = ref.watch(providerImportReporterProvider);
  final enableOffload = ref.watch(providerImportOffloadProvider);
  final resumeStoreFuture = ref.watch(importResumeStoreFutureProvider);
  return ProviderImportService(
    ref,
    reporter: reporter,
    enableOffload: enableOffload,
    resumeStoreFuture: resumeStoreFuture,
  );
});

/// Coordinates the first-time database seeding for newly-onboarded providers.
///
/// Login flows still run through their legacy probes so we keep this service
/// focused on taking a fully-resolved profile (with secrets) and populating
/// the Drift database via the importers. Each protocol implementation lives
/// behind a small helper so we can extend coverage incrementally.
class ProviderImportService {
  ProviderImportService(
    this._ref, {
    ProviderImportReporter? reporter,
    bool enableOffload = true,
    Future<ImportResumeStore>? resumeStoreFuture,
  })  : _enableOffload = enableOffload,
        _resumeStoreFuture =
            resumeStoreFuture ?? ImportResumeStore.openDefault() {
    _reporter = reporter ?? _LocalImportReporter(_publishEvent);
    _ref.onDispose(() {
      for (final controller in _progressControllers.values) {
        controller.close();
      }
      _progressControllers.clear();
    });
  }

  final Ref _ref;
  late final ProviderImportReporter _reporter;
  final bool _enableOffload;
  final Future<ImportResumeStore> _resumeStoreFuture;

  final XtreamHttpClient _xtreamHttpClient = XtreamHttpClient();
  final M3uXmlClient _m3uClient = M3uXmlClient();
  final StalkerHttpClient _stalkerHttpClient = StalkerHttpClient();
  final Map<int, Future<void>> _inFlightImports = {};
  final Map<int, StreamController<ProviderImportEvent>> _progressControllers =
      {};
  bool get _canUseWorker => !kIsWeb && !DatabaseFlags.enableSqlCipher;
  final Map<int, _WorkerHandle> _workerHandles = {};

  Stream<ProviderImportEvent> watchProgress(int providerId) {
    return _controllerFor(providerId).stream;
  }

  Future<void> cancelImport(int providerId) async {
    final handle = _workerHandles.remove(providerId);
    if (handle != null) {
      await handle.cancel();
      return;
    }
    _debug('No active import worker for providerId=$providerId to cancel.');
  }

  StreamController<ProviderImportEvent> _controllerFor(int providerId) {
    return _progressControllers.putIfAbsent(
      providerId,
      () => StreamController<ProviderImportEvent>.broadcast(),
    );
  }

  void _publishEvent(ProviderImportEvent event) {
    final controller = _controllerFor(event.providerId);
    if (!controller.isClosed) {
      controller.add(event);
    }
  }

  void _emitProgress(
    ResolvedProviderProfile profile,
    String phase, {
    Map<String, Object?>? metadata,
  }) {
    final providerId = profile.providerDbId;
    if (providerId == null) {
      return;
    }
    _reporter.report(
      ProviderImportProgressEvent(
        providerId: providerId,
        kind: profile.record.kind,
        phase: phase,
        metadata: metadata ?? const {},
      ),
    );
  }

  Map<String, Object?> _metricsMetadata(ImportMetrics? metrics) {
    if (metrics == null) {
      return const {};
    }
    return {
      'channelsUpserted': metrics.channelsUpserted,
      'categoriesUpserted': metrics.categoriesUpserted,
      'moviesUpserted': metrics.moviesUpserted,
      'seriesUpserted': metrics.seriesUpserted,
      'seasonsUpserted': metrics.seasonsUpserted,
      'episodesUpserted': metrics.episodesUpserted,
      'channelsDeleted': metrics.channelsDeleted,
      'programsUpserted': metrics.programsUpserted,
      'durationMs': metrics.duration.inMilliseconds,
    };
  }

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
    final future = _enableOffload && _canUseWorker
        ? _runImportInIsolate(profile, providerId)
        : _runImportJob(profile, providerId);
    _inFlightImports[providerId] = future.whenComplete(() {
      _inFlightImports.remove(providerId);
    });
    return future;
  }

  Future<void> _runImportJob(
    ResolvedProviderProfile profile,
    int providerId,
  ) async {
    final providerKind = profile.record.kind;
    final kind = providerKind.name;
    _emitProgress(profile, 'started');
    unawaited(
      _logImportMetric(
        providerId: providerId,
        kind: kind,
        phase: 'started',
        metadata: {'providerName': profile.record.displayName},
      ),
    );
    try {
      ImportMetrics? metrics;
      switch (profile.record.kind) {
        case ProviderKind.xtream:
          metrics = await _importXtream(providerId, profile);
          break;
        case ProviderKind.m3u:
          metrics = await _importM3u(providerId, profile);
          break;
        case ProviderKind.stalker:
          metrics = await _importStalker(providerId, profile);
          break;
      }
      unawaited(
        _logImportMetric(
          providerId: providerId,
          kind: kind,
          phase: 'completed',
        ),
      );
      _emitProgress(
        profile,
        'completed',
        metadata: _metricsMetadata(metrics),
      );
      final resumeStore = await _resumeStoreFuture;
      await resumeStore.clearProvider(providerId);
      _reporter.report(
        ProviderImportResultEvent(
          providerId: providerId,
          kind: providerKind,
          metrics: ProviderImportMetricsSummary.fromMetrics(metrics),
        ),
      );
    } catch (error, stackTrace) {
      _emitProgress(
        profile,
        'error',
        metadata: {'message': error.toString()},
      );
      _reporter.report(
        ProviderImportErrorEvent(
          providerId: providerId,
          kind: providerKind,
          message: error.toString(),
        ),
      );
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

  Future<ImportMetrics?> _importXtream(
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
      return null;
    }

    _emitProgress(profile, 'xtream.fetch');
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
    return importer.importAll(
      providerId: providerId,
      live: liveStreams,
      vod: vodStreams,
      series: seriesStreams,
      liveCategories: liveCategories,
      vodCategories: vodCategories,
      seriesCategories: seriesCategories,
    );
  }

  Future<ImportMetrics?> _importM3u(
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
      return null;
    }

    try {
      _emitProgress(profile, 'm3u.fetch');
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
        return null;
      }

      final importer = _ref.read(m3uImporterProvider);
      return importer.importEntries(
        providerId: providerId,
        entries: Stream<M3uEntry>.fromIterable(entries),
      );
    } catch (error, stackTrace) {
      _logError(
        'M3U import failed for ${profile.record.displayName}',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<void> _runImportInIsolate(
    ResolvedProviderProfile profile,
    int providerId,
  ) async {
    final controller = _controllerFor(providerId);
    if (controller.hasListener == false) {
      // Ensure the controller exists even before listeners attach.
      _publishEvent(
        ProviderImportProgressEvent(
          providerId: providerId,
          kind: profile.record.kind,
          phase: 'scheduled',
        ),
      );
    }
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<void>();
    StreamSubscription? progressSub;
    StreamSubscription? errorSub;
    StreamSubscription? exitSub;
    Isolate? isolate;
    var cleanedUp = false;

    Future<void> cleanup({bool cancelled = false}) async {
      if (cleanedUp) return;
      cleanedUp = true;
      _workerHandles.remove(providerId);
      await progressSub?.cancel();
      await errorSub?.cancel();
      await exitSub?.cancel();
      receivePort.close();
      errorPort.close();
      exitPort.close();
      if (cancelled) {
        isolate?.kill(priority: Isolate.immediate);
        _publishEvent(
          ProviderImportProgressEvent(
            providerId: providerId,
            kind: profile.record.kind,
            phase: 'cancelled',
          ),
        );
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else {
        isolate?.kill(priority: Isolate.immediate);
      }
    }

    try {
      final dbFile = await OpenIptvDb.resolveDatabaseFile();
      if (!await dbFile.exists()) {
        await cleanup();
        return _runImportJob(profile, providerId);
      }
      final request = _ProviderImportWorkerRequest(
        sendPort: receivePort.sendPort,
        profile: _serializeProfile(profile),
        dbPath: dbFile.path,
      );
      isolate = await Isolate.spawn<_ProviderImportWorkerRequest>(
        _providerImportWorkerEntry,
        request,
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
      _workerHandles[providerId] = _WorkerHandle(
        providerKind: profile.record.kind,
        cancelCallback: () => cleanup(cancelled: true),
      );
    } catch (error, stackTrace) {
      _logError('Failed to spawn import worker', error, stackTrace);
      await cleanup();
      return _runImportJob(profile, providerId);
    }

    progressSub = receivePort.listen((message) {
      final event = ProviderImportEventSerializer.deserialize(message);
      if (event != null) {
        _publishEvent(event);
      }
    });

    errorSub = errorPort.listen((dynamic message) async {
      await cleanup();
      final error = message is List && message.isNotEmpty ? message.first : message;
      final stackTrace = message is List && message.length > 1
          ? StackTrace.fromString('${message[1]}')
          : StackTrace.current;
      _publishEvent(
        ProviderImportErrorEvent(
          providerId: providerId,
          kind: profile.record.kind,
          message: error?.toString() ?? 'Import worker error',
        ),
      );
      if (!completer.isCompleted) {
        completer.completeError(
          Exception(error?.toString() ?? 'Import worker error'),
          stackTrace,
        );
      }
    });

    exitSub = exitPort.listen((_) async {
      await cleanup();
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    return completer.future;
  }

  Future<ImportMetrics?> _importStalker(
    int providerId,
    ResolvedProviderProfile profile,
  ) async {
    final resumeStore = await _resumeStoreFuture;
    final mac = profile.record.configuration['macAddress'];
    if (mac == null || mac.isEmpty) {
      _debug(
        'Stalker import skipped for ${profile.record.displayName}: '
        'missing MAC address.',
      );
      return null;
    }

    final configuration = StalkerPortalConfiguration(
      baseUri: profile.lockedBase,
      macAddress: mac,
      userAgent: profile.record.configuration['userAgent'],
      allowSelfSignedTls: profile.record.allowSelfSignedTls,
      extraHeaders: _decodeCustomHeaders(profile),
    );

    try {
      _emitProgress(profile, 'stalker.session');
      final session = await _ref.read(
        stalkerSessionProvider(configuration).future,
      );
      final headers = session.buildAuthenticatedHeaders();
      _emitProgress(profile, 'stalker.categories.fetch');
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
          providerId: providerId,
          resumeStore: resumeStore,
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
          providerId: providerId,
          resumeStore: resumeStore,
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
          providerId: providerId,
          resumeStore: resumeStore,
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
        providerId: providerId,
        resumeStore: resumeStore,
        configuration: configuration,
        headers: headers,
        session: session,
        module: 'itv',
        categories: live,
        enableCategoryPaging: false,
      );
      final vodItems = await _fetchStalkerItems(
        providerId: providerId,
        resumeStore: resumeStore,
        configuration: configuration,
        headers: headers,
        session: session,
        module: 'vod',
        categories: vod,
        enableCategoryPaging: true,
      );
      final seriesItems = await _fetchStalkerItems(
        providerId: providerId,
        resumeStore: resumeStore,
        configuration: configuration,
        headers: headers,
        session: session,
        module: 'series',
        categories: series,
        enableCategoryPaging: true,
      );
      final radioItems = await _fetchStalkerItems(
        providerId: providerId,
        resumeStore: resumeStore,
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
      _emitProgress(
        profile,
        'stalker.categories.ready',
        metadata: {
          'live': live.length,
          'vod': vod.length,
          'series': series.length,
          'radio': radio.length,
        },
      );
      _emitProgress(
        profile,
        'stalker.items.ready',
        metadata: {
          'live': liveItems.length,
          'vod': vodItems.length,
          'series': seriesItems.length,
          'radio': radioItems.length,
        },
      );

      final importer = _ref.read(stalkerImporterProvider);
      return importer.importCatalog(
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
      return null;
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
    const probes = [
      _StalkerCategoryProbe(action: 'get_categories'),
      _StalkerCategoryProbe(
        action: 'get_categories_v2',
        includeJsToggle: false,
      ),
    ];
    for (final probe in probes) {
      final result = await _tryFetchStalkerCategoryProbe(
        config: config,
        session: session,
        headers: baseHeaders,
        module: module,
        probe: probe,
      );
      if (result.isNotEmpty) {
        return result;
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
    return const [];
  }

  Future<List<Map<String, dynamic>>> _tryFetchStalkerCategoryProbe({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String module,
    required _StalkerCategoryProbe probe,
  }) async {
    final toggles = probe.includeJsToggle ? [true, false] : [false];
    for (final includeJs in toggles) {
      try {
        final stopwatch = Stopwatch()..start();
        final envelope = await _stalkerHttpClient.getPortal(
          config,
          queryParameters: {
            'type': module,
            'action': probe.action,
            'token': session.token,
            'mac': config.macAddress.toLowerCase(),
            if (includeJs) 'JsHttpRequest': '1-xml',
          },
          headers: headers,
        );
        stopwatch.stop();
        unawaited(
          _logQueryLatency(
            source: 'stalker.$module.${probe.action}',
            duration: stopwatch.elapsed,
          ),
        );
        final decoded = _decodePortalMap(envelope.body);
        final categories = _extractPortalCategories(decoded);
        if (categories.isNotEmpty) {
          return categories;
        }
      } catch (error, stackTrace) {
        _logError(
          'Stalker categories action ${probe.action} failed for module $module',
          error,
          stackTrace,
        );
        unawaited(
          _logQueryLatency(
            source: 'stalker.$module.${probe.action}',
            duration: Duration.zero,
            success: false,
            metadata: {'error': error.toString()},
          ),
        );
      }
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> _fetchStalkerItems({
    required int providerId,
    required ImportResumeStore resumeStore,
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
        providerId: providerId,
        resumeStore: resumeStore,
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
      providerId: providerId,
      resumeStore: resumeStore,
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
    int? providerId,
    ImportResumeStore? resumeStore,
    bool enableResume = true,
  }) async {
    final results = <Map<String, dynamic>>[];
    int? expectedPages;
    final resumeKey = categoryId ?? '*';
    var startPage = 1;
    final resumeStoreRef = resumeStore;
    final resumeProviderId = providerId;
    if (enableResume &&
        resumeProviderId != null &&
        resumeStoreRef != null) {
      final checkpoint = await resumeStoreRef.readNextPage(
        resumeProviderId,
        module,
        resumeKey,
      );
      if (checkpoint != null && checkpoint > 1) {
        startPage = checkpoint;
      }
    }
    for (var page = startPage; page <= maxPages; page += 1) {
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
        if (enableResume &&
            resumeProviderId != null &&
            resumeStoreRef != null) {
          await resumeStoreRef.writeNextPage(
            resumeProviderId,
            module,
            resumeKey,
            page + 1,
          );
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
    return _extractPortalListFromCandidates(
      parsed,
      const ['data', 'js', 'results'],
    );
  }

  List<Map<String, dynamic>> _extractPortalCategories(
    Map<String, dynamic> parsed,
  ) {
    return _extractPortalListFromCandidates(
      parsed,
      const ['js', 'categories', 'genres', 'data', 'results'],
    );
  }

  static List<Map<String, dynamic>> _extractPortalListFromCandidates(
    Map<String, dynamic> parsed,
    List<String> candidateKeys,
  ) {
    for (final key in candidateKeys) {
      final normalized = _normalizePortalListCandidate(parsed[key]);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>>? _normalizePortalListCandidate(
    dynamic candidate,
  ) {
    if (candidate is List && candidate.isNotEmpty) {
      return candidate
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    }
    if (candidate is Map) {
      const nestedKeys = ['data', 'results', 'items', 'categories', 'genres'];
      for (final nestedKey in nestedKeys) {
        final nested = candidate[nestedKey];
        final normalized = _normalizePortalListCandidate(nested);
        if (normalized != null && normalized.isNotEmpty) {
          return normalized;
        }
      }
    }
    return null;
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
      final data = _extractPortalListFromCandidates(
        decoded,
        const ['js', 'genres', 'data', 'results'],
      );
      if (data.isNotEmpty) {
        return data;
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
    required int providerId,
    required ImportResumeStore resumeStore,
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
              'Stalker skipping locked/censored category $categoryId for module=$module',
            ),
          );
        }
        continue;
      }

      try {
        final entries = await _fetchStalkerListing(
          providerId: providerId,
          resumeStore: resumeStore,
          configuration: configuration,
          headers: headers,
          session: session,
          module: module,
          maxPages: maxPagesPerCategory,
          categoryId: categoryId,
        );
        for (final entry in entries) {
          final idKey = _coerceString(
                entry['id'] ?? entry['cmd'] ?? entry['name'],
              ) ??
              '${categoryId}_${entry.hashCode}';
          if (seenKeys.add('$module:$idKey')) {
            entry.putIfAbsent('category_id', () => categoryId);
            aggregated.add(entry);
          }
        }
      } catch (error, stackTrace) {
        _logError(
          'Stalker category $categoryId fetch failed',
          error,
          stackTrace,
        );
      }
    }

    return aggregated;
  }

  Future<List<Map<String, dynamic>>> _deriveCategoriesFromGlobal({
    required int providerId,
    required ImportResumeStore resumeStore,
    required StalkerPortalConfiguration configuration,
    required Map<String, String> headers,
    required StalkerSession session,
    required String module,
  }) async {
    const samplePages = 5;
    final seeds = await _fetchStalkerListing(
      providerId: providerId,
      resumeStore: resumeStore,
      configuration: configuration,
      headers: headers,
      session: session,
      module: module,
      maxPages: samplePages,
      enableResume: false,
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
      return '${text.substring(0, 200)}ÔÇª';
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

  /// Exposed for unit tests to validate category payload normalization.
  @visibleForTesting
  static List<Map<String, dynamic>> normalizePortalCategoryPayload(
    Map<String, dynamic> payload,
  ) {
    return _extractPortalListFromCandidates(
      payload,
      const ['js', 'categories', 'genres', 'data', 'results'],
    );
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

class _StalkerCategoryProbe {
  const _StalkerCategoryProbe({
    required this.action,
    this.includeJsToggle = true,
  });

  final String action;
  final bool includeJsToggle;
}

class _WorkerHandle {
  _WorkerHandle({
    required this.providerKind,
    required this.cancelCallback,
  });

  final ProviderKind providerKind;
  final Future<void> Function() cancelCallback;

  Future<void> cancel() => cancelCallback();
}

/// --- Progress Reporting & Serialization ------------------------------------

abstract class ProviderImportReporter {
  void report(ProviderImportEvent event);
}

class _LocalImportReporter implements ProviderImportReporter {
  _LocalImportReporter(this._emit);

  final void Function(ProviderImportEvent) _emit;

  @override
  void report(ProviderImportEvent event) {
    _emit(event);
  }
}

class _SendPortImportReporter implements ProviderImportReporter {
  _SendPortImportReporter(this._port);

  final SendPort _port;

  @override
  void report(ProviderImportEvent event) {
    _port.send(ProviderImportEventSerializer.serialize(event));
  }
}

sealed class ProviderImportEvent {
  const ProviderImportEvent({required this.providerId, required this.kind});

  final int providerId;
  final ProviderKind kind;
}

class ProviderImportProgressEvent extends ProviderImportEvent {
  const ProviderImportProgressEvent({
    required super.providerId,
    required super.kind,
    required this.phase,
    this.metadata = const {},
  });

  final String phase;
  final Map<String, Object?> metadata;
}

class ProviderImportResultEvent extends ProviderImportEvent {
  const ProviderImportResultEvent({
    required super.providerId,
    required super.kind,
    required this.metrics,
  });

  final ProviderImportMetricsSummary metrics;
}

class ProviderImportErrorEvent extends ProviderImportEvent {
  const ProviderImportErrorEvent({
    required super.providerId,
    required super.kind,
    required this.message,
  });

  final String message;
}

class ProviderImportMetricsSummary {
  const ProviderImportMetricsSummary({
    this.channelsUpserted = 0,
    this.categoriesUpserted = 0,
    this.moviesUpserted = 0,
    this.seriesUpserted = 0,
    this.seasonsUpserted = 0,
    this.episodesUpserted = 0,
    this.channelsDeleted = 0,
    this.programsUpserted = 0,
    this.durationMs = 0,
  });

  final int channelsUpserted;
  final int categoriesUpserted;
  final int moviesUpserted;
  final int seriesUpserted;
  final int seasonsUpserted;
  final int episodesUpserted;
  final int channelsDeleted;
  final int programsUpserted;
  final int durationMs;

  static ProviderImportMetricsSummary fromMetrics(ImportMetrics? metrics) {
    if (metrics == null) {
      return const ProviderImportMetricsSummary();
    }
    return ProviderImportMetricsSummary(
      channelsUpserted: metrics.channelsUpserted,
      categoriesUpserted: metrics.categoriesUpserted,
      moviesUpserted: metrics.moviesUpserted,
      seriesUpserted: metrics.seriesUpserted,
      seasonsUpserted: metrics.seasonsUpserted,
      episodesUpserted: metrics.episodesUpserted,
      channelsDeleted: metrics.channelsDeleted,
      programsUpserted: metrics.programsUpserted,
      durationMs: metrics.duration.inMilliseconds,
    );
  }

  factory ProviderImportMetricsSummary.fromJson(Map<String, dynamic> json) {
    return ProviderImportMetricsSummary(
      channelsUpserted: json['channelsUpserted'] as int? ?? 0,
      categoriesUpserted: json['categoriesUpserted'] as int? ?? 0,
      moviesUpserted: json['moviesUpserted'] as int? ?? 0,
      seriesUpserted: json['seriesUpserted'] as int? ?? 0,
      seasonsUpserted: json['seasonsUpserted'] as int? ?? 0,
      episodesUpserted: json['episodesUpserted'] as int? ?? 0,
      channelsDeleted: json['channelsDeleted'] as int? ?? 0,
      programsUpserted: json['programsUpserted'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
        'channelsUpserted': channelsUpserted,
        'categoriesUpserted': categoriesUpserted,
        'moviesUpserted': moviesUpserted,
        'seriesUpserted': seriesUpserted,
        'seasonsUpserted': seasonsUpserted,
        'episodesUpserted': episodesUpserted,
        'channelsDeleted': channelsDeleted,
        'programsUpserted': programsUpserted,
        'durationMs': durationMs,
      };
}

class ProviderImportEventSerializer {
  static Map<String, Object?> serialize(ProviderImportEvent event) {
    final base = <String, Object?>{
      'providerId': event.providerId,
      'kind': event.kind.index,
    };
    if (event is ProviderImportProgressEvent) {
      return {
        ...base,
        'type': 'progress',
        'phase': event.phase,
        'metadata': event.metadata,
      };
    }
    if (event is ProviderImportResultEvent) {
      return {
        ...base,
        'type': 'result',
        'metrics': event.metrics.toJson(),
      };
    }
    if (event is ProviderImportErrorEvent) {
      return {
        ...base,
        'type': 'error',
        'message': event.message,
      };
    }
    return {
      ...base,
      'type': 'unknown',
    };
  }

  static ProviderImportEvent? deserialize(Object? message) {
    if (message is! Map) return null;
    final map = message.cast<String, Object?>();
    final providerId = map['providerId'] as int?;
    final kindIndex = map['kind'] as int?;
    if (providerId == null || kindIndex == null) {
      return null;
    }
    final kind = ProviderKind.values[kindIndex];
    switch (map['type']) {
      case 'progress':
        final metadata = (map['metadata'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{};
        return ProviderImportProgressEvent(
          providerId: providerId,
          kind: kind,
          phase: map['phase'] as String? ?? 'unknown',
          metadata: metadata,
        );
      case 'result':
        final metricsJson =
            (map['metrics'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        return ProviderImportResultEvent(
          providerId: providerId,
          kind: kind,
          metrics: ProviderImportMetricsSummary.fromJson(metricsJson),
        );
      case 'error':
        return ProviderImportErrorEvent(
          providerId: providerId,
          kind: kind,
          message: map['message']?.toString() ?? 'unknown error',
        );
      default:
        return null;
    }
  }
}

class _ProviderImportWorkerRequest {
  const _ProviderImportWorkerRequest({
    required this.sendPort,
    required this.profile,
    required this.dbPath,
  });

  final SendPort sendPort;
  final Map<String, Object?> profile;
  final String dbPath;
}

Map<String, Object?> _serializeProfile(ResolvedProviderProfile profile) {
  final record = profile.record;
  return {
    'providerDbId': profile.providerDbId,
    'secrets': profile.secrets,
    'record': {
      'id': record.id,
      'kind': record.kind.index,
      'displayName': record.displayName,
      'lockedBase': record.lockedBase.toString(),
      'needsUserAgent': record.needsUserAgent,
      'allowSelfSignedTls': record.allowSelfSignedTls,
      'followRedirects': record.followRedirects,
      'configuration': record.configuration,
      'hints': record.hints,
      'createdAt': record.createdAt.toIso8601String(),
      'updatedAt': record.updatedAt.toIso8601String(),
      'lastOkAt': record.lastOkAt?.toIso8601String(),
      'lastError': record.lastError,
      'hasSecrets': record.hasSecrets,
    },
  };
}

ResolvedProviderProfile _deserializeProfile(
  Map<String, Object?> payload,
) {
  final recordJson =
      (payload['record'] as Map).cast<String, Object?>();
  final record = ProviderProfileRecord(
    id: recordJson['id'] as String,
    kind: ProviderKind.values[recordJson['kind'] as int],
    displayName: recordJson['displayName'] as String,
    lockedBase: Uri.parse(recordJson['lockedBase'] as String),
    needsUserAgent: recordJson['needsUserAgent'] as bool? ?? false,
    allowSelfSignedTls: recordJson['allowSelfSignedTls'] as bool? ?? false,
    followRedirects: recordJson['followRedirects'] as bool? ?? true,
    configuration:
        (recordJson['configuration'] as Map?)?.cast<String, String>() ??
        const <String, String>{},
    hints: (recordJson['hints'] as Map?)?.cast<String, String>() ??
        const <String, String>{},
    createdAt: DateTime.parse(recordJson['createdAt'] as String),
    updatedAt: DateTime.parse(recordJson['updatedAt'] as String),
    lastOkAt: recordJson['lastOkAt'] == null
        ? null
        : DateTime.parse(recordJson['lastOkAt'] as String),
    lastError: recordJson['lastError'] as String?,
    hasSecrets: recordJson['hasSecrets'] as bool? ?? false,
  );
  final secrets =
      (payload['secrets'] as Map?)?.cast<String, String>() ??
      const <String, String>{};
  final providerDbId = payload['providerDbId'] as int?;
  return ResolvedProviderProfile(
    record: record,
    secrets: secrets,
    providerDbId: providerDbId,
  );
}

Future<void> _providerImportWorkerEntry(
  _ProviderImportWorkerRequest request,
) async {
  final profile = _deserializeProfile(request.profile);
  final dbFile = File(request.dbPath);
  final db = OpenIptvDb.forTesting(
    NativeDatabase(
      dbFile,
      logStatements: false,
    ),
  );
  final resumeStoreFuture =
      ImportResumeStore.openAtDirectory(dbFile.parent.path);
  final telemetryFile = File(
    '${Directory.systemTemp.path}/openiptv_worker_telemetry.log',
  );
  final telemetry = TelemetryService(telemetryFile);
  final container = ProviderContainer(
    overrides: [
      openIptvDbProvider.overrideWithValue(db),
      telemetryServiceProvider.overrideWith((ref) async => telemetry),
      providerImportReporterProvider.overrideWithValue(
        _SendPortImportReporter(request.sendPort),
      ),
      providerImportOffloadProvider.overrideWithValue(false),
      importResumeStoreFutureProvider.overrideWithValue(resumeStoreFuture),
    ],
  );
  try {
    final service = container.read(providerImportServiceProvider);
    await service.runInitialImport(profile);
  } catch (error, stackTrace) {
    request.sendPort.send(
      ProviderImportEventSerializer.serialize(
        ProviderImportErrorEvent(
          providerId: profile.providerDbId ?? -1,
          kind: profile.record.kind,
          message: error.toString(),
        ),
      ),
    );
    Zone.current.handleUncaughtError(error, stackTrace);
  } finally {
    telemetry.dispose();
    container.dispose();
    await db.close();
  }
}

