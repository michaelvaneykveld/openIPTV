import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/dao/import_run_dao.dart';
import '../db/dao/movie_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/series_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/database_locator.dart';
import '../db/openiptv_db.dart';
import 'import_context.dart';

final stalkerImporterProvider = r.Provider<StalkerImporter>((ref) {
  final db = ref.watch(openIptvDbProvider);
  final context = ImportContext(
    db: db,
    providerDao: ProviderDao(db),
    channelDao: ChannelDao(db),
    categoryDao: CategoryDao(db),
    movieDao: MovieDao(db),
    seriesDao: SeriesDao(db),
    summaryDao: SummaryDao(db),
    epgDao: EpgDao(db),
    importRunDao: ImportRunDao(db),
  );
  return StalkerImporter(context);
});

class StalkerImporter {
  StalkerImporter(this.context);

  final ImportContext context;
  static const int _rowEstimateBytes = 640;

  Future<ImportMetrics> importCatalog({
    required int providerId,
    required List<Map<String, dynamic>> liveCategories,
    required List<Map<String, dynamic>> vodCategories,
    List<Map<String, dynamic>>? seriesCategories,
    List<Map<String, dynamic>>? radioCategories,
    List<Map<String, dynamic>> liveItems = const [],
    List<Map<String, dynamic>> vodItems = const [],
    List<Map<String, dynamic>> seriesItems = const [],
    List<Map<String, dynamic>> radioItems = const [],
    int? liveSummaryOverride,
    int? vodSummaryOverride,
    int? seriesSummaryOverride,
    int? radioSummaryOverride,
    StalkerSeriesDetailFetcher? seriesDetailFetcher,
  }) async {
    final estimatedBytes = _estimatePayloadBytes(
      liveCount: liveItems.length,
      vodCount: vodItems.length,
      seriesCount: seriesItems.length,
      radioCount: radioItems.length,
    );
    return context.runWithRetry(
      (txn) async {
        final metrics = ImportMetrics();

        await txn.channels.markAllAsCandidateForDelete(providerId);
        await txn.movies.markAllAsCandidateForDelete(providerId);
        await txn.series.markSeriesForDeletion(providerId);

        final liveCatMap = await _upsertCategorySet(
          txn,
          providerId: providerId,
          kind: CategoryKind.live,
          payload: liveCategories,
          metrics: metrics,
        );
        final vodCatMap = await _upsertCategorySet(
          txn,
          providerId: providerId,
          kind: CategoryKind.vod,
          payload: vodCategories,
          metrics: metrics,
        );
        final seriesCatMap = await _upsertCategorySet(
          txn,
          providerId: providerId,
          kind: CategoryKind.series,
          payload: seriesCategories ?? const [],
          metrics: metrics,
        );
        final radioCatMap = await _upsertCategorySet(
          txn,
          providerId: providerId,
          kind: CategoryKind.radio,
          payload: radioCategories ?? const [],
          metrics: metrics,
        );

        final liveCount = await _upsertChannelEntries(
          txn,
          providerId: providerId,
          items: liveItems,
          categoryIndex: liveCatMap,
          kind: CategoryKind.live,
          isRadio: false,
        );
        final radioCount = await _upsertChannelEntries(
          txn,
          providerId: providerId,
          items: radioItems,
          categoryIndex: radioCatMap,
          kind: CategoryKind.radio,
          isRadio: true,
        );
        final vodCount = await _upsertMovies(
          txn,
          providerId: providerId,
          items: vodItems,
          categoryIndex: vodCatMap,
          metrics: metrics,
        );
        final seriesCount = await _upsertSeries(
          txn,
          providerId: providerId,
          items: seriesItems,
          categoryIndex: seriesCatMap,
          metrics: metrics,
          seriesDetailFetcher: seriesDetailFetcher,
        );
        metrics.channelsUpserted += liveCount + radioCount;

        final purgeCutoff = DateTime.now().toUtc().subtract(
          const Duration(days: 3),
        );
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

        await txn.summaries.upsertSummary(
          providerId: providerId,
          kind: CategoryKind.live,
          totalItems: liveSummaryOverride ?? liveCount,
        );
        await txn.summaries.upsertSummary(
          providerId: providerId,
          kind: CategoryKind.vod,
          totalItems: vodSummaryOverride ?? vodCount,
        );
        await txn.summaries.upsertSummary(
          providerId: providerId,
          kind: CategoryKind.series,
          totalItems: seriesSummaryOverride ?? seriesCount,
        );
        await txn.summaries.upsertSummary(
          providerId: providerId,
          kind: CategoryKind.radio,
          totalItems: radioSummaryOverride ?? radioCount,
        );

        await txn.providers.setLastSyncAt(
          providerId: providerId,
          lastSyncAt: DateTime.now().toUtc(),
        );

        return metrics;
      },
      providerId: providerId,
      importType: 'stalker.catalog',
      metricsSelector: (result) => result,
      optimizeForLargeImport: true,
      estimatedWriteBytes: estimatedBytes,
    );
  }

