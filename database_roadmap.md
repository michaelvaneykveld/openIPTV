
# 🎯 Objectives

* **Multi-provider, multi-profile**: clean isolation so one broken portal can’t corrupt others.
* **Fast startup**: home/guide loads in milliseconds via pre-computed, indexed summaries.
* **Delta sync**: never re-download the world—import small diffs safely.
* **Offline-first**: app works without network once data is cached.
* **Secure by design**: no secrets in DB (use secure storage); optional full-DB encryption for sensitive caches.
* **Deterministic migrations**: zero data loss through schema evolution.
* **Playable at scale**: handles 50k+ channels, long EPG windows, and large VOD catalogs.

---

# 🧱 Domain model (normalized, provider-aware)

Use **surrogate integer keys** internally, but enforce **provider-scoped natural keys** to dedupe imports.

## Core entities

* **providers**

  * `id` (PK autoincrement)
  * `kind` (enum: stalker | xtream | m3u)
  * `display_name`, `locked_base`, `needs_ua`, `allow_self_signed`
  * `last_sync_at`, `etag_hash` (optional hash/etag equivalent per provider)
  * **Secrets not here** (kept in secure storage)

* **channels**

  * `id` (PK)
  * `provider_id` (FK providers.id)
  * `provider_channel_key` (TEXT) ← *stable key from the provider* (e.g., xtream stream_id, stalker id, m3u tvg-id or URL)
  * `name`, `logo_url`, `number` (nullable), `is_radio` (bool)
  * `stream_url_template` (TEXT, may include placeholders)
  * `last_seen_at` (for tombstoning)
  * **Unique(provider_id, provider_channel_key)**

* **categories**

  * `id` (PK)
  * `provider_id` (FK)
  * `kind` (enum: live | vod | series | radio)
  * `provider_category_key` (provider’s id)
  * `name`, `position`
  * **Unique(provider_id, kind, provider_category_key)**

* **channel_categories** (many-to-many)

  * `channel_id` (FK)
  * `category_id` (FK)
  * **Unique(channel_id, category_id)**

* **series**

  * `id` (PK)
  * `provider_id` (FK)
  * `provider_series_key` (xtream series_id or stalker vod/series key)
  * `title`, `poster_url`, `year`, `overview`
  * **Unique(provider_id, provider_series_key)**

* **seasons**

  * `id` (PK)
  * `series_id` (FK)
  * `season_number`
  * **Unique(series_id, season_number)**

* **episodes**

  * `id` (PK)
  * `series_id` (FK)
  * `provider_episode_key`
  * `season_number`, `episode_number`
  * `title`, `overview`, `duration_sec`
  * `stream_url_template`
  * **Unique(series_id, provider_episode_key)**

* **movies**

  * `id` (PK)
  * `provider_id` (FK)
  * `provider_vod_key`
  * `title`, `year`, `overview`, `poster_url`, `duration_sec`, `stream_url_template`
  * **Unique(provider_id, provider_vod_key)**

* **epg_programs** (normalized guide)

  * `id` (PK)
  * `channel_id` (FK)
  * `start_utc`, `end_utc`
  * `title`, `subtitle`, `description`
  * `season`, `episode`
  * **Index(channel_id, start_utc)**, **Index(channel_id, end_utc)**
  * Optional **FTS** mirror for `title/description` (see search below)

* **artwork_cache**

  * `id` (PK)
  * `url` (TEXT), `etag` (TEXT), `bytes` (BLOB) or file path
  * `last_fetched_at`, `width`, `height`
  * Eviction policy via LRU (see maintenance)

* **playback_history**

  * `id` (PK)
  * `provider_id`, `content_kind` (live|vod|series|movie)
  * `content_id` (FK to channels/movies/episodes)
  * `played_at`, `duration_sec`, `position_sec`, `completed` (bool)
  * **Index(provider_id, played_at DESC)**

* **user_flags**

  * `id` (PK)
  * `provider_id`, `content_kind`, `content_id`
  * `is_favorite`, `hidden`, `pin_protected`
  * **Unique(provider_id, content_kind, content_id)**

* **summaries** (precomputed counts)

  * `id` (PK)
  * `provider_id`
  * `kind` (live|vod|series|radio)
  * `total_items`
  * `updated_at`
  * **Unique(provider_id, kind)**

