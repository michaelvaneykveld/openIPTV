# Player UI Phase-1 Checklist

## North Star Outcomes
- [x] Deliver Live, VOD, and Radio playback with core transport controls, track selection, and clear error feedback.
- [ ] Keep the UI isolate responsive so D-pad/remote navigation never stutters on TV hardware.[1]
- [ ] Maintain a composable Player UI shell that talks to PlayerAdapter/PlayerController through a tiny contract so backend swaps require no UI changes.
- [x] PlayerShell launches PlayerScreen with provider playlists (categories and library actions now feed real channel streams).

## Scope Guardrails
### Must Ship Now
- [x] Provide a fullscreen video surface with an auto-hiding transport bar (OSD).[2]
- [x] Support Play/Pause, +/-10s or +/-30s seek, and Next/Previous for live channel zap.
- [x] Ship Audio and Subtitle pickers as modal sheets.
- [x] Show a read-only quality/bitrate indicator in the OSD.
- [x] Surface buffering spinner plus error toast with Retry.
- [x] Guarantee D-pad and keyboard navigation (Enter/Back/Arrows) parity.[1]
- [x] Keep the screen awake during playback on Android/tvOS.[3]
- [x] Route PlayerShell (play button & category previews) into PlayerScreen with real provider playlists for Live, Films, and Series.

### Explicitly Deferred (Phase-2+)
- [ ] Confirm PiP, trick-mode previews, DVR/timeshift timelines, ad markers, watch-next rails, chroma key, and advanced stats overlays remain out of Phase-1 scope.

## UI Structure & Components
### PlayerScreen
- [x] Own PlayerController (facade over PlayerAdapter) and manage lifecycle.
- [x] Host VideoSurface plus OverlayOSD, handling safe areas and keepScreenOn hooks.

### VideoSurface
- [x] Render video using the platform texture/view exposed by PlayerAdapter without unnecessary rebuilds.

### OverlayOSD
- [x] Provide transport row (Play/Pause, Rewind/Forward, Live zap left/right) with deterministic focus order.
- [x] Render progress/seek bar showing time for VOD/Series and a LIVE pill when appropriate.
- [x] Show right-aligned info cluster (current time, bitrate label, CC/Audio state).
- [x] Offer secondary buttons (Audio, Subtitles, Quality) that open modal pickers.
- [x] Auto-hide after inactivity and reappear instantly on any user input.

### ModalSheet: TrackPicker
- [x] List audio tracks with language/channels/codec metadata and highlight current selection.
- [x] List subtitle tracks (defaulting to Off) and handle empty lists gracefully.

### Toast/ErrorBubble
- [x] Display non-blocking network/DRM/manifest/decoder errors along with Retry control.

### Focus Styling
- [x] Apply clear focus indicators (scale/halo) that meet Android TV focus guidance.[4]

## Input Model
- [x] Map OK/Enter/Space to toggle Play/Pause.
- [x] Map Left/Right to seek +/-10s (VOD/Series) or zap previous/next (Live).
- [x] Map Up to show the OSD (or open Audio sheet when OSD already visible).
- [x] Map Down to show the OSD (or open Subtitles sheet when OSD already visible).
- [x] Map Back/Escape to close sheet, then OSD, then exit player in order.
- [x] Prepare long-press Left/Right hook for accelerated seek (Phase-1.5).
- [x] Ensure every control is reachable through predictable D-pad focus chains.[1]

## State Machine
- [x] Implement IDLE -> LOADING -> PLAYING/PAUSED states with ERROR branch.
- [x] Show spinner and disable seek while LOADING.
- [x] Auto-hide OSD while PLAYING or PAUSED after N seconds of inactivity.
- [x] Keep session context so Retry from ERROR resumes the last media.
- [ ] Emit adapter events (`onBuffering`, `onPlay`, `onPause`, `onEnded`, `onError`, `onTracksChanged`, `onBitrateChanged`, `onLiveEdge`) into the UI.

## Data Contract (UI <-> PlayerAdapter)
- [x] Expose read fields: `isLive`, `position`, `duration?`, `buffered`, `bitrateKbps?`, `tracks{audio[],text[]}`, `selectedAudio`, `selectedText`.
- [x] Provide commands: `play`, `pause`, `seekTo`, `selectAudio`, `selectText`, `zapNext`, `zapPrev`.
- [x] Stream events: `onStateChanged`, `onError`, `onTracksChanged`, `onBitrateChanged`.

## First-Run UX & Defaults
- [ ] Make first OK/Enter show the transport bar; second tap toggles Play/Pause.[2]
- [ ] Default to best audio track (respecting preferred language) and Subtitles Off unless user prefs say otherwise.
- [ ] For Live playback, replace time slider with LIVE badge and disable seek affordances when timeshift is unavailable.
- [x] Disable or grey out Audio/Subtitles buttons when track lists are empty, showing tooltips like "No subtitles available."

