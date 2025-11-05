part of '../openiptv_db.dart';

@DataClassName('SeriesRecord')
class Series extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  TextColumn get providerSeriesKey => text()();

  IntColumn get categoryId => integer()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();

  TextColumn get title => text()();

  TextColumn get posterUrl => text().nullable()();

  IntColumn get year => integer().nullable()();

  TextColumn get overview => text().nullable()();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {providerId, providerSeriesKey},
      ];
}
