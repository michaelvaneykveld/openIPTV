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
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _play();
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
    await _player.open(
      Media(url, httpHeaders: playable.headers),
      play: widget.autoPlay,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Video(controller: _controller, controls: MaterialVideoControls),
    );
  }
}
