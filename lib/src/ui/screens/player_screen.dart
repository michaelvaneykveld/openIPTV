import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:openiptv/src/core/models/channel.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name),
      ),
      body: Center(
        child: _errorMessage != null
            ? Text(_errorMessage!)
            : (_controller != null && _controller!.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : const CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final streamUrl = _resolveStreamUrl(widget.channel);
    if (streamUrl == null) {
      setState(() {
        _errorMessage = 'Geen stream-URL beschikbaar voor dit kanaal.';
      });
      return;
    }

    final parsedUri = Uri.tryParse(streamUrl);
    if (parsedUri == null) {
      setState(() {
        _errorMessage = 'Ongeldige stream-URL: $streamUrl';
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(parsedUri);
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.play();
      setState(() {
        _controller = controller;
      });
    } catch (error) {
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kan stream niet afspelen: $error';
      });
    }
  }

  String? _resolveStreamUrl(Channel channel) {
    if (channel.streamUrl != null && channel.streamUrl!.isNotEmpty) {
      return channel.streamUrl;
    }
    if (channel.cmd != null && channel.cmd!.isNotEmpty) {
      return channel.cmd;
    }
    final cmds = channel.cmds ?? [];
    for (final cmd in cmds) {
      if (cmd.url != null && cmd.url!.isNotEmpty) {
        return cmd.url;
      }
    }
    return null;
  }
}
