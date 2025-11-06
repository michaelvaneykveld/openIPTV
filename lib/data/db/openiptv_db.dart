import 'dart:async';
import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

import 'database_flags.dart';
import 'database_key_store.dart';

part 'openiptv_db.g.dart';

/// Primary database entry-point for OpenIPTV.
///
/// Tables will be layered in as we progress through the roadmap; for now the
/// empty declaration keeps the generated mixin in place so we can wire the DB
/// through Riverpod and integration points.
part 'tables/providers.dart';
part 'tables/channels.dart';
part 'tables/categories.dart';
part 'tables/channel_categories.dart';
part 'tables/summaries.dart';
part 'tables/epg_programs.dart';
part 'tables/movies.dart';
part 'tables/series.dart';
part 'tables/seasons.dart';
part 'tables/episodes.dart';
part 'tables/artwork_cache.dart';
part 'tables/playback_history.dart';
part 'tables/user_flags.dart';
part 'tables/maintenance_log.dart';
part 'tables/import_runs.dart';

@DriftDatabase(
  tables: [
    Providers,
    Channels,
    Categories,
    ChannelCategories,
    Summaries,
    EpgPrograms,
    Movies,
    Series,
    Seasons,
    Episodes,
    ArtworkCache,
    PlaybackHistory,
    UserFlags,
    MaintenanceLog,
    ImportRuns,
  ],
)
class OpenIptvDb extends _$OpenIptvDb {
  static const int schemaVersionLatest = 2;

  OpenIptvDb._(this._overrideSchemaVersion, super.executor);

  int? _overrideSchemaVersion;

  /// Construct a database instance backed by the on-device file store.
  factory OpenIptvDb.open({DatabaseKeyStore? keyStore}) =>
      OpenIptvDb._(null, _openConnection(keyStore: keyStore));

  /// Convenience factory for tests that prefer an in-memory database.
  factory OpenIptvDb.inMemory() => OpenIptvDb._(null, _openInMemory());

  /// Testing constructor that allows schema version overrides.
  factory OpenIptvDb.forTesting(
    QueryExecutor executor, {
    int? schemaVersionOverride,
  }) =>
      OpenIptvDb._(schemaVersionOverride, executor);

  /// Resolves the on-disk location for the primary database file.
  static Future<File> resolveDatabaseFile() async {
    if (kIsWeb) {
      throw UnsupportedError('Database file is not available on web.');
    }
    final directory = await _resolveStorageDirectory();
    final dbPath = p.join(directory.path, 'openiptv.db');
    return File(dbPath);
  }

  @override
  int get schemaVersion => _overrideSchemaVersion ?? schemaVersionLatest;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          for (var version = from; version < to; version++) {
            switch (version) {
              case 1:
                await _migrateFrom1To2(m);
                break;
              default:
                break;
            }
          }
        },
        beforeOpen: (OpeningDetails details) async {
          // Enforce fundamentals every time the database is opened.
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA synchronous = NORMAL;');
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA temp_store = MEMORY;');
        },
      );

  Future<void> _migrateFrom1To2(Migrator m) async {
    await _createIfMissing(m, maintenanceLog);
    await _createIfMissing(m, artworkCache);
    await _createIfMissing(m, playbackHistory);
    await _createIfMissing(m, userFlags);
    await _createIfMissing(m, importRuns);
  }

  Future<void> _createIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
  ) async {
    final existing = await customSelect(
      'SELECT name FROM sqlite_master WHERE type = "table" AND name = ?',
      variables: [Variable<String>(table.actualTableName)],
    ).get();
    if (existing.isEmpty) {
      await m.createTable(table);
    }
  }
}

QueryExecutor _openConnection({DatabaseKeyStore? keyStore}) {
  return LazyDatabase(() async {
    if (kIsWeb) {
      throw UnsupportedError('The offline database is not available on web.');
    }

    final directory = await _resolveStorageDirectory();
    final dbPath = p.join(directory.path, 'openiptv.db');

    if (DatabaseFlags.enableSqlCipher) {
      if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        throw UnsupportedError(
          'SQLCipher is currently supported on Android, iOS, and macOS builds.',
        );
      }
      final store = keyStore ?? SecureDatabaseKeyStore();
      final key = await store.obtainOrCreateKey();
      return SqlCipherQueryExecutor(
        path: dbPath,
        password: key,
      );
    }

    if (_useNativeDatabase()) {
      return NativeDatabase(
        File(dbPath),
        logStatements: false,
      );
    }

    return SqfliteQueryExecutor(
      path: dbPath,
      singleInstance: true,
      logStatements: false,
    );
  });
}

QueryExecutor _openInMemory() {
  if (_useNativeDatabase()) {
    return NativeDatabase.memory(logStatements: false);
  }
  // Sqflite memory database uses the special path ":memory:".
  return SqfliteQueryExecutor.inDatabaseFolder(
    path: 'openiptv_test.sqlite',
    singleInstance: false,
    logStatements: false,
  );
}

Future<Directory> _resolveStorageDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return getApplicationDocumentsDirectory();
  }
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return getApplicationSupportDirectory();
  }
  // Fallback for other platforms (e.g. FFI tests).
  return getTemporaryDirectory();
}

bool _useNativeDatabase() {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

class SqlCipherQueryExecutor extends DelegatedDatabase {
  SqlCipherQueryExecutor({
    required String path,
    required String password,
    bool singleInstance = true,
    bool? logStatements,
  }) : super(
          _SqlCipherDelegate(
            path: path,
            password: password,
            singleInstance: singleInstance,
          ),
          logStatements: logStatements,
        );

  @override
  bool get isSequential => true;
}

class _SqlCipherDelegate extends DatabaseDelegate {
  _SqlCipherDelegate({
    required this.path,
    required this.password,
    required this.singleInstance,
  });

  final String path;
  final String password;
  final bool singleInstance;

  sqlcipher.Database? _db;
  bool _isOpen = false;

  sqlcipher.Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('SQLCipher database has not been opened yet.');
    }
    return db;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  late final DbVersionDelegate versionDelegate =
      _SqlCipherVersionDelegate(() => _database);

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  Future<void> close() async {
    if (_db != null) {
      await _database.close();
      _db = null;
      _isOpen = false;
    }
  }

  @override
  Future<void> open(QueryExecutorUser user) async {
    _db = await sqlcipher.openDatabase(
      path,
      password: password,
      singleInstance: singleInstance,
    );
    _isOpen = true;
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final batch = _database.batch();
    for (final stmt in statements.arguments) {
      batch.execute(
        statements.statements[stmt.statementIndex],
        stmt.arguments,
      );
    }
    await batch.apply(noResult: true);
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) {
    return _database.execute(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    return _database.rawInsert(statement, args);
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final rows = await _database.rawQuery(statement, args);
    return QueryResult.fromRows(rows);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    return _database.rawUpdate(statement, args);
  }
}

class _SqlCipherVersionDelegate extends DynamicVersionDelegate {
  _SqlCipherVersionDelegate(this._databaseProvider);

  final sqlcipher.Database Function() _databaseProvider;

  @override
  Future<int> get schemaVersion async {
    final result = await _databaseProvider().rawQuery('PRAGMA user_version;');
    return result.single.values.first as int;
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await _databaseProvider()
        .rawUpdate('PRAGMA user_version = $version;');
  }
}

