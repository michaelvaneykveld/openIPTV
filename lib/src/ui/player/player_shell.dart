import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/repositories/channel_repository.dart';
import 'package:openiptv/data/repositories/vod_repository.dart';
import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_vod_service.dart';

import 'package:openiptv/src/providers/artwork_fetcher_provider.dart';
import 'package:openiptv/src/providers/player_library_providers.dart';
import 'package:openiptv/src/providers/provider_import_service.dart';
import 'package:openiptv/src/playback/ffmpeg_restreamer.dart';
import 'package:openiptv/src/playback/playable.dart';
import 'package:openiptv/src/playback/playable_resolver.dart';
import 'package:openiptv/src/ui/widgets/import_progress_banner.dart';
import 'package:openiptv/src/player_ui/controller/lazy_media_kit_adapter.dart';
import 'package:openiptv/src/player_ui/controller/lazy_playback_models.dart';
import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/player_ui/controller/video_player_adapter.dart';
import 'package:openiptv/src/player_ui/controller/media_kit_playlist_adapter.dart';
import 'package:openiptv/src/player_ui/ui/player_screen.dart';
import 'package:openiptv/src/playback/windows_playback_policy.dart';
import 'package:openiptv/src/utils/playback_logger.dart';

// Helper class to hold season data for UI display
class _UiSeasonData {
  _UiSeasonData({
    required this.id,
    required this.seriesId,
    required this.seasonNumber,
    required this.name,
    this.stalkerSeasonId,
  });

  factory _UiSeasonData.fromDb(SeasonRecord record) {
    return _UiSeasonData(
      id: record.id,
      seriesId: record.seriesId,
      seasonNumber: record.seasonNumber,
      name: record.name ?? 'Season ${record.seasonNumber}',
    );
  }

  factory _UiSeasonData.fromStalker(
    StalkerSeason stalker,
    int seriesId,
    int index,
  ) {
    return _UiSeasonData(
      id: index,
      seriesId: seriesId,
      seasonNumber: stalker.seasonNumber ?? index + 1,
      name: stalker.name,
      stalkerSeasonId: stalker.id,
    );
  }

  final int id;
  final int seriesId;
  final int seasonNumber;
  final String name;
  final String? stalkerSeasonId; // Set for Stalker providers

  bool get isStalker => stalkerSeasonId != null;
}

class PlayerShell extends ConsumerStatefulWidget {
  const PlayerShell({super.key, required this.profile});

  final ResolvedProviderProfile profile;

  @override
  ConsumerState<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends ConsumerState<PlayerShell>
    with _PlayerPlaybackMixin<PlayerShell> {
  bool _showSummary = false;
  bool _importScheduled = false;
  bool _isRefreshing = false;
  ProviderImportEvent? _importEvent;
  StreamSubscription<ProviderImportEvent>? _importSubscription;
  bool _isCancellingImport = false;
  late PlayableResolver _playableResolver;

  @override
  PlayableResolver get playableResolver => _playableResolver;

  @override
  void initState() {
    super.initState();
    _playableResolver = PlayableResolver(widget.profile);
    _maybePrimeProviderImport();
    _subscribeToImportProgress();
  }

  @override
  void didUpdateWidget(covariant PlayerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _playableResolver = PlayableResolver(widget.profile);
    }
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
            tooltip: 'Play channels',
            icon: const Icon(Icons.smart_display_outlined),
            onPressed: _openProviderPlayer,
          ),
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
                        data: (data) => _CategoriesView(
                          profile: widget.profile,
                          data: data,
                        ),
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
      await importService.runInitialImport(widget.profile, forceRefresh: true);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _openProviderPlayer() async {
    final providerId = widget.profile.providerDbId;
    if (providerId == null) {
      _showSnack('Sync this provider locally to enable playback.');
      return;
    }
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var dialogVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ).whenComplete(() => dialogVisible = false),
    );
    try {
      final repo = ref.read(channelRepositoryProvider);
      final page = await repo.fetchChannelPage(
        providerId: providerId,
        limit: 200,
      );
      if (!mounted) {
        return;
      }
      final channels = page.items.map((entry) => entry.channel).toList();
      bool success = false;
      if (_shouldUseLazyPlayback(context)) {
        final lazyEntries = _buildLazyChannelEntries(channels);
        if (!mounted) {
          return;
        }
        success = await _pushLazyPlaylist(
          context: context,
          entries: lazyEntries,
          initialIndex: 0,
        );
      } else {
        final playlistEntries = await _resolveChannelSources(channels);
        if (!mounted) {
          return;
        }
        success = await _pushMediaPlaylist(
          context: context,
          sources: playlistEntries.map((entry) => entry.source).toList(),
          initialIndex: 0,
        );
      }
      if (!success) {
        _showSnack('No playable channels yet. Try refreshing the import.');
      }
    } catch (error) {
      _showSnack('Unable to load channels: $error');
    } finally {
      if (dialogVisible && rootNavigator.canPop()) {
        rootNavigator.pop();
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
      normalizedCounts.update(
        normalized,
        (prev) => prev + value,
        ifAbsent: () => value,
      );
    });
    final chips = normalizedCounts.entries
        .map((entry) => Chip(label: Text('${entry.key}: ${entry.value}')))
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
          return _CategoryPreviewList(
            profile: widget.profile,
            bucket: widget.bucket,
            category: widget.category,
            result: result,
            icon: widget.icon,
          );
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _launch(context, ref),
      child: Column(
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
      ),
    );
  }

  Future<void> _launch(BuildContext context, WidgetRef ref) async {
    final state = context.findAncestorStateOfType<_PlayerShellState>();
    await state?._launchSingleChannel(channel.channel);
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
      onTap: () => _launch(context, ref, channel),
    );
  }

  Future<void> _launch(
    BuildContext context,
    WidgetRef ref,
    ChannelRecord channel,
  ) async {
    final state = context.findAncestorStateOfType<_PlayerShellState>();
    await state?._launchSingleChannel(channel);
  }
}

