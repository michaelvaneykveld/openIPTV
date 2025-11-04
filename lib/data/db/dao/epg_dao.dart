import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'epg_dao.g.dart';

@DriftAccessor(tables: [EpgPrograms, Channels])
class EpgDao extends DatabaseAccessor<OpenIptvDb> with _$EpgDaoMixin {
  EpgDao(super.db);

  Future<void> bulkUpsert(List<EpgProgramsCompanion> programs) async {
    if (programs.isEmpty) return;
    await batch((batch) {
      for (final companion in programs) {
        batch.insert(
          epgPrograms,
          companion,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<int> purgeOlderThan(
    DateTime thresholdUtc, {
    int? providerId,
  }) async {
    if (providerId == null) {
      return (delete(epgPrograms)
            ..where((tbl) => tbl.endUtc.isSmallerThanValue(thresholdUtc)))
          .go();
    }

    final channelIds = await (select(channels)
          ..where((tbl) => tbl.providerId.equals(providerId)))
        .map((row) => row.id)
        .get();
    if (channelIds.isEmpty) return 0;

    return (delete(epgPrograms)
          ..where((tbl) => tbl.endUtc.isSmallerThanValue(thresholdUtc))
          ..where((tbl) => tbl.channelId.isIn(channelIds)))
        .go();
  }

  Stream<List<EpgProgramRecord>> watchNow({
    required int providerId,
    required DateTime nowUtc,
  }) {
    final channelIdQuery = selectOnly(channels)
      ..addColumns([channels.id])
      ..where(channels.providerId.equals(providerId));

    final query = select(epgPrograms)
      ..where((tbl) => tbl.startUtc.isSmallerOrEqualValue(nowUtc))
      ..where((tbl) => tbl.endUtc.isBiggerThanValue(nowUtc))
      ..where((tbl) => tbl.channelId.isInQuery(channelIdQuery))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.startUtc),
      ]);

    return query.watch();
  }

  Future<List<EpgProgramRecord>> fetchRangeForChannel({
    required int channelId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final query = select(epgPrograms)
      ..where((tbl) => tbl.channelId.equals(channelId))
      ..where(
        (tbl) =>
            tbl.endUtc.isBiggerThanValue(rangeStart) &
            tbl.startUtc.isSmallerThanValue(rangeEnd),
      )
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.startUtc),
      ]);
    return query.get();
  }
}





