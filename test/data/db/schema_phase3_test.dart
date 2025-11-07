import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/category_dao.dart';
import 'package:openiptv/data/db/dao/movie_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/series_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  late OpenIptvDb db;
  late ProviderDao providerDao;
  late CategoryDao categoryDao;
  late MovieDao movieDao;
  late SeriesDao seriesDao;
  late int providerId;
  late int vodCategoryId;
  late int seriesCategoryId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    providerDao = ProviderDao(db);
    categoryDao = CategoryDao(db);
    movieDao = MovieDao(db);
    seriesDao = SeriesDao(db);

    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://demo',
        displayName: const Value('Demo Provider'),
      ),
    );

    vodCategoryId = await categoryDao.upsertCategory(
      providerId: providerId,
      kind: CategoryKind.vod,
      providerKey: 'vod',
      name: 'Films',
      position: null,
    );

    seriesCategoryId = await categoryDao.upsertCategory(
      providerId: providerId,
      kind: CategoryKind.series,
      providerKey: 'series',
      name: 'Series',
      position: null,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('movies enforce unique provider keys and purge stale entries', () async {
    await movieDao.upsertMovie(
      providerId: providerId,
      providerVodKey: 'vod-1',
      title: 'Original Title',
      categoryId: vodCategoryId,
      year: 2020,
    );

    await movieDao.upsertMovie(
      providerId: providerId,
      providerVodKey: 'vod-1',
      title: 'Updated Title',
      categoryId: vodCategoryId,
      year: 2021,
    );

    final movies = await movieDao.listMovies(providerId);
    expect(movies, hasLength(1));
    expect(movies.first.title, 'Updated Title');
    expect(movies.first.categoryId, vodCategoryId);

    await movieDao.markAllAsCandidateForDelete(providerId);
    final purged = await movieDao.purgeStaleMovies(
      providerId: providerId,
      olderThan: DateTime.now().toUtc().add(const Duration(seconds: 1)),
    );
    expect(purged, 1);
  });

  test('series hierarchy upsert replaces seasons and episodes', () async {
    await seriesDao.upsertSeries(
      providerId: providerId,
      providerSeriesKey: 'series-1',
      title: 'Demo Series',
      categoryId: seriesCategoryId,
    );

    final seriesRecord = await seriesDao.findSeries(
      providerId: providerId,
      providerSeriesKey: 'series-1',
    );
    expect(seriesRecord, isNotNull);
    final storedSeriesId = seriesRecord!.id;

    final seasonId = await seriesDao.upsertSeason(
      seriesId: storedSeriesId,
      seasonNumber: 1,
      name: 'Season 1',
    );
    expect(seasonId, greaterThan(0));

    final seasonRecord = await seriesDao.findSeason(
      seriesId: storedSeriesId,
      seasonNumber: 1,
    );
    expect(seasonRecord, isNotNull);

    await seriesDao.upsertEpisode(
      seriesId: storedSeriesId,
      seasonId: seasonRecord!.id,
      providerEpisodeKey: 'ep-1',
      seasonNumber: 1,
      episodeNumber: 1,
      title: 'Pilot',
    );

    var episodes = await seriesDao.listEpisodes(seasonRecord.id);
    expect(episodes, hasLength(1));

    await seriesDao.deleteHierarchyForSeries(storedSeriesId);
    episodes = await seriesDao.listEpisodes(seasonRecord.id);
    expect(episodes, isEmpty);

    await seriesDao.markSeriesForDeletion(providerId);
    final removed = await seriesDao.purgeStaleSeries(
      providerId: providerId,
      olderThan: DateTime.now().toUtc().add(const Duration(seconds: 1)),
    );
    expect(removed, greaterThanOrEqualTo(1));
  });
}
