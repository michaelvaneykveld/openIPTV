# Stalker Windows Playback – Working Notes

These are the exact ingredients that made Stalker live playback succeed on Windows in this repo snapshot:

1. **Use the portal’s `ffmpeg …` command verbatim.**  
   - Every Stalker `create_link` response includes a full `ffmpeg http://...play/live.php?...` command.  
   - We now pass that string straight to our local restreamer so ffmpeg executes exactly what the portal expects (same query params, `play_token`, optional `sn2`, etc.).

2. **Replay the portal headers verbatim.**  
   - Before launching ffmpeg we inject the header bundle supplied by the session (`X-User-Agent`, `User-Agent`, `Referer`, `Accept`, `Connection`, plus the `Cookie` string with `mac`, `stb_lang`, `timezone`, `token`, and the short-lived `play_token`).  
   - Those headers are inserted *before* `-i` so ffmpeg sends them with the GET.

3. **Run through a local restreamer.**  
   - We spawn `ffmpeg -i <portal URL> -c copy -f mpegts pipe:1`, serve the bytes via `http://127.0.0.1:<port>/stream/<id>`, and point MediaKit at that local URL.  
   - This avoids Windows Media Foundation’s header restrictions while still honoring every portal requirement.

4. **Let the portal session populate headers/cookies.**  
   - All Stalker requests go through the authenticated session so `sessionHeaders` (token, MAC, etc.) are always merged before building the playable.  
   - We never strip `Cookie`, `Authorization`, or the portal’s custom `X-User-Agent`.

5. **Keep Windows policy in “warn + restream” mode.**  
   - `WindowsPlaybackSupport.needsHeaders` / `likelyCodecIssue` entries trigger MediaKit automatically; we only warn once but do not block playback.

6. **Confirmed behaviour (logs):**  
   - `Playback][Stalker]` shows the resolved `ffmpeg` command and the header list `["X-User-Agent","Accept","Connection","User-Agent","Referer","Cookie"]`.  
   - `Playback][VideoInfo] {"stage":"ffmpeg-restream-command",...}` logs the exact command we run, including headers and cookies.  
   - MediaKit reports `1280 720` and renders successfully – “white smoke.”

Keep this file next time we worry that Stalker broke on Windows; these are the knobs that have to stay in place.
