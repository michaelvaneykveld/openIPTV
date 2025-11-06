import 'dart:async';

import '../db/dao/category_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/import_run_dao.dart';
import '../db/dao/movie_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/series_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/openiptv_db.dart';

class ImportMetrics {
  int channelsUpserted = 0;
  int categoriesUpserted = 0;
  int moviesUpserted = 0;
  int seriesUpserted = 0;
  int seasonsUpserted = 0;
  int episodesUpserted = 0;
  int channelsDeleted = 0;
  int programsUpserted = 0;
  Duration duration = Duration.zero;
}

typedef ImportAction<T> = Future<T> Function(ImportTxn txn);

class ImportTxn {
  ImportTxn(
    this.db,
    this.providers,
    this.channels,
    this.categories,
    this.movies,
    this.series,
    this.summaries,
    this.epg,
  );

  final OpenIptvDb db;
  final ProviderDao providers;
  final ChannelDao channels;
  final CategoryDao categories;
  final MovieDao movies;
  final SeriesDao series;
  final SummaryDao summaries;
  final EpgDao epg;
}

class ImportContext {
  ImportContext({
    required this.db,
    required this.providerDao,
    required this.channelDao,
    required this.categoryDao,
    required this.movieDao,
    required this.seriesDao,
    required this.summaryDao,
    required this.epgDao,
    required this.importRunDao,
  });

  final OpenIptvDb db;
  final ProviderDao providerDao;
  final ChannelDao channelDao;
  final CategoryDao categoryDao;
  final MovieDao movieDao;
  final SeriesDao seriesDao;
  final SummaryDao summaryDao;
  final EpgDao epgDao;
  final ImportRunDao importRunDao;

  static final Map<int, _AsyncMutex> _providerLocks = {};

  Future<T> run<T>(ImportAction<T> action) async {
    final start = DateTime.now();
    final txn = ImportTxn(
      db,
      providerDao,
      channelDao,
      categoryDao,
      movieDao,
      seriesDao,
      summaryDao,
      epgDao,
    );
    final result = await db.transaction(() => action(txn));
    final duration = DateTime.now().difference(start);
    if (result is ImportMetrics) {
      result.duration = duration;
    }
    return result;
  }

  Future<T> runWithRetry<T>(
    ImportAction<T> action, {
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 200),
    int? providerId,
    String? importType,
    ImportMetricsSelector<T>? metricsSelector,
  }) async {
    final startUtc = DateTime.now().toUtc();
    var attempt = 0;
    Object? lastError;
    while (attempt < maxAttempts) {
      attempt += 1;
      try {
        final result = await _executeWithLock(
          providerId: providerId,
          runAction: () => run(action),
        );
        await _maybeLogImport(
          providerId: providerId,
          importType: importType,
          startedAt: startUtc,
          result: result,
          metricsSelector: metricsSelector,
        );
        return result;
      } catch (error) {
        lastError = error;
        if (attempt >= maxAttempts) {
          await _maybeLogImport(
            providerId: providerId,
            importType: importType,
            startedAt: startUtc,
            error: error,
          );
          break;
        }
        await Future<void>.delayed(delay * attempt);
      }
    }
    throw lastError ?? StateError('Import failed without error.');
  }

  Future<T> _executeWithLock<T>({
    required Future<T> Function() runAction,
    int? providerId,
  }) {
    if (providerId == null) {
      return runAction();
    }
    final mutex = _providerLocks.putIfAbsent(
      providerId,
      () => _AsyncMutex(),
    );
    return mutex.synchronized(runAction);
  }

  Future<void> _maybeLogImport<T>({
    required int? providerId,
    required String? importType,
    required DateTime startedAt,
    T? result,
    ImportMetricsSelector<T>? metricsSelector,
    Object? error,
  }) async {
    if (providerId == null || importType == null) return;
    try {
      final provider =
          await providerDao.findById(providerId);
      if (provider == null) return;

      ImportMetrics? metrics;
      if (result != null && metricsSelector != null) {
        metrics = metricsSelector(result);
      }

      await importRunDao.insertRun(
        providerId: providerId,
        providerKind: provider.kind,
        importType: importType,
        startedAt: startedAt,
        duration: metrics?.duration,
        metrics: metrics == null
            ? null
            : ImportMetricsSnapshot(
                channelsUpserted: metrics.channelsUpserted,
                categoriesUpserted: metrics.categoriesUpserted,
                moviesUpserted: metrics.moviesUpserted,
                seriesUpserted: metrics.seriesUpserted,
                seasonsUpserted: metrics.seasonsUpserted,
                episodesUpserted: metrics.episodesUpserted,
                channelsDeleted: metrics.channelsDeleted,
              ),
        error: error?.toString(),
      );
    } catch (_) {
      // Ignore logging failures.
    }
  }
}

typedef ImportMetricsSelector<T> = ImportMetrics? Function(T result);

class _AsyncMutex {
  Future<void> _pending = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final next = Completer<void>();
    final run = _pending.then((_) => action());
    _pending = next.future;
    return run.whenComplete(() {
      if (!next.isCompleted) {
        next.complete();
      }
    });
  }
}
