import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/player_ui/controller/player_state.dart';
import 'package:openiptv/src/player_ui/controller/video_player_adapter.dart'
    show PlayerVideoSurfaceProvider;
import 'package:openiptv/src/utils/playback_logger.dart';

class MediaKitPlaylistAdapter
    implements PlayerAdapter, PlayerVideoSurfaceProvider {
  MediaKitPlaylistAdapter({
    required List<PlayerMediaSource> sources,
    int initialIndex = 0,
    bool autoPlay = true,
  }) : _sources = sources,
       _autoPlay = autoPlay,
       _snapshotController = StreamController<PlayerSnapshot>.broadcast() {
    MediaKit.ensureInitialized();
    _player = Player();
    _videoController = VideoController(_player);
    _currentIndex = initialIndex.clamp(0, sources.length - 1);
    _snapshot = _initialSnapshot();
    _attachListeners();
    unawaited(_loadCurrent());
  }

  final List<PlayerMediaSource> _sources;
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

  PlayerMediaSource get _currentSource => _sources[_currentIndex];

  @override
  Stream<PlayerSnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Widget buildVideoSurface(BuildContext context) {
    return SizedBox.expand(
      child: Video(controller: _videoController, fit: BoxFit.cover),
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
  Future<void> selectAudio(String trackId) async {
    // media_kit exposes audio track selection APIs, but they require probing.
    // For now we leave this as a no-op until track metadata is plumbed through.
  }

  @override
  Future<void> selectText(String? trackId) async {
    // Subtitle routing not implemented yet for the media_kit backend.
  }

  @override
  Future<void> zapNext() async {
    if (_sources.length == 1) {
      return;
    }
    _currentIndex = (_currentIndex + 1) % _sources.length;
    await _loadCurrent();
  }

  @override
  Future<void> zapPrevious() async {
    if (_sources.length == 1) {
      return;
    }
    _currentIndex = (_currentIndex - 1 + _sources.length) % _sources.length;
    await _loadCurrent();
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
    await _player.dispose();
    await _snapshotController.close();
  }

  Future<void> _loadCurrent() async {
    final source = _currentSource;
    try {
      await _player.open(
        Media(
          source.playable.url.toString(),
          httpHeaders: source.playable.headers,
        ),
        play: _autoPlay,
      );
      final seekStart = source.playable.seekStart;
      if (seekStart != null) {
        await _player.seek(seekStart);
      }
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        phase: PlayerPhase.error,
        error: PlayerError(code: 'MEDIAKIT_LOAD', message: '$error'),
      );
      _emitSnapshot();
      PlaybackLogger.videoError('media-kit-load', error: error);
    }
  }

  void _attachListeners() {
    _positionSub = _player.stream.position.listen((value) {
      _position = value;
      _emitSnapshot();
    });
    _durationSub = _player.stream.duration.listen((value) {
      _duration = value;
      _emitSnapshot();
    });
    _playingSub = _player.stream.playing.listen((value) {
      _isPlaying = value;
      _emitSnapshot();
    });
    _bufferingSub = _player.stream.buffering.listen((value) {
      _isBuffering = value;
      _emitSnapshot();
    });
    _errorSub = _player.stream.error.listen((value) {
      _snapshot = _snapshot.copyWith(
        phase: PlayerPhase.error,
        error: PlayerError(code: 'MEDIAKIT_ERROR', message: value.toString()),
      );
      _emitSnapshot();
    });
  }

  PlayerSnapshot _initialSnapshot() {
    final source = _currentSource;
    return PlayerSnapshot(
      phase: PlayerPhase.loading,
      isLive: source.playable.isLive,
      position: Duration.zero,
      buffered: Duration.zero,
      duration: source.playable.isLive ? null : Duration.zero,
      bitrateKbps: source.bitrateKbps,
      audioTracks: source.audioTracks,
      textTracks: source.textTracks,
      selectedAudio: source.defaultAudioTrack(),
      selectedText: source.defaultTextTrack(),
      error: null,
      isBuffering: true,
      mediaTitle: source.title ?? source.playable.url.toString(),
    );
  }

  void _emitSnapshot() {
    if (_isDisposed) {
      return;
    }
    final source = _currentSource;
    final phase = _resolvePhase();
    _snapshot = _snapshot.copyWith(
      phase: phase,
      isLive: source.playable.isLive,
      position: _position,
      buffered: _position,
      duration: source.playable.isLive ? null : _duration,
      isBuffering: _isBuffering,
      mediaTitle: source.title ?? source.playable.url.toString(),
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
