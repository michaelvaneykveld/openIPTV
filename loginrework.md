
# 0) Unify what you already have (from Stalker)

* [x] Extract your Stalker URL normalizer + candidate generator + probe into a reusable service: `PortalDiscovery`.
* [x] Interface:

  ```dart
  abstract class PortalDiscovery {
    Future<DiscoveryResult> discover(String userInput);
  }
  class DiscoveryResult {
    final ProviderKind kind;      // stalker | xtream | m3u
    final Uri lockedBase;         // canonical base
    final Map<String, String> hints; // { "needsUA": "true", ... }
  }
  ```
* [x] Keep your **User-Agent / MAC / TLS** knobs in a shared `DiscoveryOptions`.
* [x] Ensure your **logging + redaction** is used by all discoverers.

This creates symmetry so Xtream/M3U feel like more of the same.

---

# 1) Input classifier (front door for all three)

* [x] Build `InputClassifier.classify(String s) -> ProviderKind? + ParsedBits`.

  * Detect **Xtream** if `get.php`, `player_api.php`, `xmltv.php`, or `username=` & `password=` query params are present.
  * Detect **M3U** if `.m3u`/`.m3u8` present or `#EXTM3U` after a tiny GET (head/body sniff).
  * Else default to **Stalker** (your current flow), but allow **manual override** in UI.
* [x] Extract creds from pasted Xtream URLs and prefill fields (do not store yet).
* [x] If classifier says M3U but link is actually `get.php?username=<value>&password=<value>`, reclassify as **Xtream**.

---

# 2) Shared normalization utilities (used by all)

* [x] `canonicalizeScheme(String)`: add `https://` if missing.
* [x] `normalizePort(Uri)`: keep explicit port if present; otherwise default 443/80 depending on scheme.
* [x] `stripKnownFiles(Uri)`: remove `player_api.php`, `get.php`, `xmltv.php`, `portal.php`, `index.php` and their query.
* [x] `ensureTrailingSlash(Uri)` for base endpoints that behave like directories.

---

# 3) Xtream discovery (piling onto your Stalker pattern)

### Candidates

* [x] From normalized base: try **exact base** and base with/without trailing slash:

  * `{base}/player_api.php`
  * `{base}/get.php` (only for classification and URL building)
  * `{base}/xmltv.php` (for EPG link tests)

### Probe (fast & deterministic)

* [x] One **tiny GET** to `player_api.php?username=__probe__&password=__probe__`

  * Accept if response is JSON with keys like `user_info`/`server_info` (even if invalid creds).
  * If **HTML/404**, flip scheme (https->http) once and retry.
* [x] Follow redirects (max 5); adopt final URL as `lockedBase`.
* [x] If 403 on first try, retry with **custom UA** (configurable per provider).

### Credential hygiene

* [x] If user pasted a full M3U Xtream URL (with creds), parse out `username`/`password`, strip the query from `lockedBase`, and store creds in **secure storage** only after successful connect.

### Lock-in & persistence

* [x] Persist `lockedBase` (scheme/host/port/path), plus discovered hints (e.g., `needsUA=true`).
* [x] On subsequent launches, **skip discovery** and hit `player_api.php` directly; if it fails (host changed/cert changed), fall back to discovery.

---

# 4) M3U discovery

### Modes

* URL mode:

  * [x] Normalize URL (scheme/default ports).
  * [x] If it contains `get.php?username=&password=`, reclassify as **Xtream** and jump to 3.
* File mode:

  * [x] Verify extension `.m3u`/`.m3u8` and that file is readable; sniff first line for `#EXTM3U`.

### Probe (URL mode)

* [x] Send **HEAD** first:

  * Accept `200` with `Content-Type` in `audio/x-mpegurl`, `application/x-mpegURL`, or `application/octet-stream`.
* [x] If HEAD blocked, send a **range GET** for first 2-4 KB and ensure it begins with `#EXTM3U`.
* [x] Follow redirects; some providers redirect to signed URLs.
* [x] If 403/406, retry once with a **media UA** (e.g., `VLC/3.0.18`).

### Optional EPG pairing

* [ ] If user provides separate XMLTV URL, do a **HEAD** (allow gzip) and store it; otherwise rely on downstream protocol (Xtream) or let user add later.

### Lock-in & persistence

* [x] Persist the final resolved playlist URL (without secrets embedded if any), plus UA hint.
* [x] For **file** playlists, persist file handle/path and last modified time; schedule a re-parse when file changes.

---

# 5) Retry & error taxonomy (shared)

* [x] **Timeouts** for probes: connect 1500-2500 ms, receive 1500-2500 ms.
* [x] **Redirects**: enabled, capped at 5; record the final resolved URL.
* [x] **TLS** errors:

  * If user profile has allow self-signed enabled, retry the probe with permissive context (scoped to this request only).
  * Surface a clear message; do not silently downgrade to HTTP unless the user selects that option.
* [x] **HTTP 5xx**:

  * Treat 503/512 as transient - retry once, then try the alternative scheme (https->http).
* [x] **403**:

  * Likely UA filtering - retry with custom UA; if success, store `needsUA=true`.