---

# 🗂 Key design choices (why this works)

* **Provider-scoped keys** prevent duplicates when names/logos change.
* **Normalization** keeps the DB lean and fast to update; UI uses **materialized summaries** for instant load.
* **Template stream URLs** keep secrets out of the DB; assemble at play time from secure storage.
* **Tombstones** (`last_seen_at`) allow safe deletions (two-phase deletion after N days).
* **FTS5** (optional) powers instant search across title/description without heavy RAM.

---

# ⚙️ Drift specifics (Flutter)

* Enable **WAL** mode and foreign keys at open.
* Use **companion classes** for upserts.
* Wrap imports in **transactions** for atomicity.
* Use **Batch** for large EPG inserts.
* Put heavy EPG imports in an **Isolate** (compute) with chunking (e.g., 5–10k rows per commit).

**SQLite pragmas at open (safe defaults):**

```sql
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;      -- or FULL for maximum durability
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = -40000;       -- ~40MB cache, tune by device
```

---

# 🔐 Security model

* **No secrets in DB**: user/pass/tokens live in `flutter_secure_storage`.
* **DB encryption** (optional): use SQLCipher via `sqlcipher_flutter_libs` if you cache sensitive EPG or artwork; store cipher key in secure storage.
* Strip query params with secrets before persisting URLs.
* Redact in logs.

---

# 🚅 Performance tactics

* **Precompute summaries** (`summaries` table) per provider/kind after imports.
* **Partial indexes** for common filters:

  * `CREATE INDEX idx_channels_live ON channels(provider_id) WHERE is_radio = 0;`
  * `CREATE INDEX idx_channels_radio ON channels(provider_id) WHERE is_radio = 1;`
* **Covering indexes** for guide:

  * `(channel_id, start_utc, end_utc)` to answer “what’s on now/next?”
* **FTS5** virtual table `epg_programs_fts(title, description)` with contentless option + external content linking for low storage.

---

# 🔄 Import & sync (delta-first)

## Xtream

* **Live/VOD/Series lists**: fetch lists, map to provider keys (`stream_id`, `series_id`, `vod_id`).
* **Delta**: compare keys set vs DB; insert new, update changed metadata, tombstone missing.
* **Categories**: fetch `*_categories`, build mapping via join tables.
* **Counts**: update `summaries`.

## Stalker/Ministra

* **Categories** via `get_categories`, **counts** via `get_ordered_list` and `total_items`.
* **Channels** via ordered list pages (***don’t*** fetch full pages if you only need counts; when you need items, page with limit N).
* **Delta** keyed by provider channel IDs. Respect token/MAC.

## M3U

* **Streaming parser** (line-by-line) to avoid loading entire files in memory.
* Extract `tvg-id`, `tvg-name`, `group-title`, `tvg-logo`, and URL (as provider key).
* Build groups as categories; dedupe by `tvg-id` or final URL.
* For VOD/Series: **heuristics** (group names, file names) if present; otherwise treat as live.

**General delta flow (all providers):**

1. Begin transaction.
2. Mark all existing items `candidate_for_delete=true`.
3. Upsert imports; clear the flag on touched rows.
4. Soft-delete any remaining flagged rows (set `last_seen_at=now()`, keep for N days).
5. Recompute `summaries`.
6. End transaction.

---

# 🔍 Search & browse

* **Search**: FTS5 over (`title`, `description`) for programs, and optionally `channels.name`.
* **Browse**: primary navigations served via **pre-filtered indexed queries**:

  * Channels by category (join `channel_categories`) sorted by `number` then `name`.
  * Now/Next: `WHERE start_utc <= now AND end_utc > now` per channel_id with covering index.

---

# 🧼 Data quality & deduping

* Normalize channel names: trim, collapse whitespace, uppercase for comparisons.
* Prefer `tvg-id` > provider id > URL hash as uniqueness for M3U.
* Keep **alias tables** if you later need cross-provider merging:

  * `channel_aliases(channel_id, external_id, source)`

---

# 🧰 Migrations strategy

* **Semantic versions** in a `schema_meta(version, migrated_at)` table.
* Drift migration scripts with:

  * *additive* changes first (new tables/columns with defaults).
  * backfill **computed** columns in small batches to avoid UI jank.
