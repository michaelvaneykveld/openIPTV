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
  group('ChannelRepository pagination', () {
    late OpenIptvDb db;
    late ChannelRepository repository;
    late ProviderDao providerDao;
    late ChannelDao channelDao;
    late UserFlagDao userFlagDao;
    late int providerId;

    setUp(() async {
      db = OpenIptvDb.inMemory();
      providerDao = ProviderDao(db);
      channelDao = ChannelDao(db);
      userFlagDao = UserFlagDao(db);
      repository = ChannelRepository(
        channelDao: channelDao,
        categoryDao: CategoryDao(db),
        userFlagDao: userFlagDao,
      );
      providerId = await providerDao.createProvider(
        ProvidersCompanion.insert(
          kind: ProviderKind.xtream,
          lockedBase: 'https://seeded.example/',
          displayName: const Value('Seeded'),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await channelDao.upsertChannel(
          providerId: providerId,
          providerKey: 'key-$i',
          name: 'Channel $i',
          number: i,
        );
      }
      await userFlagDao.setFlags(
        providerId: providerId,
        channelId: 3,
        isFavorite: true,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('returns paginated chunks with cursor', () async {
      expect(
        (await channelDao.findByProvider(providerId)).length,
        5,
      );
      final firstPage = await repository.fetchChannelPage(
        providerId: providerId,
        limit: 2,
      );
      expect(firstPage.items.length, 2);
      expect(firstPage.nextCursor, isNotNull);
      expect(firstPage.hasMore, isTrue);
      expect(firstPage.items.first.channel.name, 'Channel 0');
      expect(
        firstPage.items.map((c) => c.channel.name).toList(),
        ['Channel 0', 'Channel 1'],
      );

      final secondPage = await repository.fetchChannelPage(
        providerId: providerId,
        limit: 2,
        afterChannelId: firstPage.nextCursor,
      );
      expect(secondPage.items.first.channel.name, 'Channel 2');
      expect(secondPage.items.first.isFavorite, isTrue);

      final finalPage = await repository.fetchChannelPage(
        providerId: providerId,
        limit: 2,
        afterChannelId: secondPage.nextCursor,
      );
      expect(finalPage.items.length, 1);
      expect(finalPage.hasMore, isFalse);
    });
  });
}