class _CategoryPreviewList extends ConsumerStatefulWidget {
  const _CategoryPreviewList({
    required this.profile,
    required this.bucket,
    required this.category,
    required this.result,
    required this.icon,
  });

  final ResolvedProviderProfile profile;
  final ContentBucket bucket;
  final CategoryEntry category;
  final CategoryPreviewResult result;
  final IconData icon;

  @override
  ConsumerState<_CategoryPreviewList> createState() =>
      _CategoryPreviewListState();
}

class _CategoryPreviewListState extends ConsumerState<_CategoryPreviewList>
    with _PlayerPlaybackMixin<_CategoryPreviewList> {
  late final ScrollController _controller;
  late PlayableResolver _playableResolver;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _playableResolver = PlayableResolver(widget.profile);
  }

  @override
  void didUpdateWidget(covariant _CategoryPreviewList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _playableResolver = PlayableResolver(widget.profile);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  PlayableResolver get playableResolver => _playableResolver;

  @override
  Widget build(BuildContext context) {
    final items = widget.result.items;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No preview items yet.'),
      );
    }

    if (widget.bucket == ContentBucket.series) {
      return _buildSeriesHierarchy(items);
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
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => _handlePlay(item),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeriesHierarchy(List<CategoryPreviewItem> items) {
    final baseHeight = items.length * 60.0;
    final height = baseHeight.clamp(120.0, 480.0);

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
            return _ExpandableSeriesItem(
              series: item,
              icon: widget.icon,
              profile: widget.profile,
              playableResolver: playableResolver,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handlePlay(CategoryPreviewItem item) async {
    PlaybackLogger.userAction(
      'category-item-clicked',
      extra: {
        'bucket': widget.bucket.name,
        'itemId': item.id,
        'itemTitle': item.title,
      },
    );
    final providerId = widget.profile.providerDbId;
    if (providerId == null) {
      final success = await _playPreviewItemsDirect(item);
      if (!success) {
        _showSnack('No playable streams in this category yet.');
      }
      return;
    }
    final categoryId = int.tryParse(widget.category.id);
    if (categoryId == null) {
      PlaybackLogger.userAction(
        'invalid-category-id',
        extra: {'categoryIdStr': widget.category.id},
      );
      _showSnack('Unable to determine category id for playback.');
      return;
    }
    await _withLoadingOverlay(() async {
      bool success = false;
      switch (widget.bucket) {
        case ContentBucket.live:
        case ContentBucket.radio:
          success = await _playChannels(
            providerId: providerId,
            categoryId: categoryId,
            item: item,
          );
          break;
        case ContentBucket.films:
          PlaybackLogger.userAction(
            'starting-movie-playback',
            extra: {
              'providerId': providerId,
              'categoryId': categoryId,
              'itemId': item.id,
            },
          );
          success = await _playMovies(
            providerId: providerId,
            categoryId: categoryId,
            item: item,
          );
          break;
        case ContentBucket.series:
          success = await _playSeries(
            providerId: providerId,
            categoryId: categoryId,
            item: item,
          );
          break;
      }
      if (!success) {
        PlaybackLogger.userAction(
          'playback-failed',
          extra: {'bucket': widget.bucket.name, 'itemId': item.id},
        );
        _showSnack('No playable streams in this category yet.');
      }
    });
  }

  Future<void> _withLoadingOverlay(Future<void> Function() action) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var dialogVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ).whenComplete(() => dialogVisible = false),
    );
    try {
      await action();
    } catch (error, _) {
      PlaybackLogger.videoError(
        'playback-exception',
        description: 'Exception during playback: $error',
        error: error,
      );
      _showSnack('Unable to load category: $error');
    } finally {
      if (dialogVisible && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }
  }

  Future<bool> _playChannels({
    required int providerId,
    required int categoryId,
    required CategoryPreviewItem item,
  }) async {
    final repo = ref.read(channelRepositoryProvider);
    final channels = await repo.fetchChannelsForCategory(categoryId);
    if (!mounted) {
      return false;
    }
    if (channels.isEmpty) {
      return false;
    }
    if (_shouldUseLazyPlayback(context)) {
      final lazyEntries = _buildLazyChannelEntries(channels);
      if (!mounted) {
        return false;
      }
      final initialIndex = _initialIndexForRecords<ChannelRecord>(
        channels,
        int.tryParse(item.id),
        (channel) => channel.id,
      );
      return _pushLazyPlaylist(
        context: context,
        entries: lazyEntries,
        initialIndex: initialIndex,
      );
    }
    final playlist = await _resolveChannelSources(channels);
    if (!mounted || playlist.isEmpty) {
      return false;
    }
    final initialIndex = _initialIndexFor<int>(playlist, int.tryParse(item.id));
    return _pushMediaPlaylist(
      context: context,
      sources: playlist.map((entry) => entry.source).toList(growable: false),
      initialIndex: initialIndex,
    );
  }

  Future<bool> _playMovies({
    required int providerId,
    required int categoryId,
    required CategoryPreviewItem item,
  }) async {
    PlaybackLogger.userAction(
      'fetch-movies-for-category',
      extra: {'providerId': providerId, 'categoryId': categoryId},
    );
    final vodRepo = ref.read(vodRepositoryProvider);
    final movies = await vodRepo.listMovies(providerId, categoryId: categoryId);
    PlaybackLogger.userAction(
      'movies-fetched',
      extra: {'count': movies.length, 'categoryId': categoryId},
    );
    if (!mounted) {
      return false;
    }
    if (movies.isEmpty) {
      PlaybackLogger.userAction(
        'no-movies-in-category',
        extra: {'categoryId': categoryId, 'fallingBackToPreview': true},
      );
      // Fall back to playing preview items directly when database is empty
      return _playPreviewItemsDirect(item);
    }
    if (_shouldUseLazyPlayback(context)) {
      final lazyEntries = _buildLazyMovieEntries(movies);
      if (!mounted) {
        return false;
      }
      final tappedId = int.tryParse(item.id);
      final initialIndex = _initialIndexForRecords<MovieRecord>(
        movies,
        tappedId,
        (movie) => movie.id,
      );
      PlaybackLogger.userAction(
        'launching-lazy-movie-playlist',
        extra: {
          'movieCount': movies.length,
          'initialIndex': initialIndex,
          'tappedId': tappedId,
        },
      );
      return _pushLazyPlaylist(
        context: context,
        entries: lazyEntries,
        initialIndex: initialIndex,
      );
    }
    final playlist = await _resolveMovieSources(movies);
    if (!mounted || playlist.isEmpty) {
      PlaybackLogger.userAction(
        'no-resolvable-movies',
        extra: {'totalMovies': movies.length, 'resolved': playlist.length},
      );
      return false;
    }
    final tappedId = int.tryParse(item.id);
    final initialIndex = _initialIndexFor<int>(playlist, tappedId);
    return _pushMediaPlaylist(
      context: context,
      sources: playlist.map((entry) => entry.source).toList(growable: false),
      initialIndex: initialIndex,
    );
  }

  Future<bool> _playSeries({
    required int providerId,
    required int categoryId,
    required CategoryPreviewItem item,
  }) async {
    final tappedSeriesId = int.tryParse(item.id);
    if (tappedSeriesId == null) {
      _showSnack('Unable to load series details.');
      return false;
    }

    final vodRepo = ref.read(vodRepositoryProvider);
    final seasons = await vodRepo.listSeasons(tappedSeriesId);
    if (!mounted) {
      return false;
    }

    if (seasons.isEmpty) {
      _showSnack('No seasons available for this series yet.');
      return false;
    }

    // Show season picker dialog
    final selectedSeason = await showDialog<SeasonRecord>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Season - ${item.title}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: seasons.length,
            itemBuilder: (context, index) {
              final season = seasons[index];
              return ListTile(
                title: Text(season.name ?? 'Season ${season.seasonNumber}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(season),
              );
            },
          ),
        ),
      ),
    );

    if (selectedSeason == null || !mounted) {
      return false;
    }

    // Load episodes for selected season
    final episodes = await vodRepo.listEpisodes(selectedSeason.id);
    if (!mounted) {
      return false;
    }

    if (episodes.isEmpty) {
      _showSnack('No episodes available for this season yet.');
      return false;
    }

    // Play episodes
    if (_shouldUseLazyPlayback(context)) {
      final lazyEntries = _buildLazyEpisodeEntries(episodes, {
        tappedSeriesId: item.title,
      });
      if (!mounted) {
        return false;
      }
      return _pushLazyPlaylist(
        context: context,
        entries: lazyEntries,
        initialIndex: 0,
      );
    }

    final playlist = await _resolveEpisodeSources(episodes, {
      tappedSeriesId: item.title,
    });
    if (!mounted || playlist.isEmpty) {
      _showSnack('No playable episodes in this season.');
      return false;
    }

    return _pushMediaPlaylist(
      context: context,
      sources: playlist.map((entry) => entry.source).toList(growable: false),
      initialIndex: 0,
    );
  }

  Future<bool> _playPreviewItemsDirect(CategoryPreviewItem tappedItem) async {
    final playlist = <({String id, PlayerMediaSource source})>[];
    for (final preview in widget.result.items) {
      final source = await _playableResolver.preview(preview, widget.bucket);
      if (source == null) {
        continue;
      }
      playlist.add((id: preview.id, source: source));
    }
    if (playlist.isEmpty) {
      return false;
    }
    if (!mounted) {
      return false;
    }
    final initialIndex = _initialIndexFor<String>(playlist, tappedItem.id);
    return _pushMediaPlaylist(
      context: context,
      sources: playlist.map((entry) => entry.source).toList(growable: false),
      initialIndex: initialIndex,
    );
  }
}

