import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:openiptv/src/player_ui/controller/mock_player_adapter.dart';
import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/player_ui/controller/player_state.dart';
import 'package:openiptv/src/player_ui/controller/video_player_adapter.dart';
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

  factory PlayerScreen.sample({Key? key}) {
    final sources = [
      PlayerMediaSource(
        uri: Uri.parse(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
        title: 'Big Buck Bunny',
        bitrateKbps: 5200,
        audioTracks: const [
          PlayerTrack(
            id: 'bb-en',
            label: 'English • Stereo',
            language: 'en',
            channels: '2.0',
            codec: 'AAC',
          ),
          PlayerTrack(
            id: 'bb-es',
            label: 'Spanish • Stereo',
            language: 'es',
            channels: '2.0',
            codec: 'AAC',
          ),
        ],
        textTracks: const [
          PlayerTrack(id: 'bb-en-cc', label: 'English CC', language: 'en'),
          PlayerTrack(id: 'bb-es-cc', label: 'Español', language: 'es'),
        ],
      ),
      PlayerMediaSource(
        uri: Uri.parse(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        ),
        title: 'Sintel',
        bitrateKbps: 3800,
        audioTracks: const [
          PlayerTrack(
            id: 'si-en',
            label: 'English 5.1',
            language: 'en',
            channels: '5.1',
            codec: 'AAC',
          ),
          PlayerTrack(
            id: 'si-fr',
            label: 'Français',
            language: 'fr',
            channels: '2.0',
            codec: 'AAC',
          ),
        ],
        textTracks: const [
          PlayerTrack(id: 'si-en-cc', label: 'English CC', language: 'en'),
          PlayerTrack(id: 'si-de', label: 'Deutsch', language: 'de'),
        ],
      ),
    ];
    final adapter = PlaylistVideoPlayerAdapter(
      sources: sources,
      autoPlay: true,
    );
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
  bool _wakelockEnabled = false;
  bool _isSheetOpen = false;

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
    if (_wakelockEnabled) {
      WakelockPlus.disable();
    }
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
            _syncKeepScreenOn(state);
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
                  PlayerVideoSurface(
                    state: state,
                    videoChild: _buildVideoChild(context),
                  ),
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

  Widget? _buildVideoChild(BuildContext context) {
    final adapter = widget.controller.adapter;
    if (adapter is PlayerVideoSurfaceProvider) {
      return (adapter as PlayerVideoSurfaceProvider).buildVideoSurface(context);
    }
    return null;
  }

  void _syncKeepScreenOn(PlayerViewState state) {
    final shouldEnable = state.isKeepScreenOnEnabled;
    if (_wakelockEnabled == shouldEnable) {
      return;
    }
    _wakelockEnabled = shouldEnable;
    WakelockPlus.toggle(enable: shouldEnable);
  }

  Widget _buildOverlay(PlayerViewState state) {
    final hasAudioTracks = state.audioTracks.isNotEmpty;
    final hasSubtitleTracks = state.textTracks.isNotEmpty;
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
            onShowAudioSheet: hasAudioTracks
                ? () => _showTrackPicker(context, showAudio: true)
                : null,
            onShowSubtitlesSheet: hasSubtitleTracks
                ? () => _showTrackPicker(context, showAudio: false)
                : null,
            onExitPlayer: () => Navigator.of(context).maybePop(),
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
    if (_isSheetOpen) {
      return;
    }
    _isSheetOpen = true;
    final state = widget.controller.state.value;
    widget.controller.showOverlay();
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.black87,
        isScrollControlled: true,
        builder: (sheetContext) => PlayerTrackPickerSheet(
          audioTracks: state.audioTracks,
          textTracks: state.textTracks,
          selectedAudio: state.selectedAudio,
          selectedText: state.selectedText,
          onAudioSelected: (track) {
            Navigator.of(sheetContext).pop();
            widget.controller.selectAudio(track);
          },
          onTextSelected: (track) {
            Navigator.of(sheetContext).pop();
            widget.controller.selectText(track);
          },
        ),
      );
    } finally {
      _isSheetOpen = false;
      widget.controller.showOverlay();
    }
  }

  void _handleSheetIntent(bool showAudio) {
    final state = widget.controller.state.value;
    final hasTracks = showAudio
        ? state.audioTracks.isNotEmpty
        : state.textTracks.isNotEmpty;
    if (!state.isOverlayVisible) {
      widget.controller.showOverlay();
      return;
    }
    if (!hasTracks) {
      widget.controller.reportUserInteraction();
      return;
    }
    _showTrackPicker(context, showAudio: showAudio);
  }

  void _handleBackIntent() {
    if (_isSheetOpen) {
      Navigator.of(context).maybePop();
      return;
    }
    if (widget.controller.state.value.isOverlayVisible) {
      widget.controller.hideOverlay();
      return;
    }
    Navigator.of(context).maybePop();
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
      case PlayerRemoteIntent.seekForwardFast:
      case PlayerRemoteIntent.seekBackwardFast:
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
        _handleSheetIntent(true);
        break;
      case PlayerRemoteIntent.showSubtitlesSheet:
        _handleSheetIntent(false);
        break;
      case PlayerRemoteIntent.closeOverlay:
        _handleBackIntent();
        break;
      case PlayerRemoteIntent.exitPlayer:
        Navigator.of(context).maybePop();
        break;
    }
    return true;
  }
}