* Pre-flight check: block app write operations if migration is in progress (boolean flag).

**Examples you will almost certainly need:**

* Add `is_radio` to channels and backfill from categories.
* Split VOD into `movies/series` tables later; keep a compatibility view if needed.

---

# 🧹 Maintenance & retention

* **Artwork eviction**: keep a size-bounded cache (e.g., 100–200MB), delete oldest by `last_fetched_at`.
* **EPG retention**: keep `-1 day → +14 days` window; purge older rows nightly.
* **Vacuum** periodically (only if WAL checkpoints become large):

  * `PRAGMA wal_checkpoint(TRUNCATE);` then `VACUUM;` (off the main thread).

---

# 📦 Example DDL (SQLite/Drift-friendly)

```sql
CREATE TABLE providers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kind TEXT NOT NULL,                 -- stalker|xtream|m3u
  display_name TEXT NOT NULL,
  locked_base TEXT NOT NULL,
  needs_ua INTEGER NOT NULL DEFAULT 0,
  allow_self_signed INTEGER NOT NULL DEFAULT 0,
  last_sync_at INTEGER,
  etag_hash TEXT
);

CREATE TABLE channels (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider_id INTEGER NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  provider_channel_key TEXT NOT NULL,
  name TEXT NOT NULL,
  logo_url TEXT,
  number INTEGER,
  is_radio INTEGER NOT NULL DEFAULT 0,
  stream_url_template TEXT,
  last_seen_at INTEGER,
  UNIQUE(provider_id, provider_channel_key)
);

CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider_id INTEGER NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,                 -- live|vod|series|radio
  provider_category_key TEXT NOT NULL,
  name TEXT NOT NULL,
  position INTEGER,
  UNIQUE(provider_id, kind, provider_category_key)
);

CREATE TABLE channel_categories (
  channel_id INTEGER NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (channel_id, category_id)
);

CREATE TABLE epg_programs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel_id INTEGER NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  start_utc INTEGER NOT NULL,         -- epoch seconds
  end_utc INTEGER NOT NULL,
  title TEXT,
  subtitle TEXT,
  description TEXT,
  season INTEGER,
  episode INTEGER
);

CREATE INDEX idx_epg_now ON epg_programs(channel_id, start_utc, end_utc);
CREATE INDEX idx_channels_provider ON channels(provider_id);
CREATE INDEX idx_categories_provider ON categories(provider_id);
```

*(Add `movies/series/seasons/episodes` tables as you finalize VOD ingestion.)*

---

# 🧪 Validation & test plan

* **Schema unit tests**: create an in-memory DB; run migrations up and down; assert constraints/uniques.
* **Importer tests**: feed fixture payloads (xtream/stalker/m3u) and assert:

  * Same import twice → no duplicates.
  * Removed items → tombstoned then purged after retention.
  * Categories map correctly; channel counts match summaries.
* **Performance tests**: seed 50k channels + 14-day EPG; confirm:

  * Home loads (<50ms) from summaries.
  * Now/Next query for 1000 channels executes <150ms with covering index.

---

# 🧭 Phased implementation roadmap

**Phase 1 — Foundations (1–2 weeks)**

* Implement `providers`, `channels`, `categories`, `channel_categories`, `summaries`.
* Wire importers (stalker/xtream/m3u) to do **delta upserts** and **summary recompute**.
* Build repository methods + DAO tests.

**Phase 2 — EPG & Search (1–2 weeks)**

* Implement `epg_programs` with indexes and retention window.
* Add optional `epg_programs_fts` for FTS5 search.
* Add Now/Next and quick program lookups.

**Phase 3 — VOD & Series (1–2 weeks)**

* Add `movies`, `series`, `seasons`, `episodes` and link categories.
* Upsert importers for Xtream VOD/Series (Stalker where applicable).

**Phase 4 — UX Glue & Maintenance (ongoing)**

* Precomputed summaries used across the app.
* Artwork cache + eviction, VACUUM policy.
* Telemetry (non-PII) to measure import timings and query latencies.

---

# 🧠 Practical tips

