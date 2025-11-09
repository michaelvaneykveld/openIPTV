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

    test('upsertChannel updates on provider/key conflicts', () async {
      final channelId = await channelDao.upsertChannel(
        providerId: providerId,
        providerKey: 'dup-key',
        name: 'Original',
        number: 1,
      );
      final secondId = await channelDao.upsertChannel(
        providerId: providerId,
        providerKey: 'dup-key',
        name: 'Updated',
        number: 5,
        isRadio: true,
      );
      expect(secondId, channelId);

      final stored = await (db.select(db.channels)
            ..where((tbl) => tbl.id.equals(channelId)))
          .getSingle();
      expect(stored.name, 'Updated');
      expect(stored.number, 5);
      expect(stored.isRadio, isTrue);
    });

    test('mergeProgramWindow keeps earliest and latest timestamps', () async {
      final channelId = await channelDao.upsertChannel(
        providerId: providerId,
        providerKey: 'channel-1',
        name: 'Window Channel',
      );

      final early = DateTime.utc(2024, 1, 1, 8);
      final late = DateTime.utc(2024, 1, 1, 10);
      await channelDao.mergeProgramWindow(
        channelId: channelId,
        firstProgramAt: early,
        lastProgramAt: late,
      );

      // Attempt to widen window.
      await channelDao.mergeProgramWindow(
        channelId: channelId,
        firstProgramAt: DateTime.utc(2024, 1, 1, 9),
        lastProgramAt: DateTime.utc(2024, 1, 1, 9, 30),
      );
      await channelDao.mergeProgramWindow(
        channelId: channelId,
        firstProgramAt: DateTime.utc(2023, 12, 31, 23),
        lastProgramAt: DateTime.utc(2024, 1, 2),
      );

      final row = await (db.select(db.channels)
            ..where((tbl) => tbl.id.equals(channelId)))
          .getSingle();
      expect(row.firstProgramAt?.toUtc(), DateTime.utc(2023, 12, 31, 23));
      expect(row.lastProgramAt?.toUtc(), DateTime.utc(2024, 1, 2));
    });
  });
}
