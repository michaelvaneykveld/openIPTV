import 'dart:math' as math;

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

  Future<int> bulkUpsertChannels(
    List<ChannelsCompanion> entries, {
    int chunkSize = 500,
  }) async {
    if (entries.isEmpty) return 0;
    final safeChunk = math.max(1, chunkSize);
    var total = 0;
    for (var offset = 0; offset < entries.length; offset += safeChunk) {
      final chunk = entries.sublist(
        offset,
        math.min(entries.length, offset + safeChunk),
      );
      await batch((batch) {
        for (final entry in chunk) {
          batch.insert(
            channels,
            entry,
            onConflict: DoUpdate(
              (_) => entry,
              target: [channels.providerId, channels.providerChannelKey],
            ),
          );
        }
      });
      total += chunk.length;
    }
    return total;
  }

  Future<Map<String, int>> fetchIdsForProviderKeys(
    int providerId,
    Iterable<String> providerKeys,
  ) async {
    final distinctKeys = providerKeys.toSet();
    if (distinctKeys.isEmpty) return const {};
    final query = select(channels)
      ..where((tbl) => tbl.providerId.equals(providerId))
      ..where((tbl) => tbl.providerChannelKey.isIn(distinctKeys.toList()));
    final rows = await query.get();
    return {
      for (final row in rows) row.providerChannelKey: row.id,
    };
  }
}
