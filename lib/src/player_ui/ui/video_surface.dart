import 'package:flutter/material.dart';

import 'package:openiptv/src/player_ui/controller/player_state.dart';

/// Placeholder surface. Later this will host the platform-specific texture.
class PlayerVideoSurface extends StatelessWidget {
  const PlayerVideoSurface({super.key, required this.state});

  final PlayerViewState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: AnimatedOpacity(
        opacity: state.phase == PlayerPhase.loading ? 1 : 0,
        duration: const Duration(milliseconds: 300),
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
    );
  }
}
