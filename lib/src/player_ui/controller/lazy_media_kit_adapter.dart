import 'dart:async';

import 'package:flutter/widgets.dart';
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
        libass: true,
        protocolWhitelist: const ['file', 'http', 'https', 'tcp', 'udp', 'rtp', 'rtsp'],
      ),
    );
    _videoController = VideoController(_player);
    _currentIndex = initialIndex.clamp(0, entries.length - 1);
    _snapshot = _initialSnapshot();
    _attachListeners();
    unawaited(_loadCurrent());
  }

  final List<LazyPlaybackEntry> _entries;
  final List<_LazyEntryState> _states;
  final ResolveScheduler _scheduler;
  final ResolveConfig _config;
  final bool _autoPlay;

  late final Player _player;
  late final VideoController _videoController;
  late int _currentIndex;
  late PlayerSnapshot _snapshot;

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

  PlayerMediaSource? get _currentSource =>
      _states[_currentIndex].resolved?.source;

  @override
  Stream<PlayerSnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Widget buildVideoSurface(BuildContext context) {
    return SizedBox.expand(
      child: Video(
        controller: _videoController,
        fit: BoxFit.cover,
        controls: NoVideoControls,
      ),
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
    _currentIndex = (_currentIndex + 1).clamp(0, _entries.length - 1);
    await _loadCurrent(highPriority: true);
  }

  @override
  Future<void> zapPrevious() async {
    if (_entries.length == 1) {
      return;
    }
    _currentIndex = (_currentIndex - 1).clamp(0, _entries.length - 1);
    await _loadCurrent(highPriority: true);
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

      final url = playback.source.playable.url.toString();
      final headers = playback.source.playable.headers;

      PlaybackLogger.mediaOpen(
        url,
        headers: headers,
        title: playback.source.title,
        isLive: playback.source.playable.isLive,
      );

      await _player.open(Media(url, httpHeaders: headers), play: _autoPlay);

      PlaybackLogger.playbackStarted(url, title: playback.source.title);

      final seekStart = playback.source.playable.seekStart;
      if (seekStart != null) {
        await _player.seek(seekStart);
        PlaybackLogger.playbackState(
          'seeked',
          extra: {'position': seekStart.toString()},
        );
      }
      _prefetchNeighbors();
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
      PlaybackLogger.playbackState('duration-update', extra: {'duration': value.toString()});
      _emitSnapshot();
    });
    _playingSub = _player.stream.playing.listen((value) {
      _isPlaying = value;
      PlaybackLogger.playbackState(value ? 'playing' : 'paused');
      _emitSnapshot();
    });
    _bufferingSub = _player.stream.buffering.listen((value) {
      _isBuffering = value;
      PlaybackLogger.playbackState(value ? 'buffering' : 'buffer-ready');
      _emitSnapshot();
    });
    _errorSub = _player.stream.error.listen((value) {
      PlaybackLogger.videoError('media-kit-error', description: value.toString(), error: value);
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
    // Use durationHint from source if available, otherwise use stream duration
    final effectiveDuration = resolved?.playable.isLive == true
        ? null
        : (resolved?.playable.durationHint ?? _duration);
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