* [x] **Connection closed before full header**:

  * For probes, send `Connection: close`, disable gzip, and enforce HTTP/1.1.

---

# 6) Unified provider profile & storage

* [ ] Schema additions (non-secret DB):

  * `providers(id, kind, locked_base, needs_ua, allow_self_signed, last_ok_at, last_error)`
  * `provider_secrets(id -> secure vault key)` (no secrets here-just reference)
* [ ] Vault entries (secure storage):

  * `xtream`: `username`, `password`
  * `m3u`: any bearer or basic auth secrets (rare)
* [ ] On successful login, **atomically** persist: non-secret profile -> vault -> verification ping.

---

# 7) UX consistency

* [ ] Single input field that accepts **anything**; classifier decides which adapter path to show.
* [ ] If classifier re-routes (e.g., pasted Xtream link in M3U mode), show a small non-blocking banner: Detected Xtream link; adjusted settings.
* [ ] Advanced expands to **User-Agent**, **Allow self-signed**, **Custom headers** (per provider).

---

# 8) Networking knobs (shared `Dio` instance per provider)

* [ ] Base options:

  * `followRedirects: true`, `maxRedirects: 5`
  * Timeouts configurable; tighter for probes than for normal API calls.
* [ ] Interceptors:

  * **Redacting logger** (active only when debug is on).
  * **Retry** policy (idempotent GETs only) with jitter.
* [ ] UA strategy:

  * Default UA per **kind** (Stalker-like, Media-like, Neutral).
  * Allow per-provider override saved in profile.

---

# 9) Tests (must-have)

* [ ] **Classifier**: unit tests for ambiguous inputs (Xtream as M3U, naked host, with/without scheme, with port).
* [ ] **Xtream**: mock server returning JSON for `player_api.php`, with redirect and with 403 UA block.
  * [x] Ensure HTML `INVALID_CREDENTIALS` banners emitted by branded panels are recognised during discovery.
* [ ] **M3U**: HEAD returns `application/octet-stream`; range GET starts with `#EXTM3U`; redirect chain to signed URL.
* [x] **TLS**: self-signed failure on first probe, success on permissive path when user enables the option.
* [ ] **Regression**: connection closed early path uses `Connection: close` and succeeds on retry.

---

# 10) Performance & caching

* [ ] Cache discovery **per provider** (keyed by user-visible name + host) and **skip probes** on subsequent app launches.
* [ ] Keep a short TTL (e.g., 24h) to re-validate base URLs in the background; if the portal changed path/scheme, silently update the profile.
* [ ] For M3U, cache small HEAD/meta to avoid re-downloading full playlists during login.

---

# 11) Security & privacy guardrails

* [ ] Never log full URLs containing `username`, `password`, or tokens-your interceptor must redact.
* [ ] Store **secrets in secure storage only**; non-secret endpoints in DB.
* [x] Build any secret-bearing URLs **in memory** just-in-time; never persist them.

---

## Minimal code shapes to add

### `XtreamDiscovery` (sketch)

```dart
class XtreamDiscovery implements PortalDiscovery {
  final Dio dio;
  XtreamDiscovery(this.dio);

  @override
  Future<DiscoveryResult> discover(String input) async {
    final base = _canonicalXtreamBase(input);
    final probe = await dio.getUri(
      base.replace(path: '${base.path}player_api.php', queryParameters: {'username':'__probe__','password':'__probe__'}),
      options: Options(followRedirects: true, validateStatus: (_) => true),
    );
    if (_looksLikeXtreamJson(probe)) {
      return DiscoveryResult(kind: ProviderKind.xtream, lockedBase: probe.realUri ?? base, hints: {});
    }
    // Try scheme flip & UA retry...
    throw DiscoveryException('Not an Xtream endpoint');
  }
}
```

### `M3uDiscovery` (sketch)

```dart
class M3uDiscovery implements PortalDiscovery {
  final Dio dio;
  M3uDiscovery(this.dio);

  @override
  Future<DiscoveryResult> discover(String input) async {
    final url = _canonicalizeUrl(input);
    final head = await dio.headUri(url, options: Options(validateStatus: (_) => true));
    if (_isM3uContentType(head.headers)) {
      return DiscoveryResult(kind: ProviderKind.m3u, lockedBase: head.realUri ?? url, hints: {});
    }
    // Fallback: small GET, check #EXTM3U; UA retry on 403/406
    // Redirects auto-resolved via dio
    throw DiscoveryException('Not a valid M3U endpoint/file');
  }
}
```

---

### TL;DR implementation order

1. **Classifier** routes to adapter.
2. **Shared normalizers** (scheme/port/files/trailing slash).
3. **XtreamDiscovery** (player_api probe + creds extraction).
4. **M3uDiscovery** (HEAD/range GET + #EXTM3U).
5. **Lock-in & persistence** (profile + vault).
6. **Retries/UA/TLS** knobs unified across adapters.
7. **Tests** for redirects, UA blocks, TLS, early close.

This mirrors your Stalker solution, so the whole login story becomes consistent: **any string in -> correct portal out**.

