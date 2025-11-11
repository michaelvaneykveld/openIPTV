import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;
import 'package:sqlite3/sqlite3.dart';

import '../db/dao/category_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/movie_dao.dart';
import '../db/dao/series_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/dao/import_run_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';
import 'import_context.dart';

final m3uImporterProvider = r.Provider<M3uImporter>((ref) {
  final db = ref.watch(openIptvDbProvider);
  final providerDao = ProviderDao(db);
  final channelDao = ChannelDao(db);
  final categoryDao = CategoryDao(db);
  final summaryDao = SummaryDao(db);
  final movieDao = MovieDao(db);
  final seriesDao = SeriesDao(db);
  final epgDao = EpgDao(db);
  final importRunDao = ImportRunDao(db);
  final context = ImportContext(
    db: db,
    providerDao: providerDao,
    channelDao: channelDao,
    categoryDao: categoryDao,
    movieDao: movieDao,
    seriesDao: seriesDao,
    summaryDao: summaryDao,
    epgDao: epgDao,
    importRunDao: importRunDao,
  );
  return M3uImporter(context);
});

class M3uEntry {
  M3uEntry({
    required this.key,
    required this.name,
    required this.group,
    required this.isRadio,
    this.logoUrl,
  });

  final String key;
  final String name;
  final String group;
  final bool isRadio;
  final String? logoUrl;
}

class M3uImporter {
  M3uImporter(this.context);

  final ImportContext context;
  static const int _rowEstimateBytes = 640;

  Future<ImportMetrics> importEntries({
    required int providerId,
    required Stream<M3uEntry> entries,
  }) async {
    final estimatedBytes = await _estimateWriteBytes(providerId: providerId);
    return context.runWithRetry(
      (txn) async {
        final metrics = ImportMetrics();

        await txn.channels.markAllAsCandidateForDelete(providerId);
        await txn.movies.markAllAsCandidateForDelete(providerId);
        await txn.series.markSeriesForDeletion(providerId);

        final categoryCache = <String, int>{};
        final totals = <CategoryKind, int>{
          for (final kind in CategoryKind.values) kind: 0,
        };

        await for (final entry in entries) {
          final kind = _inferCategoryKind(entry);
          final normalizedGroup = _normalizeGroupName(entry.group);
          final categoryId = await _resolveCategoryId(
            txn: txn,
            cache: categoryCache,
            providerId: providerId,
            kind: kind,
            groupName: normalizedGroup,
            metrics: metrics,
          );
          final seenAt = DateTime.now().toUtc();
          final channelId = await txn.channels.upsertChannel(
            providerId: providerId,
            providerKey: entry.key,
            name: entry.name,
            logoUrl: entry.logoUrl,
            isRadio: kind == CategoryKind.radio,
            streamUrlTemplate: entry.key,
          );
          metrics.channelsUpserted += 1;

          await _safeLinkChannelToCategory(
            txn: txn,
            channelId: channelId,
            categoryId: categoryId,
          );

          totals[kind] = (totals[kind] ?? 0) + 1;
          if (kind == CategoryKind.vod) {
            await txn.movies.upsertMovie(
              providerId: providerId,
              providerVodKey: entry.key,
              title: entry.name,
              categoryId: categoryId,
              posterUrl: entry.logoUrl,
              streamUrlTemplate: entry.key,
              seenAt: seenAt,
            );
            metrics.moviesUpserted += 1;
          } else if (kind == CategoryKind.series) {
            await _upsertSeriesEntry(
              txn: txn,
              providerId: providerId,
              entry: entry,
              categoryId: categoryId,
              metrics: metrics,
              seenAt: seenAt,
            );
          }
        }

        final purgeCutoff = DateTime.now().subtract(const Duration(days: 3));
        metrics.channelsDeleted = await txn.channels.purgeStaleChannels(
          providerId: providerId,
          olderThan: purgeCutoff,
        );
        await txn.movies.purgeStaleMovies(
          providerId: providerId,
          olderThan: purgeCutoff,
        );
        await txn.series.purgeStaleSeries(
          providerId: providerId,
          olderThan: purgeCutoff,
        );

        for (final kind in CategoryKind.values) {
          await txn.summaries.upsertSummary(
            providerId: providerId,
            kind: kind,
            totalItems: totals[kind] ?? 0,
          );
        }

        await txn.providers.setLastSyncAt(
          providerId: providerId,
          lastSyncAt: DateTime.now().toUtc(),
        );

        return metrics;
      },
      providerId: providerId,
      importType: 'm3u.catalog',
      metricsSelector: (result) => result,
      optimizeForLargeImport: true,
      estimatedWriteBytes: estimatedBytes,
    );
  }