  Future<Map<String, int>> _upsertCategorySet(
    ImportTxn txn, {
    required int providerId,
    required CategoryKind kind,
    required List<Map<String, dynamic>> payload,
    required ImportMetrics metrics,
  }) async {
    final map = <String, int>{};
    for (final item in payload) {
      final key = _coerceString(
        item['id'] ??
            item['category_id'] ??
            item['tv_genre_id'] ??
            item['alias'],
      );
      final name = _coerceString(
        item['title'] ??
            item['name'] ??
            item['category_name'] ??
            item['tv_genre_title'],
      );
      if (key == null || key.isEmpty || name == null || name.isEmpty) {
        continue;
      }

      final id = await txn.categories.upsertCategory(
        providerId: providerId,
        kind: kind,
        providerKey: key,
        name: name,
        position: _parseInt(item['number'] ?? item['position']),
      );
      map[key] = id;
      metrics.categoriesUpserted += 1;
    }
    return map;
  }

  Future<int> _upsertChannelEntries(
    ImportTxn txn, {
    required int providerId,
    required List<Map<String, dynamic>> items,
    required Map<String, int> categoryIndex,
    required CategoryKind kind,
    required bool isRadio,
  }) async {
    if (items.isEmpty) {
      return 0;
    }
    var count = 0;
    for (final item in items) {
      final key = _resolveChannelKey(item);
      final title =
          _coerceString(item['name'] ?? item['title'] ?? item['cmd']) ?? '';
      if (key.isEmpty || title.isEmpty) {
        continue;
      }
      final channelId = await txn.channels.upsertChannel(
        providerId: providerId,
        providerKey: key,
        name: title,
        logoUrl: _coerceString(
          item['logo'] ?? item['screenshot_uri'] ?? item['icon'],
        ),
        number: _parseInt(item['number'] ?? item['order']),
        isRadio: isRadio,
        streamUrlTemplate: _coerceString(item['cmd']),
      );
      final categoryId = _resolveCategoryId(item, kind, categoryIndex);
      if (categoryId != null) {
        await txn.channels.linkChannelToCategory(
          channelId: channelId,
          categoryId: categoryId,
        );
      }
      count += 1;
    }
    return count;
  }

  Future<int> _upsertMovies(
    ImportTxn txn, {
    required int providerId,
    required List<Map<String, dynamic>> items,
    required Map<String, int> categoryIndex,
    required ImportMetrics metrics,
  }) async {
    if (items.isEmpty) {
      return 0;
    }
    final seenAt = DateTime.now().toUtc();
    var count = 0;
    for (final item in items) {
      final key = _coerceString(item['id'] ?? item['cmd']) ?? '';
      final title =
          _coerceString(item['name'] ?? item['title'] ?? item['cmd']) ?? '';
      if (key.isEmpty || title.isEmpty) continue;
      final categoryId = _resolveCategoryId(
        item,
        CategoryKind.vod,
        categoryIndex,
      );
      await txn.movies.upsertMovie(
        providerId: providerId,
        providerVodKey: key,
        title: title,
        categoryId: categoryId,
        year: _parseYear(item['year']),
        overview: _coerceString(item['description'] ?? item['plot']),
        posterUrl: _coerceString(
          item['screenshot_uri'] ?? item['logo'] ?? item['icon'],
        ),
        durationSec: _parseDurationSeconds(item['time_to_play']),
        streamUrlTemplate: _coerceString(item['cmd']),
        seenAt: seenAt,
      );
      metrics.moviesUpserted += 1;
      count += 1;
    }
    return count;
  }

  Future<int> _upsertSeries(
    ImportTxn txn, {
    required int providerId,
    required List<Map<String, dynamic>> items,
    required Map<String, int> categoryIndex,
    required ImportMetrics metrics,
    StalkerSeriesDetailFetcher? seriesDetailFetcher,
  }) async {
    if (items.isEmpty) {
      return 0;
    }
    final seenAt = DateTime.now().toUtc();
    var count = 0;
    for (final item in items) {
      final key = _coerceString(item['id'] ?? item['cmd']) ?? '';
      final title =
          _coerceString(item['name'] ?? item['title'] ?? item['cmd']) ?? '';
      if (key.isEmpty || title.isEmpty) continue;
      final categoryId = _resolveCategoryId(
        item,
        CategoryKind.series,
        categoryIndex,
      );
      final seriesId = await txn.series.upsertSeries(
        providerId: providerId,
        providerSeriesKey: key,
        title: title,
        categoryId: categoryId,
        year: _parseYear(item['year']),
        overview: _coerceString(item['description'] ?? item['plot']),
        posterUrl: _coerceString(
          item['screenshot_uri'] ?? item['logo'] ?? item['icon'],
        ),
        seenAt: seenAt,
      );
      
      // Import seasons and episodes if series data contains them
      var detailsImported = await _upsertSeriesSeasons(
        txn,
        seriesId: seriesId,
        seriesItem: item,
        seenAt: seenAt,
      );

      // If no seasons found in item and fetcher provided, fetch details
      if (!detailsImported && seriesDetailFetcher != null) {
        final details = await seriesDetailFetcher.fetchSeriesDetails(key);
        if (details != null) {
          await _upsertSeriesSeasons(
            txn,
            seriesId: seriesId,
            seriesItem: details,
            seenAt: seenAt,
          );
        }
      }
      
      metrics.seriesUpserted += 1;
      count += 1;
    }
    return count;
  }

