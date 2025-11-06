import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'maintenance_log_dao.g.dart';

@DriftAccessor(tables: [MaintenanceLog])
class MaintenanceLogDao extends DatabaseAccessor<OpenIptvDb>
    with _$MaintenanceLogDaoMixin {
  MaintenanceLogDao(super.db);

  Future<DateTime?> lastRun(String task) async {
    final query = select(maintenanceLog)
      ..where((tbl) => tbl.task.equals(task))
      ..limit(1);
    final record = await query.getSingleOrNull();
    return record?.lastRunAt;
  }

  Future<void> markRun(String task, DateTime timestamp) async {
    await into(maintenanceLog).insertOnConflictUpdate(
      MaintenanceLogCompanion(
        task: Value(task),
        lastRunAt: Value(timestamp),
      ),
    );
  }
}

