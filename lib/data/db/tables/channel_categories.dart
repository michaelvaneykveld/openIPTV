part of '../openiptv_db.dart';

@DataClassName('ChannelCategoryRecord')
@DataClassName('ChannelCategoryRecord')
class ChannelCategories extends Table {
  IntColumn get channelId =>
      integer().references(Channels, #id, onDelete: KeyAction.cascade)();

  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {channelId, categoryId};
}
