import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';

class MiniPlayer extends StatefulWidget {
  final PlayerMediaSource source;
  final bool autoPlay;

  const MiniPlayer({super.key, required this.source, this.autoPlay = true});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  late final Player _player;
  VideoController? _controller;
  bool _isCreatingController = false;

  @override
  void initState() {
    super.initState();
    print('[MINI-PLAYER] initState called - NOT creating VideoController yet');
    _player = Player(
      configuration: PlayerConfiguration(
        title: 'OpenIPTV',
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

    // Configure libmpv for IPTV streaming
    try {
      final platform = _player.platform as dynamic;
      platform.setProperty('load-unsafe-playlists', 'yes');
      platform.setProperty('http-version', '1.1'); // Force HTTP/1.1
      platform.setProperty('network-timeout', '30'); // 30 second timeout
      platform.setProperty('cache', 'yes');
      platform.setProperty('cache-secs', '10');
      // Enable verbose logging from libmpv
      platform.setProperty('msg-level', 'all=v');
      platform.setProperty('term-osd-bar', 'no');
      print('[MINI-PLAYER] libmpv properties configured for IPTV');
    } catch (e) {
      print('[MINI-PLAYER] WARNING: Could not configure libmpv properties: $e');
    }

    // Listen to log messages if available
    try {
      final platform = _player.platform as dynamic;
      if (platform.streams?.log != null) {
        platform.streams.log.listen((event) {
          print('[MINI-PLAYER] libmpv: ${event.level} - ${event.text}');
        });
      }
    } catch (e) {
      print('[MINI-PLAYER] Could not attach to libmpv log stream: $e');
    }

    // Listen to player state changes
    _player.stream.playing.listen((isPlaying) {
      print('[MINI-PLAYER] Player playing state: $isPlaying');
    });
    _player.stream.buffering.listen((isBuffering) {
      print('[MINI-PLAYER] Player buffering: $isBuffering');
    });
    _player.stream.error.listen((error) {
      print('[MINI-PLAYER] Player ERROR: $error');
    });
    _player.stream.position.listen((position) {
      if (position.inMilliseconds > 0) {
        print('[MINI-PLAYER] Playback position: ${position.inSeconds}s');
      }
    });
    _player.stream.duration.listen((duration) {
      print(
        '[MINI-PLAYER] Duration: ${duration.inSeconds}s (live=${duration == Duration.zero})',
      );
    });

    // CRITICAL: VideoController will be created lazily after layout
    // CRITICAL: Don't play until VideoController is created
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _play();
    }
  }

  Future<void> _play() async {
    final playable = widget.source.playable;
    final url = playable.rawUrl ?? playable.url.toString();
    print('[MINI-PLAYER] Opening media: ${url.substring(0, 50)}...');
    print('[MINI-PLAYER] Headers: ${playable.headers}');

    // Set headers as player properties (required for libmpv)
    try {
      final platform = _player.platform as dynamic;
      if (playable.headers.isNotEmpty) {
        // Filter out Connection header (libmpv manages connections itself)
        final filteredHeaders = Map<String, String>.from(playable.headers);
        filteredHeaders.remove('Connection');

        if (filteredHeaders.isNotEmpty) {
          // Build header string for libmpv format
          final headerString = filteredHeaders.entries
              .map((e) => '${e.key}: ${e.value}')
              .join('\r\n');
          print('[MINI-PLAYER] Setting http-header-fields: $headerString');
          platform.setProperty('http-header-fields', headerString);
        }
      }
      // Set user-agent separately if present
      if (playable.headers.containsKey('User-Agent')) {
        print(
          '[MINI-PLAYER] Setting user-agent: ${playable.headers['User-Agent']}',
        );
        platform.setProperty('user-agent', playable.headers['User-Agent']);
      }
    } catch (e) {
      print('[MINI-PLAYER] WARNING: Could not set player properties: $e');
    }

    print('[MINI-PLAYER] Calling _player.open()...');
    try {
      // Open without httpHeaders - we already set them as properties above
      await _player.open(Media(url), play: widget.autoPlay);
      print(
        '[MINI-PLAYER] Media opened successfully, playing=${widget.autoPlay}',
      );
      print(
        '[MINI-PLAYER] Player state - playing: ${_player.state.playing}, buffering: ${_player.state.buffering}',
      );
    } catch (e, stack) {
      print('[MINI-PLAYER] EXCEPTION during open: $e');
      print('[MINI-PLAYER] Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> _createVideoControllerForSize(Size size) async {
    print(
      '[MINI-PLAYER] _createVideoControllerForSize: ${size.width}x${size.height}',
    );

    if (_isCreatingController || _controller != null) {
      print('[MINI-PLAYER] Already creating or exists, skipping');
      return;
    }
    if (size.width <= 0 || size.height <= 0) {
      print('[MINI-PLAYER] Invalid size, skipping');
      return;
    }

    _isCreatingController = true;
    try {
      print(
        '[MINI-PLAYER] Creating VideoController with size ${size.width.toInt()}x${size.height.toInt()}',
      );
      final controller = VideoController(
        _player,
        configuration: VideoControllerConfiguration(
          width: size.width.toInt(),
          height: size.height.toInt(),
        ),
      );
      if (mounted) {
        setState(() {
          _controller = controller;
        });
        print('[MINI-PLAYER] VideoController created and setState called');
        // Now that VideoController exists, start playing
        _play();
      }
    } catch (e) {
      print('[MINI-PLAYER] ERROR creating controller: $e');
    } finally {
      _isCreatingController = false;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      '[MINI-PLAYER] build called, _controller=${_controller != null ? "exists" : "null"}',
    );

    return Material(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          print(
            '[MINI-PLAYER] LayoutBuilder constraints: ${size.width}x${size.height}',
          );

          if (_controller == null && !_isCreatingController) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('[MINI-PLAYER] Post-frame callback executing');
              _createVideoControllerForSize(size);
            });
          }

          if (_controller == null) {
            print('[MINI-PLAYER] Showing loading indicator');
            return const Center(child: CircularProgressIndicator());
          }

          print('[MINI-PLAYER] Rendering Video widget');
          return Video(
            controller: _controller!,
            controls: MaterialVideoControls,
          );
        },
      ),
    );
  }
}
