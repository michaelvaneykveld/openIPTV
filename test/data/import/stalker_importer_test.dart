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

  test('importCatalog upserts categories, media, and summaries', () async {
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
    final liveStreams = [
      {'id': 'c1', 'name': 'Channel One', 'category_id': '1', 'cmd': 'udp://1'},
    ];
    final radioStreams = [
      {
        'id': 'r1',
        'name': 'Radio One',
        'category_id': '30',
        'cmd': 'http://radio',
      },
    ];
    final vodItems = [
      {
        'id': 'm1',
        'name': 'Movie One',
        'category_id': '10',
        'description': 'Plot',
        'screenshot_uri': 'http://art/movie.png',
      },
    ];
    final seriesItems = [
      {
        'id': 's1',
        'name': 'Series One',
        'category_id': '20',
        'description': 'Overview',
        'screenshot_uri': 'http://art/series.png',
      },
    ];

    final metrics = await importer.importCatalog(
      providerId: providerId,
      liveCategories: liveCategories,
      vodCategories: vodCategories,
      seriesCategories: seriesCategories,
      radioCategories: radioCategories,
      liveItems: liveStreams,
      radioItems: radioStreams,
      vodItems: vodItems,
      seriesItems: seriesItems,
    );

    expect(
      metrics.categoriesUpserted,
      liveCategories.length +
          vodCategories.length +
          seriesCategories.length +
          radioCategories.length,
    );
    expect(metrics.channelsUpserted, 2);
    expect(metrics.moviesUpserted, 1);
    expect(metrics.seriesUpserted, 1);

    final storedLive = await categoryDao.fetchForProvider(
      providerId,
      kind: CategoryKind.live,
    );
    expect(storedLive.map((c) => c.name), containsAll(['General', 'Sports']));

    final summaries = await summaryDao.mapForProvider(providerId);
    expect(summaries[CategoryKind.live], 1);
    expect(summaries[CategoryKind.vod], 1);
    expect(summaries[CategoryKind.series], 1);
    expect(summaries[CategoryKind.radio], 1);

    final storedMovies = await db.select(db.movies).get();
    expect(storedMovies, hasLength(1));
    final storedSeries = await db.select(db.series).get();
    expect(storedSeries, hasLength(1));

    final updatedMetrics = await importer.importCatalog(
      providerId: providerId,
      liveCategories: [
        {'id': '1', 'title': 'General HD', 'number': 1},
        {'id': '3', 'title': 'Kids', 'number': 3},
      ],
      vodCategories: vodCategories,
      liveItems: [
        {
          'id': 'c2',
          'name': 'Channel Two',
          'category_id': '1',
          'cmd': 'udp://2',
        },
      ],
      radioItems: radioStreams,
    );
    expect(updatedMetrics.categoriesUpserted, 3);

    final updatedLive = await categoryDao.fetchForProvider(
      providerId,
      kind: CategoryKind.live,
    );
    expect(updatedLive, hasLength(3));
    expect(
      updatedLive.map((c) => c.name),
      containsAll(['General HD', 'Sports', 'Kids']),
    );

    final updatedSummaries = await summaryDao.mapForProvider(providerId);
    expect(updatedSummaries[CategoryKind.live], 1);
    expect(updatedSummaries[CategoryKind.radio], 1);
  });
}
