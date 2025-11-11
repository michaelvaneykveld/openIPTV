import 'package:flutter/material.dart';

import 'package:openiptv/src/player_ui/theming/player_theme.dart';

Decoration buildPlayerFocusDecoration(
  BuildContext context, {
  required bool focused,
}) {
  final theme = Theme.of(context);
  final playerTheme = PlayerTheme.of(context);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(playerTheme.focusBorderRadius),
    border: focused
        ? Border.all(
            color: theme.colorScheme.onSurface,
            width: playerTheme.focusBorderWidth,
          )
        : null,
    color: focused
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : Colors.transparent,
  );
}
