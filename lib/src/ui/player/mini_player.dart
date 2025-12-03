import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/playback/ffmpeg_restreamer.dart';

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
  RestreamHandle? _restreamHandle;

  @override
  void initState() {
    super.initState();
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
      platform.setProperty('http-version', '1.1');
      platform.setProperty('network-timeout', '30');
      platform.setProperty('cache', 'yes');
      platform.setProperty('cache-secs', '10');
    } catch (e) {
      debugPrint('MiniPlayer: Failed to configure libmpv: $e');
    }

    _player.stream.error.listen((error) {
      debugPrint('MiniPlayer ERROR: $error');
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
    debugPrint('MiniPlayer: _play() called');

    // Dispose previous restream if exists
    await _restreamHandle?.dispose();
    _restreamHandle = null;

    PlayerMediaSource sourceToPlay = widget.source;

    if (widget.source.playable.headers.isNotEmpty) {
      // Use FFmpeg for header support
      debugPrint('MiniPlayer: Using FfmpegRestreamer for header support');
      final handle = await FfmpegRestreamer.instance.restream(widget.source);
      if (handle != null) {
        _restreamHandle = handle;
        sourceToPlay = handle.source;
        debugPrint('MiniPlayer: Restreamed to: ${sourceToPlay.playable.url}');
      } else {
        debugPrint('MiniPlayer: Restream failed, using original source');
      }
    }

    final finalUrl =
        sourceToPlay.playable.rawUrl ?? sourceToPlay.playable.url.toString();
    debugPrint('MiniPlayer: Opening: $finalUrl');

    try {
      await _player.open(Media(finalUrl), play: widget.autoPlay);
      debugPrint('MiniPlayer: Media.open() completed');
    } catch (e, stack) {
      debugPrint('MiniPlayer: EXCEPTION: $e\n$stack');
      rethrow;
    }
  }

  Future<void> _createVideoControllerForSize(Size size) async {
    if (_isCreatingController || _controller != null) {
      return;
    }
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    _isCreatingController = true;
    try {
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
        // Now that VideoController exists, start playing
        _play();
      }
    } finally {
      _isCreatingController = false;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _restreamHandle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          if (_controller == null && !_isCreatingController) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _createVideoControllerForSize(size);
            });
          }

          if (_controller == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Video(
            controller: _controller!,
            controls: MaterialVideoControls,
          );
        },
      ),
    );
  }
}
