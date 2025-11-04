import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import 'openiptv_db.dart';

/// Riverpod provider exposing the shared database instance.
final openIptvDbProvider = r.Provider<OpenIptvDb>((ref) {
  final db = OpenIptvDb.open();
  ref.onDispose(db.close);
  return db;
});

/// Override for tests that need an in-memory database.
final openIptvDbInMemoryProvider = r.Provider<OpenIptvDb>((ref) {
  final db = OpenIptvDb.inMemory();
  ref.onDispose(db.close);
  return db;
});
