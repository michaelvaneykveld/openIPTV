Below is an **engineer‑to‑engineer deep dive** into high‑quality, actively‑useful IPTV codebases and workflows for **Stalker/Ministra**, **Xtream Codes**, and **plain M3U/XMLTV**, with specific notes on **what to borrow** for your Flutter app (auth/handshake, channel & EPG retrieval, caching & DB). I’ve prioritized repositories with clean code, clear API coverage, release cadence, and battle‑tested features; I call out why each is solid.

---

## TL;DR — Best‑of repos by protocol

### **Xtream Codes (client libraries + apps)**

* **`pauli2406/xtream_code_client` (Dart/Flutter)** – typed Dart models for Xtream, resilient HTTP; includes EPG (XMLTV) parsing classes you can lift straight into Flutter. Ideal as your protocol layer. ([GitHub][1])
* **`felixssimoes/muxa_xtream` (Dart/Flutter)** – ergonomic Xtream client w/ strongly‑typed models, URL builders, M3U/XMLTV helpers; good examples of retries and stream URL construction in Dart. ([GitHub][2])
* **`@iptv/xtream-api` (TypeScript)** – very clean API surface and documentation; shows complete profile→categories→channels→EPG flow and safe stream URL generation. Great for understanding endpoint coverage and flow sequencing. ([ektotv.github.io][3])

### **Stalker / Ministra (clients + reference code)**

* **`opendreambox/enigma2-plugin-stalkerclient` (Python)** – a minimal but clear **MAC‑based** Stalker client. Shows single‑MAC portal access and where EPG would integrate; good for seeing the **shape** of calls and state. ([GitHub][4])
* **`erkexzcx/stalkerhek` (Go, archived)** – concise implementation demonstrating the **handshake→token** pattern the ecosystem uses (“reserve token” + MAC), which aligns with community guidance and STB clients. Useful as a specification surrogate. ([GitHub][5])
* **Infomir (Ministra) REST v1 docs** – official admin/API structure to understand response conventions and status semantics (not the STB handshake itself, but authoritative on Ministra’s resource model). ([Infomir Wiki][6])

### **M3U/XMLTV (apps, players & tooling)**

* **Kodi PVR IPTV Simple (`kodi-pvr/pvr.iptvsimple`) (C++)** – gold standard client for **M3U + XMLTV**: supports **Gzip/XZ EPG compression**, **multiple M3U/XML pairs**, **catch‑up**, **timeshift**, robust mapping & settings. Copy their **format support** and **EPG handling** ideas. ([GitHub][7])
* **IPTVnator (`4gray/iptvnator`) (Electron/TS)** – cross‑platform app with clean M3U/EPG UX (favorites, archive/catch‑up). A good reference for **playlist/EPG ingestion and UI state**; also shows PWA/Electron deployment. ([GitHub][8])
* **Linux Mint Hypnotix (`linuxmint/hypnotix`) (Python/MPV)** – IPTV player supporting **M3U URL, local M3U, and Xtream API**; code shows provider abstraction and **retry/user‑agent** details for Xtream. ([GitHub][9])
* **Megacubo (`EdenwareApps/megacubo`) (JS/Electron/Capacitor)** – large, cross‑platform M3U player with playlist mgmt, history, bookmarks; good reference for **multi‑provider management** and **UX features** at scale. ([GitHub][10])

### **EPG + data sources & utilities**

* **`iptv-org/epg`** – mature XMLTV grabbing/aggregation project (Docker images updated frequently). Model your **EPG update pipeline** on how this project batches, normalizes and ships EPG. ([GitHub][11])
* **`iptv-org/database`** – community channel metadata DB (names, countries, logos). Use its **channel IDs** to improve M3U↔EPG matching. ([GitHub][12])
* **`@iptv/xmltv`** – tiny, fast XMLTV parser/generator (TS); great reference for **schema‑faithful XMLTV modeling**. ([GitHub][13])

### **M3U/EPG aggregation proxies (design ideas)**

* **Threadfin / xTeVe / xM3U (Go)** – show **playlist merging**, **EPG aggregation**, **filtering**, **logos/categorization**, **re‑streaming buffer**, and **automatic updates**. Even if you don’t proxy, borrow their **data model & update strategies**. ([GitHub][14])

---

## Why these codebases are “solid” (and what to copy)

**Kodi PVR IPTV Simple**

* Maintained, high‑usage addon with **182 releases**; supports **compressed EPG (Gzip/XZ)**, **multiple M3U/XML pairs**, **catch‑up + timeshift** with `inputstream.adaptive` / `ffmpegdirect`. Copy: support **compressed feeds**, structured **catch‑up** params, and **multiple provider configs** via profiles. ([GitHub][7])

