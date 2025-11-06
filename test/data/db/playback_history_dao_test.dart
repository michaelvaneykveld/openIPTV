import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/playback_history_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';

void main() {
  late OpenIptvDb db;
  late ProviderDao providerDao;
  late ChannelDao channelDao;
  late PlaybackHistoryDao historyDao;
  late int providerId;
  late int channelId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    providerDao = ProviderDao(db);
    channelDao = ChannelDao(db);
    historyDao = PlaybackHistoryDao(db);

    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://demo',
        displayName: const Value('Demo Provider'),
      ),
    );

    channelId = await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'stream-1',
      name: 'Demo Channel',
      logoUrl: null,
      number: 1,
      isRadio: false,
      streamUrlTemplate: null,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertProgress inserts and updates playback state', () async {
    await historyDao.upsertProgress(
      providerId: providerId,
      channelId: channelId,
      positionSec: 120,
      durationSec: 3600,
    );

    final first = await historyDao.findByChannel(channelId);
    expect(first, isNotNull);
    expect(first!.positionSec, 120);
    expect(first.durationSec, 3600);
    final startedAt = first.startedAt;

    await historyDao.upsertProgress(
      providerId: providerId,
      channelId: channelId,
      positionSec: 240,
      durationSec: 3600,
      completed: true,
    );

    final updated = await historyDao.findByChannel(channelId);
    expect(updated, isNotNull);
    expect(updated!.positionSec, 240);
    expect(updated.durationSec, 3600);
    expect(updated.completed, isTrue);
    expect(updated.startedAt, equals(startedAt));
    expect(updated.updatedAt.isAfter(startedAt) || updated.updatedAt == startedAt, isTrue);
  });

  test('pruneOlderThan removes stale entries', () async {
    await historyDao.upsertProgress(
      providerId: providerId,
      channelId: channelId,
      positionSec: 10,
    );

    // Force the updatedAt timestamp to be old.
    await (db.update(db.playbackHistory)
          ..where((tbl) => tbl.channelId.equals(channelId)))
        .write(
      PlaybackHistoryCompanion(
        updatedAt: Value(DateTime.utc(2020, 1, 1)),
      ),
    );

    final removed = await historyDao.pruneOlderThan(
      DateTime.utc(2021, 1, 1),
    );
    expect(removed, 1);

    final remaining = await historyDao.findByChannel(channelId);
    expect(remaining, isNull);
  });
}

