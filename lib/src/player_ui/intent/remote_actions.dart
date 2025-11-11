import 'package:flutter/services.dart';

import 'package:openiptv/src/player_ui/controller/player_state.dart';

/// High-level intents triggered by remote or keyboard input.
enum PlayerRemoteIntent {
  togglePlayPause,
  seekForward,
  seekBackward,
  seekForwardFast,
  seekBackwardFast,
  zapNext,
  zapPrevious,
  showAudioSheet,
  showSubtitlesSheet,
  closeOverlay,
  exitPlayer,
}

/// Maps incoming [KeyEvent]s to Player intents while respecting VOD vs Live UX.
PlayerRemoteIntent? intentFromKeyEvent(
  KeyEvent event, {
  required PlayerViewState state,
}) {
  if (event is! KeyDownEvent) {
    return null;
  }
  final key = event.logicalKey;
  final isRepeat = event is KeyRepeatEvent;
  if (_kPlayPauseKeys.contains(key)) {
    return PlayerRemoteIntent.togglePlayPause;
  }
  if (key == LogicalKeyboardKey.arrowLeft) {
    if (!state.isLive && isRepeat) {
      return PlayerRemoteIntent.seekBackwardFast;
    }
    return state.isLive
        ? PlayerRemoteIntent.zapPrevious
        : PlayerRemoteIntent.seekBackward;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    if (!state.isLive && isRepeat) {
      return PlayerRemoteIntent.seekForwardFast;
    }
    return state.isLive
        ? PlayerRemoteIntent.zapNext
        : PlayerRemoteIntent.seekForward;
  }
  if (key == LogicalKeyboardKey.mediaFastForward) {
    return PlayerRemoteIntent.seekForwardFast;
  }
  if (key == LogicalKeyboardKey.mediaRewind) {
    return PlayerRemoteIntent.seekBackwardFast;
  }
  if (key == LogicalKeyboardKey.arrowUp) {
    return PlayerRemoteIntent.showAudioSheet;
  }
  if (key == LogicalKeyboardKey.arrowDown) {
    return PlayerRemoteIntent.showSubtitlesSheet;
  }
  if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
    return PlayerRemoteIntent.closeOverlay;
  }
  if (key == LogicalKeyboardKey.endCall || key == LogicalKeyboardKey.exit) {
    return PlayerRemoteIntent.exitPlayer;
  }
  return null;
}

Duration seekDeltaForIntent(PlayerRemoteIntent intent) {
  switch (intent) {
    case PlayerRemoteIntent.seekForward:
      return const Duration(seconds: 30);
    case PlayerRemoteIntent.seekBackward:
      return const Duration(seconds: -10);
    case PlayerRemoteIntent.seekForwardFast:
      return const Duration(minutes: 2);
    case PlayerRemoteIntent.seekBackwardFast:
      return const Duration(minutes: -1);
    default:
      return Duration.zero;
  }
}

final Set<LogicalKeyboardKey> _kPlayPauseKeys =
    Set<LogicalKeyboardKey>.unmodifiable(<LogicalKeyboardKey>{
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.mediaPlayPause,
    });
