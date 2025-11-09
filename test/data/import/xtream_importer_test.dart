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
import 'package:openiptv/data/import/xtream_importer.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  late OpenIptvDb db;
  late XtreamImporter importer;
  late ProviderDao providerDao;
  late CategoryDao categoryDao;
  late ChannelDao channelDao;
  late SummaryDao summaryDao;
  late int providerId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    providerDao = ProviderDao(db);
    channelDao = ChannelDao(db);
    categoryDao = CategoryDao(db);
    summaryDao = SummaryDao(db);
    final context = ImportContext(
      db: db,
      providerDao: providerDao,
      channelDao: channelDao,
      categoryDao: categoryDao,
      movieDao: MovieDao(db),
      seriesDao: SeriesDao(db),
      summaryDao: summaryDao,
      epgDao: EpgDao(db),
      importRunDao: ImportRunDao(db),
    );
    importer = XtreamImporter(context);
    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://demo.xtream/',
        displayName: const Value('Demo Xtream'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'importAll upserts streams, summaries, and purges stale channels',
    () async {
      final liveCategories = [
        {'category_id': '100', 'category_name': 'News'},
        {'category_id': '999', 'category_name': 'Radio Lounge'},
      ];
      final liveStreams = [
        {'stream_id': 101, 'name': 'BBC One', 'category_id': '100'},
        {
          'stream_id': 401,
          'name': 'Jazz FM',
          'category_id': '999',
          'stream_type': 'radio_streams',
        },
      ];
      final vodCategories = [
        {'category_id': '200', 'category_name': 'Movies'},
      ];
      final vodStreams = [
        {'stream_id': 501, 'name': 'Action Movie', 'category_id': '200'},
      ];

      await importer.importAll(
        providerId: providerId,
        live: liveStreams,
        vod: vodStreams,
        series: const [],
        liveCategories: liveCategories,
        vodCategories: vodCategories,
        seriesCategories: const [],
      );

      final channelsAfterFirstImport = await db.select(db.channels).get();
      expect(channelsAfterFirstImport, hasLength(3));

      final summaries = await summaryDao.mapForProvider(providerId);
      expect(summaries[CategoryKind.live], 1);
      expect(summaries[CategoryKind.vod], 1);
      expect(summaries[CategoryKind.radio], 1);

      // Age only the original live stream so the next import can purge it.
      final staleTimestamp = DateTime.now().toUtc().subtract(
        const Duration(days: 10),
      );
      await (db.update(db.channels)
            ..where((tbl) => tbl.providerId.equals(providerId))
            ..where((tbl) => tbl.providerChannelKey.equals('101')))
          .write(ChannelsCompanion(lastSeenAt: Value(staleTimestamp)));

      final liveReplacement = [
        {'stream_id': 102, 'name': 'CNN', 'category_id': '100'},
        {
          'stream_id': 401,
          'name': 'Jazz FM',
          'category_id': '999',
          'stream_type': 'radio',
        },
      ];

      await importer.importAll(
        providerId: providerId,
        live: liveReplacement,
        vod: const [],
        series: const [],
        liveCategories: liveCategories,
        vodCategories: vodCategories,
        seriesCategories: const [],
      );

      final finalChannels = await db.select(db.channels).get();
      expect(
        finalChannels.map((c) => c.providerChannelKey),
        containsAll(['102', '401']),
      );
      expect(
        finalChannels.map((c) => c.providerChannelKey),
        isNot(contains('101')),
      );
      final updatedSummaries = await summaryDao.mapForProvider(providerId);
      expect(updatedSummaries[CategoryKind.live], 1);
      expect(updatedSummaries[CategoryKind.vod] ?? 0, 0);
      expect(updatedSummaries[CategoryKind.radio], 1);
    },
  );
}
