import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'user_flag_dao.g.dart';

@DriftAccessor(tables: [UserFlags])
class UserFlagDao extends DatabaseAccessor<OpenIptvDb>
    with _$UserFlagDaoMixin {
  UserFlagDao(super.db);

  Future<UserFlagRecord?> findByChannel(int channelId) {
    final query = select(userFlags)
      ..where((tbl) => tbl.channelId.equals(channelId))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> setFlags({
    required int providerId,
    required int channelId,
    bool isFavorite = false,
    bool isHidden = false,
    bool isPinned = false,
  }) async {
    if (!isFavorite && !isHidden && !isPinned) {
      await (delete(userFlags)
            ..where((tbl) => tbl.channelId.equals(channelId)))
          .go();
      return;
    }

    final now = DateTime.now().toUtc();
    await into(userFlags).insert(
      UserFlagsCompanion.insert(
        providerId: providerId,
        channelId: channelId,
        isFavorite: Value(isFavorite),
        isHidden: Value(isHidden),
        isPinned: Value(isPinned),
        updatedAt: now,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> clearAllForProvider(int providerId) async {
    await (delete(userFlags)..where((tbl) => tbl.providerId.equals(providerId)))
        .go();
  }

  Stream<List<UserFlagRecord>> watchForProvider(int providerId) {
    final query =
        select(userFlags)..where((tbl) => tbl.providerId.equals(providerId));
    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.updatedAt,
            mode: OrderingMode.desc,
          ),
    ]);
    return query.watch();
  }

  Stream<UserFlagRecord?> watchForChannel(int channelId) {
    final query = select(userFlags)
      ..where((tbl) => tbl.channelId.equals(channelId))
      ..limit(1);
    return query.watchSingleOrNull();
  }
}

