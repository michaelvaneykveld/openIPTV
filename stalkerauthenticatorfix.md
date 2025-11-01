Got it — let’s make your Stalker/Ministra URL entry **bullet-proof** so even “creative” inputs end up at the right portal endpoint and your app stops flaking out.

I’ll give you:

1. a robust **normalization + probe** strategy,
2. concrete **Flutter/Dart** implementation notes,
3. fixes for the exact failures you mentioned (early connection close, 512/503, etc.),
4. how other apps effectively “find the right endpoint”.

I cite a few vendor/open-source sources so this isn’t guesswork.

---

# 1) What users type vs what the portal expects

Users may paste:

* bare host: `example.com`
* scheme variants: `http://…`, `https://…`
* ports: `:88`, `:8080`, etc.
* paths: `/`, `/c`, `/c/`, `/stalker_portal/`, `/stalker_portal/c/`
* even UI pages (not STB endpoints)

**What actually serves the STB API** is typically under the **classic UI path** (`…/stalker_portal/c/`) or the server backend (`…/stalker_portal/server/load.php`) where requests are routed by `type`/`action` parameters. You’ll also see portals mounted directly under `/c/`. Infomir’s own examples and code trees show these layouts and the classic “/c/” path. ([wiki.infomir.eu][1])

---

# 2) The approach: Canonicalize → Generate candidates → Probe (fast) → Lock-in

## A) Canonicalize input

* Trim spaces, lowercase the **host** only; **preserve** case elsewhere.
* If scheme missing, **prefer `https`**, then fall back to `http` if TLS fails or cert is obviously self-signed (behind an “unsafe” advanced toggle).
* If the path contains `/portal.php` or `/index.php`, strip to its **directory base**.

> Reason: many portals are reachable at multiple URLs (with/without `/stalker_portal/`), and operators often terminate TLS behind odd ports or have expired certs. Debug examples from Infomir show classic paths under `/stalker_portal/c/`. ([wiki.infomir.eu][1])

## B) Generate a **candidate matrix** (ordered)

Given a canonical `{scheme}://{host}{:port?}{basePath?}`, build and try these **in order**:

1. `{base}/stalker_portal/c/`
2. `{base}/c/`
3. `{base}/stalker_portal/`
4. `{base}/`  *(only if the basePath looked like a portal already, otherwise skip)*

> If the user already entered a “/c” or “/stalker_portal/c”, **try that first**, then the rest.

Also generate **API candidates** (you won’t show these to users, but they’re great for cheap detection):

* `{cand}/portal.php`
* `{cand}../server/load.php` (if the candidate ends with `/c/`, the sibling `server/` is common)
  Open-source Ministra trees route STB actions through `server/load.php` and the classic UI under `/c/`. ([GitHub][2])

## C) Probe each candidate **cheaply**

For each candidate, run a *short* sequence with tight timeouts:

1. **HEAD** (or a tiny GET) on the candidate directory:

   * Accept **200/3xx** as promising; follow redirects (limit e.g. 5).
2. **Signature check** on body/headers (from the tiny GET):

   * Paths or markup that indicate Ministra/Stalker (e.g., references to `stalker_portal`, `ministra`, `/c/`, or classic assets). Seeing `…/stalker_portal/c/?debug` in official docs is a strong hint for the classic UI. ([wiki.infomir.eu][1])
3. **Light handshake ping**:

   * Try calling the portal backend with a non-destructive query (`type` + `action` with benign values) or just request `portal.php` and verify you get structured JSON or STB markup instead of an HTML landing page. The server code shows `DataLoader(type, action)`—i.e., these params are the backend dispatch. ([GitHub][2])

**When one candidate passes**, persist its **locked base** (e.g., `https://host:port/stalker_portal/c/`) and always build your subsequent **handshake** and **list** calls against that.

> If *none* pass:
>
> * Retry with the **other scheme** (https↔http).
> * Retry with and without **port 80/443** if the user gave a naked host.
>   Some portals run on non-default ports; examples in the wild show `…:1339/c`. ([linux-sat.nl][3])

## D) Retry policy & identity

* Use a **MAG-style client identity**: many servers gate behavior on UA + headers. At minimum, allow a configurable **User-Agent** (per provider) and send a stable **MAC** in cookies/headers when probing (even before full auth), because some stacks look for it early. Forum & app discussions emphasize the **token + MAC** pair for subsequent calls. ([forum2.progdvb.com][4])
* **Redirects**: follow 301/302/307/308 and update your locked base to the *final* target.
* **Backoff**: simple 200->400 ms jittered backoff across candidates; total probe budget ≤ 3–4 s.