## Performance Budget
- [ ] Keep OSD show/hide animation under 16 ms (one 60 fps frame).
- [ ] Keep key press to visual feedback under 100 ms.
- [ ] Avoid rebuilding the VideoSurface; only rebuild OSD widgets when state changes.
- [ ] Ensure keepScreenOn (or platform equivalent) stays active during playback.[3]

## Accessibility & TV Specifics
- [x] Provide visible, non-color-only focus indicators and scaling on focused controls.[4]
- [x] Use large tap/focus targets (72-96 px) to respect 10-foot UX guidance.[5]
- [x] Maintain consistent Back behavior (sheet -> OSD -> exit) and expose an explicit exit control in the OSD.
- [x] Keep a Caption/Subtitles button visible whenever captions are available per Apple HIG.[2]

## Error Model
- [ ] Map adapter error codes to human-friendly strings plus short identifiers (e.g., NET_TIMEOUT, DRM_DENIED).
- [ ] Show toast + Retry for recoverable errors without blocking playback flow.
- [ ] Log raw error payloads in dev builds for debugging while keeping user messaging simple.

## Acceptance Criteria
- [ ] Validate Play/Pause/Seek/Audio/Subtitles across Live, VOD, Series, and Radio (Radio shows transport without seek).
- [ ] Confirm D-pad focus covers every control and Back unwinds layers predictably.[1]
- [ ] Verify OSD auto-hides after 3-5 s inactivity and returns instantly on input.[2]
- [ ] Meet performance numbers (OSD <=16 ms, key-to-action <=100 ms) with no UI jank during playback.
- [ ] Ensure recoverable errors show toast + Retry and keep UI responsive.
- [ ] Keep Android devices awake during playback sessions.[3]

## Folder & Code Skeleton
- [x] Create `lib/player/ui/player_screen.dart` to wire controller + OSD.
- [x] Create `lib/player/ui/video_surface.dart` for the platform texture/view.
- [x] Create `lib/player/ui/overlay_osd.dart` for transport, progress, and badges.
- [x] Create `lib/player/ui/track_picker_sheet.dart` for modal audio/subtitle selection.
- [x] Create `lib/player/ui/error_toast.dart` for transient messaging.
- [x] Create `lib/player/ui/focus_styles.dart` for reusable focus indicators.
- [x] Create `lib/player/controller/player_controller.dart` wrapping PlayerAdapter streams.
- [x] Create `lib/player/controller/player_state.dart` for enums/data blob.
- [x] Create `lib/player/intent/remote_actions.dart` for remote/key intents.
- [x] Create `lib/player/theming/player_theme.dart` for sizes, paddings, focus ring tokens.

## Phase-2+ Hooks to Reserve
- [ ] Leave slots in the OSD layout (transport/center/right/bottom) so ad markers, chapter markers, watch-next rails, and info panels can drop in later.[6]
- [ ] Plan integration points for PiP/system transport APIs on tvOS/Android TV.[7]
- [ ] Reserve dev-toggle overlay area for advanced stats (FPS, dropped frames, buffer/bitrate graphs).
- [ ] Keep gesture/long-press/trick-play thumbnail hooks ready for accelerated navigation improvements.

## Day-1 Build Order
- [x] Create PlayerState + PlayerController backed by a mock adapter.
- [x] Implement PlayerScreen with placeholder VideoSurface and functional OverlayOSD (auto-hide enabled).
- [x] Wire remote/keyboard intents through RemoteActions into the controller for Play/Pause/Seek/Zap.
- [x] Build TrackPickerSheet and bind to controller `tracks` and selection commands.
- [x] Add ErrorToast plus error-code mapping layer.
- [x] Implement keepScreenOn hook for Android/tvOS.
- [ ] Validate focus flow on TV hardware: tab through controls and ensure Back unwinds layers cleanly.[1]

[1]: https://developer.android.com/training/tv/get-started/navigation?utm_source=chatgpt.com
[2]: https://developer.apple.com/design/human-interface-guidelines/playing-video?utm_source=chatgpt.com
[3]: https://developer.android.com/media/media3/ui/playerview?utm_source=chatgpt.com
[4]: https://developer.android.com/design/ui/tv/guides/styles/focus-system?utm_source=chatgpt.com
[5]: https://developer.android.com/design/ui/tv?utm_source=chatgpt.com
[6]: https://android.googlesource.com/platform/external/exoplayer/%2B/refs/heads/master/tree_8e57d3715f9092d5ec54ebe2e538f34bfcc34479/docs/ad-insertion.md?utm_source=chatgpt.com
[7]: https://developer.apple.com/documentation/avkit/customizing-the-tvos-playback-experience?utm_source=chatgpt.com
