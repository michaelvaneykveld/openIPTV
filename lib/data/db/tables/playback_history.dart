part of '../openiptv_db.dart';

@DataClassName('PlaybackHistoryRecord')
class PlaybackHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  IntColumn get channelId =>
      integer().references(Channels, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get positionSec =>
      integer().withDefault(const Constant(0))();

  IntColumn get durationSec => integer().nullable()();

  BoolColumn get completed =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {channelId},
      ];
}