---

# 3) Fixing the failures you described (with exact knobs)

### Symptom: `HttpException: Connection closed before full header was received`

**Cause(s)** commonly seen with these portals:

* reverse proxy closes persistent connections aggressively,
* buggy chunked encoding,
* TLS middleboxes that don’t love keep-alive,
* gzip mismatch.

**Mitigations** (set only for Stalker adapter):

* Force **HTTP/1.1** and send `Connection: close` for probes/handshake (disable keep-alive just for the initial discovery).
* Disable automatic gzip for the tiny probe requests; request **plain**.
* Use **short timeouts**: connect 1500 ms, receive 1500 ms for probes; switch to normal after lock-in.
* On TLS error, if the user enabled “allow self-signed”, retry with a permissive context **only** for the probe (never default).

### Symptom: 503s / intermittent 5xx during probe

* Treat as **transient**: retry the **next candidate** first, then do one backoff retry on the previous; many Ministra stacks are fronted by overloaded proxies.
* If 503 persists but another candidate returns a portal signature, **prefer the working candidate** and mark the 503 one as “deprioritized” for this provider.

### Symptom: HTTP **512** or custom JSON error payloads

* Some deployments emit non-standard 5xx codes (e.g., `512`) from PHP/web server. If the body matches Ministra error JSON or classic portal HTML **and** your candidate path looks right, **don’t fail the whole provider**—advance to the handshake step; many servers respond “weirdly” to bare hits but behave for STB calls.
* The server code shows routing by `type/action`—i.e., a naked `GET` might 5xx while the proper `load.php?type=…&action=…` route is fine. ([GitHub][2])

---

# 4) How other apps “just work”

* They **accept messy inputs**, then aggressively **canonicalize** to classic **`/stalker_portal/c/`** or **`/c/`**, follow redirects, and **probe** both UI and backend paths until one answers with a portal signature.
* They send a **plausible STB identity** (UA/MAC) early. Even community posts for 3rd-party players talk about first grabbing a **token** and then using **token + MAC cookie** on subsequent calls—so your probe/handshake must be willing to set those headers/cookies consistently. ([forum2.progdvb.com][4])
* They keep **per-portal quirks** (e.g., needs HTTP not HTTPS, needs port 88, needs a special UA) in a **saved profile** so the next launch skips discovery.

---

# 5) Flutter/Dart: implementation notes (idiomatic & resilient)

### A) The normalizer

* Accept a `String input`, return a `Uri lockedBase` + `discoveryReport`.
* Use `Uri.parse` safely; if scheme missing, try `https`, then `http`.
* If `uri.path` looks like `/portal.php` or ends with `.php`, strip to dir.
* Build candidates (see §2B), then **probe** using `Dio` with:

  * `connectTimeout: 1500`, `receiveTimeout: 1500`
  * `validateStatus: (s) => s != null && s < 600`
  * `followRedirects: true`, `maxRedirects: 5`
  * headers: `User-Agent`, and if you already generated a MAC, include it in a `Cookie` (some stacks expect it early).

Signature predicates (accept any):

* body contains `stalker_portal` or `ministra`,
* path `/c/` or classic assets,
* `portal.php` or `server/load.php` returns JSON or a known JSON envelope.

### B) Handshake step (after lock-in)

* Use your **Stalker adapter** (the one you already have/plan) to do the formal handshake with **token + MAC** and cache the working **base** + **headers** in the provider profile. Community and plugin notes confirm the token+MAC pairing for authenticated calls. ([forum2.progdvb.com][4])

### C) Error taxonomy and UX

* **Invalid URL** (parse failed or no candidates reachable): “That address doesn’t look like a Ministra/Stalker portal. Try the operator’s *portal URL* (often ends with `/stalker_portal/c/`).”
* **TLS**: “Secure connection failed. If your operator uses a self-signed certificate, enable ‘Allow self-signed’ in Advanced and try again.”
* **Portal found but handshake failed**: “This portal requires a registered MAC or special access. Verify your MAC with the provider and try again.”

### D) Caching the discovery

* Save: resolved scheme, host, port, **final base path**, and **UA requirement** (if you had to set a custom UA).
* On the next run, **skip probes** and go straight to handshake. Keep a **“Retry discovery”** action if handshake comes back 401/403/404 so you can recover from operator changes.

