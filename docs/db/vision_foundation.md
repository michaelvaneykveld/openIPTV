# Database Vision & Foundation Decisions

Last updated: 2024-12-06

## Objectives, Scope, Success Metrics
- Aligns with `database_roadmap.md` goals: multi-provider isolation, fast startup, delta sync, offline-first, secure design, deterministic migrations, 50k+ channel scalability.
- Success criteria:
  - Initial data load <= 3 minutes for 50k channels / 14-day EPG on mid-tier devices.
  - Subsequent app launches load home dashboard/highlights in < 100 ms (warm cache).
  - Delta syncs download < 5% of catalog on average after initial import.
  - Offline capability: browsing cached channels, EPG, VOD metadata without network.
  - Zero secret leakage to SQLite; secrets remain in secure storage only.
  - Migrations validated via automated upgrade/downgrade tests (see roadmap checklist).

## Platform Support & Dependency Baseline
| Platform | Status | Storage Backend | Drift Adapter | Notes |
|----------|--------|-----------------|---------------|-------|
| Android  | ✅ primary target | `getApplicationDocumentsDirectory` | `drift_sqflite` | WAL enabled; optional SQLCipher build flavour |
| iOS      | ✅ primary target | `NSDocumentDirectory` via `path_provider` | `drift_sqflite` | Exclude DB from iCloud backups if required |
| Windows  | ✅ supported | `getApplicationSupportDirectory` | `NativeDatabase` + `sqlite3_flutter_libs` | Use `sqflite_common_ffi` for tests |
| Linux    | ✅ supported | `getApplicationSupportDirectory` | `NativeDatabase` | Ensure libsqlite3 packaged |
| macOS    | ✅ supported | `getApplicationSupportDirectory` | `NativeDatabase` | Mirror iOS secure storage handling |

Dependency baselines (already in `pubspec.yaml`):
- `drift: ^2.18.0`, `drift_sqflite: ^2.0.1`
- `sqflite: ^2.4.2`, `sqflite_common_ffi: ^2.3.6`
- `flutter_secure_storage: ^9.2.4`
- `path_provider: ^2.1.3`
- Optional: `sqlite3_flutter_libs` (add for desktop release builds)

## Storage & Secret Handling
- Secrets (provider credentials, tokens) remain in existing secure storage module (`flutter_secure_storage`); DB tables never store them.
- Database file locations:
  - Mobile: `<app documents>/data/openiptv.db`
  - Desktop: `<app support>/OpenIPTV/openiptv.db`
  - Tests: in-memory via `NativeDatabase.memory()` / `DriftIsolate.inCurrent()`
- Migration playbook will include backup/restore guidance for these paths.

## Feature Flag Strategy
- Introduce compile-time Dart defines:
  - `--dart-define=DB_ENABLE_SQLCIPHER=true` to enable SQLCipher adapter in security-sensitive builds.
  - `--dart-define=DB_ENABLE_FTS=true` to enable FTS5 tables on platforms where binary size/perf allows.
- Provide defaults in `lib/config/database_flags.dart` with fallbacks when define absent.
- Add CI matrix to test both flag combinations (standard vs encrypted/FTS builds).

## Next Actions
- Implement `database_flags.dart` module exposing the new defines.
- Add desktop dependency `sqlite3_flutter_libs` to `pubspec.yaml` prior to desktop release.
- Update developer setup doc with platform-specific storage locations and flag usage.
