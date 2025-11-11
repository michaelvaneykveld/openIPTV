import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'series_dao.g.dart';

@DriftAccessor(tables: [Series, Seasons, Episodes])
class SeriesDao extends DatabaseAccessor<OpenIptvDb> with _$SeriesDaoMixin {
  SeriesDao(super.db);

  Future<int> upsertSeries({
    required int providerId,
    required String providerSeriesKey,
    required String title,
    int? categoryId,
    int? year,
    String? overview,
    String? posterUrl,
    DateTime? seenAt,
  }) async {
    final resolvedSeenAt = seenAt ?? DateTime.now().toUtc();
    final updated =
        await (update(series)
              ..where((tbl) => tbl.providerId.equals(providerId))
              ..where((tbl) => tbl.providerSeriesKey.equals(providerSeriesKey)))
            .write(
              SeriesCompanion(
                categoryId: Value(categoryId),
                title: Value(title),
                posterUrl: Value(posterUrl),
                year: Value(year),
                overview: Value(overview),
                lastSeenAt: Value(resolvedSeenAt),
              ),
            );

    if (updated > 0) {
      final existing = await findSeries(
        providerId: providerId,
        providerSeriesKey: providerSeriesKey,
      );
      return existing?.id ?? 0;
    }

    return into(series).insert(
      SeriesCompanion(
        providerId: Value(providerId),
        providerSeriesKey: Value(providerSeriesKey),
        categoryId: Value(categoryId),
        title: Value(title),
        posterUrl: Value(posterUrl),
        year: Value(year),
        overview: Value(overview),
        lastSeenAt: Value(resolvedSeenAt),
      ),
    );
  }

  Future<int> upsertSeason({
    required int seriesId,
    required int seasonNumber,
    String? name,
  }) async {
    final updated =
        await (update(seasons)
              ..where((tbl) => tbl.seriesId.equals(seriesId))
              ..where((tbl) => tbl.seasonNumber.equals(seasonNumber)))
            .write(SeasonsCompanion(name: Value(name)));

    if (updated > 0) {
      final existing = await findSeason(
        seriesId: seriesId,
        seasonNumber: seasonNumber,
      );
      return existing?.id ?? 0;
    }

    return into(seasons).insert(
      SeasonsCompanion(
        seriesId: Value(seriesId),
        seasonNumber: Value(seasonNumber),
        name: Value(name),
      ),
    );
  }

  Future<int> upsertEpisode({
    required int seriesId,
    required int seasonId,
    required String providerEpisodeKey,
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    String? overview,
    int? durationSec,
    String? streamUrlTemplate,
    DateTime? seenAt,
  }) async {
    final resolvedSeenAt = seenAt ?? DateTime.now().toUtc();
    final updated =
        await (update(episodes)
              ..where((tbl) => tbl.seriesId.equals(seriesId))
              ..where(
                (tbl) => tbl.providerEpisodeKey.equals(providerEpisodeKey),
              ))
            .write(
              EpisodesCompanion(
                seasonId: Value(seasonId),
                seasonNumber: Value(seasonNumber),
                episodeNumber: Value(episodeNumber),
                title: Value(title),
                overview: Value(overview),
                durationSec: Value(durationSec),
                streamUrlTemplate: Value(streamUrlTemplate),
                lastSeenAt: Value(resolvedSeenAt),
              ),
            );

    if (updated > 0) {
      final existing = await findEpisode(
        seriesId: seriesId,
        providerEpisodeKey: providerEpisodeKey,
      );
      return existing?.id ?? 0;
    }

    return into(episodes).insert(
      EpisodesCompanion(
        seriesId: Value(seriesId),
        seasonId: Value(seasonId),
        providerEpisodeKey: Value(providerEpisodeKey),
        seasonNumber: Value(seasonNumber),
        episodeNumber: Value(episodeNumber),
        title: Value(title),
        overview: Value(overview),
        durationSec: Value(durationSec),
        streamUrlTemplate: Value(streamUrlTemplate),
        lastSeenAt: Value(resolvedSeenAt),
      ),
    );
  }

