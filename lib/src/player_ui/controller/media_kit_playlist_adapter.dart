import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
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
    print('[PLAYLIST-INIT] MediaKitPlaylistAdapter constructor called');
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
    _currentIndex = initialIndex.clamp(0, sources.length - 1);
    _snapshot = _initialSnapshot();
    // CRITICAL: VideoController will be created lazily after first non-zero layout
  }

  Future<void> _createVideoControllerForSize(Size size) async {
    print(
      '[PLAYLIST-INIT] _createVideoControllerForSize called: ${size.width}x${size.height}',
    );

    if (_isCreatingController) {
      print('[PLAYLIST-INIT] Already creating controller, skipping');
      return;
    }
    if (_videoController != null) {
      print('[PLAYLIST-INIT] Controller already exists, skipping');
      return;
    }
    if (size.width <= 0 || size.height <= 0) {
      print(
        '[PLAYLIST-INIT] Invalid size (${size.width}x${size.height}), skipping',
      );
      return;
    }

    _isCreatingController = true;
    print(
      '[PLAYLIST-INIT] Starting controller creation with size ${size.width}x${size.height}',
    );
    PlaybackLogger.videoInfo(
      'playlist-controller-creation-start',
      extra: {'width': size.width, 'height': size.height},
    );

    try {
      // Small delay to ensure native window metrics are fully settled
      print('[PLAYLIST-INIT] Waiting 16ms for window metrics to settle...');
      await Future.delayed(const Duration(milliseconds: 16));

      // Create VideoController with measured dimensions
      print(
        '[PLAYLIST-INIT] Creating VideoController with config: ${size.width.toInt()}x${size.height.toInt()}',
      );
      _videoController = VideoController(
        _player,
        configuration: VideoControllerConfiguration(
          width: size.width.toInt(),
          height: size.height.toInt(),
        ),
      );
      print('[PLAYLIST-INIT] VideoController created successfully');

      PlaybackLogger.videoInfo(
        'playlist-controller-creation-success',
        extra: {'width': size.width, 'height': size.height},
      );

      _attachListeners();
      unawaited(_loadCurrent());
    } catch (e, st) {
      print('[PLAYLIST-INIT] ERROR creating controller: $e');
      PlaybackLogger.videoError(
        'playlist-controller-creation-failed',
        description: '$e\n$st',
        error: e,
      );
    } finally {
      _isCreatingController = false;
      print('[PLAYLIST-INIT] Controller creation completed');
    }
  }

  final List<PlayerMediaSource> _sources;
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
    print('[PLAYLIST-INIT] buildVideoSurface called');

    // CRITICAL: Use LayoutBuilder to observe real constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        print(
          '[PLAYLIST-INIT] LayoutBuilder constraints: ${constraints.maxWidth}x${constraints.maxHeight}',
        );

        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Use finite dimensions or fallback to reasonable defaults
        final width = size.width.isFinite ? size.width : 1920.0;
        final height = size.height.isFinite ? size.height : 1080.0;
        final measuredSize = Size(width, height);

        print(
          '[PLAYLIST-INIT] Measured size: ${width}x$height (finite: ${size.width.isFinite}x${size.height.isFinite})',
        );

        // Track last known non-zero size
        if (width > 0 && height > 0 && _lastKnownSize != measuredSize) {
          _lastKnownSize = measuredSize;
          print('[PLAYLIST-INIT] Updated _lastKnownSize to ${width}x$height');
          PlaybackLogger.videoInfo(
            'playlist-layout-measured',
            extra: {'width': width, 'height': height},
          );
        }

        print(
          '[PLAYLIST-INIT] Controller state: exists=${_videoController != null}, creating=$_isCreatingController, lastSize=${_lastKnownSize.width}x${_lastKnownSize.height}',
        );

        // If we don't have a controller yet and we have measured non-zero size -> create it
        if (_videoController == null &&
            !_isCreatingController &&
            _lastKnownSize.width > 0 &&
            _lastKnownSize.height > 0) {
          print(
            '[PLAYLIST-INIT] Scheduling post-frame callback to create controller',
          );
          // Create controller AFTER this frame (ensures native sees real window metrics)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('[PLAYLIST-INIT] Post-frame callback executing');
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
