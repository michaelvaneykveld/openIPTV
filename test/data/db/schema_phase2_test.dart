import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;

import 'package:openiptv/data/db/dao/epg_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';

void main() {
  late OpenIptvDb db;
  late ProviderDao providerDao;
  late EpgDao epgDao;
  late int providerId;
  late int channelId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    providerDao = ProviderDao(db);
    epgDao = EpgDao(db);

    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://demo',
        displayName: const Value('Demo Provider'),
      ),
    );
    channelId = await db.into(db.channels).insert(
      ChannelsCompanion.insert(
        providerId: providerId,
        providerChannelKey: 'stream-1',
        name: 'Demo Channel',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('epg enforces unique channel-start constraint', () async {
    final program = EpgProgramsCompanion.insert(
      channelId: channelId,
      startUtc: DateTime.utc(2024, 1, 1, 12),
      endUtc: DateTime.utc(2024, 1, 1, 13),
      title: const Value('News'),
    );

    await epgDao.bulkUpsert([program]);
    await epgDao.bulkUpsert([program.copyWith(title: const Value('Updated'))]);

    final rows = await epgDao.fetchRangeForChannel(
      channelId: channelId,
      rangeStart: DateTime.utc(2024, 1, 1, 0),
      rangeEnd: DateTime.utc(2024, 1, 2),
    );
    expect(rows, hasLength(1));
    expect(rows.first.title, 'Updated');
  });

  test('purges programs older than threshold', () async {
    await epgDao.bulkUpsert([
      EpgProgramsCompanion.insert(
        channelId: channelId,
        startUtc: DateTime.utc(2024, 1, 1, 9),
        endUtc: DateTime.utc(2024, 1, 1, 10),
      ),
      EpgProgramsCompanion.insert(
        channelId: channelId,
        startUtc: DateTime.utc(2024, 1, 1, 12),
        endUtc: DateTime.utc(2024, 1, 1, 13),
      ),
    ]);

    final removed = await epgDao.purgeOlderThan(
      DateTime.utc(2024, 1, 1, 11),
      providerId: providerId,
    );

    expect(removed, 1);
    final remaining = await epgDao.fetchRangeForChannel(
      channelId: channelId,
      rangeStart: DateTime.utc(2024, 1, 1, 0),
      rangeEnd: DateTime.utc(2024, 1, 2),
    );
    expect(remaining, hasLength(1));
  });

  test('watchNow streams current programs', () async {
    final now = DateTime.utc(2024, 1, 1, 12, 30);

    await epgDao.bulkUpsert([
      EpgProgramsCompanion.insert(
        channelId: channelId,
        startUtc: DateTime.utc(2024, 1, 1, 12),
        endUtc: DateTime.utc(2024, 1, 1, 13),
        title: const Value('Live Program'),
      ),
    ]);

    final stream = epgDao.watchNow(providerId: providerId, nowUtc: now);
    final programs = await stream.first;
    expect(programs, hasLength(1));
    expect(programs.first.title, 'Live Program');
  });
}

