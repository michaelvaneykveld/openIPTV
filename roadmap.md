# OpenIPTV Rewrite Roadmap

## Session Log - Stalker Authentication Rewrite
- Established a dedicated protocol layer for Stalker/Ministra portals, introducing immutable configuration, HTTP client, handshake models, session state, and authenticator orchestration files under `lib/src/protocols/stalker/` to support a modular rewrite of MAC/token login flows.

## Session Log - Xtream Authentication Rewrite
- Mirrored the modular protocol layer for Xtream Codes by adding configuration, HTTP client, login payload models, session utilities, and an authenticator under `lib/src/protocols/xtream/`, paving the way for reusable login/profile flows aligned with the rewrite guidelines.

## Session Log - M3U/XMLTV Ingestion Rewrite
- Introduced a dedicated M3U/XMLTV protocol module (`lib/src/protocols/m3uxml/`) covering source descriptors for URL/file inputs, portal configuration, unified fetch client with compression awareness, session container, and an authenticator that validates playlists and optional XMLTV feeds for both remote and local imports.

## Session Log - Protocol Riverpod Integration
- Added Riverpod providers in `lib/src/application/providers/protocol_auth_providers.dart` that expose the new Stalker, Xtream, and M3U/XMLTV authenticators, along with helper families to bridge existing credential models into the modular session APIs for upcoming login refactors.
- Wired the login screen to consume those providers so each protocol handshake now flows through the modular adapters while keeping active portal state (`portal_session_providers.dart`) in sync for future UI refactors.

## Session Log - Minimal Shell Reset
- Removed legacy repositories, database helpers, and UI stacks so the project now boots straight into a pared-down login experience powered solely by the modular protocol adapters (`lib/src/providers/protocol_auth_providers.dart`, `lib/src/ui/login_screen.dart`).

## Session Log - Login Flow Controller
- Introduced a Riverpod-driven controller/state layer (`lib/src/providers/login_flow_controller.dart`) and refactored `lib/src/ui/login_screen.dart` to use it for provider selection, field validation, and multi-step test progress management in line with the new login blueprint.
- Broadened URL validation to accept bare domains, IPs, and IPv6 hosts by reusing the lenient HTTP parser, with regression coverage keeping the form checks in sync (`lib/src/providers/login_flow_controller.dart`, `lib/src/utils/url_normalization.dart`, `test/providers/login_flow_controller_validation_test.dart`).

## Session Log - Login Layout Overhaul
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
- Added regression coverage ensuring scheme flip fallbacks and User-Agent retries stay operational (`test/protocols/stalker_portal_discovery_test.dart`).

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

## Session Log - Stalker Scheme Fallback
- Hardened discovery when links are auto-upgraded to HTTPS by testing both the supplied scheme and an HTTP fallback before surfacing failures (`lib/src/protocols/stalker/stalker_portal_discovery.dart`).
- Normalised probe telemetry so resolved URIs remain redacted while reflecting the scheme that ultimately matched (`lib/src/protocols/stalker/stalker_portal_discovery.dart`).

## Session Log - Xtream HTML Signature
- Accepted control panels that return HTML `INVALID_CREDENTIALS` banners as valid Xtream signatures so branded skins still lock the base (`lib/src/protocols/xtream/xtream_portal_discovery.dart`).
- Added a regression test that spins up a fake XUI endpoint to guarantee the HTML detection path stays covered (`test/protocols/xtream_portal_discovery_test.dart`).

## Session Log - M3U Discovery Hardening
- Introduced a dedicated M3U discovery adapter that normalises playlist URLs, reclassifies disguised Xtream links, and adds scheme flipping plus media User-Agent retries (`lib/src/protocols/m3uxml/m3u_portal_discovery.dart`).
- Verified remote playlists with HEAD and range GET probes, redacting telemetry and logging only sanitized endpoints in debug builds (`lib/src/ui/login_screen.dart`).
- Synced the login flow to persist redacted playlist/EPG URLs and refreshed file metadata so subsequent sessions reuse the resolved locations safely (`lib/src/providers/login_flow_controller.dart`, `lib/src/ui/login_screen.dart`).
- Added an XMLTV HEAD probe so remote guides are validated before download, surfacing content-type/last-modified hints and persisting the resolved EPG endpoint for profiles (`lib/src/protocols/m3uxml/m3u_xml_client.dart`, `lib/src/ui/login_screen.dart`).
- Added test coverage for redirect-to-signed playlist URLs so discovery tracks the resolved endpoint and stores a sanitized hint (`test/protocols/m3u_portal_discovery_test.dart`).
- Introduced shared discovery interceptors for redacted logging and retry jitter across Stalker, Xtream, and M3U probes (`lib/src/protocols/discovery/discovery_interceptors.dart`, `lib/src/protocols/*/*_portal_discovery.dart`).

