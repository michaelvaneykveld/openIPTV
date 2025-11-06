## Migration Playbook

1. **Backup first**
   - Export the current SQLite database file and secure-storage key.
   - Snapshot import telemetry via `flutter pub run tool/db_maintenance.dart --export-import-runs=import_runs.json`.

2. **Apply upgrade**
   - Ship the new build (Drift schema version now `OpenIptvDb.schemaVersionLatest`).
   - On first launch, Drift runs incremental migrations (see `openiptv_db.dart` `onUpgrade` loop).

3. **Verify success**
   - Check the log output for `Running VACUUM/ANALYZE…` entries and ensure no migration errors.
   - Optionally run `flutter pub run tool/db_maintenance.dart --sweep` to confirm maintenance tasks still operate.
   - Confirm tables (e.g., `import_runs`) exist via CLI or Drift inspector.

4. **Failure recovery**
   - Restore the saved database file and encryption key.
   - Roll back the app build, then rerun the migration after addressing the root cause.
   - For partial migrations, delete the new tables (e.g., `DROP TABLE import_runs;`) before retrying to maintain idempotence.

