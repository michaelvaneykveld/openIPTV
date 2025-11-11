import 'package:collection/collection.dart';

/// Player lifecycle states that drive top-level UI affordances.
enum PlayerPhase { idle, loading, playing, paused, error }

/// Lightweight description of an audio or text track that can be selected.
class PlayerTrack {
  const PlayerTrack({
    required this.id,
    required this.label,
    this.language,
    this.channels,
    this.codec,
  });

  final String id;
  final String label;
  final String? language;
  final String? channels;
  final String? codec;

  @override
  String toString() =>
      'PlayerTrack(id: $id, label: $label, language: $language, channels: $channels, codec: $codec)';

  @override
  bool operator ==(Object other) {
    return other is PlayerTrack &&
        id == other.id &&
        label == other.label &&
        language == other.language &&
        channels == other.channels &&
        codec == other.codec;
  }

  @override
  int get hashCode => Object.hash(id, label, language, channels, codec);
}

/// Describes a recoverable player error.
class PlayerError {
  const PlayerError({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'PlayerError($code, $message)';
}

/// Immutable snapshot of everything the Player UI needs to render.
class PlayerViewState {
  const PlayerViewState({
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
    this.isOverlayVisible = false,
    this.isKeepScreenOnEnabled = false,
    this.mediaTitle,
  });

  factory PlayerViewState.initial({
    bool isLive = false,
    Duration position = Duration.zero,
    Duration buffered = Duration.zero,
  }) {
    return PlayerViewState(
      phase: PlayerPhase.idle,
      isLive: isLive,
      position: position,
      buffered: buffered,
      mediaTitle: null,
    );
  }

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
  final bool isOverlayVisible;
  final bool isKeepScreenOnEnabled;
  final String? mediaTitle;

  PlayerViewState copyWith({
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
    bool? isOverlayVisible,
    bool? isKeepScreenOnEnabled,
    String? mediaTitle,
  }) {
    return PlayerViewState(
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
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isKeepScreenOnEnabled:
          isKeepScreenOnEnabled ?? this.isKeepScreenOnEnabled,
      mediaTitle: mediaTitle ?? this.mediaTitle,
    );
  }

  bool get isPlaying => phase == PlayerPhase.playing;

  bool get isPaused => phase == PlayerPhase.paused;

  bool get hasDuration => duration != null && duration != Duration.zero;

  bool get showErrorToast => error != null && phase == PlayerPhase.error;

  String get bitrateLabel => bitrateKbps == null
      ? '—'
      : '${(bitrateKbps! / 1000).toStringAsFixed(1)} Mbps';

  @override
  String toString() {
    return 'PlayerViewState(phase: $phase, isLive: $isLive, position: $position, duration: $duration, buffered: $buffered, bitrate: $bitrateKbps, overlay: $isOverlayVisible)';
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerViewState &&
        other.phase == phase &&
        other.isLive == isLive &&
        other.position == position &&
        other.duration == duration &&
        other.buffered == buffered &&
        other.bitrateKbps == bitrateKbps &&
        const ListEquality<PlayerTrack>().equals(
          other.audioTracks,
          audioTracks,
        ) &&
        const ListEquality<PlayerTrack>().equals(
          other.textTracks,
          textTracks,
        ) &&
        other.selectedAudio == selectedAudio &&
        other.selectedText == selectedText &&
        other.error == error &&
        other.isBuffering == isBuffering &&
        other.isOverlayVisible == isOverlayVisible &&
        other.isKeepScreenOnEnabled == isKeepScreenOnEnabled &&
        other.mediaTitle == mediaTitle;
  }

  @override
  int get hashCode => Object.hash(
    phase,
    isLive,
    position,
    duration,
    buffered,
    bitrateKbps,
    const ListEquality<PlayerTrack>().hash(audioTracks),
    const ListEquality<PlayerTrack>().hash(textTracks),
    selectedAudio,
    selectedText,
    error,
    isBuffering,
    isOverlayVisible,
    isKeepScreenOnEnabled,
    mediaTitle,
  );
}
