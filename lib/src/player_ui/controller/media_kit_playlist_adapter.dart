import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
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
    _player = Player(
      configuration: PlayerConfiguration(
        title: 'OpenIPTV',
        libass: true,
        protocolWhitelist: const ['file', 'http', 'https', 'tcp', 'udp', 'rtp', 'rtsp'],
      ),
    );
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
  http.Client? _probeClient;

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
    _probeClient?.close();
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
      _probePlaybackFailure(source, error);
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
      final failingSource = _currentSource;
      _snapshot = _snapshot.copyWith(
        phase: PlayerPhase.error,
        error: PlayerError(code: 'MEDIAKIT_ERROR', message: value.toString()),
      );
      _emitSnapshot();
      PlaybackLogger.videoError('media-kit-error', error: value);
      _probePlaybackFailure(failingSource, value);
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
    // Use durationHint from source if available, otherwise use stream duration
    final effectiveDuration = source.playable.isLive
        ? null
        : (source.playable.durationHint ?? _duration);
    _snapshot = _snapshot.copyWith(
      phase: phase,
      isLive: source.playable.isLive,
      position: _position,
      buffered: _position,
      duration: effectiveDuration,
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

  void _probePlaybackFailure(
    PlayerMediaSource source,
    Object error,
  ) {
    final uri = source.playable.url;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return;
    }
    final headers = source.playable.headers;
    unawaited(_logHttpProbe(uri, headers, error));
  }

  Future<void> _logHttpProbe(
    Uri uri,
    Map<String, String> headers,
    Object error,
  ) async {
    final client = _probeClient ??= http.Client();
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers.addAll(headers);
    request.headers.putIfAbsent('Range', () => 'bytes=0-2047');
    try {
      final response =
          await client.send(request).timeout(const Duration(seconds: 8));
      final sample = await _readSample(response.stream, 2048);
      PlaybackLogger.videoInfo(
        'media-kit-http-probe',
        uri: uri,
        extra: {
          'code': response.statusCode,
          'contentType': response.headers['content-type'] ?? 'unknown',
          'bytes': sample.length,
          'payload': base64Encode(
            sample.length > 256 ? sample.sublist(0, 256) : sample,
          ),
          'error': error.toString(),
        },
      );
    } catch (probeError) {
      PlaybackLogger.videoError(
        'media-kit-http-probe-error',
        description: uri.toString(),
        error: probeError,
      );
    }
  }

  Future<List<int>> _readSample(
    Stream<List<int>> stream,
    int maxBytes,
  ) async {
    final buffer = <int>[];
    await for (final chunk in stream) {
      final remaining = maxBytes - buffer.length;
      if (remaining <= 0) {
        break;
      }
      if (chunk.length <= remaining) {
        buffer.addAll(chunk);
      } else {
        buffer.addAll(chunk.take(remaining));
        break;
      }
    }
    return buffer;
  }
}