  Future<bool> _upsertSeriesSeasons(
    ImportTxn txn, {
    required int seriesId,
    required Map<String, dynamic> seriesItem,
    required DateTime seenAt,
  }) async {
    // Stalker series can have seasons in 'seasons' array or directly in item
    final seasonsData = seriesItem['seasons'];
    if (seasonsData is! List || seasonsData.isEmpty) {
      return false;
    }

    for (final seasonItem in seasonsData) {
      if (seasonItem is! Map<String, dynamic>) continue;
      
      final seasonNum = _parseInt(
        seasonItem['season_number'] ?? seasonItem['season'] ?? seasonItem['id'],
      );
      if (seasonNum == null) continue;

      final seasonName = _coerceString(
        seasonItem['name'] ?? seasonItem['title'] ?? 'Season $seasonNum',
      );

      final seasonId = await txn.series.upsertSeason(
        seriesId: seriesId,
        seasonNumber: seasonNum,
        name: seasonName,
      );

      // Import episodes for this season
      await _upsertSeasonEpisodes(
        txn,
        seriesId: seriesId,
        seasonId: seasonId,
        seasonNumber: seasonNum,
        seasonItem: seasonItem,
        seenAt: seenAt,
      );
    }
    return true;
  }

  Future<void> _upsertSeasonEpisodes(
    ImportTxn txn, {
    required int seriesId,
    required int seasonId,
    required int seasonNumber,
    required Map<String, dynamic> seasonItem,
    required DateTime seenAt,
  }) async {
    final episodesData = seasonItem['episodes'] ?? seasonItem['series'];
    if (episodesData is! List || episodesData.isEmpty) {
      return;
    }

    for (final episodeItem in episodesData) {
      if (episodeItem is! Map<String, dynamic>) continue;

      final episodeKey = _coerceString(
        episodeItem['id'] ?? episodeItem['cmd'] ?? episodeItem['episode_id'],
      );
      if (episodeKey == null || episodeKey.isEmpty) continue;

      final episodeNum = _parseInt(
        episodeItem['episode_number'] ?? 
        episodeItem['episode'] ?? 
        episodeItem['series'],
      );
      final title = _coerceString(
        episodeItem['name'] ?? 
        episodeItem['title'] ?? 
        'Episode $episodeNum',
      );

      await txn.series.upsertEpisode(
        seriesId: seriesId,
        seasonId: seasonId,
        providerEpisodeKey: episodeKey,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNum,
        title: title,
        overview: _coerceString(
          episodeItem['description'] ?? episodeItem['plot'],
        ),
        durationSec: _parseDurationSeconds(episodeItem['time_to_play']),
        streamUrlTemplate: _coerceString(episodeItem['cmd']),
        seenAt: seenAt,
      );
    }
  }

  int? _resolveCategoryId(
    Map<String, dynamic> item,
    CategoryKind kind,
    Map<String, int> categories,
  ) {
    final key = _coerceString(
      item['category_id'] ??
          item['genre'] ??
          item['tv_genre_id'] ??
          item['genre_id'] ??
          item['fav_category'],
    );
    if (key == null) {
      return null;
    }
    return categories[key];
  }

  String _resolveChannelKey(Map<String, dynamic> item) {
    return _coerceString(
          item['cmd'] ??
              item['stream_url'] ??
              item['id'] ??
              item['ch_id'] ??
              item['number'],
        ) ??
        '';
  }

  String? _coerceString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final text = value.toString();
    return int.tryParse(text);
  }

  int? _parseYear(dynamic value) {
    final text = _coerceString(value);
    if (text == null || text.isEmpty) {
      return null;
    }
    final fourDigits = RegExp(r'\d{4}');
    final match = fourDigits.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return int.tryParse(text);
  }

  int? _parseDurationSeconds(dynamic value) {
    final text = _coerceString(value);
    if (text == null || text.isEmpty) return null;
    if (text.contains(':')) {
      final parts = text.split(':').reversed.toList();
      var total = 0;
      for (var index = 0; index < parts.length; index += 1) {
        final component = int.tryParse(parts[index]) ?? 0;
        final multiplier = switch (index) {
          0 => 1,
          1 => 60,
          2 => 3600,
          _ => 3600,
        };
        total += component * multiplier;
      }
      return total;
    }
    return int.tryParse(text);
  }

  int _estimatePayloadBytes({
    required int liveCount,
    required int vodCount,
    required int seriesCount,
    required int radioCount,
  }) {
    final total = liveCount + vodCount + seriesCount + radioCount;
    if (total <= 0) return 0;
    return total * _rowEstimateBytes;
  }
}

/// Interface for fetching detailed series information from Stalker portal
abstract class StalkerSeriesDetailFetcher {
  Future<Map<String, dynamic>?> fetchSeriesDetails(String seriesId);
}
