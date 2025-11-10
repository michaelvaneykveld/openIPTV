# Next-Level Database TODOs

Use this backlog to track the "ultimate" database roadmap. Check items that already ship in `main`; leave the rest for future work.

## First Priority - Portal Ingest Reliability
- [x] Portal-aware category discovery with probe chain (get_categories -> get_genres -> get_categories_v2), parental unlock hook, and derived-category fallback stored per portal dialect. -> Stalker imports now consult a persisted dialect (preferred category action + derived cache), reuse cached buckets, retry probes in the new sequence, and flag portals that surface locked categories so the UI can prompt for the parental password.
- [x] Per-category paging with caps/backoff plus radio coverage; global "*" paging only as a limited fallback. -> All Stalker modules (including Live/Radio) now prefer the bulk `get_all_*` endpoints, falling back to capped per-category paging with short inter-page yields, and only then to a 25-page "*" sweep. This keeps imports under control and eliminates the minutes-long, multi-novel logs.
- [x] Offload imports to a dedicated isolate that streams progress, keeps Drift writes off the UI thread, and supports cancel/resume. -> ProviderImportService now spawns a Drift worker isolate (non-web, non-encrypted builds) and relays progress via a typed event stream.
- [x] Persist resume tokens/checkpoints per provider+category so subsequent sessions resume instead of rewalking from the start. -> Stalker imports now persist per-category page checkpoints in a JSON sidecar next to the Drift DB, reuse them across isolate restarts, and clear them once an import fully completes.
- [ ] Surface lightweight progress UI (state + cancel) while imports run in the background.

## North-Star Metrics
- [ ] Cold tune-to-first-channel <= 2.0s; warm <= 1.2s.
- [ ] Search 10-50k channels plus multi-million EPG rows in <= 100ms typical.
- [ ] Keep memory stable while scrolling/importing (<= 200MB during imports via streaming/pagination).
- [ ] Run heavy imports off the UI isolate with visible progress plus cancel/rollback.
- [ ] Maintain platform parity (Drift sqlite3/FFI for native, Drift IndexedDB for web) behind the same DAO APIs.

## Phase 1 - Core Schema & Access Patterns
- [x] **Prioritized:** Persist last discovery payload per provider (categories + summaries) and hydrate them on app resume before hitting the network. -> `ProviderImportService` re-primes Drift on connect; login tiles & PlayerShell read from DB-first providers.
- [x] **Prioritized:** Remove legacy discovery fallback once DB streams contain data; only re-run discovery if the DB is empty or explicitly refreshed. -> Player shell & login UI only call legacy probes when no DB record exists.
- [x] Model `providers`, `channel_groups`, `channels`, `stream_endpoints`, `epg_events` in Drift.
- [x] Add mandatory indexes: `(provider_id, stable_key)` unique, `(group_id, sort_key)`, NOCASE `name`, EPG covering indexes, `stream_endpoints(channel_id, priority)`.
- [x] Implement chunked bulk upserts (1-5k rows) using `INSERT ... ON CONFLICT DO UPDATE`.
- [x] Build key-set pagination reads (no OFFSET) with prepared statements and an off-isolate write queue. -> `ChannelRepository.fetchChannelPage` + DAO helpers stream cursor-based chunks.
- [x] Apply WAL-friendly PRAGMAs (`journal_mode=WAL`, `synchronous=NORMAL`, cache sizing, `foreign_keys=ON`).
- [ ] Acceptance: import 100k channels < 30s and keep channel list scrolling at 60fps.

## Phase 2 - Parsing & Ingest at Scale
- [ ] Run M3U/XMLTV/Xtream/Stalker parsing and Drift writes inside isolates (single writer, shared readers).
- [ ] Partition EPG imports by day and store ETag/Last-Modified hashes to skip unchanged payloads.
- [x] Track tombstones for removed channels; schedule background hard-prune.
- [ ] Acceptance: imports can cancel/resume safely and re-running identical input results in zero data changes.

## Phase 3 - Instant Search & Zap
- [x] Add FTS5 external-content tables for channels (name, alt names, group title) and optional EPG snippets using unicode61 tokenizer.
- [x] Create triggers to keep FTS mirrors in sync on insert/update/delete.
- [ ] Build hot caches: LRU "recent channels" table + tiny in-memory buffer for the last 3-5 logos/mini-EPG entries.
- [ ] Pre-fetch the next channel's EPG row on focus changes.
- [ ] Acceptance: FTS search over 50k rows returns <= 80ms; switching between recent channels hits cached data (< 120ms cold miss).

## Phase 4 - Retention, Compaction & Memory Hygiene
- [x] Enforce an EPG retention window (D-2 ... D+14) with nightly/idle sweeps (10k-row chunks).
- [x] Store per-channel `min(start_ts)` / `max(end_ts)` to short-circuit range queries.
- [x] Run VACUUM only after large deletes and while idle/charging; expose IndexedDB size on web builds.
- [ ] Stream DAO results directly to slivers/lazy lists; add projection tables for lightweight tile reads.
- [ ] Acceptance: DB stays within 10-20% of steady-state size and EPG never grows unbounded.

## Phase 5 - Consistency, Migrations & Durability
- [x] Ship semantic migrations with DAO checksum tracking.
- [ ] Execute `PRAGMA integrity_check` pre-flight and surface user-facing fallback on failure.
- [ ] Add cascading triggers for provider deletes + keep FTS mirrors consistent across upserts.
- [ ] Acceptance: CI exercises upgrade/downgrade on empty/small/huge DBs.

## Phase 6 - Query Tuning & Telemetry
- [ ] Log slow-query metrics (duration, rows read/returned) to build a heatmap dashboard.
- [ ] Review `EXPLAIN QUERY PLAN` for hot queries to ensure index-only scans.
- [ ] Tune PRAGMAs per device class (busy_timeout, cache_size) and temporarily disable WAL for >100MB imports when needed.

## Phase 7 - Cross-Platform Specifics
- [x] Keep Android/iOS/macOS/Windows/Linux on sqlite3/FFI with identical schema + DAOs.
- [x] Implement Drift IndexedDB backend for web; if EPG FTS is too large, ship channels-only FTS or opt-in builds. -> `OpenIptvDb` now opens `WebDatabase` storage on Flutter web.

## "Ultimate" Enhancements (Optional)
- [ ] Add covering indexes or projection tables for tile-ready queries.
- [ ] Evaluate LZ4/Zstd synopsis compression once I/O is proven to be the bottleneck.
- [ ] Prototype an adaptive prefetcher that predicts and preloads likely next channels.

## Implementation Snapshot
- [x] DB bootstrap: schema + indices + PRAGMAs + DAO skeletons.
- [x] Provider importers hydrate Drift for M3U/Xtream/Stalker (live/vod/series/radio buckets).
- [ ] Ingest engine: isolate parsing, chunked upserts, idempotent runs.
- [x] Search: channel FTS + triggers.
- [x] Retention: sweeper + compaction guardrails.
- [ ] Hot caches: recents + mini-EPG prewarm with key-set pagination.
- [x] Migrations: integrity checks + downgrade coverage.
- [x] Performance harness: scripted 10k/100k imports plus scroll/search benchmarks in CI.
