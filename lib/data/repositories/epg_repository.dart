import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/epg_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';

final epgDaoProvider = r.Provider<EpgDao>(
  (ref) => EpgDao(ref.watch(openIptvDbProvider)),
);

final epgRepositoryProvider = r.Provider<EpgRepository>(
  (ref) => EpgRepository(ref.watch(epgDaoProvider)),
);

class EpgRepository {
  EpgRepository(this._dao);

  final EpgDao _dao;

  Future<void> savePrograms(List<EpgProgramsCompanion> programs) =>
      _dao.bulkUpsert(programs);

  Stream<List<EpgProgramRecord>> watchNow({
    required int providerId,
    required DateTime nowUtc,
  }) =>
      _dao.watchNow(providerId: providerId, nowUtc: nowUtc);

  Future<List<EpgProgramRecord>> loadRange({
    required int channelId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) =>
      _dao.fetchRangeForChannel(
        channelId: channelId,
        rangeStart: startUtc,
        rangeEnd: endUtc,
      );

  Future<int> purgeOlderThan(
    DateTime thresholdUtc, {
    int? providerId,
  }) =>
      _dao.purgeOlderThan(thresholdUtc, providerId: providerId);
}
