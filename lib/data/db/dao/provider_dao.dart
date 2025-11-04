import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'provider_dao.g.dart';

@DriftAccessor(tables: [Providers])
class ProviderDao extends DatabaseAccessor<OpenIptvDb>
    with _$ProviderDaoMixin {
  ProviderDao(super.db);

  Future<int> createProvider(ProvidersCompanion companion) {
    return into(providers).insert(companion);
  }

  Future<void> updateProvider(ProvidersCompanion companion) {
    return update(providers).replace(companion);
  }

  Future<void> deleteProvider(int providerId) {
    return (delete(providers)..where((tbl) => tbl.id.equals(providerId))).go();
  }

  Future<void> setLastSyncAt({
    required int providerId,
    required DateTime lastSyncAt,
    String? etagHash,
  }) {
    return (update(providers)..where((tbl) => tbl.id.equals(providerId))).write(
      ProvidersCompanion(
        lastSyncAt: Value(lastSyncAt),
        etagHash: Value(etagHash),
      ),
    );
  }

  Future<ProviderRecord?> findById(int providerId) {
    return (select(providers)..where((tbl) => tbl.id.equals(providerId)))
        .getSingleOrNull();
  }

  Stream<List<ProviderRecord>> watchAll() {
    final query = select(providers)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.displayName)]);
    return query.watch();
  }
}
