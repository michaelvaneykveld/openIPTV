import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/provider_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';

final providerDaoProvider = r.Provider<ProviderDao>(
  (ref) => ProviderDao(ref.watch(openIptvDbProvider)),
);

final summaryDaoProvider = r.Provider<SummaryDao>(
  (ref) => SummaryDao(ref.watch(openIptvDbProvider)),
);

final providerRepositoryProvider = r.Provider<ProviderRepository>(
  (ref) => ProviderRepository(
    providerDao: ref.watch(providerDaoProvider),
    summaryDao: ref.watch(summaryDaoProvider),
  ),
);

class ProviderRepository {
  ProviderRepository({
    required this.providerDao,
    required this.summaryDao,
  });

  final ProviderDao providerDao;
  final SummaryDao summaryDao;

  Stream<List<ProviderRecord>> watchProviders() => providerDao.watchAll();

  Future<int> createProvider(ProvidersCompanion companion) =>
      providerDao.createProvider(companion);

  Future<void> updateProvider(ProvidersCompanion companion) =>
      providerDao.updateProvider(companion);

  Future<void> deleteProvider(int providerId) =>
      providerDao.deleteProvider(providerId);

  Future<void> markSynced({
    required int providerId,
    required DateTime at,
    String? etagHash,
  }) =>
      providerDao.setLastSyncAt(
        providerId: providerId,
        lastSyncAt: at,
        etagHash: etagHash,
      );

  Future<Map<CategoryKind, int>> getSummary(int providerId) =>
      summaryDao.mapForProvider(providerId);

  Stream<Map<CategoryKind, int>> watchSummary(int providerId) =>
      summaryDao.watchForProvider(providerId);
}
