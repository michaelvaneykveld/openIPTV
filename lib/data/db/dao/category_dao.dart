import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<OpenIptvDb>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<int> upsertCategory({
    required int providerId,
    required CategoryKind kind,
    required String providerKey,
    required String name,
    int? position,
  }) async {
    final companion = CategoriesCompanion.insert(
      providerId: providerId,
      kind: kind,
      providerCategoryKey: providerKey,
      name: name,
      position: Value(position),
    );

    return into(categories).insertOnConflictUpdate(companion);
  }

  Future<List<CategoryRecord>> fetchForProvider(
    int providerId, {
    CategoryKind? kind,
  }) {
    final query =
        select(categories)..where((tbl) => tbl.providerId.equals(providerId));
    if (kind != null) {
      query.where((tbl) => tbl.kind.equalsValue(kind));
    }
    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.position,
            mode: OrderingMode.asc,
          ),
      (tbl) => OrderingTerm(expression: tbl.name),
    ]);
    return query.get();
  }

  Stream<List<CategoryRecord>> watchForProvider(
    int providerId, {
    CategoryKind? kind,
  }) {
    final query =
        select(categories)..where((tbl) => tbl.providerId.equals(providerId));
    if (kind != null) {
      query.where((tbl) => tbl.kind.equalsValue(kind));
    }
    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.position,
            mode: OrderingMode.asc,
          ),
      (tbl) => OrderingTerm(expression: tbl.name),
    ]);
    return query.watch();
  }
}
