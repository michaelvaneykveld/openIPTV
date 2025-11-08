import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  group('ChannelDao bulk upsert', () {
    late OpenIptvDb db;
    late ChannelDao channelDao;
    late ProviderDao providerDao;
    late int providerId;

    setUp(() async {
      db = OpenIptvDb.inMemory();
      channelDao = ChannelDao(db);
      providerDao = ProviderDao(db);
      providerId = await providerDao.createProvider(
        ProvidersCompanion.insert(
          kind: ProviderKind.xtream,
          lockedBase: 'https://seeded.example/',
          displayName: const Value('Seeded'),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('inserts and updates channels in chunks', () async {
      final entries = List.generate(1200, (index) {
        return ChannelsCompanion.insert(
          providerId: providerId,
          providerChannelKey: 'key-$index',
          name: 'Channel $index',
          number: Value(index),
          isRadio: const Value(false),
          lastSeenAt: Value(DateTime.utc(2024, 1, 1).add(Duration(seconds: index))),
        );
      });

      final inserted =
          await channelDao.bulkUpsertChannels(entries, chunkSize: 200);
      expect(inserted, entries.length);

      final idMap = await channelDao.fetchIdsForProviderKeys(
        providerId,
        ['key-0', 'key-1199'],
      );
      expect(idMap.length, 2);

      final updatedEntries = [
        ChannelsCompanion.insert(
          providerId: providerId,
          providerChannelKey: 'key-0',
          name: 'Updated Channel 0',
          isRadio: const Value(false),
          lastSeenAt: Value(DateTime.utc(2025, 1, 1)),
        ),
      ];
      await channelDao.bulkUpsertChannels(updatedEntries, chunkSize: 200);

      final updatedRow = await (db.select(db.channels)
            ..where((tbl) => tbl.providerId.equals(providerId))
            ..where((tbl) => tbl.providerChannelKey.equals('key-0')))
          .getSingle();
      expect(updatedRow.name, 'Updated Channel 0');
    });
  });
}
