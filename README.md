# OpenIPTV

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/CI-local-blueviolet.svg)](#)

OpenIPTV is a modern, cross‑platform IPTV player built with Flutter. It brings live TV, VOD, and series catalogs from M3U playlists, Xtream Codes, and Stalker/Ministra portals together in a single experience that runs on mobile, desktop, and the web.

---

## Highlights

- **Multi‑protocol ingestion** — authenticate against Xtream and Stalker portals or load traditional M3U playlists.
- **Cross‑platform delivery** — the Flutter shell targets Android, iOS, Windows, macOS, Linux, and the web from a single codebase.
- **Rich navigation tree** — live, VOD, and series content is normalised into a unified tree with search and responsive layouts.
- **Channel management** — reorder channels, rename, regroup, or hide entries with overrides stored per portal.
- **Background synchronisation** — opt‑in scheduler refreshes playlists/EPG automatically with Wi‑Fi‑only safeguards.
- **Personal DVR tooling** — schedule or start recordings instantly and track local files with resume/status metadata.
- **EPG reminders** — queue notifications before programmes start; reminders survive restarts and rehydrate on boot.
- **Multi‑account switching** — maintain multiple portal credentials and swap profiles in-app without signing out.
- **Desktop friendly** — keyboard shortcuts, navigation rail layouts, and focus traversal built with large screens in mind.

---

## Feature Overview

| Area | Details |
| ---- | ------- |
| **Sync Scheduler** | Toggle auto refresh, select 30–360 minute intervals, and enforce Wi‑Fi‑only syncs. Runs immediately after settings change and cycles through all saved portals. |
| **Channel Manager** | Drag **ReorderableListView** to change ordering, rename or regroup channels, and toggle visibility. Overrides persist in the SQLite backing store. |
| **Recording Centre** | Browse scheduled/active/completed recordings, launch ad‑hoc or scheduled jobs, and stop/cancel existing tasks. Recordings write TS files under a portal-specific directory. |
| **Reminder Centre** | Create, list, and remove programme reminders. Utilises the local notifications plugin with automatic rescheduling after restarts. |
| **Player Screen** | Video playback via `video_player` with inline record toggle, stream URL diagnostics, and contextual error messaging. |
| **Navigation Tree** | Builds a portal-scoped content tree, respecting channel overrides and grouping by provider metadata or manual folders. |

---

## Architecture

```
lib/
 ├─ src/application/   ← Riverpod providers, schedulers, services
 ├─ src/core/          ← Data models and SQLite helper
 ├─ src/data/          ← Protocol repositories and adapters
 ├─ src/ui/            ← Feature screens and responsive layouts
 └─ utils/             ← Shared helpers (logging, etc.)
```

- **State management**: Riverpod/StateNotifier for deterministic, testable flows.
- **Persistence**: `sqflite` (+ ffi) powers the local catalogue, overrides, recordings, and reminders.
- **Background work**: Timer-based scheduler handles sync and reminder restoration after restarts.
- **Navigation**: `go_router` backs deep linking between login, home, player, and management screens.

---

## Platform Support

| Platform | Status | Notes |
| -------- | ------ | ----- |
| Android / iOS | ✅ | Uses secure storage for credentials, `path_provider` for DVR output. |
| Windows / macOS / Linux | ✅ | Bundles `sqflite_common_ffi` for native desktop persistence. |
| Web | ✅ | Navigation tree and management screens render responsively; DVR/notifications are no‑ops. |

> Tip: desktop targets require the Flutter FFI tooling (`sqflite_common_ffi`) which is already initialised in `main.dart`.

---

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run the application
flutter run -d windows   # or macos, linux, chrome, android, ios

# Static analysis
flutter analyze

# Format Dart sources
dart format lib test
```

A valid IPTV account (M3U URL, Xtream credentials, or Stalker portal) is required to exercise the app end‑to‑end.

---

## Roadmap

- **Short term**
  - Finalise 10‑foot / TV layouts.
  - Expose DVR file browser with playback integrations.
  - Expand reminder UI with per-programme notification offsets.

- **Long term**
  - Parental controls and PIN locking.
  - Integrated transcoding/proxy service for CORS-limited streams.
  - Smart TV packaging (Android TV, tvOS).

Progress is tracked via GitHub issues; contributions to any of the above are welcome.

---

## Contributing

1. Fork the repository and create a feature branch.
2. Run `flutter analyze` and `dart format` before committing.
3. Submit a pull request describing your change and steps to validate it.

Bug reports, feature ideas, and UI/UX suggestions are encouraged via the issue tracker.

---

## License

OpenIPTV is released under the [MIT License](LICENSE). Feel free to use it commercially or privately with attribution.
