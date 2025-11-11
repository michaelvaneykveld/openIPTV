part of '../openiptv_db.dart';

@DataClassName('ChannelRecord')
class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  TextColumn get providerChannelKey => text()();

  TextColumn get name => text()();

  TextColumn get logoUrl => text().nullable()();

  IntColumn get number => integer().nullable()();

  BoolColumn get isRadio => boolean().withDefault(const Constant(false))();

  TextColumn get streamUrlTemplate => text().nullable()();

  TextColumn get streamHeadersJson => text().nullable()();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  DateTimeColumn get firstProgramAt => dateTime().nullable()();

  DateTimeColumn get lastProgramAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {providerId, providerChannelKey},
  ];
}
