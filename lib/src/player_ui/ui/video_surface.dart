import 'package:flutter/material.dart';

import 'package:openiptv/src/player_ui/controller/player_state.dart';

class PlayerVideoSurface extends StatelessWidget {
  const PlayerVideoSurface({super.key, required this.state, this.videoChild});

  final PlayerViewState state;
  final Widget? videoChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.black),
            child: videoChild ?? const SizedBox.shrink(),
          ),
        ),
        if (state.phase == PlayerPhase.loading || state.isBuffering)
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.isLive ? 'Loading channel…' : 'Loading video…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        if (state.phase == PlayerPhase.error && state.error != null)
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  state.error!.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
