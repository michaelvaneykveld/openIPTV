# Database Implementation Checklist

## Vision & Foundation
- [x] Re-read `database_roadmap.md` and lock objectives, scope, and success metrics with the team. -> see `docs/db/vision_foundation.md`.
- [x] Confirm platform support matrix (Android, iOS, Windows, Linux, macOS) and Drift/SQLite dependency versions in `pubspec.yaml`.
- [x] Decide on DB storage location per platform and verify secure storage plumbing is ready for provider secrets.
- [x] Define feature flags for optional SQLCipher/FTS usage per build flavour.

## Drift Project Setup
- [x] Add core packages (`drift`, `drift_sqflite`, `sqlite3_flutter_libs`, generators) and configure build_runner. -> dependency updates in `pubspec.yaml`.
- [x] Create a dedicated `lib/data/db/` module structure (tables, daos, repositories, importers). -> see `lib/data/db/*`.
- [x] Implement the Drift database class with WAL PRAGMAs, foreign-key enforcement, and hot/open helpers. -> `lib/data/db/openiptv_db.dart`.
- [x] Introduce a centralized database locator/service wired into Riverpod for injection. -> `lib/data/db/database_locator.dart`.

## Schema Phase 1 – Providers & Live Channels
- [x] Define tables: `providers`, `channels`, `categories`, `channel_categories`, `summaries`. -> see `lib/data/db/tables/`.
- [x] Enforce all declared unique constraints and foreign keys (provider scoped keys, many-to-many bridge).
- [x] Generate Drift companions/data classes and ensure integer surrogate keys map correctly.
- [x] Write schema unit tests creating the in-memory DB and asserting constraints/indexes. -> test/data/db/schema_phase1_test.dart.

## DAO & Repository Layer (Phase 1)
- [x] Implement `ProviderDao` with CRUD, last-sync tracking, and display metadata helpers. -> `lib/data/db/dao/provider_dao.dart`.
- [x] Implement `ChannelDao` with upsert-by-provider-key, tombstoning, and category linking helpers. -> `lib/data/db/dao/channel_dao.dart`.
- [x] Implement `CategoryDao` with upsert, ordering, and lookup APIs. -> `lib/data/db/dao/category_dao.dart`.
- [x] Implement `SummaryDao` for pre-computed counts and provider snapshots. -> `lib/data/db/dao/summary_dao.dart`.
- [x] Create repositories that orchestrate DAOs and expose watch/stream APIs for UI/state. -> `lib/data/repositories/*`.

## Import Pipelines – Foundations
- [x] Build a shared `ImportContext` abstraction (transaction wrapper, conflict handling, metrics). -> `lib/data/import/import_context.dart`.
- [x] Implement Xtream importer (live categories + channels) with delta upserts and summary recompute. -> `lib/data/import/xtream_importer.dart`.
- [x] Implement Stalker importer (live categories + channels) respecting provider-specific keys. -> `lib/data/import/stalker_importer.dart`.
- [x] Implement M3U importer (group-based categories, radio/live split). -> `lib/data/import/m3u_importer.dart`.
- [x] Ensure all importers mark missing rows as tombstoned, and emit summary totals. -> ChannelDao + importers use tombstone/purge logic.
- [x] Add retry/backoff wrappers and guardrails for malformed payloads per provider. -> `ImportContext.runWithRetry`.

## Schema Phase 2 – EPG & Search
- [x] Add `epg_programs` table with indexes (`channel_id` + time window) and optional FTS mirror. -> `lib/data/db/tables/epg_programs.dart` (index creation in `openiptv_db.dart`).
- [x] Implement DAO queries for now/next, date-range, and bulk inserts (batch API). -> `lib/data/db/dao/epg_dao.dart`.
- [x] Create retention job to purge programs older than configured window. -> `EpgDao.purgeOlderThan` + importer retention controls.
- [x] Wire importer to ingest EPG deltas per provider (Xtream/other) and update summaries. -> `lib/data/import/epg_importer.dart`.

## Schema Phase 3 – VOD & Series
- [x] Create tables: `movies`, `series`, `seasons`, `episodes` plus relationships. -> `lib/data/db/tables/movies.dart`, `series.dart`, `seasons.dart`, `episodes.dart`.
- [x] Extend importers to fetch and upsert VOD/series metadata (Xtream, Stalker where available). -> `lib/data/import/xtream_importer.dart`.
- [x] Link VOD/series items to categories and compute VOD/series summaries. -> Category foreign keys + summary recompute in `lib/data/import/xtream_importer.dart`.
- [x] Expose repository APIs for browsing VOD catalog and series hierarchy (series -> seasons -> episodes). -> `lib/data/repositories/vod_repository.dart`.

