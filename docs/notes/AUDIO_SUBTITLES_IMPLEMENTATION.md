# Audio and Subtitle Track Implementation

## Overview
Stalker Portal streams (and many other IPTV streams) embed audio and subtitle tracks directly in the media container (MPEG-TS, MKV, MP4). These tracks are **not** exposed via the Stalker API metadata.

We have implemented dynamic track discovery using `media_kit`.

## Implementation Details

### 1. Track Discovery
We listen to the `tracks` stream from the `media_kit` Player. This stream emits the list of available audio and subtitle tracks whenever the player loads a new source or discovers tracks in the stream.

**File:** `lib/src/player_ui/controller/media_kit_playlist_adapter.dart`

```dart
_tracksSub = _player.stream.tracks.listen((tracks) {
  // Map media_kit AudioTrack to PlayerTrack
  final audioTracks = tracks.audio.map((t) => PlayerTrack(...)).toList();
  
  // Map media_kit SubtitleTrack to PlayerTrack
  final textTracks = tracks.subtitle.map((t) => PlayerTrack(...)).toList();

  // Update PlayerSnapshot
  _snapshot = _snapshot.copyWith(
    audioTracks: audioTracks,
    textTracks: textTracks,
  );
  _emitSnapshot();
});
```

### 2. Track Selection
We listen to the `track` stream (singular) to know which track is currently selected by the player (e.g. default track or auto-selected).

```dart
_trackSub = _player.stream.track.listen((track) {
  // Update selected tracks in snapshot
  _snapshot = _snapshot.copyWith(
    selectedAudio: PlayerTrack(...),
    selectedText: PlayerTrack(...),
  );
  _emitSnapshot();
});
```

### 3. User Selection
We implemented `selectAudio` and `selectText` methods in `MediaKitPlaylistAdapter`.

```dart
@override
Future<void> selectAudio(String trackId) async {
  final track = _player.state.tracks.audio.firstWhereOrNull((t) => t.id == trackId);
  if (track != null) {
    await _player.setAudioTrack(track);
  }
}

@override
Future<void> selectText(String? trackId) async {
  if (trackId == null) {
    await _player.setSubtitleTrack(SubtitleTrack.no());
    return;
  }
  final track = _player.state.tracks.subtitle.firstWhereOrNull((t) => t.id == trackId);
  if (track != null) {
    await _player.setSubtitleTrack(track);
  }
}
```

## Usage
The UI can now display the list of available tracks from `PlayerViewState.audioTracks` and `PlayerViewState.textTracks`.
When a user selects a track, the UI should call `controller.selectAudio(track)` or `controller.selectText(track)`.

## Notes
- **Audio Tracks:** Includes language, channels, and codec information if available.
- **Subtitle Tracks:** Includes language and codec information.
- **Default Tracks:** The player automatically selects the default track based on stream metadata or user preferences (if configured in `media_kit`).
