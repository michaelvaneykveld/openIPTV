import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/category_dao.dart';
import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/epg_dao.dart';
import 'package:openiptv/data/db/dao/import_run_dao.dart';
import 'package:openiptv/data/db/dao/movie_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/series_dao.dart';
import 'package:openiptv/data/db/dao/summary_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/import/import_context.dart';
import 'package:openiptv/data/import/m3u_importer.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  late OpenIptvDb db;
  late M3uImporter importer;
  late ChannelDao channelDao;
  late ProviderDao providerDao;
  late SummaryDao summaryDao;
  late int providerId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    channelDao = ChannelDao(db);
    providerDao = ProviderDao(db);
    summaryDao = SummaryDao(db);
    final context = ImportContext(
      db: db,
      providerDao: providerDao,
      channelDao: channelDao,
      categoryDao: CategoryDao(db),
      movieDao: MovieDao(db),
      seriesDao: SeriesDao(db),
      summaryDao: summaryDao,
      epgDao: EpgDao(db),
      importRunDao: ImportRunDao(db),
    );
    importer = M3uImporter(context);
    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.m3u,
        lockedBase: 'file://local',
        displayName: const Value('Demo Playlist'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('importEntries seeds categories and purges stale channels', () async {
    Future<void> runImport(List<M3uEntry> entries) {
      return importer.importEntries(
        providerId: providerId,
        entries: Stream.fromIterable(entries),
      );
    }

    await runImport(
      [
        M3uEntry(
          key: 'http://stream/live1',
          name: 'Live One',
          group: 'Live',
          isRadio: false,
        ),
        M3uEntry(
          key: 'http://stream/radio',
          name: 'Radio One',
          group: 'Radio',
          isRadio: true,
        ),
      ],
    );

    var channels = await db.select(db.channels).get();
    expect(channels, hasLength(2));
    var summaries = await summaryDao.mapForProvider(providerId);
    expect(summaries[CategoryKind.live], 1);
    expect(summaries[CategoryKind.radio], 1);

    // Age existing channels beyond the retention window so they can be purged.
    final past = DateTime.now().toUtc().subtract(const Duration(days: 5));
    await (db.update(db.channels)
          ..where(
            (tbl) => tbl.providerId.equals(providerId),
          ))
        .write(ChannelsCompanion(lastSeenAt: Value(past)));

    await runImport(
      [
        M3uEntry(
          key: 'http://stream/live2',
          name: 'Live Two',
          group: 'Live',
          isRadio: false,
        ),
      ],
    );

    channels = await db.select(db.channels).get();
    expect(channels.length, 1);
    expect(channels.single.providerChannelKey, 'http://stream/live2');
    summaries = await summaryDao.mapForProvider(providerId);
    expect(summaries[CategoryKind.live], 1);
    expect(summaries[CategoryKind.radio], 0);
  });
}