**Hypnotix**

* Clear provider abstraction: **M3U URL, Xtream API, Local M3U**; commits and issues indicate pragmatic handling of **user‑agent quirks + connection retry** for Xtream. Copy: **provider adapters**, **UA/retry settings**, and simple **libmpv** playback pipeline equivalent (Flutter → `media_kit`). ([GitHub][9])

**IPTVnator**

* Cross‑platform Electron/TS app with **favorites, EPG, archive/catch‑up**; code shows **playlist import flows** and **state management** that mirror common IPTV UX. Copy: **import pipeline**, **EPG mapping/view models**, and **catch‑up navigation**. ([GitHub][8])

**Megacubo**

* Long‑running project with **multi‑provider management**, **history/bookmarks**, **Android/desktop** builds; useful patterns for **playlist refresh, filtering, dedup**. Copy: **provider registry**, **channel dedup & normalization**, **logo handling**. ([GitHub][10])

**Xtream (Dart)** – `xtream_code_client` & `muxa_xtream`

* Give you **typed endpoints** and **URL builders**, including **EPG helpers** in Dart; perfect drop‑in for a Flutter client layer. Copy: error handling, retries/backoff, **typed models**, and **stream URL building** patterns. ([GitHub][1])

**Stalker** – `stalkerhek` and Enigma2 plugin

* Show **MAC + token** authentication and “**handshake** reserves token” pattern seen across STB clients; the Dreambox plugin explicitly works as **single MAC‑based portal access**. Use as your **protocol reference** where official public docs are sparse. ([GitHub][5])

**EPG Tooling** – `iptv-org/epg` & `@iptv/xmltv`

* Demonstrate **source scrapers**, **batching**, **normalization**, **Dockerized pipelines**, and a **schema‑faithful parser**; great examples for building a **reliable EPG refresh job** and **fast parsing**. ([GitHub][11])

---

## Protocol workflows you can adopt

### 1) **Xtream Codes** — robust client flow

**Endpoints (common)**

* Auth & profile: `GET /player_api.php?username=U&password=P` → `user_info`, `server_info`, and lists.
* Channels: `GET /player_api.php?username=U&password=P&action=get_live_streams` (and VOD/series analogues).
* EPG: `GET /xmltv.php?username=U&password=P` (full XMLTV).
* M3U: `GET /get.php?username=U&password=P&type=m3u_plus&output=ts` (or `hls`).
  Cleanly represented in **`@iptv/xtream-api`** docs and covered by the Dart libs above. ([ektotv.github.io][3])

**Recommended sequence**

1. **Get profile/server** → read time/format/timezone to compute catch‑up windows. ([ektotv.github.io][3])
2. **Fetch categories** → channels (paged if needed). ([ektotv.github.io][3])
3. **Fetch EPG XMLTV** (support Gzip if server provides) → map to channels by `tvg-id` / `epg_channel_id`.
4. **Optional**: also keep the **M3U** to cross‑check attributes like `catchup`, `tvg-logo`, `group-title`.

**Borrow from the Dart libs**: **typed models**, **retryable HTTP**, **stream URL builders**, **XMLTV parser class** (from `xtream_code_client`). ([GitHub][1])

---

### 2) **Stalker / Ministra** — MAC + token handshake

Common client behavior (as shown by open‑source clients & community notes):

1. **Handshake** with portal (`/portal.php` or similar) to negotiate and **reserve a token**. **Token + MAC** become your credentials for subsequent API calls. ([GitHub][5])
2. **Subsequent calls** include **token** (often Bearer or cookie) and **MAC** (header/cookie). Community & vendor guidance emphasize the MAC identity and a token obtained by an STB‑style client. ([forum2.progdvb.com][15])
3. **Fetch profile/lineup** → get channel categories and list; **get_epg** style methods are used to retrieve guides. (Use the Enigma2 plugin to understand feature boundaries and MAC‑based access.) ([GitHub][4])

Official Ministra **REST v1** docs don’t describe the STB handshake but are useful for **response schemas and error conventions**. Treat **`stalkerhek`** as a practical handshake reference (reserve token logic). ([Infomir Wiki][6])

---

### 3) **Plain M3U + XMLTV** — capabilities & best practices

* **Support compressed EPG** (Gzip/XZ) like Kodi does; large EPGs are the norm. ([GitHub][7])
* **Multiple sources**: allow multiple M3U/XML pairs/profiles (corporate vs personal). Kodi shows how to expose this cleanly. ([GitHub][7])
* **Catch‑up & timeshift**: parse M3U `catchup`, `timeshift` attributes and present **archive navigation** (seek/jump to past program). Kodi’s README explains differences across inputstreams. ([GitHub][7])
* **Channel normalization**: join on **`tvg-id`**; if missing, use `channel name` + country + **iptv-org/database** metadata for fuzzy matching. ([GitHub][12])

