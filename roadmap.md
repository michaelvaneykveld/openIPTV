# OpenIPTV Rewrite Roadmap

## Session Log — Stalker Authentication Rewrite

- Established a dedicated protocol layer for Stalker/Ministra portals, introducing immutable configuration, HTTP client, handshake models, session state, and authenticator orchestration files under `lib/src/protocols/stalker/` to support a modular rewrite of MAC/token login flows.

## Session Log — Xtream Authentication Rewrite

- Mirrored the modular protocol layer for Xtream Codes by adding configuration, HTTP client, login payload models, session utilities, and an authenticator under `lib/src/protocols/xtream/`, paving the way for reusable login/profile flows aligned with the rewrite guidelines.

## Session Log — M3U/XMLTV Ingestion Rewrite

- Introduced a dedicated M3U/XMLTV protocol module (`lib/src/protocols/m3uxml/`) covering source descriptors for URL/file inputs, portal configuration, unified fetch client with compression awareness, session container, and an authenticator that validates playlists and optional XMLTV feeds for both remote and local imports.
