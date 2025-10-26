# OpenIPTV Rewrite Roadmap

## Session Log ´┐¢ Stalker Authentication Rewrite
- Established a dedicated protocol layer for Stalker/Ministra portals, introducing immutable configuration, HTTP client, handshake models, session state, and authenticator orchestration files under `lib/src/protocols/stalker/` to support a modular rewrite of MAC/token login flows.

## Session Log ´┐¢ Xtream Authentication Rewrite
- Mirrored the modular protocol layer for Xtream Codes by adding configuration, HTTP client, login payload models, session utilities, and an authenticator under `lib/src/protocols/xtream/`, paving the way for reusable login/profile flows aligned with the rewrite guidelines.

## Session Log ´┐¢ M3U/XMLTV Ingestion Rewrite
- Introduced a dedicated M3U/XMLTV protocol module (`lib/src/protocols/m3uxml/`) covering source descriptors for URL/file inputs, portal configuration, unified fetch client with compression awareness, session container, and an authenticator that validates playlists and optional XMLTV feeds for both remote and local imports.

## Session Log ´┐¢ Protocol Riverpod Integration
- Added Riverpod providers in `lib/src/application/providers/protocol_auth_providers.dart` that expose the new Stalker, Xtream, and M3U/XMLTV authenticators, along with helper families to bridge existing credential models into the modular session APIs for upcoming login refactors.
- Wired the login screen to consume those providers so each protocol handshake now flows through the modular adapters while keeping active portal state (`portal_session_providers.dart`) in sync for future UI refactors.

## Session Log ´┐¢ Minimal Shell Reset
- Removed legacy repositories, database helpers, and UI stacks so the project now boots straight into a pared-down login experience powered solely by the modular protocol adapters (`lib/src/providers/protocol_auth_providers.dart`, `lib/src/ui/login_screen.dart`).

## Session Log ´┐¢ Login Flow Controller
- Introduced a Riverpod-driven controller/state layer (`lib/src/providers/login_flow_controller.dart`) and refactored `lib/src/ui/login_screen.dart` to use it for provider selection, field validation, and multi-step test progress management in line with the new login blueprint.

## Session Log ´┐¢ Login Layout Overhaul
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

## Session Log - Stalker Portal Discovery
- Normalised portal input, generated canonical candidate endpoints, and implemented a lightweight probe loop that follows redirects and honours advanced headers before locking the working base (`lib/src/protocols/stalker/stalker_portal_normalizer.dart`, `lib/src/protocols/stalker/stalker_portal_discovery.dart`).
- Cached the resolved base URI in the login state so future sessions skip discovery unless the user changes the address or the handshake fails (`lib/src/providers/login_flow_controller.dart`, `lib/src/ui/login_screen.dart`).

## Session Log - Advanced Connection Options
- Wired the Stalker, Xtream, and M3U login flows to honour custom headers, user-agent overrides, and TLS trust settings end-to-end so authenticator probes and follow-up metadata fetches respect advanced input.
- Refreshed the login UI with provider-specific advanced panels (headers, user-agent, redirect and TLS toggles) and persisted those values in drafts for future reuse (`lib/src/ui/login_screen.dart`, `lib/src/providers/login_flow_controller.dart`).
- Added a reusable header parser with dedicated unit coverage (`lib/src/utils/header_parser.dart`, `test/utils/header_parser_test.dart`) to validate multiline input consistently and surface targeted field errors.

## Session Log - M3U File Picker UX
- Introduced a platform-aware file picker for the M3U file import path so the login flow now opens the native chooser and captures filename/size metadata (`lib/src/ui/login_screen.dart`).
- Synced picker selections back into the flow controller and text controller, including graceful messaging for unsupported platforms and updated draft persistence.

## Session Log - Contextual Paste Actions
- Moved the clipboard paste affordance into the relevant URL fields for Stalker, Xtream, and M3U (URL mode) so users can insert addresses inline without reaching for a global toolbar icon (`lib/src/ui/login_screen.dart`).
- Updated the login header controls to keep only context-agnostic actions (Help, QR), aligning with the streamlined UI guidance in `logindesign.md`.

## Session Log - Portal Discovery Abstraction
- Introduced a shared `PortalDiscovery` contract with reusable options, telemetry, and redaction-aware logging hooks (`lib/src/protocols/discovery/portal_discovery.dart`).
- Refactored the Stalker adapter to implement the shared abstraction, emit sanitised probe telemetry, and respect unified discovery options (`lib/src/protocols/stalker/stalker_portal_discovery.dart`).
- Updated the login flow to consume the new discovery options, surface friendly failures, and stream debug telemetry only in development builds (`lib/src/ui/login_screen.dart`).