## Session Log - Discovery Retry Policy
- Codified transient retry handling across Stalker, Xtream, and M3U discovery clients so 503/512 responses, connection drop-outs, and UA blocks trigger a single scoped retry before flipping schemes (`lib/src/protocols/stalker/stalker_portal_discovery.dart`, `lib/src/protocols/xtream/xtream_portal_discovery.dart`, `lib/src/protocols/m3uxml/m3u_portal_discovery.dart`).
- Surfaced `needsUserAgent` hints and debug telemetry for retry attempts, allowing the login flow to prompt users for STB/media UA overrides where required (`lib/src/ui/login_screen.dart`).

## Session Log - Input Classifier
- Implemented a protocol-aware `InputClassifier` that recognises Xtream, M3U, and Stalker inputs, extracts embedded credentials, and returns normalised hints (`lib/src/utils/input_classifier.dart`).
- Added unit coverage for credential extraction, playlist heuristics, and fallback logic (`test/utils/input_classifier_test.dart`).
- Wired the login flow to auto-switch providers on confident matches, prefill Xtream/M3U forms, and guard Stalker attempts with classifier feedback while preserving manual override controls (`lib/src/ui/login_screen.dart`).
- Updated playlist heuristics so credential-bearing `get.php` links with `type=m3u` style parameters stay in the M3U flow first, only falling back to Xtream when discovery confirms it (`lib/src/utils/input_classifier.dart`, `lib/src/ui/login_screen.dart`).
- Extended the ambiguous-input heuristics to detect bare Xtream hosts with explicit ports and locked the behaviour in with regression coverage (`lib/src/utils/input_classifier.dart`, `test/utils/input_classifier_test.dart`).

