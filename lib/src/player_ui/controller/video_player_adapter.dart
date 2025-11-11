import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
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

/// Adapter that manages a playlist of [PlayerMediaSource] entries.
class PlaylistVideoPlayerAdapter
    implements PlayerAdapter, PlayerVideoSurfaceProvider {
  PlaylistVideoPlayerAdapter({
    required List<PlayerMediaSource> sources,
    int initialIndex = 0,
    this.autoPlay = true,
  }) : assert(sources.isNotEmpty, 'Playlist requires at least one source'),
       _sources = List.unmodifiable(sources),
       _snapshotController = StreamController<PlayerSnapshot>.broadcast() {
    _currentIndex = initialIndex.clamp(0, _sources.length - 1);
    _snapshot = _buildSnapshotForSource(
      source: _currentSource,
      phase: PlayerPhase.loading,
    );
    _emitSnapshot();
    unawaited(_loadController());
  }

  final bool autoPlay;
  final List<PlayerMediaSource> _sources;
  final StreamController<PlayerSnapshot> _snapshotController;

  late int _currentIndex;
  VideoPlayerController? _controller;
  late PlayerSnapshot _snapshot;
  bool _isDisposed = false;
  final Map<int, PlayerTrack?> _selectedAudio = {};
  final Map<int, PlayerTrack?> _selectedText = {};

  PlayerMediaSource get _currentSource => _sources[_currentIndex];

  @override
  Stream<PlayerSnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Widget buildVideoSurface(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    final size = controller.value.isInitialized
        ? controller.value.size
        : MediaQuery.sizeOf(context);
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> selectAudio(String trackId) async {
    final track = _currentSource.audioTracks.firstWhereOrNull(
      (t) => t.id == trackId,
    );
    if (track == null) {
      return;
    }
    _selectedAudio[_currentIndex] = track;
    _snapshot = _snapshot.copyWith(selectedAudio: track);
    _emitSnapshot();
  }

  @override
  Future<void> selectText(String? trackId) async {
    if (trackId == null || trackId.isEmpty) {
      _selectedText[_currentIndex] = null;
      _snapshot = _snapshot.copyWith(selectedText: null);
      _emitSnapshot();
      return;
    }
    final track = _currentSource.textTracks.firstWhereOrNull(
      (t) => t.id == trackId,
    );
    if (track == null) {
      return;
    }
    _selectedText[_currentIndex] = track;
    _snapshot = _snapshot.copyWith(selectedText: track);
    _emitSnapshot();
  }

  @override
  Future<void> zapNext() async {
    if (_sources.length == 1) {
      return;
    }
    _currentIndex = (_currentIndex + 1) % _sources.length;
    await _loadController();
  }

  @override
  Future<void> zapPrevious() async {
    if (_sources.length == 1) {
      return;
    }
    _currentIndex = (_currentIndex - 1 + _sources.length) % _sources.length;
    await _loadController();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _controller?.removeListener(_handleControllerUpdate);
    await _controller?.dispose();
    await _snapshotController.close();
  }

  Future<void> _loadController() async {
    final source = _currentSource;
    _controller?.removeListener(_handleControllerUpdate);
    await _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(source.uri);
    _controller!.addListener(_handleControllerUpdate);
    _snapshot = _buildSnapshotForSource(
      source: source,
      phase: PlayerPhase.loading,
    );
    _emitSnapshot();
    try {
      await _controller!.initialize();
      if (_isDisposed) {
        return;
      }
      if (autoPlay) {
        await _controller!.play();
      }
      _handleControllerUpdate(); // ensure fresh snapshot with duration/position
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        phase: PlayerPhase.error,
        error: PlayerError(code: 'LOAD_FAILED', message: '$error'),
      );
      _emitSnapshot();
    }
  }

  PlayerSnapshot _buildSnapshotForSource({
    required PlayerMediaSource source,
    required PlayerPhase phase,
  }) {
    final audioTrack =
        _selectedAudio[_currentIndex] ?? source.defaultAudioTrack();
    final textTrack = _selectedText[_currentIndex] ?? source.defaultTextTrack();
    return PlayerSnapshot(
      phase: phase,
      isLive: source.isLive,
      position: Duration.zero,
      buffered: Duration.zero,
      duration: source.isLive ? null : Duration.zero,
      bitrateKbps: source.bitrateKbps,
      audioTracks: source.audioTracks,
      textTracks: source.textTracks,
      selectedAudio: audioTrack,
      selectedText: textTrack,
      error: null,
      isBuffering: true,
    );
  }

  void _handleControllerUpdate() {
    final controller = _controller;
    if (controller == null || _isDisposed) {
      return;
    }
    final value = controller.value;
    final bufferedPosition = value.buffered.isEmpty
        ? Duration.zero
        : value.buffered.last.end;
    _snapshot = _snapshot.copyWith(
      phase: _derivePhase(value),
      position: value.position,
      buffered: bufferedPosition,
      duration: _currentSource.isLive ? null : value.duration,
      isBuffering: value.isBuffering,
    );
    _emitSnapshot();
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

  void _emitSnapshot() {
    if (_isDisposed) {
      return;
    }
    _snapshotController.add(_snapshot);
  }
}
