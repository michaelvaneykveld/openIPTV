import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/repositories/channel_repository.dart';
import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/providers/artwork_fetcher_provider.dart';
import 'package:openiptv/src/providers/player_library_providers.dart';

class PlayerShell extends ConsumerStatefulWidget {
  const PlayerShell({super.key, required this.profile});

  final ResolvedProviderProfile profile;

  @override
  ConsumerState<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends ConsumerState<PlayerShell> {
  bool _showSummary = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _watchCategories(widget.profile.providerDbId);
    final summaryAsync = _watchSummary(widget.profile.providerDbId);

    final isReloadingCategories = categoriesAsync.isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.record.displayName),
        actions: [
          IconButton(
            tooltip: _showSummary ? 'Hide summary' : 'Show summary',
            icon: Icon(_showSummary ? Icons.close : Icons.info_outline),
            onPressed: summaryAsync.isLoading
                ? null
                : () {
                    setState(() {
                      _showSummary = !_showSummary;
                    });
                  },
          ),
        ],
      ),
      floatingActionButton: _showSummary
          ? null
          : FloatingActionButton(
              onPressed: isReloadingCategories
                  ? null
                  : () {
                      ref.invalidate(
                        legacyCategoriesProvider(widget.profile),
                      );
                    },
              tooltip: 'Reload categories',
              child: const Icon(Icons.refresh),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _showSummary
              ? summaryAsync.when(
                  data: (data) => _SummaryView(data: data),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      _CategoriesError(message: error.toString()),
                )
              : categoriesAsync.when(
                  data: (data) =>
                      _CategoriesView(profile: widget.profile, data: data),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      _CategoriesError(message: error.toString()),
                ),
        ),
      ),
    );
  }

  AsyncValue<CategoryMap> _watchCategories(int? providerId) {
    if (providerId == null) {
      return ref.watch(legacyCategoriesProvider(widget.profile));
    }
    final dbValue = ref.watch(dbCategoriesProvider(providerId));
    final shouldFallback = dbValue.maybeWhen(
      data: (map) => map.isEmpty,
      error: (error, stackTrace) {
        return true;
      },
      orElse: () => false,
    );
    if (!shouldFallback) {
      return dbValue;
    }
    return ref.watch(legacyCategoriesProvider(widget.profile));
  }

  AsyncValue<SummaryData> _watchSummary(int? providerId) {
    if (providerId == null) {
      return ref.watch(legacySummaryProvider(widget.profile));
    }
    final dbValue = ref.watch(
      dbSummaryProvider(
        DbSummaryArgs(providerId, widget.profile.kind),
      ),
    );
    final shouldFallback = dbValue.maybeWhen(
      data: (summary) => summary.counts.isEmpty,
      error: (error, stackTrace) {
        return true;
      },
      orElse: () => false,
    );
    if (!shouldFallback) {
      return dbValue;
    }
    return ref.watch(legacySummaryProvider(widget.profile));
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.data});

  final SummaryData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = data.counts.entries
        .map((entry) => Chip(label: Text('${entry.key}: ${entry.value}')))
        .toList(growable: false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _summaryTitleForKind(data.kind),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Updated ${TimeOfDay.fromDateTime(data.fetchedAt.toLocal()).format(context)}',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 24),
                if (data.fields.isNotEmpty)
                  ...data.fields.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(flex: 2, child: Text(entry.value)),
                        ],
                      ),
                    ),
                  ),
                if (chips.isNotEmpty) ...[
                  const Divider(),
                  Wrap(spacing: 12, runSpacing: 12, children: chips),
                ],
                if (chips.isEmpty && data.fields.isEmpty)
                  const Text('No metadata available yet.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summaryTitleForKind(ProviderKind kind) {
    const labels = {
      ProviderKind.stalker: 'Stalker Portal Summary',
      ProviderKind.xtream: 'Xtream Portal Summary',
      ProviderKind.m3u: 'M3U Playlist Summary',
    };
    return labels[kind] ?? 'Provider Summary';
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView({required this.profile, required this.data});

  final ResolvedProviderProfile profile;
  final CategoryMap data;

  static final Map<ContentBucket, (String, IconData)> _bucketMeta = {
    ContentBucket.live: ('Live', Icons.live_tv),
    ContentBucket.films: ('Films', Icons.movie),
    ContentBucket.series: ('Series', Icons.video_library),
    ContentBucket.radio: ('Radio', Icons.radio),
  };

  @override
  Widget build(BuildContext context) {
    final providerId = profile.providerDbId;
    final sections = ContentBucket.values
        .where((bucket) => data[bucket]?.isNotEmpty == true)
        .toList();

    if (sections.isEmpty) {
      return const Center(
        child: Text('No categories found for this provider yet.'),
      );
    }

    final tiles = <Widget>[];
    if (providerId != null) {
      tiles.add(_EngagementPanel(profile: profile, providerId: providerId));
      tiles.add(const SizedBox(height: 12));
    }
    for (final bucket in sections) {
      tiles.add(_buildSection(context, bucket, data[bucket]!));
      tiles.add(const SizedBox(height: 12));
    }
    return ListView(children: tiles);
  }

  Widget _buildSection(
    BuildContext context,
    ContentBucket bucket,
    List<CategoryEntry> categories,
  ) {
    final theme = Theme.of(context);
    final (label, icon) = _bucketMeta[bucket]!;
    final total = categories.fold<int>(
      0,
      (previousValue, element) => previousValue + (element.count ?? 0),
    );

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(icon),
        title: Text(label, style: theme.textTheme.titleMedium),
        subtitle: total > 0 ? Text('$total items') : null,
        children: categories
            .map(
              (category) => _CategoryTile(
                profile: profile,
                bucket: bucket,
                category: category,
                icon: icon,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CategoryTile extends ConsumerStatefulWidget {
  const _CategoryTile({
    required this.profile,
    required this.bucket,
    required this.category,
    required this.icon,
  });

  final ResolvedProviderProfile profile;
  final ContentBucket bucket;
  final CategoryEntry category;
  final IconData icon;

  @override
  ConsumerState<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends ConsumerState<_CategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewAsync = _expanded
        ? ref.watch(
            categoryPreviewProvider(
              CategoryPreviewRequest(
                profile: widget.profile,
                bucket: widget.bucket,
                categoryId: widget.category.id,
              ),
            ),
          )
        : null;

    Widget? preview;
    if (_expanded && previewAsync != null) {
      preview = previewAsync.when(
        data: (items) => _CategoryPreviewList(items: items, icon: widget.icon),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(widget.icon, color: theme.colorScheme.secondary),
      title: Text(widget.category.name),
      trailing: Text(
        widget.category.count?.toString() ?? '--',
        style: theme.textTheme.labelLarge,
      ),
      onExpansionChanged: (value) {
        setState(() {
          _expanded = value;
        });
      },
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      children: preview == null ? const [] : [preview],
    );
  }
}

class _EngagementPanel extends ConsumerWidget {
  const _EngagementPanel({
    required this.profile,
    required this.providerId,
  });

  final ResolvedProviderProfile profile;
  final int providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(providerFavoritesProvider(providerId));
    final recentAsync = ref.watch(providerRecentPlaybackProvider(providerId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Library', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Favorites', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                favoritesAsync.when(
                  data: (favorites) {
                    final visible = favorites.take(12).toList();
                    if (visible.isEmpty) {
                      return const Text('Mark channels as favorites to see them here.');
                    }
                    return SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: visible.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final channel = visible[index];
                          return _FavoriteChannelChip(channel: channel);
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (error, stackTrace) => Text(
                    'Unable to load favorites: $error',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Recently watched', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                recentAsync.when(
                  data: (recent) {
                    final visible = recent
                        .where((entry) => entry.channel != null)
                        .take(5)
                        .toList();
                    if (visible.isEmpty) {
                      return const Text('Watch a channel to build your history.');
                    }
                    return Column(
                      children: [
                        for (final entry in visible)
                          _RecentPlaybackTile(entry: entry),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (error, stackTrace) => Text(
                    'Unable to load history: $error',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteChannelChip extends ConsumerWidget {
  const _FavoriteChannelChip({required this.channel});

  final ChannelWithFlags channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ArtworkAvatar(
          url: channel.channel.logoUrl ?? '',
          fallbackIcon: Icons.live_tv,
          size: 56,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            channel.channel.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _RecentPlaybackTile extends ConsumerWidget {
  const _RecentPlaybackTile({required this.entry});

  final RecentChannelPlayback entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = entry.channel;
    if (channel == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final localization = MaterialLocalizations.of(context);
    final updated = entry.history.updatedAt.toLocal();
    final subtitle =
        '${localization.formatShortDate(updated)} ${localization.formatTimeOfDay(TimeOfDay.fromDateTime(updated))}';
    final progress = entry.progress;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _ArtworkAvatar(
        url: channel.logoUrl ?? '',
        fallbackIcon: channel.isRadio ? Icons.radio : Icons.live_tv,
        size: 40,
      ),
      title: Text(channel.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 4,
                ),
              ),
            ),
        ],
      ),
      trailing: entry.isFavorite
          ? Icon(Icons.star, color: theme.colorScheme.secondary)
          : null,
    );
  }
}

class _CategoryPreviewList extends ConsumerWidget {
  const _CategoryPreviewList({required this.items, required this.icon});

  final List<CategoryPreviewItem> items;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No preview items yet.'),
      );
    }

    return Column(
      children: [
        for (final item in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: _ArtworkAvatar(
              url: item.artUri ?? '',
              fallbackIcon: icon,
              size: 40,
            ),
            title: Text(item.title),
            subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
          ),
      ],
    );
  }
}

class _ArtworkAvatar extends ConsumerWidget {
  const _ArtworkAvatar({
    required this.url,
    required this.fallbackIcon,
    this.size = 36,
  });

  final String url;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (url.isEmpty) {
      return _fallback(context);
    }
    final imageAsync = ref.watch(artworkImageProvider(url));
    return imageAsync.when(
      data: (Uint8List? bytes) {
        if (bytes == null || bytes.isEmpty) {
          return _fallback(context);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 4),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(context),
          ),
        );
      },
      loading: () => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 4),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        fallbackIcon,
        size: size * 0.6,
        color: theme.colorScheme.secondary,
      ),
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            'Unable to fetch categories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
