import 'package:flutter/material.dart';

import 'package:openiptv/src/player_ui/controller/player_state.dart';
import 'package:openiptv/src/player_ui/theming/player_theme.dart';

class PlayerOverlayOSD extends StatelessWidget {
  const PlayerOverlayOSD({
    super.key,
    required this.state,
    required this.onTogglePlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onZapNext,
    required this.onZapPrevious,
    required this.onShowAudioSheet,
    required this.onShowSubtitlesSheet,
  });

  final PlayerViewState state;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onZapNext;
  final VoidCallback onZapPrevious;
  final VoidCallback onShowAudioSheet;
  final VoidCallback onShowSubtitlesSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerTheme = PlayerTheme.of(context);
    return IgnorePointer(
      ignoring: false,
      child: Container(
        width: double.infinity,
        padding: playerTheme.overlayPadding,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.center,
            colors: [Colors.black87, Colors.black54, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransportRow(theme),
            const SizedBox(height: 12),
            _buildProgress(theme),
            const SizedBox(height: 12),
            _buildInfoRow(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportRow(ThemeData theme) {
    final iconColor = theme.colorScheme.onSurface;
    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: state.isPlaying ? 'Pause' : 'Play',
          iconSize: 36,
          onPressed: onTogglePlayPause,
          icon: Icon(
            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: iconColor,
          ),
        ),
        IconButton(
          tooltip: state.isLive ? 'Previous channel' : 'Rewind 10s',
          icon: Icon(
            state.isLive
                ? Icons.skip_previous_rounded
                : Icons.replay_10_rounded,
            color: iconColor,
          ),
          onPressed: state.isLive ? onZapPrevious : onSeekBackward,
        ),
        IconButton(
          tooltip: state.isLive ? 'Next channel' : 'Forward 30s',
          icon: Icon(
            state.isLive ? Icons.skip_next_rounded : Icons.forward_30_rounded,
            color: iconColor,
          ),
          onPressed: state.isLive ? onZapNext : onSeekForward,
        ),
        IconButton(
          tooltip: 'Audio tracks',
          onPressed: onShowAudioSheet,
          icon: Icon(Icons.multitrack_audio_outlined, color: iconColor),
        ),
        IconButton(
          tooltip: 'Subtitles',
          onPressed: onShowSubtitlesSheet,
          icon: Icon(Icons.closed_caption_outlined, color: iconColor),
        ),
      ],
    );
  }

  Widget _buildProgress(ThemeData theme) {
    if (state.isLive || !state.hasDuration) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'LIVE',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onError,
          ),
        ),
      );
    }
    final duration = state.duration ?? Duration.zero;
    final maxValue = duration.inMilliseconds.toDouble();
    final sliderValue = state.position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: theme.sliderTheme.copyWith(
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.2),
            thumbColor: theme.colorScheme.primary,
          ),
          child: Slider(
            min: 0,
            max: maxValue,
            value: sliderValue,
            onChanged: (_) {},
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(state.position),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme) {
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final bitrate = state.bitrateKbps == null
        ? 'Bitrate unknown'
        : '${(state.bitrateKbps! / 1000).toStringAsFixed(1)} Mbps';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(state.isLive ? 'Live channel' : 'On demand', style: textStyle),
        Text(bitrate, style: textStyle),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
