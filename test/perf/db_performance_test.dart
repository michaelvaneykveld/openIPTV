import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/epg_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  group('Database performance regression', () {
    late OpenIptvDb db;
    late ProviderDao providerDao;
    late ChannelDao channelDao;
    late EpgDao epgDao;

    setUp(() {
      db = OpenIptvDb.inMemory();
      providerDao = ProviderDao(db);
      channelDao = ChannelDao(db);
      epgDao = EpgDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('listing 50k channels stays under SLA', () async {
      final providerId = await providerDao.createProvider(
        ProvidersCompanion.insert(
          kind: ProviderKind.xtream,
          lockedBase: 'https://perf.example/',
          displayName: const Value('Perf Provider'),
        ),
      );

      const totalChannels = 50000;
      await db.batch((batch) {
        for (var i = 0; i < totalChannels; i++) {
          batch.insert(
            db.channels,
            ChannelsCompanion.insert(
              providerId: providerId,
              providerChannelKey: 'ch-$i',
              name: 'Channel $i',
              number: Value(i + 1),
              isRadio: Value(i.isEven),
              lastSeenAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      });

      final sw = Stopwatch()..start();
      final channels = await channelDao.findByProvider(providerId);
      sw.stop();

      expect(channels, hasLength(totalChannels));
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 900)),
        reason: 'Channel listing should remain under SLA with 50k rows.',
      );
    });

    test('multi-day EPG range query stays under SLA', () async {
      final providerId = await providerDao.createProvider(
        ProvidersCompanion.insert(
          kind: ProviderKind.xtream,
          lockedBase: 'https://epg.example/',
          displayName: const Value('EPG Provider'),
        ),
      );
      final channelId = await db.into(db.channels).insert(
            ChannelsCompanion.insert(
              providerId: providerId,
              providerChannelKey: 'epg-ch',
              name: 'EPG Channel',
            ),
          );

      final now = DateTime.utc(2025, 1, 1);
      final entries = <EpgProgramsCompanion>[];
      for (var day = 0; day < 10; day++) {
        final dayStart = now.add(Duration(days: day));
        for (var hour = 0; hour < 24; hour++) {
          final start = dayStart.add(Duration(hours: hour));
          final end = start.add(const Duration(minutes: 50));
          entries.add(
            EpgProgramsCompanion.insert(
              channelId: channelId,
              startUtc: start,
              endUtc: end,
              title: Value('Program ${day * 24 + hour}'),
            ),
          );
        }
      }
      await epgDao.bulkUpsert(entries);

      final sw = Stopwatch()..start();
      final window = await epgDao.fetchRangeForChannel(
        channelId: channelId,
        rangeStart: now,
        rangeEnd: now.add(const Duration(days: 10)),
      );
      sw.stop();

      expect(window, hasLength(entries.length));
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 400)),
        reason: 'Multi-day EPG queries should remain under SLA.',
      );
    });
  });
}