  Future<int?> _estimateWriteBytes({required int providerId}) async {
    try {
      final totals = await context.summaryDao.mapForProvider(providerId);
      final totalItems = totals.values.fold<int>(
        0,
        (previous, value) => previous + value,
      );
      if (totalItems <= 0) return null;
      return totalItems * _rowEstimateBytes;
    } catch (_) {
      return null;
    }
  }
}

const _defaultGroupLabel = 'Ungrouped';

Future<void> _safeLinkChannelToCategory({
  required ImportTxn txn,
  required int channelId,
  required int categoryId,
}) async {
  try {
    await txn.channels.linkChannelToCategory(
      channelId: channelId,
      categoryId: categoryId,
    );
  } on SqliteException catch (error) {
    if (error.extendedResultCode == 787) {
      if (kDebugMode) {
        debugPrint(
          'Skipping channel-category link due to missing row '
          '(channelId=$channelId, categoryId=$categoryId)',
        );
      }
      return;
    }
    rethrow;
  }
}

Future<int> _resolveCategoryId({
  required ImportTxn txn,
  required Map<String, int> cache,
  required int providerId,
  required CategoryKind kind,
  required String groupName,
  required ImportMetrics metrics,
}) async {
  final cacheKey = '${kind.name}:$groupName';
  final cached = cache[cacheKey];
  if (cached != null) {
    return cached;
  }
  final id = await txn.categories.upsertCategory(
    providerId: providerId,
    kind: kind,
    providerKey: groupName,
    name: groupName,
    position: null,
  );
  cache[cacheKey] = id;
  metrics.categoriesUpserted += 1;
  return id;
}

String _normalizeGroupName(String? value) {
  if (value == null) {
    return _defaultGroupLabel;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return _defaultGroupLabel;
  }
  return trimmed;
}

CategoryKind _inferCategoryKind(M3uEntry entry) {
  final name = entry.name.toLowerCase();
  final group = entry.group.toLowerCase();
  if (entry.isRadio || name.contains('radio') || _looksLikeRadioGroup(group)) {
    return CategoryKind.radio;
  }
  if (_looksLikeSeriesGroup(group) || name.contains('series')) {
    return CategoryKind.series;
  }
  if (_looksLikeVodGroup(group) ||
      name.contains('movie') ||
      name.contains('film')) {
    return CategoryKind.vod;
  }
  return CategoryKind.live;
}

bool _looksLikeVodGroup(String group) {
  return group.contains('vod') ||
      group.contains('movie') ||
      group.contains('film') ||
      group.contains('filme');
}

bool _looksLikeSeriesGroup(String group) {
  return group.contains('series') ||
      group.contains('shows') ||
      group.contains('serial');
}

bool _looksLikeRadioGroup(String group) {
  return group.contains('radio') || group.contains('audio');
}

Future<void> _upsertSeriesEntry({
  required ImportTxn txn,
  required int providerId,
  required M3uEntry entry,
  required int categoryId,
  required ImportMetrics metrics,
  required DateTime seenAt,
}) async {
  final seriesId = await txn.series.upsertSeries(
    providerId: providerId,
    providerSeriesKey: entry.key,
    title: entry.name,
    categoryId: categoryId,
    posterUrl: entry.logoUrl,
    seenAt: seenAt,
  );
  metrics.seriesUpserted += 1;

  await txn.series.deleteHierarchyForSeries(seriesId);

  final seasonId = await txn.series.upsertSeason(
    seriesId: seriesId,
    seasonNumber: 1,
    name: 'Season 1',
  );
  if (seasonId <= 0) {
    return;
  }
  metrics.seasonsUpserted += 1;

  final episodeId = await txn.series.upsertEpisode(
    seriesId: seriesId,
    seasonId: seasonId,
    providerEpisodeKey: entry.key,
    seasonNumber: 1,
    episodeNumber: 1,
    title: entry.name,
    streamUrlTemplate: entry.key,
    seenAt: seenAt,
  );
  if (episodeId > 0) {
    metrics.episodesUpserted += 1;
  }
}