If you ever aggregate sources, Threadfin/xTeVe/xM3U show **filtering, mapping, logo management, re‑streaming buffers**, and **auto update** strategies worth emulating. ([GitHub][14])

---

## A pragmatic **Flutter** architecture (focused on reliability & speed)

**Video playback**: `media_kit` (as used by “Another IPTV Player”). It’s stable across mobile/desktop/web. ([GitHub][16])

**Protocol clients**

* **Xtream**: use `muxa_xtream` or `xtream_code_client` as your data layer; keep models typed. ([GitHub][2])
* **Stalker**: implement a **Stalker adapter** inspired by `stalkerhek` handshake and Enigma2 plugin (MAC + token). Keep **token renewals** and **portal quirks** behind an interface. ([GitHub][5])
* **M3U/XMLTV**: parse with a streaming XML parser (Dart) or run parsing in an **isolate**. If your EPG is huge, consider doing a background isolate parse + batch inserts.

**Data store (local)**
For **EPG+channels**, prefer **relational** (SQLite via **Drift**) because you’ll do heavy **joins, time‑range queries**, and **indexes**:

* **Tables**

  * `providers(id, name, type, base_url, last_sync_at, tz_offset)`
  * `channels(id, provider_id, name, tvg_id, group, logo_url, stream_url, sort_key)`
  * `epg_programs(id, channel_id, title, desc, category, start_utc, end_utc, season, episode)`
  * `artwork(channel_id, icon_url, last_checked)`
  * `sync_state(provider_id, kind, etag, last_success_at)`
* **Indexes**

  * `epg_programs(channel_id, start_utc)` for now/next/prev lookups
  * `channels(tvg_id)` for mapping; `channels(group, sort_key)` for fast grouping
    Drift gives you **reactive queries**, migrations, and cross‑platform SQLite; use `.drift` files to define **indexes** and keep schemas tidy. ([Dart packages][17])

If you want a **NoSQL** alternative, **Isar** is extremely fast and simple, but for EPG **relational queries** Drift is usually a better fit. (Isar’s positioning, perf, and tooling are strong if you keep the model denormalized.) ([isar.dev][18])

**Sync & caching strategy**

* **ETag/If‑Modified‑Since** for M3U/XMLTV; store per‑provider in `sync_state`.
* Handle **compressed EPG** (Gzip/XZ) and large files; parse in isolates; **chunk** XMLTV (per `<programme>`) to avoid spikes. (Kodi supports compressed EPG—emulate that.) ([GitHub][7])
* **Retention**: keep EPG in **[now − 2 days, now + 14 days]** window; schedule compaction.
* **Batch inserts** with transactions; de‑dup by `(channel_id, start_utc)`.
* **Logos**: resolve once, cache, and refresh on a long TTL; use `iptv-org/database` for better logos & country tags. ([GitHub][12])

**Error handling & resilience**

* Implement **retry with backoff/jitter**, **timeout budgets**, and record **provider health** (last n failures, error rate).
* For Xtream: cache `server_info` (time offset, allowed output formats) and **generate stream URLs** locally as done in `@iptv/xtream-api`. ([ektotv.github.io][3])
* For Stalker: persist **MAC + token** and refresh via handshake when you get 401/403 equivalents (see `stalkerhek` behavior). ([GitHub][5])

---

## Concrete “login → lineup → EPG → DB” recipes

### **Xtream Codes** (Dart)

1. `GET player_api.php?username&password` → store `server_info`, `user_info`. ([ektotv.github.io][3])
2. `get_live_categories`, `get_live_streams` (paged); map to `channels`. ([ektotv.github.io][3])
3. `xmltv.php?username&password` → parse XMLTV (gzip if present). Use `tvg-id` mapping; fallback: name+country fuzz.
4. Insert/update using **Drift** in a transaction; maintain `(provider_id, tvg_id)` for idempotency.
   **Reference implementations**: `muxa_xtream`, `xtream_code_client`, `@iptv/xtream-api`. ([GitHub][2])

### **Stalker / Ministra** (Dart adapter)

