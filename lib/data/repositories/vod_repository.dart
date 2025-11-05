import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/movie_dao.dart';
import '../db/dao/series_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';

final movieDaoProvider = r.Provider<MovieDao>(
  (ref) => MovieDao(ref.watch(openIptvDbProvider)),
);

final seriesDaoProvider = r.Provider<SeriesDao>(
  (ref) => SeriesDao(ref.watch(openIptvDbProvider)),
);

final vodRepositoryProvider = r.Provider<VodRepository>(
  (ref) => VodRepository(
    movieDao: ref.watch(movieDaoProvider),
    seriesDao: ref.watch(seriesDaoProvider),
  ),
);

class VodRepository {
  VodRepository({
    required this.movieDao,
    required this.seriesDao,
  });

  final MovieDao movieDao;
  final SeriesDao seriesDao;

  Stream<List<MovieRecord>> watchMovies(
    int providerId, {
    int? categoryId,
  }) {
    return movieDao.watchMovies(providerId, categoryId: categoryId);
  }

  Future<List<MovieRecord>> listMovies(
    int providerId, {
    int? categoryId,
  }) {
    return movieDao.listMovies(providerId, categoryId: categoryId);
  }

  Stream<List<SeriesRecord>> watchSeries(
    int providerId, {
    int? categoryId,
  }) {
    return seriesDao.watchSeries(providerId, categoryId: categoryId);
  }

  Future<List<SeriesRecord>> listSeries(
    int providerId, {
    int? categoryId,
  }) {
    return seriesDao.listSeries(providerId, categoryId: categoryId);
  }

  Stream<List<SeasonRecord>> watchSeasons(int seriesId) {
    return seriesDao.watchSeasons(seriesId);
  }

  Future<List<SeasonRecord>> listSeasons(int seriesId) {
    return seriesDao.listSeasons(seriesId);
  }

  Stream<List<EpisodeRecord>> watchEpisodes(int seasonId) {
    return seriesDao.watchEpisodes(seasonId);
  }

  Future<List<EpisodeRecord>> listEpisodes(int seasonId) {
    return seriesDao.listEpisodes(seasonId);
  }
}
