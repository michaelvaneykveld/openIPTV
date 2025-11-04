part of '../openiptv_db.dart';

@DataClassName('CategoryRecord')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  TextColumn get kind => textEnum<CategoryKind>()();

  TextColumn get providerCategoryKey => text()();

  TextColumn get name => text()();

  IntColumn get position => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {providerId, kind, providerCategoryKey}
      ];

}

enum CategoryKind { live, vod, series, radio }