* **Don’t block UI** on long imports: show progressive counts; import in batches.
* **Guard dog**: if a portal returns garbage and blows up parsing, keep last good dataset and surface a non-blocking warning.
* **Backpressure**: cap parallel category count requests (e.g., 4 at a time) to avoid server bans.
* **Feature flags**: toggle FTS and SQLCipher per platform build if size/perf constraints differ.


I put a full, drop-in **Drift database module** in the canvas with:

* Tables, indices, and constraints (providers, channels, categories, channel_categories, epg_programs, summaries)
* PRAGMAs (WAL, foreign keys, cache) and open helpers
* DAOs for providers, channels, categories, EPG, summaries
* **Delta-safe importers** for Xtream, Stalker, and M3U (with category and summary handling)
* A small in-memory **test harness** you can run to sanity-check the flow

// OpenIPTV Drift Database Module (v1)
// ------------------------------------------------------------
// This single file contains a full, drop-in database layer for
// your Flutter app using Drift (SQLite). It includes:
//  - Schema (tables + indices)
//  - DAOs (providers, channels, categories, EPG, summaries)
//  - Delta-safe importers for Xtream, Stalker, M3U (skeletons)
//  - Database bootstrap with recommended PRAGMAs & WAL
//  - In-memory test harness examples
//
// You can split this into multiple files later (lib/data/*).
// Minimum deps in pubspec.yaml:
//   drift: ^2.18.0
//   drift_sqflite: ^2.0.1   (mobile)
//   path_provider: ^2.1.0   (for on-device db location)
//   sqflite: ^2.3.0         (Android/iOS)
//   sqlite3_flutter_libs: ^0.5.20 (desktop)
//   # optional: sqlcipher_flutter_libs for encryption
// ------------------------------------------------------------

// ignore_for_file: constant_identifier_names, unnecessary_this

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// If you target mobile only, you can swap to drift_sqflite executor.
// import 'package:drift_sqflite/drift_sqflite.dart';

part 'openiptv_db.g.dart';

// ============================================================
// ENUMS (Drift does not have native enums, we map to TEXT)
// ============================================================
class ProviderKindType extends TypeConverter<ProviderKind, String> {
  const ProviderKindType();
  @override
  ProviderKind fromSql(String fromDb) => ProviderKind.values.firstWhere(
        (e) => e.name == fromDb,
        orElse: () => ProviderKind.stalker,
      );
  @override
  String toSql(ProviderKind value) => value.name;
}

enum ProviderKind { stalker, xtream, m3u }

enum CategoryKind { live, vod, series, radio }

class CategoryKindType extends TypeConverter<CategoryKind, String> {
  const CategoryKindType();
  @override
  CategoryKind fromSql(String fromDb) => CategoryKind.values.firstWhere(
        (e) => e.name == fromDb,
        orElse: () => CategoryKind.live,
      );
  @override
  String toSql(CategoryKind value) => value.name;
}

// ============================================================
// TABLES
// ============================================================

// providers
class Providers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text().map(const ProviderKindType())();
  TextColumn get displayName => text()();
  TextColumn get lockedBase => text()();
  BoolColumn get needsUa => boolean().withDefault(const Constant(false))();
  BoolColumn get allowSelfSigned => boolean().withDefault(const Constant(false))();
  IntColumn get lastSyncAt => integer().nullable()(); // epoch seconds
  TextColumn get etagHash => text().nullable()();
}

// channels
class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get providerId => integer().references(Providers, #id, onDelete: KeyAction.cascade)();
  TextColumn get providerChannelKey => text()();
  TextColumn get name => text()();
  TextColumn get logoUrl => text().nullable()();
  IntColumn get number => integer().nullable()();
  BoolColumn get isRadio => boolean().withDefault(const Constant(false))();
  TextColumn get streamUrlTemplate => text().nullable()();
  IntColumn get lastSeenAt => integer().nullable()();

  @override
  List<String> get customConstraints => [
        'UNIQUE(provider_id, provider_channel_key)'
      ];

  @override
  Set<Column> get primaryKey => {id};
}

// categories
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get providerId => integer().references(Providers, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text().map(const CategoryKindType())();
  TextColumn get providerCategoryKey => text()();
  TextColumn get name => text()();
  IntColumn get position => integer().nullable()();

  @override
  List<String> get customConstraints => [
        'UNIQUE(provider_id, kind, provider_category_key)'
      ];
}

