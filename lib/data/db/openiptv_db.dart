import 'dart:async';
import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart'
    show ProviderKind;
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
part 'tables/epg_programs_fts.dart';
part 'tables/channels_fts.dart';
part 'tables/vod_search_fts.dart';

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
    EpgProgramsFts,
  ],
)
class OpenIptvDb extends _$OpenIptvDb {
  static const int schemaVersionLatest = 6;

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
          await _ensureEpgSearchIndex(rebuild: true);
          await _ensureChannelSearchIndex(rebuild: true);
          await _ensureVodSearchIndex(rebuild: true);
          await _ensureProviderIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          for (var version = from; version < to; version++) {
            switch (version) {
              case 1:
                await _migrateFrom1To2(m);
                break;
              case 2:
                await _migrateFrom2To3();
                break;
              case 3:
                await _migrateFrom3To4();
                break;
              case 4:
                await _migrateFrom4To5();
                break;
              case 5:
                await _migrateFrom5To6();
                break;
              default:
                break;
            }
          }
        },
        beforeOpen: (OpeningDetails details) async {
          if (!details.wasCreated) {
            await _verifyIntegrity();
          }
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

  Future<void> _migrateFrom2To3() async {
    await _ensureEpgSearchIndex(rebuild: true);
  }

  Future<void> _migrateFrom3To4() async {
    await _ensureChannelSearchIndex(rebuild: true);
    await _ensureVodSearchIndex(rebuild: true);
  }

  Future<void> _migrateFrom4To5() async {
    await customStatement(
      'ALTER TABLE providers ADD COLUMN legacy_profile_id TEXT;',
    );
    await _ensureProviderIndexes();
  }

  Future<void> _migrateFrom5To6() async {
    await _addColumnIfMissing(
      tableName: 'channels',
      columnName: 'first_program_at',
      ddl: 'ALTER TABLE channels ADD COLUMN first_program_at TEXT;',
    );
    await _addColumnIfMissing(
      tableName: 'channels',
      columnName: 'last_program_at',
      ddl: 'ALTER TABLE channels ADD COLUMN last_program_at TEXT;',
    );
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

  Future<void> _addColumnIfMissing({
    required String tableName,
    required String columnName,
    required String ddl,
  }) async {
    final info = await customSelect(
      'PRAGMA table_info($tableName);',
    ).get();
    final exists = info.any(
      (row) => row.data['name']?.toString() == columnName,
    );
    if (!exists) {
      await customStatement(ddl);
    }
  }

  Future<void> _verifyIntegrity() async {
    final rows = await customSelect('PRAGMA integrity_check;').get();
    if (rows.isEmpty) return;
    final status = rows.first.data.values.first?.toString() ?? 'unknown';
    if (status.toLowerCase() != 'ok') {
      throw DatabaseIntegrityException(status);
    }
  }

  Future<void> _ensureEpgSearchIndex({required bool rebuild}) async {
    if (rebuild) {
      await _dropEpgFtsArtifacts();
    }

    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS epg_programs_fts USING fts5(
        title,
        description,
        program_id UNINDEXED
      );
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS epg_programs_ai
      AFTER INSERT ON epg_programs BEGIN
        INSERT INTO epg_programs_fts(rowid, title, description, program_id)
        VALUES (
          new.id,
          coalesce(new.title, ''),
          coalesce(new.description, ''),
          new.id
        );
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS epg_programs_ad
      AFTER DELETE ON epg_programs BEGIN
        DELETE FROM epg_programs_fts WHERE rowid = old.id;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS epg_programs_au
      AFTER UPDATE ON epg_programs BEGIN
        DELETE FROM epg_programs_fts WHERE rowid = old.id;
        INSERT INTO epg_programs_fts(rowid, title, description, program_id)
        VALUES(
          new.id,
          coalesce(new.title, ''),
          coalesce(new.description, ''),
          new.id
        );
      END;
    ''');

    await customStatement('DELETE FROM epg_programs_fts;');
    await customStatement('''
      INSERT INTO epg_programs_fts(rowid, title, description, program_id)
      SELECT
        id,
        coalesce(title, ''),
        coalesce(description, ''),
        id
      FROM epg_programs;
    ''');
  }

  Future<void> _dropEpgFtsArtifacts() async {
    await customStatement('DROP TRIGGER IF EXISTS epg_programs_ai;');
    await customStatement('DROP TRIGGER IF EXISTS epg_programs_ad;');
    await customStatement('DROP TRIGGER IF EXISTS epg_programs_au;');
    await customStatement('DROP TABLE IF EXISTS epg_programs_fts;');
  }

  Future<void> _ensureChannelSearchIndex({required bool rebuild}) async {
    if (rebuild) {
      await _dropChannelFtsArtifacts();
    }

    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS channel_search_fts USING fts5(
        name,
        provider_key,
        category_tokens,
        provider_id UNINDEXED,
        channel_id UNINDEXED,
        tokenize='unicode61'
      );
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channels_ai_search
      AFTER INSERT ON channels BEGIN
        DELETE FROM channel_search_fts WHERE rowid = new.id;
        INSERT INTO channel_search_fts(
          rowid, name, provider_key, category_tokens, provider_id, channel_id
        )
        VALUES(
          new.id,
          COALESCE(new.name, ''),
          COALESCE(new.provider_channel_key, ''),
          COALESCE((
            SELECT group_concat(categories.name, ' ')
            FROM channel_categories
            JOIN categories ON categories.id = channel_categories.category_id
            WHERE channel_categories.channel_id = new.id
          ), ''),
          CAST(new.provider_id AS TEXT),
          CAST(new.id AS TEXT)
        );
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channels_ad_search
      AFTER DELETE ON channels BEGIN
        DELETE FROM channel_search_fts WHERE rowid = old.id;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channels_au_search
      AFTER UPDATE ON channels BEGIN
        DELETE FROM channel_search_fts WHERE rowid = old.id;
        INSERT INTO channel_search_fts(
          rowid, name, provider_key, category_tokens, provider_id, channel_id
        )
        VALUES(
          new.id,
          COALESCE(new.name, ''),
          COALESCE(new.provider_channel_key, ''),
          COALESCE((
            SELECT group_concat(categories.name, ' ')
            FROM channel_categories
            JOIN categories ON categories.id = channel_categories.category_id
            WHERE channel_categories.channel_id = new.id
          ), ''),
          CAST(new.provider_id AS TEXT),
          CAST(new.id AS TEXT)
        );
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channel_categories_ai_search
      AFTER INSERT ON channel_categories BEGIN
        DELETE FROM channel_search_fts WHERE rowid = new.channel_id;
        INSERT INTO channel_search_fts(
          rowid, name, provider_key, category_tokens, provider_id, channel_id
        )
        SELECT
          channels.id,
          COALESCE(channels.name, ''),
          COALESCE(channels.provider_channel_key, ''),
          COALESCE((
            SELECT group_concat(categories.name, ' ')
            FROM channel_categories cc
            JOIN categories ON categories.id = cc.category_id
            WHERE cc.channel_id = channels.id
          ), ''),
          CAST(channels.provider_id AS TEXT),
          CAST(channels.id AS TEXT)
        FROM channels
        WHERE channels.id = new.channel_id;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS channel_categories_ad_search
      AFTER DELETE ON channel_categories BEGIN
        DELETE FROM channel_search_fts WHERE rowid = old.channel_id;
        INSERT INTO channel_search_fts(
          rowid, name, provider_key, category_tokens, provider_id, channel_id
        )
        SELECT
          channels.id,
          COALESCE(channels.name, ''),
          COALESCE(channels.provider_channel_key, ''),
          COALESCE((
            SELECT group_concat(categories.name, ' ')
            FROM channel_categories cc
            JOIN categories ON categories.id = cc.category_id
            WHERE cc.channel_id = channels.id
          ), ''),
          CAST(channels.provider_id AS TEXT),
          CAST(channels.id AS TEXT)
        FROM channels
        WHERE channels.id = old.channel_id;
      END;
    ''');

    await customStatement('DELETE FROM channel_search_fts;');
    await customStatement('''
      INSERT INTO channel_search_fts(
        rowid, name, provider_key, category_tokens, provider_id, channel_id
      )
      SELECT
        channels.id,
        COALESCE(channels.name, ''),
        COALESCE(channels.provider_channel_key, ''),
        COALESCE((
          SELECT group_concat(categories.name, ' ')
          FROM channel_categories
          JOIN categories ON categories.id = channel_categories.category_id
          WHERE channel_categories.channel_id = channels.id
        ), ''),
        CAST(channels.provider_id AS TEXT),
        CAST(channels.id AS TEXT)
      FROM channels;
    ''');
  }

  Future<void> _dropChannelFtsArtifacts() async {
    await customStatement('DROP TRIGGER IF EXISTS channels_ai_search;');
    await customStatement('DROP TRIGGER IF EXISTS channels_ad_search;');
    await customStatement('DROP TRIGGER IF EXISTS channels_au_search;');
    await customStatement('DROP TRIGGER IF EXISTS channel_categories_ai_search;');
    await customStatement('DROP TRIGGER IF EXISTS channel_categories_ad_search;');
    await customStatement('DROP TABLE IF EXISTS channel_search_fts;');
  }

  Future<void> _ensureVodSearchIndex({required bool rebuild}) async {
    if (rebuild) {
      await _dropVodFtsArtifacts();
    }

    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS vod_search_fts USING fts5(
        title,
        overview,
        category_tokens,
        provider_id UNINDEXED,
        item_type UNINDEXED,
        item_id UNINDEXED,
        tokenize='unicode61'
      );
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS movies_ai_search
      AFTER INSERT ON movies BEGIN
        DELETE FROM vod_search_fts WHERE rowid = new.id * 2;
        INSERT INTO vod_search_fts(
          rowid, title, overview, category_tokens, provider_id, item_type, item_id
        )
        VALUES(
          new.id * 2,
          COALESCE(new.title, ''),
          COALESCE(new.overview, ''),
          COALESCE((SELECT name FROM categories WHERE categories.id = new.category_id), ''),
          CAST(new.provider_id AS TEXT),
          'movie',
          CAST(new.id AS TEXT)
        );
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS movies_au_search
      AFTER UPDATE ON movies BEGIN
        DELETE FROM vod_search_fts WHERE rowid = old.id * 2;
        INSERT INTO vod_search_fts(
          rowid, title, overview, category_tokens, provider_id, item_type, item_id
        )
        VALUES(
          new.id * 2,
          COALESCE(new.title, ''),
          COALESCE(new.overview, ''),
          COALESCE((SELECT name FROM categories WHERE categories.id = new.category_id), ''),
          CAST(new.provider_id AS TEXT),
          'movie',
          CAST(new.id AS TEXT)
        );
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS movies_ad_search
      AFTER DELETE ON movies BEGIN
        DELETE FROM vod_search_fts WHERE rowid = old.id * 2;
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS series_ai_search
      AFTER INSERT ON series BEGIN
        DELETE FROM vod_search_fts WHERE rowid = new.id * 2 + 1;
        INSERT INTO vod_search_fts(
          rowid, title, overview, category_tokens, provider_id, item_type, item_id
        )
        VALUES(
          new.id * 2 + 1,
          COALESCE(new.title, ''),
          COALESCE(new.overview, ''),
          COALESCE((SELECT name FROM categories WHERE categories.id = new.category_id), ''),
          CAST(new.provider_id AS TEXT),
          'series',
          CAST(new.id AS TEXT)
        );
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS series_au_search
      AFTER UPDATE ON series BEGIN
        DELETE FROM vod_search_fts WHERE rowid = old.id * 2 + 1;
        INSERT INTO vod_search_fts(
          rowid, title, overview, category_tokens, provider_id, item_type, item_id
        )
        VALUES(
          new.id * 2 + 1,
          COALESCE(new.title, ''),
          COALESCE(new.overview, ''),
          COALESCE((SELECT name FROM categories WHERE categories.id = new.category_id), ''),
          CAST(new.provider_id AS TEXT),
          'series',
          CAST(new.id AS TEXT)
        );
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS series_ad_search
      AFTER DELETE ON series BEGIN
        DELETE FROM vod_search_fts WHERE rowid = old.id * 2 + 1;
      END;
    ''');

    await customStatement('DELETE FROM vod_search_fts;');
    await customStatement('''
      INSERT INTO vod_search_fts(
        rowid, title, overview, category_tokens, provider_id, item_type, item_id
      )
      SELECT
        movies.id * 2,
        COALESCE(movies.title, ''),
        COALESCE(movies.overview, ''),
        COALESCE((SELECT name FROM categories WHERE categories.id = movies.category_id), ''),
        CAST(movies.provider_id AS TEXT),
        'movie',
        CAST(movies.id AS TEXT)
      FROM movies;
    ''');
    await customStatement('''
      INSERT INTO vod_search_fts(
        rowid, title, overview, category_tokens, provider_id, item_type, item_id
      )
      SELECT
        series.id * 2 + 1,
        COALESCE(series.title, ''),
        COALESCE(series.overview, ''),
        COALESCE((SELECT name FROM categories WHERE categories.id = series.category_id), ''),
        CAST(series.provider_id AS TEXT),
        'series',
        CAST(series.id AS TEXT)
      FROM series;
    ''');
  }

  Future<void> _dropVodFtsArtifacts() async {
    await customStatement('DROP TRIGGER IF EXISTS movies_ai_search;');
    await customStatement('DROP TRIGGER IF EXISTS movies_au_search;');
    await customStatement('DROP TRIGGER IF EXISTS movies_ad_search;');
    await customStatement('DROP TRIGGER IF EXISTS series_ai_search;');
    await customStatement('DROP TRIGGER IF EXISTS series_au_search;');
    await customStatement('DROP TRIGGER IF EXISTS series_ad_search;');
    await customStatement('DROP TABLE IF EXISTS vod_search_fts;');
  }

  Future<void> _ensureProviderIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_providers_legacy_profile_id '
      'ON providers(legacy_profile_id);',
    );
  }
}

class DatabaseIntegrityException implements Exception {
  DatabaseIntegrityException(this.result);

  final String result;

  @override
  String toString() => 'DatabaseIntegrityException($result)';
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

