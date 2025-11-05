part of '../openiptv_db.dart';

@DataClassName('EpisodeRecord')
class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get seriesId =>
      integer().references(Series, #id, onDelete: KeyAction.cascade)();

  IntColumn get seasonId =>
      integer().references(Seasons, #id, onDelete: KeyAction.cascade)();

  TextColumn get providerEpisodeKey => text()();

  IntColumn get seasonNumber => integer().nullable()();

  IntColumn get episodeNumber => integer().nullable()();

  TextColumn get title => text().nullable()();

  TextColumn get overview => text().nullable()();

  IntColumn get durationSec => integer().nullable()();

  TextColumn get streamUrlTemplate => text().nullable()();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {seriesId, providerEpisodeKey},
      ];
}
