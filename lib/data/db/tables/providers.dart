part of '../openiptv_db.dart';

@DataClassName('ProviderRecord')
class Providers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get kind => textEnum<ProviderKind>()();

  TextColumn get displayName => text().withDefault(const Constant(''))();

  TextColumn get lockedBase => text()();

  BoolColumn get needsUa => boolean().withDefault(const Constant(false))();

  BoolColumn get allowSelfSigned =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  TextColumn get etagHash => text().nullable()();
}

enum ProviderKind { stalker, xtream, m3u }
