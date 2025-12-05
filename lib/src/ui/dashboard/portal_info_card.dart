import 'package:flutter/material.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

class PortalInfoCard extends StatelessWidget {
  final ResolvedProviderProfile profile;

  const PortalInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String typeLabel = '';
    switch (profile.kind) {
      case ProviderKind.stalker:
        typeLabel = 'Stalker Portal';
        break;
      case ProviderKind.xtream:
        typeLabel = 'Xtream Codes';
        break;
      case ProviderKind.m3u:
        typeLabel = 'M3U Playlist';
        break;
    }

    String? detailText;
    if (profile.kind == ProviderKind.stalker) {
      // Try to find MAC in secrets or configuration
      final mac = profile.secrets['mac'] ?? profile.record.configuration['mac'];
      if (mac != null) {
        detailText = 'MAC: $mac';
      }
    } else if (profile.kind == ProviderKind.xtream) {
      final username = profile.secrets['username'];
      if (username != null) {
        detailText = 'User: $username';
      }
    }

    return Container(
      width: 250, // Constrain width for the rail
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portal Info',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.record.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                profile.lockedBase.toString(),
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                typeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
              if (detailText != null) ...[
                const SizedBox(height: 4),
                Text(
                  detailText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
