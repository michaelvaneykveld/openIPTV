# Telemetry & Observability

OpenIPTV now emits lightweight, structured telemetry so we can diagnose
imports, measure query latency, and debug cache behaviour without
connecting to external services.

## Event log

* Location: `%APPDATA%/openIPTV/telemetry/events.jsonl` (resolved via
  `getApplicationSupportDirectory()`).
* Format: one JSON document per line containing timestamp, category,
  severity, human-readable message, optional duration, and redacted
  metadata.
* Access: tail the file directly or consume the in-memory stream exposed via
  `telemetryServiceProvider`.

Use the service’s export helper to attach logs to bug reports:

```bash
flutter pub run tool/export_db_snapshot.dart ./build/exports/openiptv.sqlite
```

This copies the active Drift database to a deterministic location and prints
instructions for launching Drift DevTools:

```bash
dart run drift_devtools --db=./build/exports/openiptv.sqlite
```

## What gets logged?

| Category | Source | Details |
|----------|--------|---------|
| `import` | `ProviderImportService` | Start/finish events, provider metadata |
| `query` | `ProviderImportService`, `ArtworkFetcher` | Network call latency + success flag |
| `cache` | `ArtworkFetcher` | Cache hits/misses with byte counts |
| `artwork` | `ArtworkFetcher` | Failures while downloading or decoding art assets |

All error-level events are written even if the UI crashes, giving us a
crash-safe breadcrumb trail without depending on external telemetry
products.
