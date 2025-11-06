import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/user_flag_dao.dart';
import '../db/database_locator.dart';
import '../db/openiptv_db.dart';

const _defaultChannelSearchLimit = 100;
const _defaultVodSearchLimit = 100;

final searchRepositoryProvider = r.Provider<SearchRepository>((ref) {
  final db = ref.watch(openIptvDbProvider);
  return SearchRepository(
    db: db,
    userFlagDao: UserFlagDao(db),
  );
});

class SearchRepository {
  SearchRepository({
    required this.db,
    required this.userFlagDao,
  });

  final OpenIptvDb db;
  final UserFlagDao userFlagDao;

  Future<List<ChannelWithProvider>> searchChannels({
    required int providerId,
    String? query,
    bool includeHidden = false,
    bool favoritesOnly = false,
    bool favoritesFirst = true,
    bool mostRecentFirst = false,
    int? categoryId,
    DateTime? updatedAfter,
    int limit = _defaultChannelSearchLimit,
  }) async {
    final trimmedQuery = query?.trim();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      return _searchChannelsWithFts(
        providerId: providerId,
        query: trimmedQuery,
        includeHidden: includeHidden,
        favoritesOnly: favoritesOnly,
        favoritesFirst: favoritesFirst,
        mostRecentFirst: mostRecentFirst,
        categoryId: categoryId,
        updatedAfter: updatedAfter,
        limit: limit,
      );
    }

    final joinedQuery = _buildChannelQuery(
      providerId: providerId,
      includeHidden: includeHidden,
      favoritesOnly: favoritesOnly,
      mostRecentFirst: mostRecentFirst,
      categoryId: categoryId,
      updatedAfter: updatedAfter,
    );
    joinedQuery
      ..orderBy(
        [
          if (favoritesFirst && !favoritesOnly)
            OrderingTerm(
              expression: db.userFlags.isFavorite,
              mode: OrderingMode.desc,
            ),
          if (mostRecentFirst)
            OrderingTerm(
              expression: db.playbackHistory.updatedAt,
              mode: OrderingMode.desc,
            ),
          OrderingTerm(
            expression: db.channels.name,
            mode: OrderingMode.asc,
          ),
        ],
      )
      ..limit(limit);

