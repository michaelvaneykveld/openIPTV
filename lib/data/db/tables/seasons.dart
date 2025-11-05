part of '../openiptv_db.dart';

@DataClassName('SeasonRecord')
class Seasons extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get seriesId =>
      integer().references(Series, #id, onDelete: KeyAction.cascade)();

  IntColumn get seasonNumber => integer()();

  TextColumn get name => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {seriesId, seasonNumber},
      ];
}
