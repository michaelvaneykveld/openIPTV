import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:openiptv/src/player_ui/controller/player_state.dart';

/// Contract that adapts a concrete media backend to the Player UI.
abstract class PlayerAdapter {
  Stream<PlayerSnapshot> get snapshotStream;

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> selectAudio(String trackId);
  Future<void> selectText(String? trackId);
  Future<void> zapNext();
  Future<void> zapPrevious();
  Future<void> dispose();
}

/// Snapshot emitted by a [PlayerAdapter].
class PlayerSnapshot {
  const PlayerSnapshot({
    required this.phase,
    required this.isLive,
    required this.position,
    required this.buffered,
    this.duration,
    this.bitrateKbps,
    this.audioTracks = const [],
    this.textTracks = const [],
    this.selectedAudio,
    this.selectedText,
    this.error,
    this.isBuffering = false,
    this.mediaTitle,
  });

  final PlayerPhase phase;
  final bool isLive;
  final Duration position;
  final Duration buffered;
  final Duration? duration;
  final int? bitrateKbps;
  final List<PlayerTrack> audioTracks;
  final List<PlayerTrack> textTracks;
  final PlayerTrack? selectedAudio;
  final PlayerTrack? selectedText;
  final PlayerError? error;
  final bool isBuffering;
  final String? mediaTitle;

  PlayerSnapshot copyWith({
    PlayerPhase? phase,
    bool? isLive,
    Duration? position,
    Duration? buffered,
    Duration? duration,
    int? bitrateKbps,
    List<PlayerTrack>? audioTracks,
    List<PlayerTrack>? textTracks,
    PlayerTrack? selectedAudio,
    PlayerTrack? selectedText,
    PlayerError? error,
    bool? isBuffering,
    String? mediaTitle,
  }) {
    return PlayerSnapshot(
      phase: phase ?? this.phase,
      isLive: isLive ?? this.isLive,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      duration: duration ?? this.duration,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      audioTracks: audioTracks ?? this.audioTracks,
      textTracks: textTracks ?? this.textTracks,
      selectedAudio: selectedAudio ?? this.selectedAudio,
      selectedText: selectedText ?? this.selectedText,
      error: error ?? this.error,
      isBuffering: isBuffering ?? this.isBuffering,
      mediaTitle: mediaTitle ?? this.mediaTitle,
    );
  }
}

/// Central state holder. Converts adapter snapshots into immutable UI-friendly state.
class PlayerController {
  PlayerController({
    required this.adapter,
    PlayerViewState? initialState,
    this.overlayAutoHideDelay = const Duration(seconds: 4),
  }) : state = ValueNotifier<PlayerViewState>(
         initialState ?? PlayerViewState.initial(),
       ) {
    _snapshotSubscription = adapter.snapshotStream.listen(
      _handleSnapshot,
      onError: (Object error, StackTrace stackTrace) {
        _updateState(
          state.value.copyWith(
            phase: PlayerPhase.error,
            error: PlayerError(code: 'ADAPTER_STREAM', message: '$error'),
          ),
        );
      },
    );
  }

  final PlayerAdapter adapter;
  final Duration overlayAutoHideDelay;
  final ValueNotifier<PlayerViewState> state;

  StreamSubscription<PlayerSnapshot>? _snapshotSubscription;
  Timer? _overlayTimer;
  bool _isDisposed = false;

  void _handleSnapshot(PlayerSnapshot snapshot) {
    final keepScreenOn = snapshot.phase == PlayerPhase.playing;
    _updateState(
      state.value.copyWith(
        phase: snapshot.phase,
        isLive: snapshot.isLive,
        position: snapshot.position,
        buffered: snapshot.buffered,
        duration: snapshot.duration,
        bitrateKbps: snapshot.bitrateKbps,
        audioTracks: snapshot.audioTracks,
        textTracks: snapshot.textTracks,
        selectedAudio: snapshot.selectedAudio,
        selectedText: snapshot.selectedText,
        error: snapshot.error,
        isBuffering: snapshot.isBuffering,
        isKeepScreenOnEnabled: keepScreenOn,
        mediaTitle: snapshot.mediaTitle,
      ),
    );
    if (snapshot.phase == PlayerPhase.playing) {
      showOverlay(extendOnly: true);
    }
  }

  void showOverlay({bool extendOnly = false}) {
    if (_isDisposed) return;
    _overlayTimer?.cancel();
    _overlayTimer = Timer(overlayAutoHideDelay, hideOverlay);
    if (extendOnly) {
      return;
    }
    if (!state.value.isOverlayVisible) {
      _updateState(state.value.copyWith(isOverlayVisible: true));
    }
  }

  void hideOverlay() {
    if (_isDisposed) return;
    _overlayTimer?.cancel();
    if (state.value.isOverlayVisible) {
      _updateState(state.value.copyWith(isOverlayVisible: false));
    }
  }

  Future<void> togglePlayPause() {
    if (state.value.isPlaying) {
      return pause();
    }
    return play();
  }

  Future<void> play() async {
    showOverlay();
    await adapter.play();
  }

  Future<void> pause() async {
    showOverlay();
    await adapter.pause();
  }

  Future<void> seekRelative(Duration delta) async {
    final newPosition = state.value.position + delta;
    final duration = state.value.duration;
    Duration clamped;
    if (!state.value.isLive && duration != null) {
      if (newPosition < Duration.zero) {
        clamped = Duration.zero;
      } else if (newPosition > duration) {
        clamped = duration;
      } else {
        clamped = newPosition;
      }
    } else {
      clamped = newPosition < Duration.zero ? Duration.zero : newPosition;
    }
    showOverlay();
    await adapter.seekTo(clamped);
  }

  Future<void> seekTo(Duration position) async {
    showOverlay();
    await adapter.seekTo(position);
  }

  Future<void> zapNext() async {
    showOverlay();
    await adapter.zapNext();
  }

  Future<void> zapPrevious() async {
    showOverlay();
    await adapter.zapPrevious();
  }

  Future<void> selectAudio(PlayerTrack track) async {
    showOverlay();
    await adapter.selectAudio(track.id);
  }

  Future<void> selectText(PlayerTrack? track) async {
    showOverlay();
    await adapter.selectText(track?.id);
  }

  void reportUserInteraction() {
    showOverlay();
  }

  void _updateState(PlayerViewState newState) {
    if (_isDisposed) {
      return;
    }
    state.value = newState;
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _overlayTimer?.cancel();
    await _snapshotSubscription?.cancel();
    await adapter.dispose();
    state.dispose();
  }
}
