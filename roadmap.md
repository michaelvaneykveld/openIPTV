# OpenIPTV Rewrite Roadmap

## Session Log — Stalker Authentication Rewrite
- Established a dedicated protocol layer for Stalker/Ministra portals, introducing immutable configuration, HTTP client, handshake models, session state, and authenticator orchestration files under `lib/src/protocols/stalker/` to support a modular rewrite of MAC/token login flows.

## Session Log — Xtream Authentication Rewrite
- Mirrored the modular protocol layer for Xtream Codes by adding configuration, HTTP client, login payload models, session utilities, and an authenticator under `lib/src/protocols/xtream/`, paving the way for reusable login/profile flows aligned with the rewrite guidelines.

## Session Log — M3U/XMLTV Ingestion Rewrite
- Introduced a dedicated M3U/XMLTV protocol module (`lib/src/protocols/m3uxml/`) covering source descriptors for URL/file inputs, portal configuration, unified fetch client with compression awareness, session container, and an authenticator that validates playlists and optional XMLTV feeds for both remote and local imports.

## Session Log — Protocol Riverpod Integration
- Added Riverpod providers in `lib/src/application/providers/protocol_auth_providers.dart` that expose the new Stalker, Xtream, and M3U/XMLTV authenticators, along with helper families to bridge existing credential models into the modular session APIs for upcoming login refactors.
- Wired the login screen to consume those providers so each protocol handshake now flows through the modular adapters while keeping active portal state (`portal_session_providers.dart`) in sync for future UI refactors.

## Session Log — Minimal Shell Reset
- Removed legacy repositories, database helpers, and UI stacks so the project now boots straight into a pared-down login experience powered solely by the modular protocol adapters (`lib/src/providers/protocol_auth_providers.dart`, `lib/src/ui/login_screen.dart`).

## Session Log — Login Flow Controller
- Introduced a Riverpod-driven controller/state layer (`lib/src/providers/login_flow_controller.dart`) and refactored `lib/src/ui/login_screen.dart` to use it for provider selection, field validation, and multi-step test progress management in line with the new login blueprint.

## Session Log — Login Layout Overhaul
- Rebuilt the login UI to match the design blueprint with header actions (Help/Paste/QR), Material 3 segmented buttons for provider and M3U selection, and provider-specific forms backed by `lib/src/ui/login_screen.dart` and the shared flow controller.

## Session Log - Form Field Enhancements
- Upgraded provider forms to Material 3 text fields with helper and error text, added a MAC address generator, introduced file picker integration for M3U imports, and surfaced advanced-setting panels per protocol to meet the revised product brief.

## Session Log - Test & Connect Workflow
- Delivered the multi-step "Test & Connect" experience with a determinate progress indicator and per-step messaging wired through `LoginTestProgress` in `lib/src/ui/login_screen.dart`.
- Introduced a success summary card backed by `LoginTestSummary`, surfacing channel counts and EPG coverage collected during protocol probes.
- Enhanced Stalker, Xtream, and M3U flows to fetch lightweight metadata (playlist parsing, channel list probes, XMLTV windows) so the UI reports meaningful post-connection details.

## Session Log - Save For Later Drafts
- Implemented a secure draft repository combining `SharedPreferences` metadata with `FlutterSecureStorage` secrets (`lib/src/providers/login_draft_repository.dart`) so provider configs can be parked without immediate testing.
- Added a shared "Save for later" action across login forms that serialises form state, filters out empty values, and persists protocol-specific secrets safely (`lib/src/ui/login_screen.dart`).
- Surface snack-bar feedback on successful saves and validation guidance when drafts lack sufficient information, preparing the ground for a dedicated drafts picker.

## Session Log - Error Feedback Enhancements
- Hardened the login flows to surface top-of-screen banner guidance for systemic failures and network issues (`lib/src/ui/login_screen.dart`).
- Added protocol-specific field microcopy so authentication failures highlight the affected inputs with actionable fixes (e.g., Xtream credentials, Stalker portal URL, M3U playlist fields).
- Centralised controller helpers for clearing/assigning field errors, enabling consistent recovery UX across retries (`lib/src/providers/login_flow_controller.dart`).

## TODO - Login Experience Implementation
- Integrate authenticator providers for Stalker/Xtream/M3U tests, honoring TLS overrides and custom headers. (todo)
- Plan persistence hooks for validated profiles and drafts using a clean storage abstraction. (todo)
- Ensure accessibility: focus traversal for TV remotes, screen-reader labels/errors, large text scaling, and high-contrast visuals. (todo)
- Add QA coverage: unit tests for validators and error mapping, widget tests for form switching/validation, integration tests with mocked protocol responses, and manual device checks. (todo)