mixin _PlayerPlaybackMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  PlayableResolver get playableResolver;

  bool _windowsWarningShown = false;
  static const ResolveConfig _resolveConfig = ResolveConfig(
    neighborRadius: 0, // Disable prefetching to avoid Stalker token conflicts
    minGap: Duration(milliseconds: 650),
  );

  Future<void> _launchSingleChannel(ChannelRecord channel) async {
    final messenger = ScaffoldMessenger.of(context);
    bool success = false;
    if (_shouldUseLazyPlayback(context)) {
      final lazyEntries = _buildLazyChannelEntries([channel]);
      if (!mounted) {
        return;
      }
      success = await _pushLazyPlaylist(
        context: context,
        entries: lazyEntries,
        initialIndex: 0,
      );
    } else {
      final source = await playableResolver.channel(
        channel,
        isRadio: channel.isRadio,
      );
      if (!mounted) {
        return;
      }
      if (source == null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('No stream available for this channel.'),
            ),
          );
        return;
      }
      success = await _pushMediaPlaylist(
        context: context,
        sources: [source],
        initialIndex: 0,
      );
    }
    if (!mounted) {
      return;
    }
    if (!success) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No stream available for this channel.'),
          ),
        );
    }
  }

  Future<List<({int? id, PlayerMediaSource source})>> _resolveChannelSources(
    List<ChannelRecord> channels,
  ) async {
    final result = <({int? id, PlayerMediaSource source})>[];
    for (final channel in channels) {
      final source = await playableResolver.channel(
        channel,
        isRadio: channel.isRadio,
      );
      if (source == null) continue;
      result.add((id: channel.id, source: source));
    }
    return result;
  }

  Future<List<({int? id, PlayerMediaSource source})>> _resolveMovieSources(
    List<MovieRecord> movies,
  ) async {
    final result = <({int? id, PlayerMediaSource source})>[];
    for (final movie in movies) {
      final source = await playableResolver.movie(movie);
      if (source == null) continue;
      result.add((id: movie.id, source: source));
    }
    return result;
  }

  Future<List<({int? id, PlayerMediaSource source})>> _resolveEpisodeSources(
    List<EpisodeRecord> episodes,
    Map<int, String> seriesTitles,
  ) async {
    final result = <({int? id, PlayerMediaSource source})>[];
    for (final episode in episodes) {
      final source = await playableResolver.episode(
        episode,
        seriesTitle: seriesTitles[episode.seriesId],
      );
      if (source == null) continue;
      result.add((id: episode.seriesId, source: source));
    }
    return result;
  }

  List<LazyPlaybackEntry> _buildLazyChannelEntries(
    List<ChannelRecord> channels,
  ) {
    return channels
        .map(
          (channel) => LazyPlaybackEntry(
            id: channel.id,
            factory: () async {
              final source = await playableResolver.channel(
                channel,
                isRadio: channel.isRadio,
              );
              if (source == null) {
                return null;
              }
              return _applyPlatformPolicyToSource(source);
            },
          ),
        )
        .toList(growable: false);
  }

  List<LazyPlaybackEntry> _buildLazyMovieEntries(List<MovieRecord> movies) {
    return movies
        .map(
          (movie) => LazyPlaybackEntry(
            id: movie.id,
            factory: () async {
              PlaybackLogger.videoInfo(
                'resolving-lazy-movie',
                extra: {
                  'movieId': movie.id,
                  'title': movie.title,
                  'hasStreamTemplate': movie.streamUrlTemplate != null,
                  'hasProviderKey': movie.providerVodKey.isNotEmpty,
                },
              );
              final source = await playableResolver.movie(movie);
              if (source == null) {
                PlaybackLogger.videoError(
                  'movie-resolution-failed',
                  description: 'Failed to resolve movie: ${movie.title}',
                );
                return null;
              }
              PlaybackLogger.videoInfo(
                'movie-resolved-successfully',
                extra: {'movieId': movie.id, 'title': movie.title},
              );
              return _applyPlatformPolicyToSource(source);
            },
          ),
        )
        .toList(growable: false);
  }

  List<LazyPlaybackEntry> _buildLazyEpisodeEntries(
    List<EpisodeRecord> episodes,
    Map<int, String> seriesTitles,
  ) {
    return episodes
        .map(
          (episode) => LazyPlaybackEntry(
            id: episode.seriesId,
            factory: () async {
              final source = await playableResolver.episode(
                episode,
                seriesTitle: seriesTitles[episode.seriesId],
              );
              if (source == null) {
                return null;
              }
              return _applyPlatformPolicyToSource(source);
            },
          ),
        )
        .toList(growable: false);
  }

  int _initialIndexFor<E>(
    List<({E? id, PlayerMediaSource source})> entries,
    E? targetId,
  ) {
    if (targetId == null) {
      return 0;
    }
    final idx = entries.indexWhere((entry) => entry.id == targetId);
    return idx >= 0 ? idx : 0;
  }

  int _initialIndexForRecords<R>(
    List<R> items,
    int? targetId,
    int? Function(R item) selector,
  ) {
    if (targetId == null || items.isEmpty) {
      return 0;
    }
    final idx = items.indexWhere((item) => selector(item) == targetId);
    return idx >= 0 ? idx : 0;
  }

  Future<bool> _pushMediaPlaylist({
    required BuildContext context,
    required List<PlayerMediaSource> sources,
    int initialIndex = 0,
  }) async {
    if (sources.isEmpty) {
      return false;
    }
    final plan = await _applyPlatformPolicy(context, sources);
    if (plan == null || plan.sources.isEmpty) {
      return false;
    }
    if (!context.mounted) {
      await plan.dispose();
      return false;
    }
    final clampedIndex = math.max(
      0,
      math.min(initialIndex, plan.sources.length - 1),
    );
    final PlayerAdapter adapter = plan.useMediaKit
        ? MediaKitPlaylistAdapter(
            sources: plan.sources,
            initialIndex: clampedIndex,
          )
        : PlaylistVideoPlayerAdapter(
            sources: plan.sources,
            initialIndex: clampedIndex,
          );
    final controller = PlayerController(adapter: adapter);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PlayerScreen(controller: controller, ownsController: true),
        ),
      );
      return true;
    } finally {
      await plan.dispose();
    }
  }

  Future<bool> _pushLazyPlaylist({
    required BuildContext context,
    required List<LazyPlaybackEntry> entries,
    int initialIndex = 0,
  }) async {
    if (entries.isEmpty) {
      return false;
    }
    if (!context.mounted) {
      return false;
    }
    final clampedIndex = math.max(
      0,
      math.min(initialIndex, entries.length - 1),
    );
    final adapter = LazyMediaKitAdapter(
      entries: entries,
      scheduler: ResolveScheduler(minGap: _resolveConfig.minGap),
      config: _resolveConfig,
      initialIndex: clampedIndex,
    );
    final controller = PlayerController(adapter: adapter);
    if (_isWindowsPlatform(context)) {
      PlaybackLogger.videoInfo(
        'windows-mediakit-fallback',
        extra: {'count': entries.length, 'mode': 'lazy'},
      );
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PlayerScreen(controller: controller, ownsController: true),
      ),
    );
    return true;
  }

  bool _shouldUseLazyPlayback(BuildContext context) {
    // Use lazy loading on Windows with neighborRadius=0 to resolve on-demand
    // This avoids requesting multiple Stalker tokens upfront
    return _isWindowsPlatform(context);
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<_PlatformPlaybackPlan?> _applyPlatformPolicy(
    BuildContext context,
    List<PlayerMediaSource> sources,
  ) async {
    if (!_isWindowsPlatform(context)) {
      return _PlatformPlaybackPlan(sources: sources, useMediaKit: false);
    }
    final adjustedSources = <PlayerMediaSource>[];
    final disposers = <Future<void> Function()>[];
    var useMediaKit = false;
    for (final source in sources) {
      final resolved = await _applyPlatformPolicyToSource(source);
      adjustedSources.add(resolved.source);
      if (resolved.dispose != null) {
        disposers.add(resolved.dispose!);
      }
      useMediaKit = useMediaKit || resolved.useMediaKit;
    }
    if (useMediaKit) {
      PlaybackLogger.videoInfo(
        'windows-mediakit-fallback',
        extra: {'count': sources.length, 'mode': 'eager'},
      );
    }
    return _PlatformPlaybackPlan(
      sources: adjustedSources,
      useMediaKit: useMediaKit,
      onDispose: () async {
        for (final dispose in disposers) {
          await dispose();
        }
      },
    );
  }

  Future<ResolvedPlayback> _applyPlatformPolicyToSource(
    PlayerMediaSource source,
  ) async {
    if (!_isWindowsPlatform(context)) {
      return ResolvedPlayback(source: source, useMediaKit: false);
    }
    PlaybackLogger.videoInfo(
      'platform-policy-called',
      uri: source.playable.url,
      extra: {
        'title': source.title,
        'hasRawUrl': source.playable.rawUrl != null,
        'rawUrlPrefix':
            source.playable.rawUrl != null &&
                source.playable.rawUrl!.length > 80
            ? '${source.playable.rawUrl!.substring(0, 80)}...'
            : source.playable.rawUrl ?? 'null',
      },
    );
    final support = classifyWindowsPlayable(source.playable);
    final warnOnly = support == WindowsPlaybackSupport.likelyCodecIssue;
    final requiresFallback = support != WindowsPlaybackSupport.okDirect;
    var adjustedSource = source;
    Future<void> Function()? disposer;
    if (requiresFallback) {
      if (!_windowsWarningShown && mounted) {
        _showSnack(windowsSupportMessage(support));
        _windowsWarningShown = true;
      }
      PlaybackLogger.videoInfo(
        'windows-play-blocked',
        uri: source.playable.url,
        headers: source.playable.headers,
        extra: {'support': support.name},
        includeFullUrl: true,
      );
      final handle = await FfmpegRestreamer.instance.restream(source);
      if (handle != null) {
        adjustedSource = handle.source;
        disposer = handle.dispose;
      }
    } else {
      _logWindowsAcceptance(source.playable, support);
    }
    if (warnOnly) {
      PlaybackLogger.videoInfo(
        'windows-play-warning',
        uri: source.playable.url,
        headers: source.playable.headers,
        extra: {'support': support.name},
        includeFullUrl: true,
      );
    }
    return ResolvedPlayback(
      source: adjustedSource,
      dispose: disposer,
      useMediaKit: requiresFallback,
    );
  }

  bool _isWindowsPlatform(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.windows;
  }

  void _logWindowsAcceptance(
    Playable playable,
    WindowsPlaybackSupport support,
  ) {
    PlaybackLogger.videoInfo(
      'windows-play-accepted',
      uri: playable.url,
      headers: playable.headers,
      extra: {'support': support.name},
      includeFullUrl: true,
    );
  }
}

