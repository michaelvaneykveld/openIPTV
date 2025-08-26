import 'package:flutter/widgets.dart';

/// Represents the current state of the player.
enum PlayerState { idle, buffering, playing, paused, ended, error }

/// A data class for playback events from the native player.
class PlaybackInfo {
  final Duration position;
  final Duration duration;
  final PlayerState state;
  final String? errorMessage;

  PlaybackInfo({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.state = PlayerState.idle,
    this.errorMessage,
  });
}

/// Abstract contract for a video player implementation.
/// This allows swapping the underlying player (VLC, ExoPlayer, AVPlayer)
/// without changing the application logic.
abstract class PlayerAdapter {
  /// A stream of playback events. The UI will listen to this to update itself.
  Stream<PlaybackInfo> get playbackInfoStream;

  /// Initializes the player.
  Future<void> initialize();

  /// Creates the widget that renders the video output.
  Widget buildView();

  /// Starts or resumes playback for a given URL.
  Future<void> play(String url);

  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}