1. **Handshake** → obtain token (portal may issue a new token if your offered one is invalid). Persist token + MAC. ([GitHub][5])
2. Call profile/lineup endpoints with token+MAC (header/cookie) to fetch channel list; then call EPG methods. (Community notes emphasize **token + MAC** as the decisive pair.) ([forum2.progdvb.com][15])
3. Normalize channels (try to infer `tvg-id` for XMLTV mapping if the portal provides it).
4. Store as above.
   **Reference**: `stalkerhek` (handshake), Enigma2 plugin (MAC‑based access). ([GitHub][5])

### **M3U + XMLTV**

1. Download **M3U**; parse `#EXTINF` attributes: `tvg-id/tvg-logo/group-title/catchup`.
2. Download **XMLTV** (support **Gzip/XZ**), parse in an isolate; create channel map by `tvg-id`. Emulate Kodi’s compressed EPG handling. ([GitHub][7])
3. Deduplicate (same channel different providers) using `tvg-id` + `provider priority`.
4. Insert channels then EPG programs; index on `(channel_id, start_utc)`.

---

## Extra patterns worth emulating

* **Multiple provider profiles** (Kodi): offer separate configs and switch quickly. ([GitHub][7])
* **Aggregation & filtering** (Threadfin/xTeVe): allow disabling categories, custom mapping, and **automatic updates**. ([GitHub][14])
* **User agent & retry** (Hypnotix): some Xtream portals require UA; implement per‑provider UA and retry settings. ([GitHub][19])
* **Channel metadata** (`iptv-org/database`): better logos, countries, and name normalization → fewer EPG misses. ([GitHub][12])

---

## Suggested **Flutter stack** (drop‑in list)

* **Playback**: `media_kit` (multi‑platform). (See “Another IPTV Player”.) ([GitHub][16])
* **Protocol**:

  * Xtream: `muxa_xtream` or `xtream_code_client`. ([GitHub][2])
  * Stalker: custom adapter (based on `stalkerhek` flow). ([GitHub][5])
* **M3U/XMLTV parsing**: your own isolate parser (Dart XML) or mirror the class structure from `xtream_code_client` for EPG models. ([Dart packages][20])
* **DB**: **Drift** (SQLite) with **.drift** schema files for indexes; or **Isar** if you prefer denormalized NoSQL. ([Dart packages][17])
* **HTTP**: `dio` with **per‑provider UA**, **ETag** caching, **gzip** decoding, and **retry/backoff**.

---

## Implementation checklist (you can paste into your backlog)

1. **Providers module**

   * [ ] Adapter interface: `authenticate()`, `fetchChannels()`, `fetchEPG(range)`, `streamUrlFor(channel, when?)`
   * [ ] Implement `XtreamAdapter` using `muxa_xtream` (handles categories/channels/EPG). ([GitHub][2])
   * [ ] Implement `StalkerAdapter` (MAC+token handshake patterned on `stalkerhek`). ([GitHub][5])
   * [ ] Implement `M3UAdapter` with XMLTV fetch (support **Gzip/XZ**). ([GitHub][7])

2. **Parsing & mapping**

   * [ ] M3U parser (extended tags: `tvg-id`, `tvg-logo`, `catchup`, `group-title`)
   * [ ] XMLTV parser in isolate; map to channels by **`tvg-id`** and `iptv-org/database` enrichment. ([GitHub][12])

3. **Database (Drift)**

   * [ ] Create tables & **indexes** (see schema above; define indexes in `.drift` SQL). ([Stack Overflow][21])
   * [ ] Batch insert programs; upsert by `(channel_id, start_utc)`.

4. **Sync**

   * [ ] ETag/If‑Modified‑Since + retry/backoff; cache server time (Xtream) and align EPG windows. ([ektotv.github.io][3])
   * [ ] Retention policy: purge older than 48h past and >14d future.

5. **Playback**

   * [ ] Use `media_kit`; implement catch‑up navigation when M3U/portal offers archive (seek to the program’s start). (See Kodi’s catch‑up semantics.) ([GitHub][7])

6. **UX basics**

   * [ ] Profiles (multi‑provider), favorites, groups, search, now/next, program detail.

---

## A few “gotchas” to plan for

* **Timezones & server offsets** (Xtream): use `server_info.server_time` to compute EPG windows correctly. ([ektotv.github.io][3])
* **User‑Agent** (Xtream): some portals 403 without UA—allow per‑provider UA override (Hypnotix PRs mention this). ([GitHub][19])
* **Huge EPGs**: parsing must be streaming/in‑isolate; support **Gzip/XZ**; avoid blocking the UI. (Kodi supports both compressions.) ([GitHub][7])
* **Stalker handshake variance**: tokens can expire silently; keep a “retry handshake” path and backoff logic (see `stalkerhek` notes). ([GitHub][5])

---

## Sources (selected, diverse & current)

