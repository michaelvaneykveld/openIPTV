import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_state.dart';

/// Adapter contract for backends that can provide their own platform surface.
abstract class PlayerVideoSurfaceProvider {
  Widget buildVideoSurface(BuildContext context);
}

/// PlayerAdapter implementation that wraps Flutter's [VideoPlayerController].
class VideoPlayerAdapter implements PlayerAdapter, PlayerVideoSurfaceProvider {
  VideoPlayerAdapter({
    required VideoPlayerController controller,
    this.isLive = false,
    this.ownsController = false,
    this.onZapNext,
    this.onZapPrevious,
  }) : _controller = controller {
    _controller.addListener(_handleControllerUpdate);
    if (!_controller.value.isInitialized) {
      _initializing = _controller.initialize().then((_) => _emitSnapshot());
    } else {
      _emitSnapshot();
    }
  }

  factory VideoPlayerAdapter.networkUrl(
    String url, {
    bool isLive = false,
    bool autoPlay = true,
  }) {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    final adapter = VideoPlayerAdapter(
      controller: controller,
      isLive: isLive,
      ownsController: true,
    );
    adapter._initializing?.then((_) {
      if (autoPlay) {
        controller.play();
      }
    });
    return adapter;
  }

  final VideoPlayerController _controller;
  final bool isLive;
  final bool ownsController;
  final Future<void> Function()? onZapNext;
  final Future<void> Function()? onZapPrevious;

  final StreamController<PlayerSnapshot> _snapshotController =
      StreamController<PlayerSnapshot>.broadcast();

  Future<void>? _initializing;
  bool _isDisposed = false;

  @override
  Stream<PlayerSnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Widget buildVideoSurface(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.isInitialized
            ? _controller.value.size.width
            : MediaQuery.sizeOf(context).width,
        height: _controller.value.isInitialized
            ? _controller.value.size.height
            : MediaQuery.sizeOf(context).height,
        child: VideoPlayer(_controller),
      ),
    );
  }

  @override
  Future<void> play() {
    return _controller.play();
  }

  @override
  Future<void> pause() {
    return _controller.pause();
  }

  @override
  Future<void> seekTo(Duration position) {
    return _controller.seekTo(position);
  }

  @override
  Future<void> selectAudio(String trackId) async {
    // Audio track management not supported via video_player directly.
  }

  @override
  Future<void> selectText(String? trackId) async {
    // Subtitle selection not supported via video_player directly.
  }

  @override
  Future<void> zapNext() async {
    if (onZapNext != null) {
      await onZapNext!.call();
    }
  }

  @override
  Future<void> zapPrevious() async {
    if (onZapPrevious != null) {
      await onZapPrevious!.call();
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _controller.removeListener(_handleControllerUpdate);
    if (ownsController) {
      await _controller.dispose();
    }
    await _snapshotController.close();
  }

  void _handleControllerUpdate() {
    _emitSnapshot();
  }

  void _emitSnapshot() {
    if (_isDisposed) {
      return;
    }
    final value = _controller.value;
    final bufferedPosition = value.buffered.isEmpty
        ? Duration.zero
        : value.buffered.last.end;
    final snapshot = PlayerSnapshot(
      phase: _derivePhase(value),
      isLive: isLive,
      position: value.position,
      buffered: bufferedPosition,
      duration: isLive ? null : value.duration,
      bitrateKbps: null,
      audioTracks: const [],
      textTracks: const [],
      selectedAudio: null,
      selectedText: null,
      error: value.hasError
          ? PlayerError(
              code: 'VIDEO_ERROR',
              message: value.errorDescription ?? 'Playback error',
            )
          : null,
      isBuffering: value.isBuffering,
    );
    _snapshotController.add(snapshot);
  }

  PlayerPhase _derivePhase(VideoPlayerValue value) {
    if (value.hasError) {
      return PlayerPhase.error;
    }
    if (!value.isInitialized) {
      return PlayerPhase.loading;
    }
    if (value.isPlaying) {
      return PlayerPhase.playing;
    }
    if (value.position > Duration.zero) {
      return PlayerPhase.paused;
    }
    return PlayerPhase.idle;
  }
}
