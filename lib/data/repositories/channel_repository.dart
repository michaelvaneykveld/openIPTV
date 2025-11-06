import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/user_flag_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';

final channelDaoProvider = r.Provider<ChannelDao>(
  (ref) => ChannelDao(ref.watch(openIptvDbProvider)),
);

final categoryDaoProvider = r.Provider<CategoryDao>(
  (ref) => CategoryDao(ref.watch(openIptvDbProvider)),
);

final userFlagDaoProvider = r.Provider<UserFlagDao>(
  (ref) => UserFlagDao(ref.watch(openIptvDbProvider)),
);

final channelRepositoryProvider = r.Provider<ChannelRepository>(
  (ref) => ChannelRepository(
    channelDao: ref.watch(channelDaoProvider),
    categoryDao: ref.watch(categoryDaoProvider),
    userFlagDao: ref.watch(userFlagDaoProvider),
  ),
);

class ChannelRepository {
  ChannelRepository({
    required this.channelDao,
    required this.categoryDao,
    required this.userFlagDao,
  });

  final ChannelDao channelDao;
  final CategoryDao categoryDao;
  final UserFlagDao userFlagDao;

  Stream<List<ChannelRecord>> watchChannels(int providerId) =>
      channelDao.watchChannelsForProvider(providerId);

  Stream<List<ChannelWithFlags>> watchChannelsWithFlags(int providerId) {
    final channels = channelDao.channels;
    final flags = userFlagDao.userFlags;

    final query = channelDao
        .select(channels)
      ..where((tbl) => tbl.providerId.equals(providerId))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.number, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.name),
      ]);

    final joined = query.join([
      leftOuterJoin(
        flags,
        flags.channelId.equalsExp(channels.id),
      ),
    ]);

    return joined.watch().map(
          (rows) => rows
              .map(
                (row) => ChannelWithFlags(
                  channel: row.readTable(channels),
                  flags: row.readTableOrNull(flags),
                ),
              )
              .toList(),
        );
  }

  Stream<List<ChannelWithFlags>> watchFavoriteChannels(int providerId) =>
      watchChannelsWithFlags(providerId).map(
        (channels) =>
            channels.where((entry) => entry.isFavorite).toList(),
      );

  Future<List<ChannelRecord>> listChannels(int providerId) =>
      channelDao.findByProvider(providerId);

  Stream<List<CategoryRecord>> watchCategories(
    int providerId, {
    CategoryKind? kind,
  }) =>
      categoryDao.watchForProvider(providerId, kind: kind);

  Future<int> upsertCategory({
    required int providerId,
    required CategoryKind kind,
    required String providerKey,
    required String name,
    int? position,
  }) =>
      categoryDao.upsertCategory(
        providerId: providerId,
        kind: kind,
        providerKey: providerKey,
        name: name,
        position: position,
      );

  Future<int> upsertChannel({
    required int providerId,
    required String providerKey,
    required String name,
    String? logoUrl,
    int? number,
    bool isRadio = false,
    String? streamUrlTemplate,
    DateTime? seenAt,
  }) =>
      channelDao.upsertChannel(
        providerId: providerId,
        providerKey: providerKey,
        name: name,
        logoUrl: logoUrl,
        number: number,
        isRadio: isRadio,
        streamUrlTemplate: streamUrlTemplate,
        seenAt: seenAt,
      );

  Future<void> linkChannelToCategory({
    required int channelId,
    required int categoryId,
  }) =>
      channelDao.linkChannelToCategory(
        channelId: channelId,
        categoryId: categoryId,
      );

  Future<int> purgeStaleChannels({
    required int providerId,
    required DateTime olderThan,
  }) =>
      channelDao.purgeStaleChannels(
        providerId: providerId,
        olderThan: olderThan,
      );

  Future<void> markAllForDeletion(int providerId) =>
      channelDao.markAllAsCandidateForDelete(providerId);

  Future<void> setChannelFlags({
    required int providerId,
    required int channelId,
    bool isFavorite = false,
    bool isHidden = false,
    bool isPinned = false,
  }) =>
      userFlagDao.setFlags(
        providerId: providerId,
        channelId: channelId,
        isFavorite: isFavorite,
        isHidden: isHidden,
        isPinned: isPinned,
      );

  Stream<UserFlagRecord?> watchFlagForChannel(int channelId) =>
      userFlagDao.watchForChannel(channelId);
}

class ChannelWithFlags {
  ChannelWithFlags({
    required this.channel,
    required this.flags,
  });

  final ChannelRecord channel;
  final UserFlagRecord? flags;

  bool get isFavorite => flags?.isFavorite ?? false;
  bool get isHidden => flags?.isHidden ?? false;
  bool get isPinned => flags?.isPinned ?? false;
}