// channel_categories (many-to-many)
class ChannelCategories extends Table {
  IntColumn get channelId => integer().references(Channels, #id, onDelete: KeyAction.cascade)();
  IntColumn get categoryId => integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {channelId, categoryId};
}

// epg_programs
class EpgPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channelId => integer().references(Channels, #id, onDelete: KeyAction.cascade)();
  IntColumn get startUtc => integer()();
  IntColumn get endUtc => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get season => integer().nullable()();
  IntColumn get episode => integer().nullable()();
}

// summaries (materialized counts per provider/kind)
class Summaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get providerId => integer().references(Providers, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text().map(const CategoryKindType())();
  IntColumn get totalItems => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().nullable()();

  @override
  List<String> get customConstraints => [
        'UNIQUE(provider_id, kind)'
      ];
}

// ============================================================
// DATABASE
// ============================================================
@DriftDatabase(
  tables: [
    Providers,
    Channels,
    Categories,
    ChannelCategories,
    EpgPrograms,
    Summaries,
  ],
  daos: [
    ProviderDao,
    ChannelDao,
    CategoryDao,
    EpgDao,
    SummaryDao,
  ],
)
class OpenIptvDb extends _$OpenIptvDb {
  OpenIptvDb(QueryExecutor e) : super(e);

  // Bump this when schema changes; add proper migrations below
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await m.createAll();
          await customStatement('CREATE INDEX IF NOT EXISTS idx_channels_provider ON channels(provider_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_categories_provider ON categories(provider_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_epg_now ON epg_programs(channel_id, start_utc, end_utc)');
        },
        onUpgrade: (m, from, to) async {
          // Add migration steps when schemaVersion increments
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA synchronous = NORMAL');
          await customStatement('PRAGMA temp_store = MEMORY');
          await customStatement('PRAGMA cache_size = -40000');
        },
      );
}

// ------------------------------------------------------------
// QueryExecutor helpers (choose one at app bootstrap)
// ------------------------------------------------------------

// In-memory (tests)
OpenIptvDb openMemoryDb() => OpenIptvDb(NativeDatabase.memory());

// On-device (desktop/mobile) with sqlite3
OpenIptvDb openNativeDb(String path) => OpenIptvDb(NativeDatabase(path, setup: (rawDb) {
      rawDb.execute('PRAGMA foreign_keys = ON');
      rawDb.execute('PRAGMA journal_mode = WAL');
    }));

// ============================================================
// DAOs
// ============================================================

@DriftAccessor(tables: [Providers])
class ProviderDao extends DatabaseAccessor<OpenIptvDb> with _$ProviderDaoMixin {
  ProviderDao(OpenIptvDb db) : super(db);

  Future<int> insertProvider(ProvidersCompanion c) => into(providers).insert(c);

  Future<void> upsertProvider({
    required ProviderKind kind,
    required String displayName,
    required String lockedBase,
    bool needsUa = false,
    bool allowSelfSigned = false,
    int? lastSyncAt,
    String? etagHash,
    int? id,
  }) async {
    if (id != null) {
      await (update(providers)..where((p) => p.id.equals(id))).write(
        ProvidersCompanion(
          kind: Value(kind),
          displayName: Value(displayName),
          lockedBase: Value(lockedBase),
          needsUa: Value(needsUa),
          allowSelfSigned: Value(allowSelfSigned),
          lastSyncAt: Value(lastSyncAt),
          etagHash: Value(etagHash),
        ),
      );
      return;
    }
    await into(providers).insert(ProvidersCompanion(
      kind: Value(kind),
      displayName: Value(displayName),
      lockedBase: Value(lockedBase),
      needsUa: Value(needsUa),
      allowSelfSigned: Value(allowSelfSigned),
      lastSyncAt: Value(lastSyncAt),
      etagHash: Value(etagHash),
    ));
  }

  Stream<List<Provider>> watchAll() => select(providers).watch();
}

@DriftAccessor(tables: [Channels, ChannelCategories, Categories])
class ChannelDao extends DatabaseAccessor<OpenIptvDb> with _$ChannelDaoMixin {
  ChannelDao(OpenIptvDb db) : super(db);

