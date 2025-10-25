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

## TODO — Login Experience Implementation
- Replace the login scaffold with the full layout: header actions (Help, Paste, QR), provider SegmentedButtons, and dynamic form sections per protocol. (todo)
- Implement Material 3 text fields with helper/error text, MAC formatter/generator, file picker preview, and optional advanced panels per protocol. (todo)
- Add clipboard paste detection, QR scan trigger (`mobile_scanner`), and M3U file selection via `file_picker`, preserving inputs while switching modes. (todo)
- Expose advanced settings (custom headers, User-Agent, TLS toggle, auto-update, output format) behind expandable panels aligned with the design blueprint. (todo)
- Build the "Test & Connect" workflow: multi-step progress tracker, determinate linear indicator, and success summary card with channel/EPG counts. (todo)
- Provide a "Save for later" draft flow that stores configurations without immediate testing. (todo)
- Surface error feedback using top banners for systemic failures and field-level messages with fix-oriented microcopy. (todo)
- Integrate authenticator providers for Stalker/Xtream/M3U tests, honoring TLS overrides and custom headers. (todo)
- Plan persistence hooks for validated profiles and drafts using a clean storage abstraction. (todo)
- Ensure accessibility: focus traversal for TV remotes, screen-reader labels/errors, large text scaling, and high-contrast visuals. (todo)
- Add QA coverage: unit tests for validators and error mapping, widget tests for form switching/validation, integration tests with mocked protocol responses, and manual device checks. (todo)