## TODO - Login Experience Implementation
- Unify portal discovery services across providers behind a shared `PortalDiscovery` abstraction. (done)
  - Extract the existing Stalker normaliser, candidate generator, and probe loop into reusable implementations conforming to the shared interface. (done)
  - Define `PortalDiscovery`, `DiscoveryResult`, and `DiscoveryOptions` (including UA/MAC/TLS knobs and logging redaction) for all adapters. (done)
  - Align discovery logging/telemetry with the global redaction policy. (done)
- Introduce an input classifier that routes pasted/typed values to the correct provider flow. (todo)
  - Detect Xtream signatures (`player_api.php`, `get.php`, embedded credentials) and prefill username/password fields safely. (todo)
  - Detect M3U playlists via extension or lightweight `#EXTM3U` sniff, reclassifying to Xtream when appropriate. (todo)
  - Allow manual override in the UI when the classifier guesses incorrectly. (todo)
- Expand shared normalization utilities for use by every protocol adapter. (todo)
  - Add helpers for canonicalising schemes, defaulting ports, stripping known file endpoints, and ensuring directory-style trailing slashes. (todo)
- Implement Xtream discovery following the shared pattern. (todo)
  - Generate candidate endpoints (`player_api.php`, `get.php`, `xmltv.php`) and lightweight probes with redirects, scheme flips, and UA retries. (todo)
  - Parse credentials from pasted URLs, strip secrets from locked bases, and record discovery hints (e.g., `needsUA`). (todo)
  - Persist locked bases and reuse them on subsequent launches, falling back to discovery only when health checks fail. (todo)
- Implement M3U discovery for both URL and file modes. (todo)
  - Normalise playlist URLs, reclassify Xtream-style links, and verify local files before import. (todo)
  - Probe remote playlists with HEAD/range GET requests, retrying with media UAs on 403/406 and following redirect chains. (todo)
  - Persist resolved playlist/EPG URLs (without secrets) and file metadata for change detection. (todo)
- Codify retry and error taxonomy for all discovery probes. (todo)
  - Standardise timeouts, redirect limits, TLS fallbacks, UA retries, and connection-close mitigation. (todo)
- Build out the unified provider profile and storage architecture (Drift + secure vault). (todo)
  - Inventory existing profile/draft writes to determine read/write needs. (todo)
  - Sketch the Drift ↔ secure storage data flow and identify DTO/domain boundaries. (todo)
  - Extend schemas (`providers`, `provider_secrets`, etc.) and define vault payloads per provider. (todo)
  - Produce repository interfaces (`CredentialsVaultRepository`, discovery caches) and document async/error semantics. (todo)
  - Specify platform storage options (Keychain, Keystore, DPAPI, Secret Service, web stance) and related configuration. (todo)
  - Choose vault key conventions, rotation/cleanup strategies, and logging policies that avoid leaking secrets. (todo)
  - Outline migration/testing requirements, including fallback when secure storage is unavailable and opt-in “remember me” flows. (todo)
- Deliver the unified UX for login input and advanced options. (todo)
  - Allow a single entry field that accepts any link and display non-blocking classifier feedback when re-routing. (todo)
  - Keep advanced panels consistent across providers (UA override, allow self-signed, custom headers). (todo)
- Standardise networking knobs via shared Dio configuration. (todo)
  - Provide per-provider defaults for timeouts, redirects, interceptors (redacting logger, retry), and user agents. (todo)
- Strengthen automated and manual test coverage. (todo)
  - Add unit tests for the classifier, discovery redirects/UA blocks/TLS paths, and regression cases (e.g., early connection close). (todo)
  - Expand widget/integration tests for login flows, including opt-in storage and probe failure UX. (todo)
- Introduce discovery caching and background revalidation. (todo)
  - Cache discovery results per provider with short TTLs and silent refresh when endpoints change. (todo)
- Enforce security and privacy guardrails. (todo)
  - Ensure secrets never appear in logs, build secret-bearing URLs only in-memory, and store credentials in secure storage exclusively. (todo)
- Ensure accessibility: focus traversal for TV remotes, screen-reader labels/errors, large text scaling, and high-contrast visuals. (todo)


