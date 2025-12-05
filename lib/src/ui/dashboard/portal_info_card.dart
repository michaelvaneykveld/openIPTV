import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

class PortalInfoCard extends ConsumerWidget {
  final ResolvedProviderProfile profile;

  const PortalInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final summaryAsync = profile.providerDbId != null
        ? ref.watch(portalSummarySnapshotProvider(profile.providerDbId!))
        : const AsyncValue.data(null);

    return Container(
      width: 260, // Slightly wider to accommodate info
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Card(
        elevation: 2,
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, colorScheme),
              summaryAsync.when(
                data: (data) {
                  if (data == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 16),
                      _buildAccountInfo(context, data),
                      if (data.hasCounts) ...[
                        const Divider(height: 16),
                        _buildContentCounts(context, data),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Info unavailable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PORTAL INFO',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
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
        const SizedBox(height: 2),
        Text(
          profile.lockedBase.host,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (detailText != null) ...[
          const SizedBox(height: 6),
          Text(
            detailText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountInfo(BuildContext context, SummaryData data) {
    final theme = Theme.of(context);
    final fields = data.fields;

    final displayItems = <Widget>[];

    // Display all fields without limit
    for (final entry in fields.entries) {
      displayItems.add(_buildInfoRow(theme, entry.key, entry.value));
    }

    if (displayItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACCOUNT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Updated ${TimeOfDay.fromDateTime(data.fetchedAt.toLocal()).format(context)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...displayItems,
      ],
    );
  }

  Widget _buildContentCounts(BuildContext context, SummaryData data) {
    final theme = Theme.of(context);
    
    final normalizedCounts = <String, int>{};
    data.counts.forEach((key, value) {
      final normalized = _normalizeCountLabel(key);
      normalizedCounts.update(
        normalized,
        (prev) => prev + value,
        ifAbsent: () => value,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTENT',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        ...normalizedCounts.entries.map(
          (e) => _buildInfoRow(theme, e.key, e.value.toString()),
        ),
      ],
    );
  }

  String _normalizeCountLabel(String raw) {
    final lower = raw.toLowerCase();
    switch (lower) {
      case 'live':
        return 'Live';
      case 'films':
      case 'vod':
      case 'movies':
        return 'Movies';
      case 'series':
        return 'Series';
      case 'radio':
        return 'Radio';
      default:
        return raw;
    }
  }  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
