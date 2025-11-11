part of '../openiptv_db.dart';

@DataClassName('MovieRecord')
class Movies extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  TextColumn get providerVodKey => text()();

  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get title => text()();

  IntColumn get year => integer().nullable()();

  TextColumn get overview => text().nullable()();

  TextColumn get posterUrl => text().nullable()();

  IntColumn get durationSec => integer().nullable()();

  TextColumn get streamUrlTemplate => text().nullable()();

  TextColumn get streamHeadersJson => text().nullable()();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {providerId, providerVodKey},
  ];
}
