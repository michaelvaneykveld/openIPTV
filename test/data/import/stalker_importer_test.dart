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
import 'package:openiptv/data/import/stalker_importer.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  late OpenIptvDb db;
  late StalkerImporter importer;
  late CategoryDao categoryDao;
  late SummaryDao summaryDao;
  late ProviderDao providerDao;
  late int providerId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    categoryDao = CategoryDao(db);
    summaryDao = SummaryDao(db);
    providerDao = ProviderDao(db);
    final context = ImportContext(
      db: db,
      providerDao: providerDao,
      channelDao: ChannelDao(db),
      categoryDao: categoryDao,
      movieDao: MovieDao(db),
      seriesDao: SeriesDao(db),
      summaryDao: summaryDao,
      epgDao: EpgDao(db),
      importRunDao: ImportRunDao(db),
    );
    importer = StalkerImporter(context);
    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.stalker,
        lockedBase: 'https://portal.example/c/',
        displayName: const Value('Stalker Test'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('importCategories upserts categories, summaries, and metrics', () async {
    final liveCategories = [
      {'id': '1', 'title': 'General', 'number': 1},
      {'id': '2', 'title': 'Sports', 'number': 2},
    ];
    final vodCategories = [
      {'id': '10', 'title': 'Movies'},
    ];
    final seriesCategories = [
      {'id': '20', 'title': 'Series'},
    ];
    final radioCategories = [
      {'id': '30', 'title': 'Radio'},
    ];

    final metrics = await importer.importCategories(
      providerId: providerId,
      live: liveCategories,
      vod: vodCategories,
      series: seriesCategories,
      radio: radioCategories,
      totalsByCategory: {'live': 80},
    );

    expect(
      metrics.categoriesUpserted,
      liveCategories.length +
          vodCategories.length +
          seriesCategories.length +
          radioCategories.length,
    );

    final storedLive =
        await categoryDao.fetchForProvider(providerId, kind: CategoryKind.live);
    expect(storedLive.map((c) => c.name), containsAll(['General', 'Sports']));

    final summaries = await summaryDao.mapForProvider(providerId);
    expect(summaries[CategoryKind.live], 80);
    expect(summaries[CategoryKind.vod], 1);
    expect(summaries[CategoryKind.series], 1);
    expect(summaries[CategoryKind.radio], 1);

    final updatedMetrics = await importer.importCategories(
      providerId: providerId,
      live: [
        {'id': '1', 'title': 'General HD', 'number': 1},
        {'id': '3', 'title': 'Kids', 'number': 3},
      ],
      vod: vodCategories,
    );
    expect(updatedMetrics.categoriesUpserted, 3);

    final updatedLive =
        await categoryDao.fetchForProvider(providerId, kind: CategoryKind.live);
    expect(updatedLive, hasLength(3));
    expect(
      updatedLive.map((c) => c.name),
      containsAll(['General HD', 'Sports', 'Kids']),
    );

    final updatedSummaries = await summaryDao.mapForProvider(providerId);
    expect(updatedSummaries[CategoryKind.live], 2);
  });
}