    final resultRows = await joinedQuery.get();
    return resultRows
        .map(
          (row) => ChannelWithProvider(
            channel: row.readTable(db.channels),
            flags: row.readTableOrNull(db.userFlags),
            lastWatchedAt: row.readTableOrNull(db.playbackHistory)?.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> setChannelFlags({
    required int providerId,
    required int channelId,
    bool isFavorite = false,
    bool isHidden = false,
    bool isPinned = false,
  }) {
    return userFlagDao.setFlags(
      providerId: providerId,
      channelId: channelId,
      isFavorite: isFavorite,
      isHidden: isHidden,
      isPinned: isPinned,
    );
  }

  Future<List<EpgSearchResult>> searchPrograms({
    required int providerId,
    required String query,
    int limit = 50,
  }) async {
    final normalized = _normalizeFtsQuery(query);
    final results = await db.customSelect(
      '''
      SELECT 
        epg.*,
        channels.provider_id,
        channels.name AS channel_name,
        snippet(epg_programs_fts, 0, '<mark>', '</mark>', '...', 20) AS title_snippet,
        snippet(epg_programs_fts, 1, '<mark>', '</mark>', '...', 20) AS description_snippet
      FROM epg_programs_fts
      JOIN epg_programs epg ON epg_programs_fts.rowid = epg.id
      JOIN channels ON channels.id = epg.channel_id
      WHERE epg_programs_fts MATCH ? AND channels.provider_id = ?
      ORDER BY epg.start_utc DESC
      LIMIT ?
      ''',
      variables: [
        Variable<String>(normalized),
        Variable<int>(providerId),
        Variable<int>(limit),
      ],
    ).get();

    return results
        .map(
          (row) => EpgSearchResult(
            program: db.epgPrograms.map(row.data),
            channelName: row.data['channel_name'] as String?,
            highlightedTitle: row.data['title_snippet'] as String?,
            highlightedDescription: row.data['description_snippet'] as String?,
          ),
        )
        .toList();
  }

  Future<List<VodSearchResult>> searchVod({
    required int providerId,
    required String query,
    List<VodItemKind>? types,
    int limit = _defaultVodSearchLimit,
  }) async {
    final normalized = _normalizeFtsQuery(query);
    final typeFilter = types?.map((e) => e.name).toList() ?? const <String>[];

    final whereTypeClause = typeFilter.isEmpty
        ? ''
        : ' AND item_type IN (${List.filled(typeFilter.length, '?').join(',')})';

    final variables = <Variable>[
      Variable<String>(providerId.toString()),
      Variable<String>(normalized),
      ...typeFilter.map(Variable<String>.new),
      Variable<int>(limit),
    ];

    final rows = await db.customSelect(
      '''
      SELECT
        rowid,
        item_type,
        item_id,
        snippet(vod_search_fts, 0, '<mark>', '</mark>', '...', 24) AS title_snippet,
        snippet(vod_search_fts, 1, '<mark>', '</mark>', '...', 24) AS overview_snippet,
        snippet(vod_search_fts, 2, '<mark>', '</mark>', '...', 24) AS category_snippet,
        bm25(vod_search_fts) AS score
      FROM vod_search_fts
      WHERE provider_id = ?
        AND vod_search_fts MATCH ?$whereTypeClause
      ORDER BY score ASC
      LIMIT ?
      ''',
      variables: variables,
    ).get();

    if (rows.isEmpty) {
      return const [];
    }

    final movieIds = <int>{};
    final seriesIds = <int>{};
    final rankMap = <String, _FtsScoredRow>{};

    for (final row in rows) {
      final type = VodItemKindExtension.fromString(row.data['item_type'] as String);
      final id = int.parse(row.data['item_id'] as String);
      final score = row.data['score'] as num;
      final titleSnippet = row.data['title_snippet'] as String?;
      final overviewSnippet = row.data['overview_snippet'] as String?;
      final categorySnippet = row.data['category_snippet'] as String?;

      rankMap['${type.name}-$id'] = _FtsScoredRow(
        score: score.toDouble(),
        titleHighlight: titleSnippet,
        descriptionHighlight: overviewSnippet,
        categoryHighlight: categorySnippet,
      );

      switch (type) {
        case VodItemKind.movie:
          movieIds.add(id);
          break;
        case VodItemKind.series:
          seriesIds.add(id);
          break;
      }
    }

    final moviesById = await _fetchMoviesById(movieIds);
    final seriesById = await _fetchSeriesById(seriesIds);

    final results = <VodSearchResult>[];
    for (final row in rows) {
      final type = VodItemKindExtension.fromString(row.data['item_type'] as String);
      final id = int.parse(row.data['item_id'] as String);
      final key = '${type.name}-$id';
      final highlights = rankMap[key];
      if (highlights == null) continue;

      switch (type) {
        case VodItemKind.movie:
          final movie = moviesById[id];
          if (movie == null) continue;
          results.add(
            VodSearchResult(
              kind: VodItemKind.movie,
              movie: movie,
              highlightedTitle: highlights.titleHighlight,
              highlightedDescription: highlights.descriptionHighlight,
              highlightedCategories: highlights.categoryHighlight,
            ),
          );
          break;
        case VodItemKind.series:
          final series = seriesById[id];
          if (series == null) continue;
          results.add(
            VodSearchResult(
              kind: VodItemKind.series,
              series: series,
              highlightedTitle: highlights.titleHighlight,
              highlightedDescription: highlights.descriptionHighlight,
              highlightedCategories: highlights.categoryHighlight,
            ),
          );
          break;
      }
    }

    return results;
  }

  Future<SearchDashboardSummary> loadDashboardSummary({
    required int providerId,
    Duration recentWindow = const Duration(days: 7),
  }) async {
    final summaryRows =
        await (db.select(db.summaries)..where((tbl) => tbl.providerId.equals(providerId))).get();

    var liveCount = 0;
    var vodCount = 0;
    var seriesCount = 0;
    var radioCount = 0;
    DateTime? latestSummaryUpdate;

    for (final row in summaryRows) {
      latestSummaryUpdate = _maxDate(latestSummaryUpdate, row.updatedAt);
      switch (row.kind) {
        case CategoryKind.live:
          liveCount = row.totalItems;
          break;
        case CategoryKind.vod:
          vodCount = row.totalItems;
          break;
        case CategoryKind.series:
          seriesCount = row.totalItems;
          break;
        case CategoryKind.radio:
          radioCount = row.totalItems;
          break;
      }
    }

    final favoritesCount = await _countUserFlag(
      providerId: providerId,
      predicate: (tbl) => tbl.isFavorite.equals(true),
    );
    final hiddenCount = await _countUserFlag(
      providerId: providerId,
      predicate: (tbl) => tbl.isHidden.equals(true),
    );

    final recentThreshold = DateTime.now().toUtc().subtract(recentWindow);
    final recentCount = await (db.selectOnly(db.playbackHistory)
          ..addColumns([db.playbackHistory.channelId.count(distinct: true)])
          ..where(db.playbackHistory.providerId.equals(providerId))
          ..where(db.playbackHistory.updatedAt.isBiggerThanValue(recentThreshold)))
        .map((row) => row.read(db.playbackHistory.channelId.count(distinct: true)) ?? 0)
        .getSingle();

    return SearchDashboardSummary(
      providerId: providerId,
      liveChannels: liveCount,
      vodItems: vodCount,
      seriesItems: seriesCount,
      radioChannels: radioCount,
      favoriteChannels: favoritesCount,
      hiddenChannels: hiddenCount,
      recentlyWatchedChannels: recentCount,
      lastSummaryUpdatedAt: latestSummaryUpdate,
    );
  }

  Future<List<ChannelWithProvider>> _searchChannelsWithFts({
    required int providerId,
    required String query,
    required bool includeHidden,
    required bool favoritesOnly,
    required bool favoritesFirst,
    required bool mostRecentFirst,
    required int? categoryId,
    required DateTime? updatedAfter,
    required int limit,
  }) async {
    final normalized = _normalizeFtsQuery(query);
    final ftsRows = await db.customSelect(
      '''
      SELECT
        CAST(channel_id AS INTEGER) AS channel_id,
        snippet(channel_search_fts, 0, '<mark>', '</mark>', '...', 20) AS name_snippet,
        snippet(channel_search_fts, 2, '<mark>', '</mark>', '...', 20) AS category_snippet,
        bm25(channel_search_fts) AS score
      FROM channel_search_fts
      WHERE provider_id = ?
        AND channel_search_fts MATCH ?
      ORDER BY score ASC
      LIMIT ?
      ''',
      variables: [
        Variable<String>(providerId.toString()),
        Variable<String>(normalized),
        Variable<int>(limit),
      ],
    ).get();

    if (ftsRows.isEmpty) {
      return const [];
    }

    final channelOrder = <int, double>{};
    final highlights = <int, _FtsScoredRow>{};

    for (final row in ftsRows) {
      final channelId = row.data['channel_id'] as int;
      final score = row.data['score'] as num;
      channelOrder[channelId] = score.toDouble();
      highlights[channelId] = _FtsScoredRow(
        score: score.toDouble(),
        titleHighlight: row.data['name_snippet'] as String?,
        categoryHighlight: row.data['category_snippet'] as String?,
      );
    }

    final channelIds = channelOrder.keys.toList();

    final joinedQuery = _buildChannelQuery(
      providerId: providerId,
      includeHidden: includeHidden,
      favoritesOnly: favoritesOnly,
      mostRecentFirst: mostRecentFirst,
      categoryId: categoryId,
      updatedAfter: updatedAfter,
      channelFilter: channelIds,
    );

    final rows = await joinedQuery.get();
    final channels = rows
        .map(
          (row) {
            final channel = row.readTable(db.channels);
            final flags = row.readTableOrNull(db.userFlags);
            final lastWatched = row.readTableOrNull(db.playbackHistory)?.updatedAt;
            final highlight = highlights[channel.id];
            if (highlight == null) {
              return null;
            }
            return ChannelWithProvider(
              channel: channel,
              flags: flags,
              lastWatchedAt: lastWatched,
              highlightedName: highlight.titleHighlight,
              highlightedCategories: highlight.categoryHighlight,
            );
          },
        )
        .whereType<ChannelWithProvider>()
        .toList();

    channels.sort(
      (a, b) {
        if (favoritesFirst && !favoritesOnly) {
          final favComparison = (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0);
          if (favComparison != 0) return favComparison;
        }

        if (mostRecentFirst) {
          final aTime = a.lastWatchedAt;
          final bTime = b.lastWatchedAt;
          if (aTime != null || bTime != null) {
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            final recency = bTime.compareTo(aTime);
            if (recency != 0) return recency;
          }
        }

        final aScore = channelOrder[a.channel.id] ?? double.maxFinite;
        final bScore = channelOrder[b.channel.id] ?? double.maxFinite;
        final scoreComparison = aScore.compareTo(bScore);
        if (scoreComparison != 0) return scoreComparison;

        return a.channel.name.compareTo(b.channel.name);
      },
    );

    return channels;
  }

  JoinedSelectStatement<dynamic, dynamic> _buildChannelQuery({
    required int providerId,
    required bool includeHidden,
    required bool favoritesOnly,
    required bool mostRecentFirst,
    int? categoryId,
    DateTime? updatedAfter,
    List<int>? channelFilter,
  }) {
    final channels = db.channels;
    final userFlags = db.userFlags;
    final history = db.playbackHistory;
    final categoryLinks = db.channelCategories;

    final needsHistoryJoin = updatedAfter != null || mostRecentFirst;

    final joins = <Join>[
      leftOuterJoin(
        userFlags,
        userFlags.channelId.equalsExp(channels.id),
      ),
    ];

    if (needsHistoryJoin) {
      joins.add(
        leftOuterJoin(
          history,
          history.channelId.equalsExp(channels.id) &
              history.providerId.equals(providerId),
        ),
      );
    }

    if (categoryId != null) {
      joins.add(
        innerJoin(
          categoryLinks,
          categoryLinks.channelId.equalsExp(channels.id) &
              categoryLinks.categoryId.equals(categoryId),
        ),
      );
    }

    final query = db.select(channels).join(joins)
      ..where(channels.providerId.equals(providerId));

    if (channelFilter != null && channelFilter.isNotEmpty) {
      query.where(channels.id.isIn(channelFilter));
    }

    if (!includeHidden) {
      query.where(userFlags.id.isNull() | userFlags.isHidden.equals(false));
    }

    if (favoritesOnly) {
      query.where(userFlags.isFavorite.equals(true));
    }

    if (updatedAfter != null) {
      query.where(history.updatedAt.isBiggerThanValue(updatedAfter));
    }

    return query;
  }

  Future<Map<int, MovieRecord>> _fetchMoviesById(Set<int> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (db.select(db.movies)..where((tbl) => tbl.id.isIn(ids))).get();
    return {for (final row in rows) row.id: row};
  }

  Future<Map<int, SeriesRecord>> _fetchSeriesById(Set<int> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (db.select(db.series)..where((tbl) => tbl.id.isIn(ids))).get();
    return {for (final row in rows) row.id: row};
  }

  Future<int> _countUserFlag({
    required int providerId,
    required Expression<bool> Function(UserFlags) predicate,
  }) async {
    final result = await (db.selectOnly(db.userFlags)
          ..addColumns([db.userFlags.id.count()])
          ..where(db.userFlags.providerId.equals(providerId))
          ..where(predicate(db.userFlags)))
        .map((row) => row.read(db.userFlags.id.count()) ?? 0)
        .getSingle();
    return result;
  }

  String _normalizeFtsQuery(String raw) {
    final tokens = raw
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .map((token) => '$token*')
        .join(' ');
    if (tokens.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'Query must not be empty.');
    }
    return tokens;
  }

  DateTime? _maxDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}

class ChannelWithProvider {
  ChannelWithProvider({
    required this.channel,
    required this.flags,
    this.lastWatchedAt,
    this.highlightedName,
    this.highlightedCategories,
  });