## Artwork, Flags, History & Cache
- [x] Implement `artwork_cache` table with LRU metadata and storage strategy (BLOB vs file pointer). -> `lib/data/db/tables/artwork_cache.dart`, `lib/data/db/dao/artwork_cache_dao.dart`.
- [x] Build image fetcher that stores etag/hash and enforces eviction limits. -> `lib/data/artwork/artwork_fetcher.dart` (+ tests in `test/data/artwork/artwork_fetcher_test.dart`).
- [x] Add `playback_history` schema + DAO for scrobbling, resumptions, and prunable history. -> `lib/data/db/tables/playback_history.dart`, `lib/data/db/dao/playback_history_dao.dart`.
- [x] Add `user_flags` schema for favourites/hidden/pin metadata, with provider scoped uniqueness. -> `lib/data/db/tables/user_flags.dart`, `lib/data/db/dao/user_flag_dao.dart`.
- [x] Ensure UI repositories surface combined channel + user flag states. -> `lib/data/repositories/channel_repository.dart` (ChannelWithFlags streams).

## Security & Storage Guardrails
- [x] Keep provider secrets (username/password/token) exclusively in secure storage and confirm DB never persists them. -> `ProviderProfileRepository` sanitizes payloads (see `test/storage/provider_profile_repository_test.dart`).
- [x] Optionally integrate SQLCipher/`sqflite_sqlcipher` for encrypted caches; expose toggle in build config. -> `DB_ENABLE_SQLCIPHER` flag in `OpenIptvDb`, documented in `docs/db/security_guardrails.md`.
- [x] Scrub logs/debug prints to avoid leaking secrets or raw payloads (use redaction helpers). -> Logging flows use `src/utils/url_redaction.dart` with coverage in `test/utils/url_redaction_test.dart`.
- [x] Document backup/restore implications (e.g., DB location excluded from auto-backup if required). -> `docs/db/security_guardrails.md` backup section.

## Performance & Maintenance Automation
- [x] Implement periodic VACUUM/ANALYZE policy gated by size/elapsed time. -> `lib/data/db/database_maintenance.dart`, `lib/data/db/dao/maintenance_log_dao.dart`, tests in `test/data/db/database_maintenance_test.dart`.
- [x] Add retention sweeper to drop tombstoned channels after grace window and prune orphaned relationships/artwork. -> `DatabaseMaintenance` uses `ChannelDao.purgeAllStaleChannels` and artwork pruning.
- [x] Enforce backpressure on import concurrency (limit parallel requests per provider). -> `_providerLocks` in `ImportContext.runWithRetry` ensures per-provider serialization.
- [x] Record import durations, row counts, and error metrics for diagnostics. -> Import runs logged via `ImportRunDao` from `ImportContext`.
- [x] Provide manual maintenance CLI/debug screen (vacuum, reset provider data, export diagnostics). -> `flutter pub run tool/db_maintenance.dart`.

## Migration Strategy
- [x] Set baseline schema version and write idempotent Drift migration scripts. -> `OpenIptvDb` schemaVersionLatest=2 with incremental migrations.
- [x] Add tests covering upgrade/downgrade paths with fixture data. -> `test/data/db/migration_test.dart` verifies v1->latest upgrade.
- [x] Establish migration playbook (backup, apply, verify) and document failure recovery. -> `docs/db/migration_playbook.md`.

## Search & Browse Integration
- [x] Implement FTS-backed EPG search with highlight snippets wired through `SearchRepository`.
- [x] Implement channel search FTS index + highlight output. -> virtual table + triggers in `lib/data/db/openiptv_db.dart`, query wiring + highlights in `lib/data/repositories/search_repository.dart`.
- [x] Implement VOD search FTS index + highlight output. -> `vod_search_fts` triggers in `lib/data/db/openiptv_db.dart`, repository API `searchVod`.
- [x] Add derived queries: favourites-first ordering, category filtering, and recent play history joins.
- [x] Create summary projections powering fast home/dashboard loads. -> `loadDashboardSummary` in `lib/data/repositories/search_repository.dart`.

## UI & App Integration
- [ ] Replace in-memory providers with DB-backed streams in home guide and discovery flows.
- [ ] Hook login onboarding to create provider records and kick off initial import jobs.
- [ ] Surface import progress/last sync state in provider management UI.
- [ ] Update playback/details screens to read user flags, history, and artwork cache.

## Telemetry & Observability
- [ ] Emit structured logs/metrics around imports, query latency, and cache hits (non-PII).
- [ ] Add crash-safe error storage for failed imports with redacted payload excerpts.
- [ ] Provide developer tooling to inspect DB (e.g., Drift devtools integration, export snapshot).

## Testing & QA
- [ ] Write unit tests for each DAO/importer using seeded fixtures (including delta + deletion cases).
- [ ] Add performance regression tests (50k channels, multi-day EPG) ensuring query SLAs.
- [ ] Create integration tests exercising UI flows against an in-memory DB with seeded data.
- [ ] Document manual QA scenarios (multi-provider, offline replay, retention sweeps).

## Release Readiness
- [ ] Conduct security review (storage, logging, encryption toggles).
- [ ] Verify migration + downgrade paths on actual devices.
- [ ] Prepare rollback plan (ability to clear DB safely without losing secure secrets).
- [ ] Update internal docs/readme with new architecture, maintenance commands, and troubleshooting steps.


