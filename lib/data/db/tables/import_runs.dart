part of '../openiptv_db.dart';

@DataClassName('ImportRunRecord')
class ImportRuns extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  TextColumn get providerKind => textEnum<ProviderKind>()();

  TextColumn get importType => text()();

  DateTimeColumn get startedAt => dateTime()();

  IntColumn get durationMs => integer().nullable()();

  IntColumn get channelsUpserted => integer().nullable()();

  IntColumn get categoriesUpserted => integer().nullable()();

  IntColumn get moviesUpserted => integer().nullable()();

  IntColumn get seriesUpserted => integer().nullable()();

  IntColumn get seasonsUpserted => integer().nullable()();

  IntColumn get episodesUpserted => integer().nullable()();

  IntColumn get channelsDeleted => integer().nullable()();

  TextColumn get error => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [];

  @override
  List<String> get customConstraints => [
        'UNIQUE(provider_id, import_type, started_at)'
      ];
}

