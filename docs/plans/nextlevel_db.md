# Next-Level Database TODOs

Use this backlog to track the "ultimate" database roadmap. Check items that already ship in `main`; leave the rest for future work.

## First Priority - Portal Ingest Reliability

### TL;DR Fixes (mirrors item 0 in the brief)
- [ ] Always probe categories via `get_categories → get_genres → get_categories_v2 → (if censored) parental unlock → re-probe`, then cache the winning action in `PortalDialect`.
- [ ] Keep all discovery paging + Drift upserts off the UI isolate (worker isolate + Drift database isolate) and enforce session/page caps so "*" never blocks the raster thread.
- [x] Propagate the full STB header set (Bearer token, MAC cookie, `stb_lang`, timezone, STB UA) on every request after handshake/profile. -> `StalkerHttpClient.getPortal` now enriches every request with the STB header/cookie defaults so even ad-hoc callers inherit the Infomir header shape.
- [x] Detect both paging shapes (`p=<page>` vs `from=<offset>&cnt=<limit>`), memoize the winner per portal, and reuse it. -> `_fetchStalkerListing` now probes both paging modes, switches when needed, and records the preference in `StalkerPortalDialect`.
- [x] De-dupe entries across categories and "*" (seen-ID set) and stop paging when a payload repeats to avoid infinite loops. -> `_fetchStalkerListing` fingerprints each page and filters `seenEntryKeys`, while per-category fetches keep their own `seenKeys`.
- [x] Persist resume tokens + derived categories per portal. -> `ImportResumeStore` now writes checkpoints + derived buckets alongside `openiptv.db`.
- [x] Surface lightweight import progress with cancel/undo affordances in the UI. -> Login + PlayerShell now render `ImportProgressBanner` with determinate progress and cancel hooks wired to `ProviderImportService.cancelImport`.

### 1) Category discovery: common pitfalls & fixes
- [ ] Implement the probe chain for every content type, including radio, and fall back to derived categories (sample first 3–5 global pages off-isolate, cache for ~24h).
- [x] Add a parental-unlock hook that runs when the portal flags censored content; persist the flag in `PortalDialect` so the UI can prompt the user once. -> `_importStalker` tracks `sawLockedCategory`, updates `StalkerPortalDialect.requiresParentalUnlock`, and the login/player UI reads it for prompts.

### 2) Authentication & headers
- [ ] Wrap all Stalker calls in a client/decorator that injects the full handshake header/cookie tuple (Authorization bearer, MAC cookie, `stb_lang`, timezone, UA) on every request—not just handshake/discovery.
- [ ] Re-apply parental-unlock state (if provided) before catalog calls and cache the outcome so subsequent imports stay in sync.

### 3) Paging semantics: mixing `p=` with `from/cnt`
- [ ] Detect both paging shapes during bootstrap, memoize the preference in `PortalDialect.prefersFromCnt`, and respect it for every category.
- [x] Hash each page's payload to break loops, and hard-stop when a duplicate or the configured page cap is reached. -> `_fetchStalkerListing` now stores page fingerprints and aborts immediately after a repeat while logging page-cap exits.

### 4) Doing heavy work on the UI isolate
- [ ] Finish the worker-isolate importer: spawn a Drift isolate connection, stream progress events, honour cancel, and ensure the UI isolate only receives lightweight updates.
- [ ] Prioritise categories currently expanded in the UI so previews stay responsive while background paging continues for the rest.

### 5) Counting mismatches: why totals differ
- [x] Maintain per-content-type seen-ID sets to de-dupe across categories and the "*" bucket so portal totals line up with DB counts. -> Category paging now keeps `seenKeys` per module and the global `"*"` sweep tracks `seenEntryKeys`, so duplicates no longer inflate totals.
- [x] Retry transient errors with jitter before assuming a category is empty, and respect adult/parental preferences when counting. -> `_retryWithJitter` now wraps Stalker portal calls with randomized delays before failing.

### 6) Missing safety rails
- [x] Enforce hard caps: global "*" = 30 pages, per-category = 200 pages, plus 200�600?ms jitter/backoff between requests. Log when a cap triggers. -> `_fetchStalkerListing` enforces `_stalkerMaxGlobalPages`/`_stalkerMaxCategoryPages`, applies randomized delays, and logs resume/cap exits.
- [x] Emit diagnostics per run (category action used, paging shape, portal totals vs ingested totals) so regressions surface quickly. -> `_logCategoryStrategy` and `_logStalkerRunSummary` now print the winning probe, counts, and adult state once per run.
- [x] Resume checkpoints already land in `ImportResumeStore`; extend diagnostics so stale checkpoints expire with the same TTL as derived categories.

### 7) Quick diff-plan you can apply now
- [x] Wrap Stalker calls in the header-injecting client. -> `StalkerHttpClient.getPortal` now normalizes every request with the STB UA/cookie set plus Authorization + token cookies.
- [x] Persist `PortalDialect` (category action, paging shape, parental flag) and reuse it for every session. -> Dialect snapshots (stored in `ImportResumeStore`) now capture preferred actions plus paging mode and are reloaded before each import.
- [x] Implement the category probe chain + derived-category fallback from item 1. -> `_fetchStalkerCategories` already walks get_categories ? get_genres ? get_categories_v2, then falls back to cached/derived buckets.
- [ ] Move ingestion to the worker isolate with dedupe, resume tokens, caps, and backpressure wired in.
- [x] Log a single-line ingestion summary per run (e.g., `vod: action=get_genres, paging=from/cnt, cats=42, items=5123 (dedup:-211), adult=off`). -> `_logStalkerRunSummary` emits a concise per-run summary for each Stalker import.

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
