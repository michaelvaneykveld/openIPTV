import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'summary_dao.g.dart';

@DriftAccessor(tables: [Summaries])
class SummaryDao extends DatabaseAccessor<OpenIptvDb>
    with _$SummaryDaoMixin {
  SummaryDao(super.db);

  Future<void> upsertSummary({
    required int providerId,
    required CategoryKind kind,
    required int totalItems,
    DateTime? updatedAt,
  }) {
    final companion = SummariesCompanion.insert(
      providerId: providerId,
      kind: kind,
      totalItems: Value(totalItems),
      updatedAt: Value(updatedAt ?? DateTime.now().toUtc()),
    );
    return into(summaries).insertOnConflictUpdate(companion);
  }

  Future<Map<CategoryKind, int>> mapForProvider(int providerId) async {
    final rows =
        await (select(summaries)..where((tbl) => tbl.providerId.equals(providerId))).get();
    return {for (final row in rows) row.kind: row.totalItems};
  }

  Stream<Map<CategoryKind, int>> watchForProvider(int providerId) {
    final query =
        select(summaries)..where((tbl) => tbl.providerId.equals(providerId));
    return query.watch().map(
          (rows) => {for (final row in rows) row.kind: row.totalItems},
        );
  }
}
