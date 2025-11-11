import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/movie_dao.dart';
import '../db/dao/series_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/dao/import_run_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';
import 'import_context.dart';

final xtreamImporterProvider = r.Provider<XtreamImporter>((ref) {
  final db = ref.watch(openIptvDbProvider);
  final categoryDao = CategoryDao(db);
  final channelDao = ChannelDao(db);
  final movieDao = MovieDao(db);
  final seriesDao = SeriesDao(db);
  final summaryDao = SummaryDao(db);
  final providerDao = ProviderDao(db);
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
  return XtreamImporter(context);
});

class XtreamImporter {
  XtreamImporter(this.context);

  final ImportContext context;
  static const int _rowEstimateBytes = 640;

  Future<ImportMetrics> importAll({
    required int providerId,
    required List<Map<String, dynamic>> live,
    required List<Map<String, dynamic>> vod,
    required List<Map<String, dynamic>> series,
    required List<Map<String, dynamic>> liveCategories,
    required List<Map<String, dynamic>> vodCategories,
    required List<Map<String, dynamic>> seriesCategories,
    Map<String, List<Map<String, dynamic>>> seriesEpisodes = const {},
  }) async {
    final estimatedBytes = _estimatePayloadBytes(
      live: live,
      vod: vod,
      series: series,
      seriesEpisodes: seriesEpisodes,
    );
    return context.runWithRetry(
      (txn) async {
        final metrics = ImportMetrics();

        await txn.channels.markAllAsCandidateForDelete(providerId);
        await txn.movies.markAllAsCandidateForDelete(providerId);
        await txn.series.markSeriesForDeletion(providerId);

        final liveCategorySplit = _splitRadioCategories(liveCategories);
        final radioCategoryKeys = liveCategorySplit.radio
            .map(_resolveCategoryKey)
            .where((key) => key.isNotEmpty)
            .toSet();
        final liveCatMap = await _upsertCategories(
          txn,
          providerId: providerId,
          kind: CategoryKind.live,
          raw: liveCategorySplit.live,
          metrics: metrics,
        );
        final radioCatMap = liveCategorySplit.radio.isEmpty
            ? <String, int>{}
            : await _upsertCategories(
                txn,
                providerId: providerId,
                kind: CategoryKind.radio,
                raw: liveCategorySplit.radio,
                metrics: metrics,
              );
        final vodCatMap = await _upsertCategories(
          txn,
          providerId: providerId,
          kind: CategoryKind.vod,
          raw: vodCategories,
          metrics: metrics,
        );
        final seriesCatMap = await _upsertCategories(
          txn,
          providerId: providerId,
          kind: CategoryKind.series,
          raw: seriesCategories,
          metrics: metrics,
        );

        final liveStreamSplit = _splitRadioStreams(live, radioCategoryKeys);
        metrics.channelsUpserted += await _upsertChannelPayload(
          txn,
          providerId: providerId,
          raw: liveStreamSplit.live,
          categoryIndex: liveCatMap,
          kind: CategoryKind.live,
          isRadio: false,
        );
        if (liveStreamSplit.radio.isNotEmpty) {
          metrics.channelsUpserted += await _upsertChannelPayload(
            txn,
            providerId: providerId,
            raw: liveStreamSplit.radio,
            categoryIndex: radioCatMap,
            kind: CategoryKind.radio,
            isRadio: true,
          );
        }
        metrics.channelsUpserted += await _upsertChannelPayload(
          txn,
          providerId: providerId,
          raw: vod,
          categoryIndex: vodCatMap,
          kind: CategoryKind.vod,
          isRadio: false,
        );
        metrics.channelsUpserted += await _upsertChannelPayload(
          txn,
          providerId: providerId,
          raw: series,
          categoryIndex: seriesCatMap,
          kind: CategoryKind.series,
          isRadio: false,
        );

        await _upsertMovies(
          txn,
          providerId: providerId,
          payload: vod,
          categoryIndex: vodCatMap,
          metrics: metrics,
        );

        await _upsertSeriesData(
          txn,
          providerId: providerId,
          seriesPayload: series,
          seriesEpisodes: seriesEpisodes,
          categoryIndex: seriesCatMap,
          metrics: metrics,
        );

        final purgeCutoff = DateTime.now().subtract(
          const Duration(days: 7),
        ); // retention window
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

        await _upsertSummary(
          txn,
          providerId: providerId,
          kind: CategoryKind.live,
          total: liveStreamSplit.live.length,
        );
        await _upsertSummary(
          txn,
          providerId: providerId,
          kind: CategoryKind.vod,
          total: metrics.moviesUpserted,
        );
        await _upsertSummary(
          txn,
          providerId: providerId,
          kind: CategoryKind.series,
          total: metrics.seriesUpserted,
        );
        if (liveStreamSplit.radio.isNotEmpty) {
          await _upsertSummary(
            txn,
            providerId: providerId,
            kind: CategoryKind.radio,
            total: liveStreamSplit.radio.length,
          );
        }

        await txn.providers.setLastSyncAt(
          providerId: providerId,
          lastSyncAt: DateTime.now().toUtc(),
        );

        return metrics;
      },
      providerId: providerId,
      importType: 'xtream.catalog',
      metricsSelector: (result) => result,
      optimizeForLargeImport: true,
      estimatedWriteBytes: estimatedBytes,
    );
  }

