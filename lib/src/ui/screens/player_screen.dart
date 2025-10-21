import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/application/services/recording_service.dart';
import 'package:openiptv/src/core/models/channel.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _controller;
  String? _errorMessage;
  bool _isRecording = false;
  int? _activeRecordingId;

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
        actions: [
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.fiber_manual_record,
              color: _isRecording ? Colors.redAccent : Colors.red,
            ),
            onPressed: () => _toggleRecording(context),
          ),
        ],
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

  Future<void> _toggleRecording(BuildContext context) async {
    final portalId = await ref.read(portalIdProvider.future);
    if (portalId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active portal to record from.')),
      );
      return;
    }

    final manager = ref.read(recordingManagerProvider);
    if (_isRecording) {
      if (_activeRecordingId != null) {
        await manager.stopRecording(_activeRecordingId!);
      }
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _activeRecordingId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recording stopped.')));
    } else {
      final recordingId = await manager.startRecordingNow(
        channel: widget.channel,
        portalId: portalId,
      );
      if (recordingId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start recording.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _activeRecordingId = recordingId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording started for ${widget.channel.name}.'),
        ),
      );
    }
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