## Session Log - URL Normalization Utilities
- Added shared helpers to canonicalise schemes, default ports, strip known file endpoints, and ensure directory-style bases across adapters (`lib/src/utils/url_normalization.dart`).
- Refactored Stalker and Xtream configurations to reuse the helpers, lowering hosts and keeping probe bases consistent (`lib/src/protocols/stalker/stalker_portal_normalizer.dart`, `lib/src/protocols/xtream/xtream_portal_configuration.dart`).
- Applied scheme normalisation to M3U/XMLTV builders so remote playlists benefit from the same hygiene (`lib/src/protocols/m3uxml/m3u_xml_portal_configuration.dart`).
- Expanded the utilities with a lenient HTTP parser and filesystem detection so odd provider domains, naked IPs, and IPv6 hosts are accepted consistently across classifiers, form validators, and discovery flows (`lib/src/utils/url_normalization.dart`, `lib/src/utils/input_classifier.dart`, `lib/src/providers/login_flow_controller.dart`, `test/utils/url_normalization_test.dart`, `test/providers/login_flow_controller_validation_test.dart`).
## Session Log - Security Logging Safeguards
## Session Log - Security Logging Safeguards
- Added shared URL and text redaction helpers so discovery logs and failure telemetry no longer expose credentials (lib/src/utils/url_redaction.dart, lib/src/protocols/*/*_portal_discovery.dart).
- Routed login debug output through the redactor-aware helpers to sanitise Dio exception messages and stack traces before printing (lib/src/ui/login_screen.dart).

## Session Log - Provider Profile Store
- Added a Drift-backed database with provider and vault mapping tables so profile metadata lives alongside migration-friendly schema definitions (`lib/storage/provider_database.dart`, `lib/storage/provider_database.g.dart`).
- Built a `ProviderProfileRepository` that bridges Drift and `FlutterSecureStorage`, exposing a clean API for persisting non-secret configuration and sensitive credentials per provider (`lib/storage/provider_profile_repository.dart`).
- Updated the Stalker, Xtream, and M3U login flows to capture discovery hints, configuration, and secrets into the repository when connections succeed, surfacing friendly failure messaging when persistence fails (`lib/src/ui/login_screen.dart`).
- Wired sqflite FFI initialisation for desktop targets so profile persistence works on Windows/Linux without manual bootstrap steps (`lib/storage/provider_database.dart`).

## Session Log - Discovery Cache Wiring
- Added a `DiscoveryCacheManager` that persists discovery results with hashed option fingerprints so TTL reuse never leaks credentials (`lib/src/ui/discovery_cache_manager.dart`).
- Updated the Stalker, Xtream, and M3U login handlers to consult the cache before probing and refresh entries when live discovery runs, trimming redundant network hops (`lib/src/ui/login_screen.dart`).
- Extended regression coverage with cache hit/expiry tests to lock in the sanitisation and TTL semantics (`test/ui/discovery_cache_manager_test.dart`).

## TODO - Login Experience Implementation
- Build out the unified provider profile and storage architecture (Drift + secure vault). (in-progress)
  - Inventory existing profile/draft writes to determine read/write needs. (done)
  - Sketch the Drift <-> secure storage data flow and identify DTO/domain boundaries. (done)
  - Extend schemas (`providers`, `provider_secrets`, etc.) and define vault payloads per provider. (done)
  - Produce repository interfaces (`CredentialsVaultRepository`, discovery caches) and document async/error semantics. (done)
  - Specify platform storage options (Keychain, Keystore, DPAPI, Secret Service, web stance) and related configuration. (done)
  - Choose vault key conventions, rotation/cleanup strategies, and logging policies that avoid leaking secrets. (done)
  - Outline migration/testing requirements, including fallback when secure storage is unavailable and opt-in "remember me" flows. (done)
    - Documented a two-phase migration plan: schema bump + secure vault seeding with rollback guardrails, and a dry-run mode that validates existing rows before committing secrets (`loginrework.md`, Secure Storage section).
    - Added test matrix covering device bootstraps with missing `FlutterSecureStorage`, simulator/web shims, and toggled "remember me" flows to ensure drafts fall back to in-memory caches without user-visible errors.
    - Captured QA acceptance steps for upgrading from legacy preferences (verify automatic vault population, ensure opt-in flag surfaces in UI, confirm disable path purges secrets) so release sign-off is unambiguous.
- Keep advanced panels consistent across providers (UA override, allow self-signed, custom headers). (done)
- Strengthen automated and manual test coverage. (in-progress)
  - Add unit tests for the classifier, discovery redirects/UA blocks/TLS paths, and regression cases (e.g., early connection close). (in-progress)
    - Added classifier coverage for ambiguous Xtream vs M3U inputs (`test/utils/input_classifier_test.dart`). (done)
    - Added Xtream discovery tests for redirects and UA fallback handling (`test/protocols/xtream_portal_discovery_test.dart`). (done)
    - Added M3U discovery regression test for premature connection close retries (`test/protocols/m3u_portal_discovery_test.dart`). (done)
  - Expand widget/integration tests for login flows, including opt-in storage and probe failure UX. (todo)
- Introduce discovery caching and background revalidation. (in-progress)
  - Cache discovery results per provider with short TTLs and silent refresh when endpoints change. (done)
  - Add background revalidation trigger so cached bases refresh after TTL or failed connects. (todo)
- Enforce security and privacy guardrails. (in-progress)
  - Ensure secrets never appear in logs or telemetry; sanitise URLs and free-form messages before logging. (done)
    - Added shared redaction helpers to purge credentials from discovery interceptors and login debug output (`lib/src/utils/url_redaction.dart`, `lib/src/protocols/*/*_portal_discovery.dart`, `lib/src/ui/login_screen.dart`).
  - Store **secrets in secure storage only**; non-secret endpoints in DB. (done)
    - Provider profile persistence now strips sensitive keys from configuration/hints and keeps credentials/custom headers exclusively in the secure vault (`lib/storage/provider_profile_repository.dart`, `lib/src/ui/login_screen.dart`).