  Future<int> upsertChannel({
    required int providerId,
    required String providerKey,
    required String name,
    String? logoUrl,
    int? number,
    bool isRadio = false,
    String? streamUrlTemplate,
    int? lastSeenAt,
  }) async {
    // Attempt insert; on conflict, update selected fields
    return await into(channels).insert(
      ChannelsCompanion(
        providerId: Value(providerId),
        providerChannelKey: Value(providerKey),
        name: Value(name),
        logoUrl: Value(logoUrl),
        number: Value(number),
        isRadio: Value(isRadio),
        streamUrlTemplate: Value(streamUrlTemplate),
        lastSeenAt: Value(lastSeenAt),
      ),
      onConflict: DoUpdate((old) => ChannelsCompanion(
            name: Value(name),
            logoUrl: Value(logoUrl),
            number: Value(number),
            isRadio: Value(isRadio),
            streamUrlTemplate: Value(streamUrlTemplate),
            lastSeenAt: Value(lastSeenAt),
          ),
          target: [channels.providerId, channels.providerChannelKey]),
    );
  }

  Future<void> linkChannelToCategory({required int channelId, required int categoryId}) async {
    await into(channelCategories).insert(
      ChannelCategoriesCompanion(
        channelId: Value(channelId),
        categoryId: Value(categoryId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> markAllAsCandidateForDelete(int providerId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(channels)..where((c) => c.providerId.equals(providerId))).write(
      ChannelsCompanion(lastSeenAt: Value(now)),
    );
  }

  Future<int> purgeOldChannels({required int providerId, required Duration olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch ~/ 1000;
    return (delete(channels)
          ..where((c) => c.providerId.equals(providerId) & c.lastSeenAt.isSmallerOrEqualValue(cutoff)))
        .go();
  }
}

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<OpenIptvDb> with _$CategoryDaoMixin {
  CategoryDao(OpenIptvDb db) : super(db);

  Future<int> upsertCategory({
    required int providerId,
    required CategoryKind kind,
    required String providerKey,
    required String name,
    int? position,
  }) async {
    return into(categories).insert(
      CategoriesCompanion(
        providerId: Value(providerId),
        kind: Value(kind),
        providerCategoryKey: Value(providerKey),
        name: Value(name),
        position: Value(position),
      ),
      onConflict: DoUpdate((old) => CategoriesCompanion(
            name: Value(name),
            position: Value(position),
          ), target: [categories.providerId, categories.kind, categories.providerCategoryKey]),
    );
  }

  Future<List<Category>> listByKind(int providerId, CategoryKind kind) {
    return (select(categories)
          ..where((c) => c.providerId.equals(providerId) & c.kind.equals(kind)))
        .get();
  }
}

@DriftAccessor(tables: [EpgPrograms])
class EpgDao extends DatabaseAccessor<OpenIptvDb> with _$EpgDaoMixin {
  EpgDao(OpenIptvDb db) : super(db);

  Future<void> insertProgramsBatch(List<EpgProgramsCompanion> batch) async {
    await batchInsert<EpgProgramsCompanion>(epgPrograms, batch);
  }

  Future<List<EpgProgram>> nowForChannels(List<int> channelIds, int nowEpochSec) async {
    if (channelIds.isEmpty) return [];
    final q = select(epgPrograms)
      ..where((e) => e.channelId.isIn(channelIds) & e.startUtc.isSmallerOrEqualValue(nowEpochSec) & e.endUtc.isBiggerThanValue(nowEpochSec));
    return q.get();
  }
}

@DriftAccessor(tables: [Summaries])
class SummaryDao extends DatabaseAccessor<OpenIptvDb> with _$SummaryDaoMixin {
  SummaryDao(OpenIptvDb db) : super(db);

  Future<void> upsertSummary({required int providerId, required CategoryKind kind, required int total}) async {
    await into(summaries).insert(
      SummariesCompanion(
        providerId: Value(providerId),
        kind: Value(kind),
        totalItems: Value(total),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ),
      onConflict: DoUpdate((old) => SummariesCompanion(
            totalItems: Value(total),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          ), target: [summaries.providerId, summaries.kind]),
    );
  }

  Future<Map<CategoryKind, int>> mapForProvider(int providerId) async {
    final rows = await (select(summaries)..where((s) => s.providerId.equals(providerId))).get();
    final m = <CategoryKind, int>{};
    for (final r in rows) {
      m[r.kind] = r.totalItems;
    }
    return m;
  }
}

// ============================================================
// DELTA-SAFE IMPORTERS (skeletons)
// Supply already-fetched payloads (DTOs) to keep responsibilities clear.
// ============================================================

class XtreamImporter {
  final OpenIptvDb db;
  XtreamImporter(this.db);

  /// Imports channels + categories + summaries for an Xtream provider.
  /// [live] / [vod] / [series] are lists of raw items from player_api actions.
  Future<void> importAll({
    required int providerId,
    required List<Map<String, dynamic>> live,
    required List<Map<String, dynamic>> vod,
    required List<Map<String, dynamic>> series,
    required List<Map<String, dynamic>> liveCats,
    required List<Map<String, dynamic>> vodCats,
    required List<Map<String, dynamic>> seriesCats,
  }) async {
    await db.transaction(() async {
      final channelsDao = ChannelDao(db);
      final catsDao = CategoryDao(db);

      // Mark for tombstone
      await channelsDao.markAllAsCandidateForDelete(providerId);

      // Categories
      final catIdByKey = <String, int>{};
      Future<void> upsertCats(List<Map<String, dynamic>> items, CategoryKind kind) async {
        for (final m in items) {
          final key = (m['category_id'] ?? m['id'] ?? m['categoryId'] ?? '').toString();
          final name = (m['category_name'] ?? m['name'] ?? m['title'] ?? 'Unknown').toString();
          final pos = int.tryParse((m['position'] ?? m['order'] ?? '').toString());
          final id = await catsDao.upsertCategory(
            providerId: providerId,
            kind: kind,
            providerKey: key,
            name: name,
            position: pos,
          );
          catIdByKey['$kind:$key'] = id;
        }
      }

      await upsertCats(liveCats, CategoryKind.live);
      await upsertCats(vodCats, CategoryKind.vod);
      await upsertCats(seriesCats, CategoryKind.series);

      // Channels (live)
      for (final c in live) {
        final key = c['stream_id'].toString();
        final name = (c['name'] ?? '').toString();
        final logo = (c['stream_icon'] ?? c['logo'] ?? '').toString();
        final number = int.tryParse((c['num'] ?? '').toString());
        final channelId = await channelsDao.upsertChannel(
          providerId: providerId,
          providerKey: key,
          name: name,
          logoUrl: logo.isEmpty ? null : logo,
          number: number,
          isRadio: false,
          streamUrlTemplate: null, // build at play time
          lastSeenAt: null, // null -> current import touched
        );
        final catKey = (c['category_id'] ?? '').toString();
        final cid = catIdByKey['${CategoryKind.live}:$catKey'];
        if (cid != null) {
          await channelsDao.linkChannelToCategory(channelId: channelId, categoryId: cid);
        }
      }

      // Summaries
      final summaryDao = SummaryDao(db);
      await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.live, total: live.length);
      await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.vod, total: vod.length);
      await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.series, total: series.length);
    });
  }
}

class StalkerImporter {
  final OpenIptvDb db;
  StalkerImporter(this.db);

