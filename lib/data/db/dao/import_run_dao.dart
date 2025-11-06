import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'import_run_dao.g.dart';

@DriftAccessor(tables: [ImportRuns])
class ImportRunDao extends DatabaseAccessor<OpenIptvDb>
    with _$ImportRunDaoMixin {
  ImportRunDao(super.db);

  Future<int> insertRun({
    required int providerId,
    required ProviderKind providerKind,
    required String importType,
    required DateTime startedAt,
    Duration? duration,
    ImportMetricsSnapshot? metrics,
    String? error,
  }) {
    return into(importRuns).insert(
      ImportRunsCompanion.insert(
        providerId: providerId,
        providerKind: providerKind,
        importType: importType,
        startedAt: startedAt,
        durationMs: Value(duration?.inMilliseconds),
        channelsUpserted: Value(metrics?.channelsUpserted),
        categoriesUpserted: Value(metrics?.categoriesUpserted),
        moviesUpserted: Value(metrics?.moviesUpserted),
        seriesUpserted: Value(metrics?.seriesUpserted),
        seasonsUpserted: Value(metrics?.seasonsUpserted),
        episodesUpserted: Value(metrics?.episodesUpserted),
        channelsDeleted: Value(metrics?.channelsDeleted),
        error: Value(error),
      ),
    );
  }

  Stream<List<ImportRunRecord>> watchRecent(int providerId, {int limit = 20}) {
    final query = (select(importRuns)
          ..where((tbl) => tbl.providerId.equals(providerId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.startedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .watch();
    return query;
  }

  Future<List<ImportRunRecord>> listRecent({int limit = 100}) {
    final query = select(importRuns)
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.startedAt,
              mode: OrderingMode.desc,
            ),
      ])
      ..limit(limit);
    return query.get();
  }
}

class ImportMetricsSnapshot {
  const ImportMetricsSnapshot({
    this.channelsUpserted,
    this.categoriesUpserted,
    this.moviesUpserted,
    this.seriesUpserted,
    this.seasonsUpserted,
    this.episodesUpserted,
    this.channelsDeleted,
  });

  final int? channelsUpserted;
  final int? categoriesUpserted;
  final int? moviesUpserted;
  final int? seriesUpserted;
  final int? seasonsUpserted;
  final int? episodesUpserted;
  final int? channelsDeleted;
}
