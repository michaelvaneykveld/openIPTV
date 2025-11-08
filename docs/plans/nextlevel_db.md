# Next-Level Database TODOs

Use this backlog to track the “ultimate” database roadmap. Check items that already ship in `main`; leave the rest for future work.

## North-Star Metrics
- [ ] Cold tune-to-first-channel ≤ 2.0 s; warm ≤ 1.2 s.
- [ ] Search 10–50 k channels + multi-million EPG rows in ≤ 100 ms typical.
- [ ] Keep memory stable while scrolling/importing (≤ 200 MB during imports via streaming/pagination).
- [ ] Run heavy imports off the UI isolate with visible progress + cancel/rollback.
- [ ] Maintain platform parity (Drift sqlite3/FFI for native, Drift IndexedDB for web) behind the same DAO APIs.

## Phase 1 – Core Schema & Access Patterns
- [x] Model `providers`, `channel_groups`, `channels`, `stream_endpoints`, `epg_events` in Drift.
- [x] Add mandatory indexes: `(provider_id, stable_key)` unique, `(group_id, sort_key)`, NOCASE `name`, EPG covering indexes, `stream_endpoints(channel_id, priority)`.
- [x] Implement chunked bulk upserts (1–5 k rows) using `INSERT … ON CONFLICT DO UPDATE`.
- [ ] Build key-set pagination reads (no OFFSET) with prepared statements and an off-isolate write queue.
- [x] Apply WAL-friendly PRAGMAs (`journal_mode=WAL`, `synchronous=NORMAL`, cache sizing, `foreign_keys=ON`).
- [ ] Acceptance: import 100 k channels < 30 s and keep channel list scrolling at 60 fps.

## Phase 2 – Parsing & Ingest at Scale
- [ ] Run M3U/XMLTV/Xtream/Stalker parsing and Drift writes inside isolates (single writer, shared readers).
- [ ] Partition EPG imports by day and store ETag/Last-Modified hashes to skip unchanged payloads.
- [x] Track tombstones for removed channels; schedule background hard-prune.
- [ ] Acceptance: imports can cancel/resume safely and re-running identical input results in zero data changes.

## Phase 3 – Instant Search & Zap
- [x] Add FTS5 external-content tables for channels (name, alt names, group title) and optional EPG snippets using unicode61 tokenizer.
- [x] Create triggers to keep FTS mirrors in sync on insert/update/delete.
- [ ] Build hot caches: LRU “recent channels” table + tiny in-memory buffer for the last 3–5 logos/mini-EPG entries.
- [ ] Pre-fetch the next channel’s EPG row on focus changes.
- [ ] Acceptance: FTS search over 50 k rows returns ≤ 80 ms; switching between recent channels hits cached data (< 120 ms cold miss).

## Phase 4 – Retention, Compaction & Memory Hygiene
- [x] Enforce an EPG retention window (D-2 … D+14) with nightly/idle sweeps (10 k-row chunks).
- [x] Store per-channel `min(start_ts)` / `max(end_ts)` to short-circuit range queries.
- [x] Run VACUUM only after large deletes and while idle/charging; expose IndexedDB size on web builds.
- [ ] Stream DAO results directly to slivers/lazy lists; add projection tables for lightweight tile reads.
- [ ] Acceptance: DB stays within 10–20 % of steady-state size and EPG never grows unbounded.

## Phase 5 – Consistency, Migrations & Durability
- [x] Ship semantic migrations with DAO checksum tracking.
- [ ] Execute `PRAGMA integrity_check` pre-flight and surface user-facing fallback on failure.
- [ ] Add cascading triggers for provider deletes + keep FTS mirrors consistent across upserts.
- [ ] Acceptance: CI exercises upgrade/downgrade on empty/small/huge DBs.

## Phase 6 – Query Tuning & Telemetry
- [ ] Log slow-query metrics (duration, rows read/returned) to build a heatmap dashboard.
- [ ] Review `EXPLAIN QUERY PLAN` for hot queries to ensure index-only scans.
- [ ] Tune PRAGMAs per device class (busy_timeout, cache_size) and temporarily disable WAL for >100 MB imports when needed.

## Phase 7 – Cross-Platform Specifics
- [x] Keep Android/iOS/macOS/Windows/Linux on sqlite3/FFI with identical schema + DAOs.
- [x] Implement Drift IndexedDB backend for web; if EPG FTS is too large, ship channels-only FTS or opt-in builds. -> `OpenIptvDb` now opens `WebDatabase` storage on Flutter web.

## “Ultimate” Enhancements (Optional)
- [ ] Add covering indexes or projection tables for tile-ready queries.
- [ ] Evaluate LZ4/Zstd synopsis compression once I/O is proven to be the bottleneck.
- [ ] Prototype an adaptive prefetcher that predicts and preloads likely next channels.

## Implementation Snapshot
- [x] DB bootstrap: schema + indices + PRAGMAs + DAO skeletons.
- [ ] Ingest engine: isolate parsing, chunked upserts, idempotent runs.
- [x] Search: channel FTS + triggers.
- [x] Retention: sweeper + compaction guardrails.
- [ ] Hot caches: recents + mini-EPG prewarm with key-set pagination.
- [x] Migrations: integrity checks + downgrade coverage.
- [x] Performance harness: scripted 10 k/100 k imports plus scroll/search benchmarks in CI.