  /// Import categories for live/vod/series/radio and update summaries.
  /// For channels, you may call a separate import when you need materialization.
  Future<void> importCategories({
    required int providerId,
    required List<Map<String, dynamic>> itvCats,
    required List<Map<String, dynamic>> vodCats,
    List<Map<String, dynamic>>? seriesCats,
    List<Map<String, dynamic>>? radioCats,
    Map<String, int>? totalsByCategoryId, // genre->total_items
    int? totalLive,
    int? totalVod,
    int? totalSeries,
    int? totalRadio,
  }) async {
    await db.transaction(() async {
      final catsDao = CategoryDao(db);
      Future<void> upsert(List<Map<String, dynamic>> list, CategoryKind kind) async {
        for (final m in list) {
          final key = (m['id'] ?? m['category_id'] ?? m['cid'] ?? m['genre_id'] ?? '').toString();
          final name = (m['title'] ?? m['name'] ?? m['category_title'] ?? 'Unknown').toString();
          final pos = int.tryParse((m['position'] ?? m['order'] ?? '').toString());
          await catsDao.upsertCategory(providerId: providerId, kind: kind, providerKey: key, name: name, position: pos);
        }
      }

      await upsert(itvCats, CategoryKind.live);
      await upsert(vodCats, CategoryKind.vod);
      if (seriesCats != null) await upsert(seriesCats, CategoryKind.series);
      if (radioCats != null) await upsert(radioCats, CategoryKind.radio);

      final summaryDao = SummaryDao(db);
      if (totalLive != null) await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.live, total: totalLive);
      if (totalVod != null) await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.vod, total: totalVod);
      if (totalSeries != null) await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.series, total: totalSeries);
      if (totalRadio != null) await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.radio, total: totalRadio);
    });
  }
}

