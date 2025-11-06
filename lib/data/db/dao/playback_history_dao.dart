import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'playback_history_dao.g.dart';

@DriftAccessor(tables: [PlaybackHistory])
class PlaybackHistoryDao extends DatabaseAccessor<OpenIptvDb>
    with _$PlaybackHistoryDaoMixin {
  PlaybackHistoryDao(super.db);

  Future<PlaybackHistoryRecord?> findByChannel(int channelId) {
    final query = select(playbackHistory)
      ..where((tbl) => tbl.channelId.equals(channelId))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> upsertProgress({
    required int providerId,
    required int channelId,
    required int positionSec,
    int? durationSec,
    bool completed = false,
  }) async {
    final now = DateTime.now().toUtc();
    final updated = await (update(playbackHistory)
          ..where((tbl) => tbl.channelId.equals(channelId)))
        .write(
      PlaybackHistoryCompanion(
        providerId: Value(providerId),
        positionSec: Value(positionSec),
        durationSec: Value(durationSec),
        completed: Value(completed),
        updatedAt: Value(now),
      ),
    );

    if (updated > 0) return;

    await into(playbackHistory).insert(
      PlaybackHistoryCompanion.insert(
        providerId: providerId,
        channelId: channelId,
        startedAt: now,
        updatedAt: now,
        positionSec: Value(positionSec),
        durationSec: Value(durationSec),
        completed: Value(completed),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> clearProgress(int channelId) async {
    await (delete(playbackHistory)
          ..where((tbl) => tbl.channelId.equals(channelId)))
        .go();
  }

  Future<int> pruneOlderThan(DateTime threshold, {int? providerId}) {
    final query = delete(playbackHistory)
      ..where((tbl) => tbl.updatedAt.isSmallerThanValue(threshold));
    if (providerId != null) {
      query.where((tbl) => tbl.providerId.equals(providerId));
    }
    return query.go();
  }

  Stream<List<PlaybackHistoryRecord>> watchRecent({
    required int providerId,
    int limit = 50,
  }) {
    final query = (select(playbackHistory)
          ..where((tbl) => tbl.providerId.equals(providerId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .watch();
    return query;
  }
}
