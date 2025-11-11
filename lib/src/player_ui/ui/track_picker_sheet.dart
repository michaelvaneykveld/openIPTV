import 'package:flutter/material.dart';

import 'package:openiptv/src/player_ui/controller/player_state.dart';

class PlayerTrackPickerSheet extends StatelessWidget {
  const PlayerTrackPickerSheet({
    super.key,
    required this.audioTracks,
    required this.textTracks,
    required this.selectedAudio,
    required this.selectedText,
    required this.onAudioSelected,
    required this.onTextSelected,
  });

  final List<PlayerTrack> audioTracks;
  final List<PlayerTrack> textTracks;
  final PlayerTrack? selectedAudio;
  final PlayerTrack? selectedText;
  final ValueChanged<PlayerTrack> onAudioSelected;
  final ValueChanged<PlayerTrack?> onTextSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyLarge!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Audio', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (audioTracks.isEmpty)
                Text(
                  'No audio tracks exposed by backend',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...audioTracks.map(
                  (track) => RadioListTile<PlayerTrack>(
                    value: track,
                    groupValue: selectedAudio,
                    onChanged: (value) {
                      if (value != null) {
                        onAudioSelected(value);
                      }
                    },
                    title: Text(track.label),
                    subtitle: Text(
                      [
                        if (track.language != null)
                          track.language!.toUpperCase(),
                        if (track.channels != null) track.channels!,
                        if (track.codec != null) track.codec!,
                      ].join(' • '),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Subtitles', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              RadioListTile<PlayerTrack?>(
                value: null,
                groupValue: selectedText,
                onChanged: onTextSelected,
                title: const Text('Off'),
              ),
              if (textTracks.isEmpty)
                Text(
                  'No subtitle tracks available',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...textTracks.map(
                  (track) => RadioListTile<PlayerTrack?>(
                    value: track,
                    groupValue: selectedText,
                    onChanged: onTextSelected,
                    title: Text(track.label),
                    subtitle: track.language == null
                        ? null
                        : Text(track.language!.toUpperCase()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
