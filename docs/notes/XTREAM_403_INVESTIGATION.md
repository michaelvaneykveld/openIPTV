# Xtream VOD 403 Forbidden Investigation

## Status: Paused (2025-11-29)

### The Issue
Xtream VOD playback from provider `atlas213.xyz` fails on Windows.
- **Symptoms:** Player connects, buffers, then fails with `Invalid argument` or `403 Forbidden`.
- **Root Cause:** The provider implements strict anti-leech/WAF protection. It blocks direct `GET` requests from `mpv` (media_kit) but allows `HEAD` requests or requests from specific clients.

### Current Implementation
We implemented a **Local Proxy** solution to bypass the block:
1.  **`StreamProbe`**: Checks if a URL is accessible and follows redirects.
2.  **`LocalProxyServer`**: A local HTTP server (`localhost`) that proxies requests to the provider using Dart's `HttpClient`.
3.  **Fallback Logic**: If `StreamProbe` detects a 403, the app rewrites the URL to point to `LocalProxyServer`.

### The Problem
The `LocalProxyServer` is **also receiving 403 Forbidden** from the provider.
```
[LocalProxyServer] Proxying: http://atlas213.xyz/movie/...
[LocalProxyServer] Upstream response: 403 Forbidden
```

### Missing Information
We have analyzed several Python test scripts in the workspace (`test_strict_raw.py`, etc.), but they are all targeted at a **Stalker** provider (`mag.4k365.xyz`).

**We are missing the working reference implementation for the Xtream provider (`atlas213.xyz`).**

### Next Steps
To fix this, we need to replicate the exact network signature of a working client for `atlas213.xyz`.

1.  **Obtain Working Script:** We need a `curl` command or Python script that successfully downloads a VOD segment from `atlas213.xyz`.
2.  **Analyze Headers:** Determine exactly which headers are required (User-Agent, Referer, Cookie, etc.) and which must be omitted.
3.  **Update Proxy:** Modify `lib/src/playback/local_proxy_server.dart` to match the working script's headers and behavior (e.g., HTTP/1.1 vs 2, cookie persistence).

### Files Modified
- `lib/src/playback/local_proxy_server.dart` (New proxy server)
- `lib/src/playback/stream_probe.dart` (New probe utility)
- `lib/src/playback/playable_resolver.dart` (Updated to use probe/proxy)
- `lib/main.dart` (Starts proxy on launch)
- `lib/src/player_ui/ui/error_toast.dart` (Fixed UI overflow)
