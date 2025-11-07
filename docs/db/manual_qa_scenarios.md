# Manual QA Scenarios

These guided scenarios ensure the new database-backed pipeline behaves correctly across real-world edge cases. Run them on every major build (pre-release) and after any schema/import change.

## 1. Multi-Provider Coverage

- **Goal:** Validate that Xtream, Stalker, and M3U providers can coexist, sync independently, and surface distinct libraries.
- **Setup:** Configure at least one provider per protocol; ensure each has unique credentials and content footprints.
- **Steps:**
  1. Onboard providers sequentially via the unified login flow. Confirm each entry creates a DB provider row (check Provider Management screen).
  2. Trigger discovery/import for all providers (manually via refresh).
  3. Open the Player shell for each provider and confirm categories, favorites, and summaries reflect the respective account.
  4. Delete one provider; remaining providers should retain their data.
- **Pass Criteria:** Imports stay isolated (no channel bleed), switching providers updates the DB-backed UI instantly, deleting a provider purges only its rows.

## 2. Offline Replay & Cache Usage

- **Goal:** Ensure the app behaves when the network is unavailable but the database already contains content.
- **Setup:** Pick a provider with a fully synced catalog. Disable network connectivity (Airplane mode or block via firewall).
- **Steps:**
  1. Relaunch the app; the login screen should list cached providers.
  2. Enter the Player shell; categories and summaries must load from the DB without hitting the network.
  3. Attempt a discovery refresh; expect a graceful error banner and no crash. Re-enable network and confirm refresh resumes.
- **Pass Criteria:** Offline mode shows cached data, surfaces actionable warnings, and retains history/favorites without clearing data.

## 3. Retention & Tombstone Sweeps

- **Goal:** Verify maintenance jobs remove stale channels/artwork while preserving active rows.
- **Setup:** Use an importer fixture that marks some channels as deleted (e.g., rerun an import with missing entries). Ensure artwork cache contains entries older than the retention window.
- **Steps:**
  1. Run the maintenance CLI (`flutter pub run tool/db_maintenance.dart --prune`) or trigger the in-app maintenance screen.
  2. Inspect the DB (Drift devtools or SQL console) to confirm tombstoned rows are removed once past the grace period, and artwork cache shrinks.
  3. Re-run imports to confirm surviving channels remain intact and summaries recalculate.
- **Pass Criteria:** Only rows flagged as stale get purged, artwork cache size drops, and summaries remain accurate after cleanup.

## Reporting

Document findings (pass/fail plus notes) in the release checklist. Capture logs (`docs/db/telemetry_observability.md` instructions) whenever issues surface so they can be attached to bug reports.