class _PlatformPlaybackPlan {
  const _PlatformPlaybackPlan({
    required this.sources,
    required this.useMediaKit,
    this.onDispose,
  });

  final List<PlayerMediaSource> sources;
  final bool useMediaKit;
  final Future<void> Function()? onDispose;

  Future<void> dispose() async {
    if (onDispose != null) {
      await onDispose!.call();
    }
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

class _ExpandableSeriesItem extends ConsumerStatefulWidget {
  const _ExpandableSeriesItem({
    required this.series,
    required this.icon,
    required this.profile,
    required this.playableResolver,
  });

  final CategoryPreviewItem series;
  final IconData icon;
  final ResolvedProviderProfile profile;
  final PlayableResolver playableResolver;

  @override
  ConsumerState<_ExpandableSeriesItem> createState() =>
      _ExpandableSeriesItemState();
}

class _ExpandableSeriesItemState extends ConsumerState<_ExpandableSeriesItem> {
  bool _expanded = false;
  List<_UiSeasonData>? _seasons;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: _ArtworkAvatar(
            url: widget.series.artUri ?? '',
            fallbackIcon: widget.icon,
            size: 40,
          ),
          title: Text(widget.series.title),
          subtitle: widget.series.subtitle != null
              ? Text(widget.series.subtitle!)
              : null,
          trailing: Icon(_expanded ? Icons.expand_more : Icons.chevron_right),
          onTap: _toggleExpansion,
        ),
        if (_expanded) ...[
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else if (_seasons != null && _seasons!.isNotEmpty)
            ..._seasons!.map(
              (season) => _ExpandableSeasonItem(
                season: season,
                seriesTitle: widget.series.title,
                profile: widget.profile,
                playableResolver: widget.playableResolver,
              ),
            )
          else if (_seasons != null && _seasons!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                'No seasons available',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _toggleExpansion() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() {
      _expanded = true;
      _loading = true;
      _error = null;
    });

    try {
      PlaybackLogger.userAction(
        'series-expand',
        extra: {
          'seriesId': widget.series.id,
          'seriesTitle': widget.series.title,
          'providerId': widget.profile.providerDbId,
        },
      );

      // Extract numeric series ID (handle formats like "8412" or "8412:8412")
      String idStr = widget.series.id;
      if (idStr.contains(':')) {
        idStr = idStr.split(':').first;
      }

      final seriesId = int.tryParse(idStr);
      if (seriesId == null) {
        PlaybackLogger.videoError(
          'series-invalid-id',
          description: 'Series ID is not numeric: ${widget.series.id}',
          error:
              'ID: ${widget.series.id}, Extracted: $idStr, Type: ${widget.series.id.runtimeType}',
        );
        throw Exception('Invalid series ID: "${widget.series.id}"');
      }

      PlaybackLogger.videoInfo(
        'series-fetch-seasons',
        extra: {
          'seriesId': seriesId,
          'providerId': widget.profile.providerDbId,
        },
      );

      List<_UiSeasonData> seasons;

      // For Stalker providers, fetch seasons from the API
      if (widget.profile.kind == ProviderKind.stalker) {
        final stalkerSeasons = await _fetchStalkerSeasons(seriesId);
        seasons = stalkerSeasons
            .asMap()
            .entries
            .map(
              (entry) =>
                  _UiSeasonData.fromStalker(entry.value, seriesId, entry.key),
            )
            .toList();
      } else {
        // For other providers, use the database
        final vodRepo = ref.read(vodRepositoryProvider);
        final dbSeasons = await vodRepo.listSeasons(seriesId);
        seasons = dbSeasons.map((s) => _UiSeasonData.fromDb(s)).toList();
      }

      if (!mounted) return;

      PlaybackLogger.videoInfo(
        'series-seasons-loaded',
        extra: {'seriesId': seriesId, 'seasonCount': seasons.length},
      );

      setState(() {
        _seasons = seasons;
        _loading = false;
      });
    } catch (e) {
      PlaybackLogger.videoError(
        'series-load-failed',
        description: 'Failed to load seasons for ${widget.series.title}',
        error: '$e',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load seasons: $e';
        _loading = false;
      });
    }
  }

