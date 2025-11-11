import 'package:flutter/material.dart';

import 'package:openiptv/src/player_ui/controller/mock_player_adapter.dart';
import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_state.dart';
import 'package:openiptv/src/player_ui/intent/remote_actions.dart';
import 'package:openiptv/src/player_ui/theming/player_theme.dart';
import 'package:openiptv/src/player_ui/ui/error_toast.dart';
import 'package:openiptv/src/player_ui/ui/overlay_osd.dart';
import 'package:openiptv/src/player_ui/ui/track_picker_sheet.dart';
import 'package:openiptv/src/player_ui/ui/video_surface.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
    this.ownsController = false,
  });

  factory PlayerScreen.mock({Key? key}) {
    final adapter = MockPlayerAdapter();
    final controller = PlayerController(adapter: adapter);
    return PlayerScreen(key: key, controller: controller, ownsController: true);
  }

  final PlayerController controller;
  final bool ownsController;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'PlayerScreenFocus');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.ownsController) {
      widget.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerTheme = PlayerThemeData(
      autoHideDelay: widget.controller.overlayAutoHideDelay,
    );
    return PlayerTheme(
      data: playerTheme,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          final handled = _handleKeyEvent(event);
          return handled ? KeyEventResult.handled : KeyEventResult.ignored;
        },
        child: ValueListenableBuilder<PlayerViewState>(
          valueListenable: widget.controller.state,
          builder: (context, state, _) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.controller.reportUserInteraction();
                widget.controller.showOverlay();
              },
              onPanDown: (_) => widget.controller.reportUserInteraction(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlayerVideoSurface(state: state),
                  _buildOverlay(state),
                  _buildErrorToast(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverlay(PlayerViewState state) {
    return IgnorePointer(
      ignoring: !state.isOverlayVisible,
      child: AnimatedOpacity(
        opacity: state.isOverlayVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: PlayerOverlayOSD(
            state: state,
            onTogglePlayPause: widget.controller.togglePlayPause,
            onSeekForward: () =>
                widget.controller.seekRelative(const Duration(seconds: 30)),
            onSeekBackward: () =>
                widget.controller.seekRelative(const Duration(seconds: -10)),
            onZapNext: widget.controller.zapNext,
            onZapPrevious: widget.controller.zapPrevious,
            onShowAudioSheet: () => _showTrackPicker(context, showAudio: true),
            onShowSubtitlesSheet: () =>
                _showTrackPicker(context, showAudio: false),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorToast(PlayerViewState state) {
    if (!state.showErrorToast || state.error == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: PlayerErrorToast(
          error: state.error!,
          onRetry: widget.controller.play,
        ),
      ),
    );
  }

  Future<void> _showTrackPicker(
    BuildContext context, {
    required bool showAudio,
  }) async {
    final state = widget.controller.state.value;
    widget.controller.showOverlay();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (context) => PlayerTrackPickerSheet(
        audioTracks: state.audioTracks,
        textTracks: state.textTracks,
        selectedAudio: state.selectedAudio,
        selectedText: state.selectedText,
        onAudioSelected: (track) {
          Navigator.of(context).pop();
          widget.controller.selectAudio(track);
        },
        onTextSelected: (track) {
          Navigator.of(context).pop();
          widget.controller.selectText(track);
        },
      ),
    );
  }

  bool _handleKeyEvent(KeyEvent event) {
    final state = widget.controller.state.value;
    final intent = intentFromKeyEvent(event, state: state);
    if (intent == null) {
      return false;
    }
    switch (intent) {
      case PlayerRemoteIntent.togglePlayPause:
        widget.controller.togglePlayPause();
        break;
      case PlayerRemoteIntent.seekForward:
      case PlayerRemoteIntent.seekBackward:
        final delta = seekDeltaForIntent(intent);
        widget.controller.seekRelative(delta);
        break;
      case PlayerRemoteIntent.zapNext:
        widget.controller.zapNext();
        break;
      case PlayerRemoteIntent.zapPrevious:
        widget.controller.zapPrevious();
        break;
      case PlayerRemoteIntent.showAudioSheet:
        _showTrackPicker(context, showAudio: true);
        break;
      case PlayerRemoteIntent.showSubtitlesSheet:
        _showTrackPicker(context, showAudio: false);
        break;
      case PlayerRemoteIntent.closeOverlay:
        widget.controller.hideOverlay();
        break;
      case PlayerRemoteIntent.exitPlayer:
        Navigator.of(context).maybePop();
        break;
    }
    return true;
  }
}