  final ChannelRecord channel;
  final UserFlagRecord? flags;
  final DateTime? lastWatchedAt;
  final String? highlightedName;
  final String? highlightedCategories;

  bool get isFavorite => flags?.isFavorite ?? false;
  bool get isHidden => flags?.isHidden ?? false;
  bool get hasWatchHistory => lastWatchedAt != null;
}

class EpgSearchResult {
  EpgSearchResult({
    required this.program,
    required this.channelName,
    this.highlightedTitle,
    this.highlightedDescription,
  });

  final EpgProgramRecord program;
  final String? channelName;
  final String? highlightedTitle;
  final String? highlightedDescription;
}

enum VodItemKind { movie, series }

extension VodItemKindExtension on VodItemKind {
  static VodItemKind fromString(String value) {
    return VodItemKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => VodItemKind.movie,
    );
  }
}

class VodSearchResult {
  VodSearchResult({
    required this.kind,
    this.movie,
    this.series,
    this.highlightedTitle,
    this.highlightedDescription,
    this.highlightedCategories,
  }) : assert(
          (kind == VodItemKind.movie && movie != null && series == null) ||
              (kind == VodItemKind.series && series != null && movie == null),
          'Provide the matching record for the selected kind.',
        );

  final VodItemKind kind;
  final MovieRecord? movie;
  final SeriesRecord? series;
  final String? highlightedTitle;
  final String? highlightedDescription;
  final String? highlightedCategories;
}

class SearchDashboardSummary {
  SearchDashboardSummary({
    required this.providerId,
    required this.liveChannels,
    required this.vodItems,
    required this.seriesItems,
    required this.radioChannels,
    required this.favoriteChannels,
    required this.hiddenChannels,
    required this.recentlyWatchedChannels,
    this.lastSummaryUpdatedAt,
  });

  final int providerId;
  final int liveChannels;
  final int vodItems;
  final int seriesItems;
  final int radioChannels;
  final int favoriteChannels;
  final int hiddenChannels;
  final int recentlyWatchedChannels;
  final DateTime? lastSummaryUpdatedAt;
}

class _FtsScoredRow {
  const _FtsScoredRow({
    required this.score,
    this.titleHighlight,
    this.descriptionHighlight,
    this.categoryHighlight,
  });

  final double score;
  final String? titleHighlight;
  final String? descriptionHighlight;
  final String? categoryHighlight;
}
