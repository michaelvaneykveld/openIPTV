import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/player_ui/controller/player_state.dart';
import 'package:openiptv/src/player_ui/controller/video_player_adapter.dart'
    show PlayerVideoSurfaceProvider;
import 'package:openiptv/src/player_ui/controller/lazy_playback_models.dart';
import 'package:openiptv/src/utils/playback_logger.dart';

class LazyMediaKitAdapter implements PlayerAdapter, PlayerVideoSurfaceProvider {
  LazyMediaKitAdapter({
    required List<LazyPlaybackEntry> entries,
    required ResolveScheduler scheduler,
    required ResolveConfig config,
    int initialIndex = 0,
    bool autoPlay = true,
  }) : _entries = entries,
       _scheduler = scheduler,
       _config = config,
       _autoPlay = autoPlay,
       _snapshotController = StreamController<PlayerSnapshot>.broadcast(),
       _states = List<_LazyEntryState>.generate(
         entries.length,
         (_) => _LazyEntryState(),
       ) {
    MediaKit.ensureInitialized();
    _player = Player(
      configuration: PlayerConfiguration(
        title: 'OpenIPTV',
        // libass: true,
        // protocolWhitelist: const [
        //   'file',
        //   'http',
        //   'https',
        //   'tcp',
        //   'udp',
        //   'rtp',
        //   'rtsp',
        // ],
      ),
    );
    // Allow redirects to potentially unsafe URLs (common in IPTV)
    try {
      // setProperty is not in the Player interface but available on NativePlayer
      (_player.platform as dynamic).setProperty('load-unsafe-playlists', 'yes');
      // Also set user-agent to match what we use in probing (okhttp/4.9.0 matches curl success)
      (_player.platform as dynamic).setProperty('user-agent', 'okhttp/4.9.0');
      // Force HTTP/1.1 to avoid issues with Nginx/Xtream panels that advertise h2 but fail to stream it
      (_player.platform as dynamic).setProperty('http-version', '1.1');
      // Removed demuxer-lavf-format restriction to allow mpv to detect format automatically
    } catch (e) {
      PlaybackLogger.videoError('media-kit-unsafe-property-failed', error: e);
    }
    _currentIndex = initialIndex.clamp(0, entries.length - 1);
    _snapshot = _initialSnapshot();
    // CRITICAL: VideoController will be created lazily after first non-zero layout
  }

  Future<void> _createVideoControllerForSize(Size size) async {
    if (_isCreatingController) {
      return;
    }
    if (_videoController != null) {
      return;
    }
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    _isCreatingController = true;
    PlaybackLogger.videoInfo(
      'lazy-controller-creation-start',
      extra: {'width': size.width, 'height': size.height},
    );

    try {
      // Small delay to ensure native window metrics are fully settled
      await Future.delayed(const Duration(milliseconds: 16));

      _videoController = VideoController(
        _player,
        configuration: VideoControllerConfiguration(
          width: size.width.toInt(),
          height: size.height.toInt(),
        ),
      );

      PlaybackLogger.videoInfo(
        'lazy-controller-creation-success',
        extra: {'width': size.width, 'height': size.height},
      );

      _attachListeners();
      unawaited(_loadCurrent());
    } catch (e, st) {
      PlaybackLogger.videoError(
        'lazy-controller-creation-failed',
        description: '$e\n$st',
        error: e,
      );
    } finally {
      _isCreatingController = false;
    }
  }

  final List<LazyPlaybackEntry> _entries;
  final List<_LazyEntryState> _states;
  final ResolveScheduler _scheduler;
  final ResolveConfig _config;
  final bool _autoPlay;

  late final Player _player;
  VideoController? _videoController;
  late int _currentIndex;
  late PlayerSnapshot _snapshot;
  bool _isCreatingController = false;
  Size _lastKnownSize = Size.zero;

  final StreamController<PlayerSnapshot> _snapshotController;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<Object>? _errorSub;

  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isDisposed = false;
  bool _neighborsPrefetchedForCurrent = false;

  PlayerMediaSource? get _currentSource =>
      _states[_currentIndex].resolved?.source;

  @override
  Stream<PlayerSnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Widget buildVideoSurface(BuildContext context) {
    PlaybackLogger.log('buildVideoSurface called', tag: 'LAZY-INIT');

    // CRITICAL: Use LayoutBuilder to observe real constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        PlaybackLogger.log(
          'LayoutBuilder constraints: ${constraints.maxWidth}x${constraints.maxHeight}',
          tag: 'LAZY-INIT',
        );

        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Use finite dimensions or fallback to reasonable defaults
        final width = size.width.isFinite ? size.width : 1920.0;
        final height = size.height.isFinite ? size.height : 1080.0;
        final measuredSize = Size(width, height);

