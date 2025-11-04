part of '../openiptv_db.dart';

@DataClassName('EpgProgramRecord')
class EpgPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get channelId =>
      integer().references(Channels, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get startUtc => dateTime()();

  DateTimeColumn get endUtc => dateTime()();

  TextColumn get title => text().nullable()();

  TextColumn get subtitle => text().nullable()();

  TextColumn get description => text().nullable()();

  IntColumn get season => integer().nullable()();

  IntColumn get episode => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {channelId, startUtc},
      ];

}

