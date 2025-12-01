import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
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
        protocolWhitelist: const [
          'file',
          'http',
          'https',
          'tcp',
          'udp',
          'rtp',
          'rtsp',
        ],
      ),
    );
    // Allow redirects to potentially unsafe URLs (common in IPTV)
    try {
      // setProperty is not in the Player interface but available on NativePlayer
      (_player.platform as dynamic).setProperty('load-unsafe-playlists', 'yes');
      // Also set user-agent to match what we use in probing
      (_player.platform as dynamic).setProperty('user-agent', 'okhttp/4.9.3');
      // Force HTTP/1.1 to avoid issues with Nginx/Xtream panels that advertise h2 but fail to stream it
      (_player.platform as dynamic).setProperty('http-version', '1.1');
      // Force demuxer to be more lenient with container mismatches (e.g. TS in MP4)
      (_player.platform as dynamic).setProperty(
        'demuxer-lavf-format',
        'mpegts,mp4,mov,m4v,matroska,avi',
      );
    } catch (e) {
      PlaybackLogger.videoError('media-kit-unsafe-property-failed', error: e);
    }
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
  StreamSubscription<Tracks>? _tracksSub;
  StreamSubscription<Track>? _trackSub;
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
    final track = _player.state.tracks.audio.firstWhereOrNull(
      (t) => t.id == trackId,
    );
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
    final track = _player.state.tracks.subtitle.firstWhereOrNull(
      (t) => t.id == trackId,
    );
    if (track != null) {
      await _player.setSubtitleTrack(track);
    }
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
    await _tracksSub?.cancel();
    await _trackSub?.cancel();
    _probeClient?.close();
    await _player.dispose();
    await _snapshotController.close();
  }

  Future<void> _loadCurrent() async {
    final source = _currentSource;
    try {
      // Filter out User-Agent from headers passed to open(), as we set it via setProperty.
      // This prevents potential duplicate User-Agent headers in mpv.
      final headers = Map<String, String>.from(source.playable.headers);
      headers.remove('User-Agent');

      PlaybackLogger.videoInfo('media-kit-open-headers', extra: headers);

      await _player.open(
        Media(
          source.playable.rawUrl ?? source.playable.url.toString(),
          httpHeaders: headers,
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
    _tracksSub = _player.stream.tracks.listen((tracks) {
      final audioTracks = tracks.audio
          .map(
            (t) => PlayerTrack(
              id: t.id,
              label: t.title ?? t.language ?? t.id,
              language: t.language,
              channels: t.channels?.toString(),
              codec: t.codec,
            ),
          )
          .toList();

      final textTracks = tracks.subtitle
          .map(
            (t) => PlayerTrack(
              id: t.id,
              label: t.title ?? t.language ?? t.id,
              language: t.language,
              codec: t.codec,
            ),
          )
          .toList();

      _snapshot = _snapshot.copyWith(
        audioTracks: audioTracks,
        textTracks: textTracks,
      );
      _emitSnapshot();
    });
    _trackSub = _player.stream.track.listen((track) {
      final audio = track.audio;
      final subtitle = track.subtitle;

      _snapshot = _snapshot.copyWith(
        selectedAudio: PlayerTrack(
          id: audio.id,
          label: audio.title ?? audio.language ?? audio.id,
          language: audio.language,
          channels: audio.channels?.toString(),
          codec: audio.codec,
        ),
        selectedText: PlayerTrack(
          id: subtitle.id,
          label: subtitle.title ?? subtitle.language ?? subtitle.id,
          language: subtitle.language,
          codec: subtitle.codec,
        ),
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

  void _probePlaybackFailure(PlayerMediaSource source, Object error) {
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
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 8));
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

  Future<List<int>> _readSample(Stream<List<int>> stream, int maxBytes) async {
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
