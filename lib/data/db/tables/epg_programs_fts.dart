part of '../openiptv_db.dart';

class EpgProgramsFts extends Table {
  TextColumn get title => text()();
  TextColumn get description => text()();
  IntColumn get programId => integer().customConstraint(
        'NOT NULL REFERENCES epg_programs(id) ON DELETE CASCADE',
      )();

  @override
  Set<Column> get primaryKey => {programId};
}
