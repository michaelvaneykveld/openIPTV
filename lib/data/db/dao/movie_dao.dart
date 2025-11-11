import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'movie_dao.g.dart';

@DriftAccessor(tables: [Movies])
class MovieDao extends DatabaseAccessor<OpenIptvDb> with _$MovieDaoMixin {
  MovieDao(super.db);

  Future<int> upsertMovie({
    required int providerId,
    required String providerVodKey,
    required String title,
    int? categoryId,
    int? year,
    String? overview,
    String? posterUrl,
    int? durationSec,
    String? streamUrlTemplate,
    DateTime? seenAt,
    String? streamHeadersJson,
  }) async {
    final resolvedSeenAt = seenAt ?? DateTime.now().toUtc();
    final updated =
        await (update(movies)
              ..where((tbl) => tbl.providerId.equals(providerId))
              ..where((tbl) => tbl.providerVodKey.equals(providerVodKey)))
            .write(
              MoviesCompanion(
                categoryId: Value(categoryId),
                title: Value(title),
                year: Value(year),
                overview: Value(overview),
                posterUrl: Value(posterUrl),
                durationSec: Value(durationSec),
                streamUrlTemplate: Value(streamUrlTemplate),
                streamHeadersJson: Value(streamHeadersJson),
                lastSeenAt: Value(resolvedSeenAt),
              ),
            );

    if (updated > 0) {
      final existing = await findByProviderKey(
        providerId: providerId,
        providerVodKey: providerVodKey,
      );
      return existing?.id ?? 0;
    }

    return into(movies).insert(
      MoviesCompanion(
        providerId: Value(providerId),
        providerVodKey: Value(providerVodKey),
        categoryId: Value(categoryId),
        title: Value(title),
        year: Value(year),
        overview: Value(overview),
        posterUrl: Value(posterUrl),
        durationSec: Value(durationSec),
        streamUrlTemplate: Value(streamUrlTemplate),
        streamHeadersJson: Value(streamHeadersJson),
        lastSeenAt: Value(resolvedSeenAt),
      ),
    );
  }

  Future<void> markAllAsCandidateForDelete(int providerId) {
    return (update(
      movies,
    )..where((tbl) => tbl.providerId.equals(providerId))).write(
      MoviesCompanion(
        lastSeenAt: Value(DateTime.fromMillisecondsSinceEpoch(0)),
      ),
    );
  }

  Future<int> purgeStaleMovies({
    required int providerId,
    required DateTime olderThan,
  }) {
    return (delete(movies)
          ..where((tbl) => tbl.providerId.equals(providerId))
          ..where((tbl) => tbl.lastSeenAt.isSmallerThanValue(olderThan)))
        .go();
  }

  Future<MovieRecord?> findByProviderKey({
    required int providerId,
    required String providerVodKey,
  }) {
    final query = select(movies)
      ..where((tbl) => tbl.providerId.equals(providerId))
      ..where((tbl) => tbl.providerVodKey.equals(providerVodKey))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<MovieRecord>> listMovies(int providerId, {int? categoryId}) {
    return _selectForProvider(providerId, categoryId: categoryId).get();
  }

  Stream<List<MovieRecord>> watchMovies(int providerId, {int? categoryId}) {
    return _selectForProvider(providerId, categoryId: categoryId).watch();
  }

  SimpleSelectStatement<Movies, MovieRecord> _selectForProvider(
    int providerId, {
    int? categoryId,
  }) {
    final query = select(movies)
      ..where((tbl) => tbl.providerId.equals(providerId));
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.title)]);
    return query;
  }
}
