import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

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
    final categoriesAsync = ref.watch(categoriesDataProvider(widget.profile));
    final summaryAsync = ref.watch(summaryDataProvider(widget.profile));

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
                      ref.invalidate(categoriesDataProvider(widget.profile));
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
    final sections = ContentBucket.values
        .where((bucket) => data[bucket]?.isNotEmpty == true)
        .toList();

    if (sections.isEmpty) {
      return const Center(
        child: Text('No categories found for this provider yet.'),
      );
    }

    return ListView(
      children: [
        for (final bucket in sections) ...[
          _buildSection(context, bucket, data[bucket]!),
          const SizedBox(height: 12),
        ],
      ],
    );
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

class _CategoryPreviewList extends StatelessWidget {
  const _CategoryPreviewList({required this.items, required this.icon});

  final List<CategoryPreviewItem> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No preview items yet.'),
      );
    }

    final theme = Theme.of(context);

    return Column(
      children: [
        for (final item in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: _buildLeading(theme, item),
            title: Text(item.title),
            subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
          ),
      ],
    );
  }

  Widget _buildLeading(ThemeData theme, CategoryPreviewItem item) {
    if (item.artUri == null || item.artUri!.isEmpty) {
      return Icon(icon, size: 20, color: theme.colorScheme.secondary);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        item.artUri!,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(icon, size: 20, color: theme.colorScheme.secondary),
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
