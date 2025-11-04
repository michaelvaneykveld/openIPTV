import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';

final channelDaoProvider = r.Provider<ChannelDao>(
  (ref) => ChannelDao(ref.watch(openIptvDbProvider)),
);

final categoryDaoProvider = r.Provider<CategoryDao>(
  (ref) => CategoryDao(ref.watch(openIptvDbProvider)),
);

final channelRepositoryProvider = r.Provider<ChannelRepository>(
  (ref) => ChannelRepository(
    channelDao: ref.watch(channelDaoProvider),
    categoryDao: ref.watch(categoryDaoProvider),
  ),
);

class ChannelRepository {
  ChannelRepository({
    required this.channelDao,
    required this.categoryDao,
  });

  final ChannelDao channelDao;
  final CategoryDao categoryDao;

  Stream<List<ChannelRecord>> watchChannels(int providerId) =>
      channelDao.watchChannelsForProvider(providerId);

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
}