  Future<List<StalkerSeason>> _fetchStalkerSeasons(int seriesId) async {
    // Use the playable resolver which already has session management
    final resolver = widget.playableResolver;

    // Ensure we have a Stalker session
    await resolver.ensureStalkerSession();

    final session = resolver.stalkerSession;
    if (session == null) {
      throw Exception('Failed to establish Stalker session');
    }

    final config = resolver.stalkerConfiguration;
    if (config == null) {
      throw Exception('No Stalker configuration available');
    }

    final vodService = StalkerVodService(
      configuration: config,
      session: session,
    );

    return vodService.getSeasons(seriesId);
  }
}

class _ExpandableSeasonItem extends ConsumerStatefulWidget {
  const _ExpandableSeasonItem({
    required this.season,
    required this.seriesTitle,
    required this.profile,
    required this.playableResolver,
  });

  final _UiSeasonData season;
  final String seriesTitle;
  final ResolvedProviderProfile profile;
  final PlayableResolver playableResolver;

  @override
  ConsumerState<_ExpandableSeasonItem> createState() =>
      _ExpandableSeasonItemState();
}

// Helper class to hold episode data for UI display
class _UiEpisodeData {
  _UiEpisodeData({
    required this.id,
    required this.title,
    this.episodeNumber,
    this.overview,
    this.durationSec,
    this.stalkerCmd,
    this.seriesId,
    this.seasonNumber,
    this.isStalkerSource = false,
  });

