# Release Readiness Checklist

Use this playbook before publishing any build that contains database/schema changes. It complements `docs/db/migration_playbook.md`, `security_guardrails.md`, and `manual_qa_scenarios.md`.

## 1. Security Review
- Confirm provider secrets never land in Drift tables (`providers.locked_base`, `channels`, etc.). Spot-check via SQL queries and log redaction helpers.
- Validate secure-storage plumbing (Android Keystore, iOS Keychain, Windows DPAPI) remains intact after refactors by running the login/onboarding flow on each platform.
- Review new logs/metrics to ensure they route through the redaction utilities; run `flutter analyze --enable-experiment=records` to confirm no `debugPrint` statements leak payloads.
- Exercise the SQLCipher toggle (`DB_ENABLE_SQLCIPHER`) for release builds and verify migrations still run under encryption.

## 2. Migration & Downgrade Verification
- Use the migration playbook to take a production snapshot, upgrade to the new schema (`flutter pub run drift_dev`), then downgrade by installing the previous build to ensure Drift can reopen the older schema without corruption.
- Execute `test/data/db/migration_test.dart` plus an on-device smoke test by installing the previous APK/IPA, populating data, and upgrading over-the-top.
- Capture timing logs to confirm large datasets (50k+ channels, multi-day EPG) migrate within acceptable windows (<30s on mid-tier Android).

## 3. Rollback Plan
- Document the steps to clear only the SQLite file while keeping secure storage intact:
  1. Export telemetry + DB snapshot for post-mortem.
  2. Delete the `openiptv.db` file via maintenance CLI (`flutter pub run tool/db_maintenance.dart --reset-provider {id}` or full `--nuke-db`).
  3. Relaunch the app; providers are rehydrated from secure storage and re-import automatically.
- Ensure CI artifacts include both the new build and the last-known-good build so QA can roll back within minutes.

## 4. Docs & Communications
- Update `docs/notes/README.md` and `docs/db/vision_foundation.md` with any architectural shifts, including new tables, background jobs, or CLI utilities.
- Regenerate the maintenance CLI help (`--help`) and copy the output into `docs/db/maintenance_cli.md`.
- Publish release notes summarizing schema changes, migration expectations, and manual QA focus areas.

Record completion of these steps in the release checklist or project tracker before tagging the release.
