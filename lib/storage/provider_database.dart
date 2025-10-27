import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
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
@DriftDatabase(tables: [ProviderProfiles, ProviderSecrets])
class ProviderDatabase extends _$ProviderDatabase {
  ProviderDatabase() : super(_openProviderConnection());

  /// Convenience constructor for tests where callers supply a custom executor.
  ProviderDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