        // Track last known non-zero size
        if (width > 0 && height > 0 && _lastKnownSize != measuredSize) {
          _lastKnownSize = measuredSize;
          PlaybackLogger.videoInfo(
            'layout-measured',
            extra: {'width': width, 'height': height},
          );
        }

        // If we don't have a controller yet and we have measured non-zero size -> create it
        if (_videoController == null &&
            !_isCreatingController &&
            _lastKnownSize.width > 0 &&
            _lastKnownSize.height > 0) {
          // Create controller AFTER this frame (ensures native sees real window metrics)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _createVideoControllerForSize(_lastKnownSize);
          });
        }

        // If controller exists, build the actual Video widget
        if (_videoController != null) {
          return SizedBox.expand(
            child: Video(
              controller: _videoController!,
              fit: BoxFit.contain,
              controls: NoVideoControls,
            ),
          );
        }

        // Placeholder while controller is being created
        // IMPORTANT: Keep the same size to avoid layout thrashing
        return SizedBox(
          width: width,
          height: height,
          child: const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Text(
                'Initializing video...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> selectAudio(String trackId) async {}

  @override
  Future<void> selectText(String? trackId) async {}

  @override
  Future<void> zapNext() async {
    if (_entries.length == 1) {
      return;
    }
    final oldIndex = _currentIndex;
    _currentIndex = (_currentIndex + 1).clamp(0, _entries.length - 1);
    await _disposePreviousChannel(oldIndex);
    await _loadCurrent(highPriority: true);
  }

  @override
  Future<void> zapPrevious() async {
    if (_entries.length == 1) {
      return;
    }
    final oldIndex = _currentIndex;
    _currentIndex = (_currentIndex - 1).clamp(0, _entries.length - 1);
    await _disposePreviousChannel(oldIndex);
    await _loadCurrent(highPriority: true);
  }

  Future<void> _disposePreviousChannel(int oldIndex) async {
    if (oldIndex < 0 || oldIndex >= _states.length) {
      return;
    }
    final oldState = _states[oldIndex];
    if (oldState.resolved?.dispose != null) {
      PlaybackLogger.playbackState(
        'disposing-previous-channel',
        extra: {'oldIndex': oldIndex, 'newIndex': _currentIndex},
      );
      try {
        await oldState.resolved!.dispose!.call();
      } catch (e) {
        PlaybackLogger.videoError(
          'dispose-previous-failed',
          description: 'Failed to dispose previous channel: $e',
        );
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playingSub?.cancel();
    await _bufferingSub?.cancel();
    await _errorSub?.cancel();
    for (final state in _states) {
      if (state.resolved?.dispose != null) {
        await state.resolved!.dispose!.call();
      }
    }
    await _player.dispose();
    await _snapshotController.close();
  }

  Future<void> _loadCurrent({bool highPriority = false}) async {
    _neighborsPrefetchedForCurrent = false;
    try {
      PlaybackLogger.playbackState(
        'resolving',
        extra: {'index': _currentIndex},
      );

      final playback = await _ensureResolved(
        _currentIndex,
        highPriority: highPriority,
      );
      if (playback == null) {
        PlaybackLogger.videoError(
          'resolve-failed',
          description: 'No playable stream available',
        );
        throw StateError('No playable stream available.');
      }

      final url =
          playback.source.playable.rawUrl ??
          playback.source.playable.url.toString();
      // Filter out User-Agent from headers passed to open(), as we set it via setProperty.
      // This prevents potential duplicate User-Agent headers in mpv.
      final headers = Map<String, String>.from(
        playback.source.playable.headers,
      );
      headers.remove('User-Agent');
      // Ensure we don't send Range or Accept headers manually, let MediaKit handle it
      headers.remove('Range');
      headers.remove('Accept');

      PlaybackLogger.mediaOpen(
        url,
        headers: headers,
        title: playback.source.title,
        isLive: playback.source.playable.isLive,
      );

      await _player.open(
        Media(url, httpHeaders: headers.isEmpty ? null : headers),
        play: _autoPlay,
      );

      PlaybackLogger.playbackStarted(url, title: playback.source.title);

      final seekStart = playback.source.playable.seekStart;
      if (seekStart != null) {
        await _player.seek(seekStart);
        PlaybackLogger.playbackState(
          'seeked',
          extra: {'position': seekStart.toString()},
        );
      }
      // Don't prefetch neighbors immediately - wait for playback to stabilize
      // Prefetching will be triggered by _attachListeners when stream starts playing
      _evictOutsideHalo();
    } catch (error, stackTrace) {
      PlaybackLogger.videoError(
        'media-kit-load',
        description: '$error\n$stackTrace',
        error: error,
      );
      _snapshot = _snapshot.copyWith(
        phase: PlayerPhase.error,
        error: PlayerError(code: 'MEDIAKIT_LOAD', message: '$error'),
      );
      _emitSnapshot();
    }
  }

  Future<ResolvedPlayback?> _ensureResolved(
    int index, {
    bool highPriority = false,
  }) {
    final state = _states[index];
    if (state.resolved != null) {
      return Future<ResolvedPlayback?>.value(state.resolved);
    }
    if (state.pending != null) {
      return state.pending!;
    }
    Future<ResolvedPlayback?> task() async {
      final result = await _entries[index].factory();
      state.resolved = result;
      state.pending = null;
      return result;
    }

    final future = _scheduler.schedule(task, highPriority: highPriority);
    state.pending = future;
    return future;
  }

  void _prefetchNeighbors() {
    if (_entries.length <= 1) {
      return;
    }
    final radius = _config.neighborRadius;
    for (var offset = 1; offset <= radius; offset++) {
      final forward = _currentIndex + offset;
      if (forward < _entries.length) {
        unawaited(_ensureResolved(forward));
      }
      final backward = _currentIndex - offset;
      if (backward >= 0) {
        unawaited(_ensureResolved(backward));
      }
    }
  }

  void _evictOutsideHalo() {
    if (_entries.length <= 2) {
      return;
    }
    final keep = <int>{_currentIndex};
    final radius = _config.neighborRadius;
    for (var offset = 1; offset <= radius; offset++) {
      final forward = _currentIndex + offset;
      final backward = _currentIndex - offset;
      if (forward < _entries.length) {
        keep.add(forward);
      }
      if (backward >= 0) {
        keep.add(backward);
      }
    }
    for (var i = 0; i < _states.length; i++) {
      if (keep.contains(i)) continue;
      final state = _states[i];
      if (state.resolved?.dispose != null) {
        unawaited(state.resolved!.dispose!.call());
      }
      state.resolved = null;
      state.pending = null;
    }
  }

  void _attachListeners() {
    _positionSub = _player.stream.position.listen((value) {
      _position = value;
      _emitSnapshot();
    });
    _durationSub = _player.stream.duration.listen((value) {
      _duration = value;
      PlaybackLogger.playbackState(
        'duration-update',
        extra: {'duration': value.toString()},
      );
      _emitSnapshot();
    });
    _playingSub = _player.stream.playing.listen((value) {
      _isPlaying = value;
      PlaybackLogger.playbackState(value ? 'playing' : 'paused');
      if (value && !_neighborsPrefetchedForCurrent) {
        _neighborsPrefetchedForCurrent = true;
        // Wait 2 seconds after playback starts before prefetching neighbors
        // This ensures ffmpeg connection is fully established before getting new tokens
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed && _isPlaying) {
            _prefetchNeighbors();
            PlaybackLogger.playbackState('prefetching-neighbors');
          }
        });
      }
      _emitSnapshot();
    });
    _bufferingSub = _player.stream.buffering.listen((value) {
      _isBuffering = value;
      PlaybackLogger.playbackState(value ? 'buffering' : 'buffer-ready');
      _emitSnapshot();
    });
    _errorSub = _player.stream.error.listen((value) {
      PlaybackLogger.videoError(
        'media-kit-error',
        description: value.toString(),
        error: value,
      );
      _snapshot = _snapshot.copyWith(
        phase: PlayerPhase.error,
        error: PlayerError(code: 'MEDIAKIT_ERROR', message: value.toString()),
      );
      _emitSnapshot();
    });
  }

  PlayerSnapshot _initialSnapshot() {
    return const PlayerSnapshot(
      phase: PlayerPhase.loading,
      isLive: true,
      position: Duration.zero,
      buffered: Duration.zero,
      duration: null,
      error: null,
      isBuffering: true,
      mediaTitle: 'Loading channel…',
    );
  }

  void _emitSnapshot() {
    if (_isDisposed) {
      return;
    }
    final resolved = _currentSource;
    final phase = _resolvePhase();
    // Use durationHint from source if available and positive, otherwise use stream duration
    final hint = resolved?.playable.durationHint;
    final effectiveDuration = resolved?.playable.isLive == true
        ? null
        : ((hint != null && hint > Duration.zero) ? hint : _duration);
    _snapshot = _snapshot.copyWith(
      phase: phase,
      isLive: resolved?.playable.isLive ?? true,
      position: _position,
      buffered: _position,
      duration: effectiveDuration,
      isBuffering: _isBuffering,
      mediaTitle: resolved?.title ?? _snapshot.mediaTitle,
    );
    _snapshotController.add(_snapshot);
  }

  PlayerPhase _resolvePhase() {
    if (_snapshot.error != null) {
      return PlayerPhase.error;
    }
    if (_isBuffering) {
      return PlayerPhase.loading;
    }
    if (_isPlaying) {
      return PlayerPhase.playing;
    }
    if (_position > Duration.zero) {
      return PlayerPhase.paused;
    }
    return PlayerPhase.idle;
  }
}

class _LazyEntryState {
  ResolvedPlayback? resolved;
  Future<ResolvedPlayback?>? pending;
}