  Future<SeriesRecord?> findSeries({
    required int providerId,
    required String providerSeriesKey,
  }) {
    final query = select(series)
      ..where((tbl) => tbl.providerId.equals(providerId))
      ..where((tbl) => tbl.providerSeriesKey.equals(providerSeriesKey))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<SeasonRecord?> findSeason({
    required int seriesId,
    required int seasonNumber,
  }) {
    final query = select(seasons)
      ..where((tbl) => tbl.seriesId.equals(seriesId))
      ..where((tbl) => tbl.seasonNumber.equals(seasonNumber))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<EpisodeRecord?> findEpisode({
    required int seriesId,
    required String providerEpisodeKey,
  }) {
    final query = select(episodes)
      ..where((tbl) => tbl.seriesId.equals(seriesId))
      ..where((tbl) => tbl.providerEpisodeKey.equals(providerEpisodeKey))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> deleteHierarchyForSeries(int seriesId) async {
    await (delete(
      episodes,
    )..where((tbl) => tbl.seriesId.equals(seriesId))).go();
    await (delete(seasons)..where((tbl) => tbl.seriesId.equals(seriesId))).go();
  }

  Future<void> markSeriesForDeletion(int providerId) {
    return (update(
      series,
    )..where((tbl) => tbl.providerId.equals(providerId))).write(
      SeriesCompanion(
        lastSeenAt: Value(DateTime.fromMillisecondsSinceEpoch(0)),
      ),
    );
  }

  Future<int> purgeStaleSeries({
    required int providerId,
    required DateTime olderThan,
  }) {
    return (delete(series)
          ..where((tbl) => tbl.providerId.equals(providerId))
          ..where((tbl) => tbl.lastSeenAt.isSmallerThanValue(olderThan)))
        .go();
  }

  Stream<List<SeriesRecord>> watchSeries(int providerId, {int? categoryId}) {
    return _selectSeries(providerId, categoryId: categoryId).watch();
  }

  Future<List<SeriesRecord>> listSeries(int providerId, {int? categoryId}) {
    return _selectSeries(providerId, categoryId: categoryId).get();
  }

  Stream<List<SeasonRecord>> watchSeasons(int seriesId) {
    final query = select(seasons)
      ..where((tbl) => tbl.seriesId.equals(seriesId));
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.seasonNumber)]);
    return query.watch();
  }

  Future<List<SeasonRecord>> listSeasons(int seriesId) {
    final query = select(seasons)
      ..where((tbl) => tbl.seriesId.equals(seriesId));
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.seasonNumber)]);
    return query.get();
  }

  Stream<List<EpisodeRecord>> watchEpisodes(int seasonId) {
    final query = select(episodes)
      ..where((tbl) => tbl.seasonId.equals(seasonId));
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.seasonNumber),
      (tbl) => OrderingTerm(expression: tbl.episodeNumber),
    ]);
    return query.watch();
  }

  Future<List<EpisodeRecord>> listEpisodes(int seasonId) {
    final query = select(episodes)
      ..where((tbl) => tbl.seasonId.equals(seasonId));
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.seasonNumber),
      (tbl) => OrderingTerm(expression: tbl.episodeNumber),
    ]);
    return query.get();
  }

  Future<List<EpisodeRecord>> listEpisodesForCategory(int categoryId) async {
    final rows = await customSelect(
      '''
SELECT ep.*
FROM episodes ep
JOIN series sr ON sr.id = ep.series_id
WHERE sr.category_id = ?
ORDER BY sr.title, ep.season_number, ep.episode_number;
''',
      variables: [Variable<int>(categoryId)],
      readsFrom: {episodes, series},
    ).get();
    return rows.map(episodes.map).toList(growable: false);
  }

  SimpleSelectStatement<Series, SeriesRecord> _selectSeries(
    int providerId, {
    int? categoryId,
  }) {
    final query = select(series)
      ..where((tbl) => tbl.providerId.equals(providerId));
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.title)]);
    return query;
  }
}
