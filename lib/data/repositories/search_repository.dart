import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/user_flag_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';

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
  }) async {
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

    final select = db.select(channels).join(joins)
      ..where(channels.providerId.equals(providerId));

    if (!includeHidden) {
      select.where(
        userFlags.id.isNull() | userFlags.isHidden.equals(false),
      );
    }

    if (favoritesOnly) {
      select.where(
        userFlags.isFavorite.equals(true),
      );
    }

    if (updatedAfter != null) {
      select.where(history.updatedAt.isBiggerThanValue(updatedAfter));
    }

    if (query != null && query.trim().isNotEmpty) {
      final normalized = query.trim().toLowerCase();
      select.where(
        channels.name.lower().like('%$normalized%') |
            channels.providerChannelKey.lower().like('%$normalized%'),
      );
    }

    final ordering = <OrderingTerm>[];

    if (favoritesFirst && !favoritesOnly) {
      ordering.add(
        OrderingTerm(
          expression: userFlags.isFavorite,
          mode: OrderingMode.desc,
        ),
      );
    }

    if (mostRecentFirst && needsHistoryJoin) {
      ordering.add(
        OrderingTerm(
          expression: history.updatedAt,
          mode: OrderingMode.desc,
        ),
      );
    }

    ordering.add(
      OrderingTerm(
        expression: channels.name,
        mode: OrderingMode.asc,
      ),
    );

    select.orderBy(ordering);

    final rows = await select.get();
    return rows
        .map(
          (row) => ChannelWithProvider(
            channel: row.readTable(channels),
            flags: row.readTableOrNull(userFlags),
            lastWatchedAt: needsHistoryJoin
                ? row.readTableOrNull(history)?.updatedAt
                : null,
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
}

class ChannelWithProvider {
  ChannelWithProvider({
    required this.channel,
    required this.flags,
    this.lastWatchedAt,
  });

  final ChannelRecord channel;
  final UserFlagRecord? flags;
  final DateTime? lastWatchedAt;

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