  Future<Map<String, int>> _upsertCategories(
    ImportTxn txn, {
    required int providerId,
    required CategoryKind kind,
    required List<Map<String, dynamic>> raw,
    required ImportMetrics metrics,
  }) async {
    final result = <String, int>{};
    for (final item in raw) {
      final key = _resolveCategoryKey(item);
      final name = _resolveCategoryName(item);
      final position = _parsePosition(item['position']);
      if (key.isEmpty || name.isEmpty) continue;
      final id = await txn.categories.upsertCategory(
        providerId: providerId,
        kind: kind,
        providerKey: key,
        name: name,
        position: position,
      );
      result[key] = id;
      metrics.categoriesUpserted += 1;
    }
    return result;
  }

  Future<void> _upsertMovies(
    ImportTxn txn, {
    required int providerId,
    required List<Map<String, dynamic>> payload,
    required Map<String, int> categoryIndex,
    required ImportMetrics metrics,
  }) async {
    final seenAt = DateTime.now().toUtc();
    for (final item in payload) {
      final key = _resolveVodKey(item);
      final title = _coerceString(item['name'] ?? item['title']) ?? '';
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
        year: _parseYear(
          item['releasedate'] ?? item['release_date'] ?? item['year'],
        ),
        overview: _coerceString(
          item['plot'] ?? item['description'] ?? item['overview'],
        ),
        posterUrl: _coerceString(
          item['stream_icon'] ?? item['cover'] ?? item['movie_image'],
        ),
        durationSec: _parseDurationSeconds(item['duration']),
        streamUrlTemplate: _coerceString(
          item['stream_url'] ?? item['direct_source'],
        ),
        seenAt: seenAt,
      );
      metrics.moviesUpserted += 1;
    }
  }

  Future<void> _upsertSeriesData(
    ImportTxn txn, {
    required int providerId,
    required List<Map<String, dynamic>> seriesPayload,
    required Map<String, List<Map<String, dynamic>>> seriesEpisodes,
    required Map<String, int> categoryIndex,
    required ImportMetrics metrics,
  }) async {
    final seenAt = DateTime.now().toUtc();
    for (final seriesItem in seriesPayload) {
      final seriesKey = _resolveSeriesKey(seriesItem);
      final title =
          _coerceString(seriesItem['name'] ?? seriesItem['title']) ?? '';
      if (seriesKey.isEmpty || title.isEmpty) continue;
      final categoryId = _resolveCategoryId(
        seriesItem,
        CategoryKind.series,
        categoryIndex,
      );
      await txn.series.upsertSeries(
        providerId: providerId,
        providerSeriesKey: seriesKey,
        title: title,
        categoryId: categoryId,
        year: _parseYear(seriesItem['release_date'] ?? seriesItem['year']),
        overview: _coerceString(
          seriesItem['plot'] ??
              seriesItem['description'] ??
              seriesItem['overview'],
        ),
        posterUrl: _coerceString(
          seriesItem['cover'] ??
              seriesItem['series_icon'] ??
              seriesItem['stream_icon'],
        ),
        seenAt: seenAt,
      );
      metrics.seriesUpserted += 1;

      final seriesRecord = await txn.series.findSeries(
        providerId: providerId,
        providerSeriesKey: seriesKey,
      );
      if (seriesRecord == null) {
        continue;
      }

      await txn.series.deleteHierarchyForSeries(seriesRecord.id);
      final episodes = seriesEpisodes[seriesKey];
      if (episodes == null || episodes.isEmpty) {
        continue;
      }

      final seasonCache = <int, int>{};
      for (final rawEpisode in episodes) {
        final episodeKey = _resolveEpisodeKey(rawEpisode);
        if (episodeKey == null || episodeKey.isEmpty) continue;
        final seasonNumber =
            _parseInt(rawEpisode['season'] ?? rawEpisode['season_number']) ?? 1;
        final episodeNumber = _parseInt(
          rawEpisode['episode'] ?? rawEpisode['episode_num'],
        );

        var seasonId = seasonCache[seasonNumber];
        if (seasonId == null) {
          await txn.series.upsertSeason(
            seriesId: seriesRecord.id,
            seasonNumber: seasonNumber,
            name: _coerceString(rawEpisode['season_name']),
          );
          final seasonRecord = await txn.series.findSeason(
            seriesId: seriesRecord.id,
            seasonNumber: seasonNumber,
          );
          if (seasonRecord == null) {
            continue;
          }
          seasonId = seasonRecord.id;
          seasonCache[seasonNumber] = seasonId;
          metrics.seasonsUpserted += 1;
        }

        await txn.series.upsertEpisode(
          seriesId: seriesRecord.id,
          seasonId: seasonId,
          providerEpisodeKey: episodeKey,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          title: _coerceString(rawEpisode['title'] ?? rawEpisode['name']),
          overview: _coerceString(
            rawEpisode['plot'] ??
                rawEpisode['description'] ??
                rawEpisode['overview'],
          ),
          durationSec: _parseDurationSeconds(rawEpisode['duration']),
          streamUrlTemplate: _coerceString(
            rawEpisode['stream_url'] ??
                rawEpisode['direct_source'] ??
                rawEpisode['url'],
          ),
          seenAt: seenAt,
        );
        metrics.episodesUpserted += 1;
      }
    }
  }

  Future<int> _upsertChannelPayload(
    ImportTxn txn, {
    required int providerId,
    required List<Map<String, dynamic>> raw,
    required Map<String, int> categoryIndex,
    required CategoryKind kind,
    required bool isRadio,
  }) async {
    if (raw.isEmpty) {
      return 0;
    }
    final prepared = <_ChannelUpsertEntry>[];
    for (final item in raw) {
      final key = _resolveChannelKey(item);
      final name = _coerceString(item['name']) ?? '';
      if (key.isEmpty || name.isEmpty) continue;
      final companion = ChannelsCompanion.insert(
        providerId: providerId,
        providerChannelKey: key,
        name: name,
        logoUrl: Value(
          _coerceString(item['stream_icon']) ??
              _coerceString(item['logo']) ??
              _coerceString(item['thumbnail']),
        ),
        number: Value(_parseInt(item['num'])),
        isRadio: Value(isRadio),
        lastSeenAt: Value(DateTime.now().toUtc()),
      );
      prepared.add(
        _ChannelUpsertEntry(
          providerKey: key,
          companion: companion,
          categoryId: _resolveCategoryId(item, kind, categoryIndex),
        ),
      );
    }
    if (prepared.isEmpty) {
      return 0;
    }
    const chunkSize = 750;
    var upserts = 0;
    for (var offset = 0; offset < prepared.length; offset += chunkSize) {
      final chunk = prepared.sublist(
        offset,
        math.min(prepared.length, offset + chunkSize),
      );
      await txn.channels.bulkUpsertChannels(
        chunk.map((entry) => entry.companion).toList(growable: false),
        chunkSize: chunkSize,
      );
      final idMap = await txn.channels.fetchIdsForProviderKeys(
        providerId,
        chunk.map((entry) => entry.providerKey),
      );
      for (final entry in chunk) {
        final categoryId = entry.categoryId;
        if (categoryId == null) continue;
        final channelId = idMap[entry.providerKey];
        if (channelId != null) {
          await txn.channels.linkChannelToCategory(
            channelId: channelId,
            categoryId: categoryId,
          );
        }
      }
      upserts += chunk.length;
    }
    return upserts;
  }

  Future<void> _upsertSummary(
    ImportTxn txn, {
    required int providerId,
    required CategoryKind kind,
    required int total,
  }) {
    return txn.summaries.upsertSummary(
      providerId: providerId,
      kind: kind,
      totalItems: total,
    );
  }

  String _resolveCategoryKey(Map<String, dynamic> item) {
    return _coerceString(
          item['category_id'] ?? item['id'] ?? item['parent_id'],
        ) ??
        '';
  }

  String _resolveCategoryName(Map<String, dynamic> item) {
    return _coerceString(
          item['category_name'] ?? item['name'] ?? item['title'],
        ) ??
        '';
  }

  int? _parsePosition(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  _CategorySplit _splitRadioCategories(List<Map<String, dynamic>> categories) {
    final live = <Map<String, dynamic>>[];
    final radio = <Map<String, dynamic>>[];
    for (final category in categories) {
      final label =
          _coerceString(category['category_name'] ?? category['name']) ?? '';
      if (label.toLowerCase().contains('radio')) {
        radio.add(category);
      } else {
        live.add(category);
      }
    }
    return _CategorySplit(live: live, radio: radio);
  }

  _StreamSplit _splitRadioStreams(
    List<Map<String, dynamic>> streams,
    Set<String> radioCategoryKeys,
  ) {
    final live = <Map<String, dynamic>>[];
    final radio = <Map<String, dynamic>>[];
    for (final stream in streams) {
      if (_looksLikeRadioStream(stream, radioCategoryKeys)) {
        radio.add(stream);
      } else {
        live.add(stream);
      }
    }
    return _StreamSplit(live: live, radio: radio);
  }

  bool _looksLikeRadioStream(
    Map<String, dynamic> stream,
    Set<String> radioCategoryKeys,
  ) {
    final streamType =
        _coerceString(stream['stream_type'])?.toLowerCase() ?? '';
    if (streamType.contains('radio')) {
      return true;
    }
    final flag = stream['is_radio'];
    if (flag is num && flag.toInt() == 1) {
      return true;
    }
    if (flag is bool && flag) {
      return true;
    }
    final categoryId = _coerceString(stream['category_id']);
    if (categoryId != null && radioCategoryKeys.contains(categoryId)) {
      return true;
    }
    final name = _coerceString(stream['name'])?.toLowerCase() ?? '';
    return name.contains('radio');
  }

  String _resolveVodKey(Map<String, dynamic> item) {
    return _coerceString(
          item['stream_id'] ?? item['vod_id'] ?? item['movie_id'] ?? item['id'],
        ) ??
        '';
  }

  String _resolveSeriesKey(Map<String, dynamic> item) {
    return _coerceString(item['series_id'] ?? item['id']) ?? '';
  }

  String? _resolveEpisodeKey(Map<String, dynamic> item) {
    return _coerceString(
      item['id'] ?? item['episode_id'] ?? item['stream_id'] ?? item['file_id'],
    );
  }

  String _resolveChannelKey(Map<String, dynamic> item) {
    return _coerceString(
          item['stream_id'] ??
              item['id'] ??
              item['num'] ??
              item['series_id'] ??
              item['vod_id'],
        ) ??
        '';
  }

  int? _resolveCategoryId(
    Map<String, dynamic> item,
    CategoryKind kind,
    Map<String, int> categories,
  ) {
    final key = switch (kind) {
      CategoryKind.live => _coerceString(item['category_id']),
      CategoryKind.vod => _coerceString(item['category_id']),
      CategoryKind.series => _coerceString(item['category_id']),
      CategoryKind.radio => _coerceString(item['category_id']),
    };
    if (key == null) return null;
    return categories[key];
  }

  String? _coerceString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed;
  }

  int? _parseYear(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final fourDigits = RegExp(r'^\d{4}');
    final match = fourDigits.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return int.tryParse(text);
  }

  int? _parseDurationSeconds(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    if (text.contains(':')) {
      final parts = text.split(':');
      final reversed = parts.reversed.toList();
      var seconds = 0;
      for (var index = 0; index < reversed.length; index++) {
        final component = int.tryParse(reversed[index]) ?? 0;
        final multiplier = switch (index) {
          0 => 1,
          1 => 60,
          2 => 3600,
          _ => 3600,
        };
        seconds += component * multiplier;
      }
      return seconds;
    }
    return int.tryParse(text);
  }

  int _estimatePayloadBytes({
    required List<Map<String, dynamic>> live,
    required List<Map<String, dynamic>> vod,
    required List<Map<String, dynamic>> series,
    required Map<String, List<Map<String, dynamic>>> seriesEpisodes,
  }) {
    final episodeCount = seriesEpisodes.values.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );
    final total = live.length + vod.length + series.length + episodeCount;
    if (total <= 0) return 0;
    return total * _rowEstimateBytes;
  }
}

class _ChannelUpsertEntry {
  _ChannelUpsertEntry({
    required this.providerKey,
    required this.companion,
    this.categoryId,
  });

  final String providerKey;
  final ChannelsCompanion companion;
  final int? categoryId;
}

class _CategorySplit {
  _CategorySplit({required this.live, required this.radio});

  final List<Map<String, dynamic>> live;
  final List<Map<String, dynamic>> radio;
}

class _StreamSplit {
  _StreamSplit({required this.live, required this.radio});

  final List<Map<String, dynamic>> live;
  final List<Map<String, dynamic>> radio;
}
