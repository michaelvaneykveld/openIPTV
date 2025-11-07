import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  test('migrates schema from v1 to latest', () async {
    final tmpFile = File('${Directory.systemTemp.path}/openiptv_migration_test.sqlite');
    if (tmpFile.existsSync()) {
      tmpFile.deleteSync();
    }
    final executor = NativeDatabase(tmpFile);

    // Create schema with version 1 to simulate legacy installation.
    final legacy = OpenIptvDb.forTesting(
      executor,
      schemaVersionOverride: 1,
    );
    await legacy.customSelect('SELECT 1').get();
    await legacy.into(legacy.providers).insert(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://legacy.example',
        displayName: const Value('Legacy'),
      ),
    );
    await legacy.close();

    // Re-open using the latest schema to trigger migrations.
    await executor.close();

    final migrated = OpenIptvDb.forTesting(NativeDatabase(tmpFile));

    // Accessing the providers table should succeed and retain existing rows.
    final providers = await migrated.select(migrated.providers).get();
    expect(providers, hasLength(1));
    expect(providers.single.displayName, 'Legacy');

    // Ensure newly introduced tables exist after migration.
    final importRunsExists = await migrated.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='import_runs';",
    ).get();
    expect(importRunsExists, isNotEmpty);

    // Confirm PRAGMA user_version bumped to latest schema.
    final pragma = await migrated.customSelect('PRAGMA user_version;').get();
    expect(
      pragma.single.data.values.first,
      OpenIptvDb.schemaVersionLatest,
    );

    await migrated.close();
    if (tmpFile.existsSync()) {
      tmpFile.deleteSync();
    }
  });
}
