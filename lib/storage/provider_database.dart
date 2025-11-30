import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

part 'provider_database.g.dart';

/// Persists simple `Map<String, String>` payloads as JSON blobs.
class MapStringConverter extends TypeConverter<Map<String, String>, String> {
  const MapStringConverter();

  @override
  Map<String, String> fromSql(String fromDb) {
    if (fromDb.isEmpty) {
      return const <String, String>{};
    }
    final decoded = jsonDecode(fromDb);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', '$value'));
    }
    return const <String, String>{};
  }

  @override
  String toSql(Map<String, String> value) {
    if (value.isEmpty) {
      return '{}';
    }
    return jsonEncode(value);
  }
}

/// Drift table carrying the non-secret profile metadata for a provider.
class ProviderProfiles extends Table {
  @override
  String get tableName => 'providers';

  TextColumn get id => text()();
  IntColumn get kind => intEnum<ProviderKind>()();
  TextColumn get displayName => text()();
  TextColumn get lockedBase => text()();
  BoolColumn get needsUserAgent =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get allowSelfSignedTls =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get followRedirects =>
      boolean().withDefault(const Constant(true))();
  TextColumn get configuration => text()
      .map(const MapStringConverter())
      .withDefault(const Constant('{}'))();
  TextColumn get hints => text()
      .map(const MapStringConverter())
      .withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOkAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Drift table that maps provider identifiers to secure storage keys.
class ProviderSecrets extends Table {
  @override
  String get tableName => 'provider_secrets';

  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  TextColumn get vaultKey => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {providerId};
}

/// Groups/Categories for Live, Movie, and Series content.
class StreamGroups extends Table {
  @override
  String get tableName => 'stream_groups';

  IntColumn get id => integer()(); // Category ID from Xtream
  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'live', 'movie', 'series'

  @override
  Set<Column<Object>> get primaryKey => {id, providerId, type};
}

/// Live TV Channels.
class LiveStreams extends Table {
  @override
  String get tableName => 'live_streams';

  IntColumn get streamId => integer()();
  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  TextColumn get name => text()();
  TextColumn get streamIcon => text().nullable()();
  TextColumn get epgChannelId => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get num => integer().nullable()();
  BoolColumn get isAdult => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {streamId, providerId};
}

/// VOD / Movies.
class VodStreams extends Table {
  @override
  String get tableName => 'vod_streams';

  IntColumn get streamId => integer()();
  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  TextColumn get name => text()();
  TextColumn get streamIcon => text().nullable()();
  TextColumn get containerExtension => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  RealColumn get rating => real().nullable()();
  DateTimeColumn get added => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {streamId, providerId};
}

/// TV Series.
class Series extends Table {
  @override
  String get tableName => 'series';

  IntColumn get seriesId => integer()();
  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  TextColumn get name => text()();
  TextColumn get cover => text().nullable()();
  TextColumn get plot => text().nullable()();
  TextColumn get cast => text().nullable()();
  TextColumn get director => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get releaseDate => text().nullable()();
  DateTimeColumn get lastModified => dateTime().nullable()();
  IntColumn get categoryId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {seriesId, providerId};
}

/// Episodes for Series (Lazy Loaded).
class Episodes extends Table {
  @override
  String get tableName => 'episodes';

  IntColumn get id => integer()();
  IntColumn get seriesId => integer()();
  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  TextColumn get title => text()();
  TextColumn get containerExtension => text().nullable()();
  TextColumn get info => text().nullable()();
  IntColumn get season => integer().nullable()();
  IntColumn get episode => integer().nullable()();
  IntColumn get duration => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id, providerId};
}

/// EPG Events.
class EpgEvents extends Table {
  @override
  String get tableName => 'epg_events';

  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  TextColumn get channelId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {providerId, channelId, start};
}

/// User Favorites.
class Favorites extends Table {
  @override
  String get tableName => 'favorites';

  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  IntColumn get contentId => integer()();
  TextColumn get type => text()(); // 'live', 'movie', 'series'
  DateTimeColumn get dateAdded => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {providerId, contentId, type};
}

/// Watch History / Resume Points.
class PlaybackHistory extends Table {
  @override
  String get tableName => 'playback_history';

  TextColumn get providerId => text().customConstraint(
    'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  )();
  IntColumn get contentId => integer()();
  TextColumn get type => text()(); // 'live', 'movie', 'series', 'episode'
  IntColumn get positionSeconds => integer()();
  IntColumn get durationSeconds => integer().nullable()();
  DateTimeColumn get lastWatched => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {providerId, contentId, type};
}

LazyDatabase _openProviderConnection() {
  return LazyDatabase(() async {
    _ensureSqfliteFactoryForDesktop();
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, 'provider_profiles.sqlite');
    return SqfliteQueryExecutor(path: path, logStatements: false);
  });
}

bool _sqfliteFactoryInitialised = false;

void _ensureSqfliteFactoryForDesktop() {
  if (_sqfliteFactoryInitialised || kIsWeb) {
    return;
  }
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
    _sqfliteFactoryInitialised = true;
  }
}

/// Central database that stores provider profiles and secure storage mappings.
@DriftDatabase(
  tables: [
    ProviderProfiles,
    ProviderSecrets,
    StreamGroups,
    LiveStreams,
    VodStreams,
    Series,
    Episodes,
    EpgEvents,
    Favorites,
    PlaybackHistory,
  ],
)
class ProviderDatabase extends _$ProviderDatabase {
  ProviderDatabase() : super(_openProviderConnection());

  /// Convenience constructor for tests where callers supply a custom executor.
  ProviderDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;
}

final providerDatabaseProvider = Provider<ProviderDatabase>((ref) {
  final db = ProviderDatabase();
  ref.onDispose(db.close);
  return db;
});
