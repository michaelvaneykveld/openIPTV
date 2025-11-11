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
                  (track) => _TrackOptionTile(
                    title: track.label,
                    subtitle: [
                      if (track.language != null) track.language!.toUpperCase(),
                      if (track.channels != null) track.channels!,
                      if (track.codec != null) track.codec!,
                    ].where((segment) => segment.isNotEmpty).join(' • '),
                    selected: selectedAudio?.id == track.id,
                    onTap: () => onAudioSelected(track),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Subtitles', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _TrackOptionTile(
                title: 'Off',
                selected: selectedText == null,
                onTap: () => onTextSelected(null),
              ),
              if (textTracks.isEmpty)
                Text(
                  'No subtitle tracks available',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...textTracks.map(
                  (track) => _TrackOptionTile(
                    title: track.label,
                    subtitle: track.language?.toUpperCase(),
                    selected: selectedText?.id == track.id,
                    onTap: () => onTextSelected(track),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackOptionTile extends StatelessWidget {
  const _TrackOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      title: Text(title),
      subtitle: subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}
