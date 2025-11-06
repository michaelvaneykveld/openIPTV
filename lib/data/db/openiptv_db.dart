import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_flags.dart';

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
  ],
)
class OpenIptvDb extends _$OpenIptvDb {
  OpenIptvDb._(super.executor);

  /// Construct a database instance backed by the on-device file store.
  factory OpenIptvDb.open() => OpenIptvDb._(_openConnection());

  /// Convenience factory for tests that prefer an in-memory database.
  factory OpenIptvDb.inMemory() => OpenIptvDb._(_openInMemory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle migrations as new phases land.
        },
        beforeOpen: (OpeningDetails details) async {
          // Enforce fundamentals every time the database is opened.
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA synchronous = NORMAL;');
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA temp_store = MEMORY;');
        },
      );
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      throw UnsupportedError('The offline database is not available on web.');
    }

    if (DatabaseFlags.enableSqlCipher) {
      // Hook for future SQLCipher integration. Until implemented, make it
      // explicit so we do not silently run without encryption.
      throw UnsupportedError(
        'SQLCipher builds are not yet configured. Disable DB_ENABLE_SQLCIPHER.',
      );
    }

    final directory = await _resolveStorageDirectory();
    final dbPath = p.join(directory.path, 'openiptv.db');

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

