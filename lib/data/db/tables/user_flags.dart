part of '../openiptv_db.dart';

@DataClassName('UserFlagRecord')
class UserFlags extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  IntColumn get channelId =>
      integer().references(Channels, #id, onDelete: KeyAction.cascade)();

  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isHidden =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {channelId},
      ];
}