---

# 6) Pseudocode (Dart) for the probe

```dart
Future<LockedPortal?> discoverPortal(String userInput, {Duration to = const Duration(milliseconds: 1500)}) async {
  final primaries = _canonicalCandidates(userInput); // ordered list of Uri
  final dio = Dio(BaseOptions(
    connectTimeout: to,
    receiveTimeout: to,
    followRedirects: true,
    maxRedirects: 5,
    headers: {
      'User-Agent': await _stbUserAgent(), // configurable
      // 'Cookie': 'mac=00:1A:79:12:34:56;', // optional early
    },
  ));

  for (final cand in primaries) {
    try {
      // 1) tiny GET on directory (accept html/json)
      final r = await dio.getUri(cand, options: Options(responseType: ResponseType.plain, headers: {'Accept-Encoding': 'identity', 'Connection': 'close'}));
      final ok = r.statusCode != null && r.statusCode! < 400;
      final looksLikePortal = ok && _hasPortalSignature(r.data?.toString() ?? '');
      if (looksLikePortal) return LockedPortal(base: _lockBaseUri(r.realUri ?? cand));

      // 2) try portal.php and/or server/load.php
      final paths = [
        cand.resolve('portal.php'),
        // if cand ends with /c/, also try sibling server/load.php
        if (cand.path.endsWith('/c/')) cand.resolve('../server/load.php'),
      ];
      for (final p in paths) {
        final rp = await dio.getUri(p, options: Options(responseType: ResponseType.plain));
        if (_looksLikeBackend(rp)) return LockedPortal(base: _lockBaseUri(rp.realUri ?? cand));
      }
    } on DioException catch (e) {
      // Handle “connection closed early” by trying http<->https or next candidate
      if (_isEarlyClose(e) || _isTlsIssue(e)) continue;
    }
  }

  // Scheme flip and retry once (https<->http)
  final flipped = _flipScheme(primaries);
  if (flipped.isNotEmpty) {
    // repeat loop once with flipped
  }

  return null;
}
```

*Point is*: centralize the messy parts **once** (this function), keep your Stalker adapter clean and oblivious to user chaos.

---

# 7) Why this works (and why your app struggled)

* Your failures (“closed before full header”, random **512/503**) are typical when hitting the **wrong path** (UI landing page instead of classic/ backend), or when a reverse proxy doesn’t like your connection settings. Using a **directory probe + backend probe** and **closing** the connection for probes avoids buggy keep-alives; then you lock the correct base and proceed.
* Infomir’s docs and code trees show the **classic `/stalker_portal/c/`** UIs and **backend routers** (`server/load.php`, `portal.php`) that dispatch by **type/action**—you’ll be treated “like a STB” only when you’re at the **right base** and provide a **plausible identity**. ([wiki.infomir.eu][1])
* Other apps cache the **resolved base** and **UA/MAC** requirements per portal so they never rediscover unless something breaks.

---

## Quick reference (what to implement this week)

* [ ] URL normalizer (scheme, port, path strip).
* [ ] Candidate generator: `/stalker_portal/c/`, `/c/`, `/stalker_portal/`, base.
* [ ] Probe (tiny GET), signature test, backend test (`portal.php`, `server/load.php`).
* [ ] Early-close/TLS handling (Connection: close, gzip off, small timeouts, optional self-signed).
* [ ] Custom **User-Agent** and sticky **MAC** header/cookie; persist per provider. ([forum2.progdvb.com][4])
* [ ] Cache locked base; skip discovery on next run; fallback to rediscover on handshake failure.


[1]: https://wiki.infomir.eu/eng/ministra-tv-platform/ministra-installation-guide/faq/how-to-run-the-ministra-portal-in-debug-mode?utm_source=chatgpt.com "How to run the Ministra portal in debug mode? - wiki.infomir.eu"
[2]: https://github.com/iptvhakr/stalker_portal/blob/master/server/load.php?utm_source=chatgpt.com "stalker_portal/server/load.php at master - GitHub"
[3]: https://www.linux-sat.nl/threads/stb-stalker-portal-mac-code.601/?utm_source=chatgpt.com "STB Stalker Portal (Mac Code) | .:| LinuxSat-Support & Exchange Forum"
[4]: https://forum2.progdvb.com/viewtopic.php?t=12975&utm_source=chatgpt.com "Support for IPTV Stalker Portal - progdvb.com"