* **Kodi PVR IPTV Simple** – capabilities (Gzip/XZ EPG, multiple M3U/XML pairs, catch‑up, timeshift). ([GitHub][7])
* **Hypnotix** – provider types (M3U URL, local M3U, Xtream), UA/retry notes. ([GitHub][9])
* **IPTVnator** – cross‑platform IPTV player features. ([GitHub][8])
* **Megacubo** – cross‑platform playlist management patterns. ([GitHub][10])
* **Xtream (Dart)** – `xtream_code_client`, `muxa_xtream`. ([GitHub][1])
* **`@iptv/xtream-api`** – full endpoint flow and types. ([ektotv.github.io][3])
* **Stalker/Ministra** – `stalkerhek` handshake (token+MAC), Enigma2 client (MAC access), official REST v1 docs. ([GitHub][5])
* **EPG & channel metadata** – `iptv-org/epg`, `iptv-org/database`, `@iptv/xmltv`. ([GitHub][11])
* **Aggregation proxies** – Threadfin, xTeVe, xM3U design ideas. ([GitHub][14])
* **Flutter DB choices** – Drift docs & examples; Isar overview & articles. ([Dart packages][17])

---


[1]: https://github.com/pauli2406/xtream_code_client?utm_source=chatgpt.com "GitHub - pauli2406/xtream_code_client"
[2]: https://github.com/felixssimoes/muxa_xtream?utm_source=chatgpt.com "GitHub - felixssimoes/muxa_xtream: Dart-only, typed client for Xtream ..."
[3]: https://ektotv.github.io/xtream-api/classes/main.Xtream.html "Xtream | @iptv/xtream-api - v1.4.1"
[4]: https://github.com/opendreambox/enigma2-plugin-stalkerclient "GitHub - opendreambox/enigma2-plugin-stalkerclient: Dreambox client for direct/native acces to any stalker portal"
[5]: https://github.com/erkexzcx/stalkerhek/blob/master/stalker/authentication.go?utm_source=chatgpt.com "stalkerhek/stalker/authentication.go at master - GitHub"
[6]: https://wiki.infomir.eu/eng/ministra-tv-platform/ministra-setup-guide/rest-api-v1?utm_source=chatgpt.com "REST API v1 | Ministra setup guide | Infomir Documentation"
[7]: https://github.com/kodi-pvr/pvr.iptvsimple "GitHub - kodi-pvr/pvr.iptvsimple: IPTV Simple client for Kodi PVR"
[8]: https://github.com/4gray/iptvnator?utm_source=chatgpt.com "Cross-platform IPTV player application with multiple ... - GitHub"
[9]: https://github.com/linuxmint/hypnotix?utm_source=chatgpt.com "GitHub - linuxmint/hypnotix: An M3U IPTV Player"
[10]: https://github.com/EdenwareApps/megacubo?utm_source=chatgpt.com "Megacubo - GitHub"
[11]: https://github.com/iptv-org/epg/blob/master/README.md?utm_source=chatgpt.com "epg/README.md at master · iptv-org/epg · GitHub"
[12]: https://github.com/iptv-org/database?utm_source=chatgpt.com "GitHub - iptv-org/database: User editable database for TV channels."
[13]: https://github.com/ektotv/xmltv?utm_source=chatgpt.com "GitHub - ektotv/xmltv: An extremely fast XMLTV parser and generator for ..."
[14]: https://github.com/Threadfin/Threadfin?utm_source=chatgpt.com "an M3U proxy for Kernel/Plex/Jellyfin/Emby based on xTeVe - GitHub"
[15]: https://forum2.progdvb.com/viewtopic.php?t=12975&utm_source=chatgpt.com "Support for IPTV Stalker Portal - progdvb.com"
[16]: https://github.com/bsogulcan/another-iptv-player "GitHub - bsogulcan/another-iptv-player: Lightweight and feature-rich IPTV player with multi-platform support."
[17]: https://pub.dev/packages/drift?utm_source=chatgpt.com "drift | Dart package - Pub"
[18]: https://isar.dev/?utm_source=chatgpt.com "Home | Isar Database"
[19]: https://github.com/linuxmint/hypnotix/issues/276?utm_source=chatgpt.com "[WIP] Xtream Updates and added settings #276 - GitHub"
[20]: https://pub.dev/documentation/xtream_code_client/latest/xtream_code_client/EPG-class.html?utm_source=chatgpt.com "EPG class - xtream_code_client library - Dart API - Pub"
[21]: https://stackoverflow.com/questions/76544716/drift-syntax-to-create-an-index?utm_source=chatgpt.com "flutter - Drift syntax to create an index - Stack Overflow"