  factory _UiEpisodeData.fromDb(EpisodeRecord record) {
    return _UiEpisodeData(
      id: record.id.toString(),
      title: record.title ?? 'Episode ${record.episodeNumber}',
      episodeNumber: record.episodeNumber,
      overview: record.overview,
      durationSec: record.durationSec,
      isStalkerSource: false,
    );
  }

  factory _UiEpisodeData.fromStalker(
    StalkerEpisode stalker,
    int index,
    int seriesId,
    int seasonNumber,
  ) {
    return _UiEpisodeData(
      id: stalker.id,
      title: stalker.name,
      episodeNumber: stalker.episodeNumber ?? index + 1,
      durationSec: stalker.duration,
      stalkerCmd: stalker.cmd,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      isStalkerSource: true,
    );
  }

  final String id;
  final String title;
  final int? episodeNumber;
  final String? overview;
  final int? durationSec;
  final String? stalkerCmd;
  final int? seriesId;
  final int? seasonNumber;
  final bool isStalkerSource;

  bool get isStalker => isStalkerSource;
}

class _ExpandableSeasonItemState extends ConsumerState<_ExpandableSeasonItem>
    with _PlayerPlaybackMixin<_ExpandableSeasonItem> {
  bool _expanded = false;
  List<_UiEpisodeData>? _episodes;
  bool _loading = false;
  String? _error;

  @override
  PlayableResolver get playableResolver => widget.playableResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seasonName = widget.season.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 32),
          title: Text(seasonName),
          trailing: Icon(_expanded ? Icons.expand_more : Icons.chevron_right),
          onTap: _toggleExpansion,
        ),
        if (_expanded) ...[
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 48),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else if (_episodes != null && _episodes!.isNotEmpty)
            ..._episodes!.map(
              (episode) => _EpisodeItem(
                episode: episode,
                onTap: () => _handleEpisodePlay(episode),
              ),
            )
          else if (_episodes != null && _episodes!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
              child: Text(
                'No episodes available',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _toggleExpansion() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() {
      _expanded = true;
      _loading = true;
      _error = null;
    });

    try {
      PlaybackLogger.videoInfo(
        'season-fetch-episodes',
        extra: {
          'seasonId': widget.season.id,
          'seasonNumber': widget.season.seasonNumber,
          'seriesTitle': widget.seriesTitle,
        },
      );

      List<_UiEpisodeData> episodes;

      // For Stalker providers, fetch episodes from the API
      if (widget.season.isStalker && widget.season.stalkerSeasonId != null) {
        final stalkerEpisodes = await _fetchStalkerEpisodes(
          widget.season.seriesId,
          widget.season.stalkerSeasonId!,
        );
        episodes = stalkerEpisodes
            .asMap()
            .entries
            .map(
              (entry) => _UiEpisodeData.fromStalker(
                entry.value,
                entry.key,
                widget.season.seriesId,
                widget.season.seasonNumber,
              ),
            )
            .toList();
      } else {
        // For other providers, use the database
        final vodRepo = ref.read(vodRepositoryProvider);
        final dbEpisodes = await vodRepo.listEpisodes(widget.season.id);
        episodes = dbEpisodes.map((e) => _UiEpisodeData.fromDb(e)).toList();
      }

      if (!mounted) return;

      PlaybackLogger.videoInfo(
        'season-episodes-loaded',
        extra: {'seasonId': widget.season.id, 'episodeCount': episodes.length},
      );

      setState(() {
        _episodes = episodes;
        _loading = false;
      });
    } catch (e) {
      PlaybackLogger.videoError(
        'season-load-failed',
        description:
            'Failed to load episodes for season ${widget.season.seasonNumber}',
        error: '$e',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load episodes: $e';
        _loading = false;
      });
    }
  }

  Future<List<StalkerEpisode>> _fetchStalkerEpisodes(
    int seriesId,
    String seasonId,
  ) async {
    // Use the playable resolver which already has session management
    final resolver = widget.playableResolver;

    // Ensure we have a Stalker session
    await resolver.ensureStalkerSession();

    final session = resolver.stalkerSession;
    if (session == null) {
      throw Exception('Failed to establish Stalker session');
    }

    final config = resolver.stalkerConfiguration;
    if (config == null) {
      throw Exception('No Stalker configuration available');
    }

    final vodService = StalkerVodService(
      configuration: config,
      session: session,
    );

    return vodService.getEpisodes(seriesId, seasonId);
  }

  Future<void> _handleEpisodePlay(_UiEpisodeData episode) async {
    PlaybackLogger.userAction(
      'episode-clicked',
      extra: {'episodeId': episode.id, 'title': episode.title},
    );

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var dialogVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ).whenComplete(() => dialogVisible = false),
    );

    try {
      PlayerMediaSource? source;

      // For Stalker episodes, use cmd field or construct JSON command
      if (episode.isStalker &&
          episode.seriesId != null &&
          episode.seasonNumber != null &&
          episode.episodeNumber != null) {
        String command;
        String format;

        if (episode.stalkerCmd != null) {
          // Server provided VOD ID like "90001" - use directly
          command = episode.stalkerCmd!;
          format = 'vod-id';
        } else {
          // Server returned episode arrays, need JSON command format
          // Construct: {"type":"series","series_id":8412,"season_num":2,"episode":1}
          command =
              '{"type":"series","series_id":${episode.seriesId},"season_num":${episode.seasonNumber},"episode":${episode.episodeNumber}}';
          format = 'json-command';
        }

        PlaybackLogger.userAction(
          'episode-constructed-command',
          extra: {
            'seriesId': episode.seriesId,
            'season': episode.seasonNumber,
            'episode': episode.episodeNumber,
            'episodeId': episode.id,
            'command': command,
            'format': format,
            'hasServerCmd': episode.stalkerCmd != null,
          },
        );

        // Create a temporary preview item to match the existing pattern
        final previewItem = CategoryPreviewItem(
          id: episode.id,
          title: episode.title,
          subtitle:
              episode.overview ?? 'Episode ${episode.episodeNumber ?? ""}',
          artUri: null,
          streamUrl: command,
          headers: null,
        );

        source = await widget.playableResolver.preview(
          previewItem,
          ContentBucket.series,
        );

        if (source != null) {
          source = PlayerMediaSource(
            playable: source.playable,
            title: '${widget.seriesTitle} - ${episode.title}',
          );
        }
      } else if (episode.isStalker) {
        // Stalker episode but missing required data
        _showSnack('Episode data incomplete');
        return;
      } else {
        // Database episodes not yet implemented
        _showSnack('Database episode playback not yet implemented');
        return;
      }

      if (!mounted) return;

      if (source == null) {
        _showSnack('No stream available for this episode.');
        return;
      }

      final success = await _pushMediaPlaylist(
        context: context,
        sources: [source],
        initialIndex: 0,
      );

      if (!success && mounted) {
        _showSnack('Failed to play episode.');
      }
    } catch (e) {
      PlaybackLogger.videoError(
        'episode-play-failed',
        description: 'Failed to play episode: $e',
        error: e,
      );
      if (mounted) {
        _showSnack('Error playing episode: $e');
      }
    } finally {
      if (dialogVisible && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }
  }

  @override
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EpisodeItem extends StatelessWidget {
  const _EpisodeItem({required this.episode, required this.onTap});

  final _UiEpisodeData episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodeNum = episode.episodeNumber;
    final title = episode.title;
    final subtitle = _buildSubtitle();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 64),
      title: Text(
        episodeNum != null
            ? 'E${episodeNum.toString().padLeft(2, '0')} - $title'
            : title,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.play_arrow_rounded, size: 20),
      onTap: onTap,
    );
  }

  String? _buildSubtitle() {
    final duration = episode.durationSec;
    if (duration == null || duration <= 0) {
      return null;
    }
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
