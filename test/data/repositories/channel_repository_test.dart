import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/category_dao.dart';
import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/user_flag_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/repositories/channel_repository.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  late OpenIptvDb db;
  late ProviderDao providerDao;
  late ChannelDao channelDao;
  late CategoryDao categoryDao;
  late UserFlagDao userFlagDao;
  late ChannelRepository repository;
  late int providerId;
  late int channelA;
  late int channelB;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    providerDao = ProviderDao(db);
    channelDao = ChannelDao(db);
    categoryDao = CategoryDao(db);
    userFlagDao = UserFlagDao(db);
    repository = ChannelRepository(
      channelDao: channelDao,
      categoryDao: categoryDao,
      userFlagDao: userFlagDao,
    );

    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://demo',
        displayName: const Value('Demo'),
      ),
    );

    channelA = await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'A',
      name: 'Channel A',
      number: 1,
      logoUrl: null,
      isRadio: false,
      streamUrlTemplate: null,
    );

    channelB = await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'B',
      name: 'Channel B',
      number: 2,
      logoUrl: null,
      isRadio: false,
      streamUrlTemplate: null,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('watchChannelsWithFlags merges user flags', () async {
    final initial =
        await repository.watchChannelsWithFlags(providerId).first;
    expect(initial, hasLength(2));
    expect(initial.every((entry) => entry.isFavorite == false), isTrue);

    await repository.setChannelFlags(
      providerId: providerId,
      channelId: channelA,
      isFavorite: true,
    );

    final next =
        await repository.watchChannelsWithFlags(providerId).first;
    final flagged = next.firstWhere((entry) => entry.channel.id == channelA);
    expect(flagged.isFavorite, isTrue);
    final other = next.firstWhere((entry) => entry.channel.id == channelB);
    expect(other.isFavorite, isFalse);
  });

  test('watchFavoriteChannels filters flagged entries', () async {
    await repository.setChannelFlags(
      providerId: providerId,
      channelId: channelB,
      isFavorite: true,
    );

    final favorites =
        await repository.watchFavoriteChannels(providerId).first;
    expect(favorites, hasLength(1));
    expect(favorites.single.channel.id, channelB);
  });
}
