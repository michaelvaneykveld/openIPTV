part of '../openiptv_db.dart';

@DataClassName('MaintenanceLogRecord')
class MaintenanceLog extends Table {
  TextColumn get task => text()();
  DateTimeColumn get lastRunAt => dateTime()();

  @override
  Set<Column> get primaryKey => {task};
}

