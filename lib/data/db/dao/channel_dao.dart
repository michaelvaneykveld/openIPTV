import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'channel_dao.g.dart';

@DriftAccessor(tables: [Channels, ChannelCategories])
class ChannelDao extends DatabaseAccessor<OpenIptvDb>
    with _$ChannelDaoMixin {
  ChannelDao(super.db);

  Future<int> upsertChannel({
    required int providerId,
    required String providerKey,
    required String name,
    String? logoUrl,
    int? number,
    bool isRadio = false,
    String? streamUrlTemplate,
    DateTime? seenAt,
  }) {
    final companion = ChannelsCompanion.insert(
      providerId: providerId,
      providerChannelKey: providerKey,
      name: name,
      logoUrl: Value(logoUrl),
      number: Value(number),
      isRadio: Value(isRadio),
      streamUrlTemplate: Value(streamUrlTemplate),
      lastSeenAt: Value(seenAt ?? DateTime.now().toUtc()),
    );
    return into(channels).insertOnConflictUpdate(companion);
  }

  Future<void> markAllAsCandidateForDelete(int providerId) {
    return (update(channels)..where((tbl) => tbl.providerId.equals(providerId))).write(
      ChannelsCompanion(
        lastSeenAt: Value(DateTime.fromMillisecondsSinceEpoch(0)),
      ),
    );
  }

  Future<int> purgeStaleChannels({
    required int providerId,
    required DateTime olderThan,
  }) {
    final query = delete(channels)
      ..where((tbl) => tbl.providerId.equals(providerId))
      ..where((tbl) => tbl.lastSeenAt.isSmallerThanValue(olderThan));
    return query.go();
  }

  Future<int> purgeAllStaleChannels({
    required DateTime olderThan,
  }) {
    final query = delete(channels)
      ..where((tbl) => tbl.lastSeenAt.isNotNull())
      ..where((tbl) => tbl.lastSeenAt.isSmallerThanValue(olderThan));
    return query.go();
  }

  Future<void> linkChannelToCategory({
    required int channelId,
    required int categoryId,
  }) {
    final companion = ChannelCategoriesCompanion.insert(
      channelId: channelId,
      categoryId: categoryId,
    );
    return into(channelCategories).insertOnConflictUpdate(companion);
  }

  Future<int> unlinkChannelFromCategory({
    required int channelId,
    required int categoryId,
  }) {
    final query = delete(channelCategories)
      ..where((tbl) => tbl.channelId.equals(channelId))
      ..where((tbl) => tbl.categoryId.equals(categoryId));
    return query.go();
  }

  Stream<List<ChannelRecord>> watchChannelsForProvider(int providerId) {
    final query =
        select(channels)..where((tbl) => tbl.providerId.equals(providerId));
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.number, mode: OrderingMode.asc),
      (tbl) => OrderingTerm(expression: tbl.name),
    ]);
    return query.watch();
  }

  Future<List<ChannelRecord>> findByProvider(int providerId) {
    final query =
        select(channels)..where((tbl) => tbl.providerId.equals(providerId));
    return query.get();
  }
}
