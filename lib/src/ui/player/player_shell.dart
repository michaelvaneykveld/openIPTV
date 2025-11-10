import 'dart:async';
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
import 'package:openiptv/src/providers/provider_import_service.dart';
import 'package:openiptv/src/ui/widgets/import_progress_banner.dart';

class PlayerShell extends ConsumerStatefulWidget {
  const PlayerShell({super.key, required this.profile});

  final ResolvedProviderProfile profile;

  @override
  ConsumerState<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends ConsumerState<PlayerShell> {
  bool _showSummary = false;
  bool _importScheduled = false;
  bool _isRefreshing = false;
  ProviderImportEvent? _importEvent;
  StreamSubscription<ProviderImportEvent>? _importSubscription;
  bool _isCancellingImport = false;

  @override
  void initState() {
    super.initState();
    _maybePrimeProviderImport();
    _subscribeToImportProgress();
  }

  @override
  void didUpdateWidget(covariant PlayerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.providerDbId != widget.profile.providerDbId) {
      _importScheduled = false;
      _maybePrimeProviderImport();
      _subscribeToImportProgress();
    }
  }

  @override
  void dispose() {
    _importSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _watchCategories(widget.profile.providerDbId);
    final summaryAsync = _watchSummary(widget.profile.providerDbId);
    final progressBanner = _buildImportProgressBanner();

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
              onPressed: isReloadingCategories || _isRefreshing
                  ? null
                  : _handleRefresh,
              tooltip: 'Reload categories',
              child: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
            ),
      body: Column(
        children: [
          if (progressBanner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: progressBanner,
            ),
          Expanded(
            child: Padding(
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
          ),
        ],
      ),
    );
  }

  AsyncValue<CategoryMap> _watchCategories(int? providerId) {
    if (providerId == null) {
      return ref.watch(legacyCategoriesProvider(widget.profile));
    }
    return ref.watch(dbCategoriesProvider(providerId));
  }

  AsyncValue<SummaryData> _watchSummary(int? providerId) {
    final legacy = ref.watch(legacySummaryProvider(widget.profile));
    if (providerId == null) {
      return legacy;
    }
    final dbCounts = ref.watch(
      dbSummaryProvider(DbSummaryArgs(providerId, widget.profile.kind)),
    );
    if (legacy.isLoading || dbCounts.isLoading) {
      return const AsyncValue.loading();
    }
    if (legacy.hasError) {
      return AsyncValue.error(
        legacy.error!,
        legacy.stackTrace ?? StackTrace.current,
      );
    }
    if (dbCounts.hasError) {
      return AsyncValue.error(
        dbCounts.error!,
        dbCounts.stackTrace ?? StackTrace.current,
      );
    }
    final legacyData = legacy.value;
    if (legacyData == null) {
      return const AsyncValue.loading();
    }
    final dbCountsMap = dbCounts.value?.counts ?? const <String, int>{};
    final mergedCounts = Map<String, int>.from(legacyData.counts);
    dbCountsMap.forEach((key, value) {
      if (value > 0) {
        mergedCounts[key] = value;
      }
    });
    final merged = SummaryData(
      kind: legacyData.kind,
      fields: legacyData.fields,
      counts: mergedCounts,
      fetchedAt: legacyData.fetchedAt,
    );
    return AsyncValue.data(merged);
  }

  void _maybePrimeProviderImport() {
    final providerId = widget.profile.providerDbId;
    if (providerId == null || _importScheduled) {
      return;
    }
    _importScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final importService = ref.read(providerImportServiceProvider);
      importService.runInitialImport(widget.profile);
    });
  }

  void _subscribeToImportProgress() {
    _importSubscription?.cancel();
    final providerId = widget.profile.providerDbId;
    if (providerId == null) {
      setState(() {
        _importEvent = null;
      });
      return;
    }
    final service = ref.read(providerImportServiceProvider);
    _importSubscription = service.watchProgress(providerId).listen((event) {
      if (!mounted) return;
      if (event is ProviderImportProgressEvent) {
        setState(() => _importEvent = event);
      } else {
        setState(() => _importEvent = null);
      }
    });
  }

  Future<void> _handleCancelImport() async {
    if (_isCancellingImport) return;
    final providerId = widget.profile.providerDbId;
    if (providerId == null) return;
    setState(() => _isCancellingImport = true);
    try {
      await ref.read(providerImportServiceProvider).cancelImport(providerId);
    } finally {
      if (mounted) {
        setState(() {
          _isCancellingImport = false;
        });
      }
    }
  }

  Widget? _buildImportProgressBanner() {
    final event = _importEvent;
    if (event is! ProviderImportProgressEvent) {
      return null;
    }
    final phase = event.phase;
    if (_isTerminalPhase(phase)) {
      return null;
    }
    final message = _describePhase(event);
    return ImportProgressBanner(
      message: message,
      showCancel: !_isCancellingImport,
      onCancel: _isCancellingImport ? null : _handleCancelImport,
    );
  }

  bool _isTerminalPhase(String phase) {
    switch (phase) {
      case 'completed':
      case 'error':
      case 'cancelled':
        return true;
    }
    return false;
  }

  String _describePhase(ProviderImportProgressEvent event) {
    switch (event.phase) {
      case 'started':
        return 'Preparing provider import...';
      case 'xtream.fetch':
        return 'Fetching Xtream catalog...';
      case 'm3u.fetch':
        return 'Downloading playlist...';
      case 'stalker.session':
        return 'Authenticating with Stalker portal...';
      case 'stalker.categories.fetch':
        return 'Discovering categories...';
      case 'stalker.categories.ready':
        final live = event.metadata['live'];
        final vod = event.metadata['vod'];
        final series = event.metadata['series'];
        return 'Categories ready '
            '(live: $live, vod: $vod, series: $series)...';
      case 'stalker.items.ready':
        final live = event.metadata['live'];
        final vod = event.metadata['vod'];
        final series = event.metadata['series'];
        return 'Ingesting items '
            '(live: $live, vod: $vod, series: $series)...';
      default:
        return 'Importing provider data...';
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) {
      return;
    }
    setState(() => _isRefreshing = true);
    try {
      final providerId = widget.profile.providerDbId;
      if (providerId == null) {
        ref
          ..invalidate(legacyCategoriesProvider(widget.profile))
          ..invalidate(legacySummaryProvider(widget.profile));
        return;
      }
      final importService = ref.read(providerImportServiceProvider);
      await importService.runInitialImport(
        widget.profile,
        forceRefresh: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.data});

  final SummaryData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedCounts = <String, int>{};
    data.counts.forEach((key, value) {
      final normalized = _normalizeCountLabel(key);
      normalizedCounts.update(normalized, (prev) => prev + value,
          ifAbsent: () => value);
    });
    final chips = normalizedCounts.entries
        .map(
          (entry) => Chip(
            label: Text('${entry.key}: ${entry.value}'),
          ),
        )
        .toList(growable: false);

    if (!data.hasFields && chips.isEmpty) {
      return const _SyncingPlaceholder(message: 'Syncing provider summary...');
    }

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
        if (raw.isEmpty) return raw;
        return raw[0].toUpperCase() + raw.substring(1);
    }
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
      if (profile.providerDbId == null) {
        return const Center(
          child: Text('No categories found for this provider yet.'),
        );
      }
      return const _SyncingPlaceholder(message: 'Syncing provider library...');
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
  int? _resolvedCount;

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
                providerKey: widget.category.providerKey,
              ),
            ),
          )
        : null;

    Widget? preview;
    if (_expanded && previewAsync != null) {
      preview = previewAsync.when(
        data: (result) {
          final resolved = result.totalItems ?? result.items.length;
          if (_resolvedCount != resolved) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _resolvedCount = resolved);
            });
          }
          return _CategoryPreviewList(result: result, icon: widget.icon);
        },
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
        (_resolvedCount ?? widget.category.count)?.toString() ?? '--',
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
  const _EngagementPanel({required this.profile, required this.providerId});

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
                      return const Text(
                        'Mark channels as favorites to see them here.',
                      );
                    }
                    return SizedBox(
                      height: 96,
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
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
                      return const Text(
                        'Watch a channel to build your history.',
                      );
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
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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

class _CategoryPreviewList extends StatefulWidget {
  const _CategoryPreviewList({required this.result, required this.icon});

  final CategoryPreviewResult result;
  final IconData icon;

  @override
  State<_CategoryPreviewList> createState() => _CategoryPreviewListState();
}

class _CategoryPreviewListState extends State<_CategoryPreviewList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.result.items;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No preview items yet.'),
      );
    }

    final baseHeight = items.length * 60.0;
    final height = baseHeight.clamp(120.0, 360.0);

    return SizedBox(
      height: height,
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _controller,
          primary: false,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: _ArtworkAvatar(
                url: item.artUri ?? '',
                fallbackIcon: widget.icon,
                size: 40,
              ),
              title: Text(item.title),
              subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
            );
          },
        ),
      ),
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
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Unable to fetch categories',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncingPlaceholder extends StatelessWidget {
  const _SyncingPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
