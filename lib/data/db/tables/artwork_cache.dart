part of '../openiptv_db.dart';

@DataClassName('ArtworkCacheRecord')
class ArtworkCache extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get url => text()();

  TextColumn get etag => text().nullable()();

  TextColumn get hash => text().nullable()();

  BlobColumn get bytes => blob().nullable()();

  TextColumn get filePath => text().nullable()();

  IntColumn get byteSize => integer().nullable()();

  IntColumn get width => integer().nullable()();

  IntColumn get height => integer().nullable()();

  DateTimeColumn get fetchedAt => dateTime()();

  DateTimeColumn get lastAccessedAt => dateTime()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  BoolColumn get needsRefresh =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {url},
      ];
}

