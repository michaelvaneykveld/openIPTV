import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/artwork_cache_dao.dart';
import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/maintenance_log_dao.dart';
import 'package:openiptv/data/db/database_maintenance.dart';
import 'package:openiptv/data/db/openiptv_db.dart';

void main() {
  late OpenIptvDb db;
  late ChannelDao channelDao;
  late ArtworkCacheDao artworkDao;
  late MaintenanceLogDao logDao;
  late DatabaseMaintenance maintenance;
  late int providerId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    channelDao = ChannelDao(db);
    artworkDao = ArtworkCacheDao(db);
    logDao = MaintenanceLogDao(db);
    maintenance = DatabaseMaintenance(
      db: db,
      logDao: logDao,
      channelDao: channelDao,
      artworkDao: artworkDao,
      config: const DatabaseMaintenanceConfig(
        vacuumInterval: Duration.zero,
        analyzeInterval: Duration.zero,
        minFileBytesForVacuum: 0,
        minFileBytesForAnalyze: 0,
        tombstoneRetention: Duration(days: 7),
        artworkEntryBudget: 0,
        artworkSizeBudgetBytes: 0,
      ),
      databaseFile: null,
    );

    providerId = await db.into(db.providers).insert(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        displayName: const Value('Test'),
        lockedBase: 'https://example.com',
      ),
    );

    final now = DateTime.now().toUtc();
    await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'recent',
      name: 'Recent Channel',
      seenAt: now,
    );
    await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'stale',
      name: 'Stale Channel',
      seenAt: now.subtract(const Duration(days: 30)),
    );

    await artworkDao.upsertEntry(
      url: 'https://example.com/logo.png',
      bytes: Uint8List.fromList([1, 2, 3]),
      byteSize: 3,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('maintenance runs VACUUM/ANALYZE and retention sweep', () async {
    final now = DateTime.now().toUtc();
    await maintenance.run(now: now);

    final vacuumRun = await logDao.lastRun('vacuum');
    final analyzeRun = await logDao.lastRun('analyze');
    expect(vacuumRun, isNotNull);
    expect(analyzeRun, isNotNull);

    final channels = await channelDao.findByProvider(providerId);
    expect(channels.map((c) => c.providerChannelKey), contains('recent'));
    expect(channels.map((c) => c.providerChannelKey), isNot(contains('stale')));

    final artwork = await artworkDao.findByUrl('https://example.com/logo.png');
    expect(artwork, isNull);
  });
}