class M3uImporter {
  final OpenIptvDb db;
  M3uImporter(this.db);

  /// Supply a streaming parser callback that yields entries with at least:
  /// { 'key': provider_key, 'name': name, 'logo': logoUrl?, 'group': groupTitle?, 'isRadio': bool }
  Future<void> importEntries({
    required int providerId,
    required Stream<Map<String, dynamic>> entries,
  }) async {
    final channelsDao = ChannelDao(db);
    final catsDao = CategoryDao(db);

    final catIdByName = <String, int>{};
    int liveCount = 0;
    int radioCount = 0;

    await db.transaction(() async {
      await channelsDao.markAllAsCandidateForDelete(providerId);

      await for (final e in entries) {
        final key = e['key'].toString();
        final name = e['name'].toString();
        final logo = (e['logo'] ?? '').toString();
        final isRadio = (e['isRadio'] ?? false) as bool;
        final group = (e['group'] ?? 'Other').toString();

        final channelId = await channelsDao.upsertChannel(
          providerId: providerId,
          providerKey: key,
          name: name,
          logoUrl: logo.isEmpty ? null : logo,
          isRadio: isRadio,
        );

        final kind = isRadio ? CategoryKind.radio : CategoryKind.live;
        final catKey = '$kind:$group';
        var catId = catIdByName[catKey];
        if (catId == null) {
          catId = await catsDao.upsertCategory(
            providerId: providerId,
            kind: kind,
            providerKey: group, // use group title as key for M3U
            name: group,
          );
          catIdByName[catKey] = catId;
        }
        await channelsDao.linkChannelToCategory(channelId: channelId, categoryId: catId);

        if (isRadio) {
          radioCount++;
        } else {
          liveCount++;
        }
      }

      final summaryDao = SummaryDao(db);
      await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.live, total: liveCount);
      await summaryDao.upsertSummary(providerId: providerId, kind: CategoryKind.radio, total: radioCount);
    });
  }
}

// ============================================================
// TEST HARNESS (examples)
// ============================================================

Future<void> exampleTestHarness() async {
  final db = openMemoryDb();
  final providers = ProviderDao(db);
  final xtream = XtreamImporter(db);

  final providerId = await providers.insertProvider(ProvidersCompanion(
    kind: Value(ProviderKind.xtream),
    displayName: const Value('Demo Xtream'),
    lockedBase: const Value('https://demo.xtream/'),
  ));

  await xtream.importAll(
    providerId: providerId,
    live: [
      {
        'stream_id': 101,
        'name': 'BBC One',
        'stream_icon': 'https://logo.example/bbcone.png',
        'num': 1,
        'category_id': '100',
      },
      {
        'stream_id': 102,
        'name': 'CNN',
        'stream_icon': '',
        'num': 2,
        'category_id': '100',
      },
    ],
    vod: const [],
    series: const [],
    liveCats: const [
      {'category_id': '100', 'category_name': 'News', 'position': '0'}
    ],
    vodCats: const [],
    seriesCats: const [],
  );

  final summary = await SummaryDao(db).mapForProvider(providerId);
  assert(summary[CategoryKind.live] == 2);
}

// ============================================================
// Utility: batchInsert helper for EPG
// ============================================================
extension _BatchInsert on DatabaseAccessor<OpenIptvDb> {
  Future<void> batchInsert<T extends Insertable<dynamic>>(TableInfo<Table, dynamic> table, List<T> items) async {
    await batch((b) => b.insertAll(table, items));
  }
}

