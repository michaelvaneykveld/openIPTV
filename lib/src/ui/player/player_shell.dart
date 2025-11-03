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
    final categoriesAsync =
        ref.watch(categoriesDataProvider(widget.profile));
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
                      ref.invalidate(
                        categoriesDataProvider(widget.profile),
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
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => _CategoriesError(
                    message: error.toString(),
                  ),
                )
              : categoriesAsync.when(
                  data: (data) => _CategoriesView(data: data),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
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
        .map(
          (entry) => Chip(
            label: Text('${entry.key}: ${entry.value}'),
          ),
        )
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
                          Expanded(
                            flex: 2,
                            child: Text(entry.value),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (chips.isNotEmpty) ...[
                  const Divider(),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: chips,
                  ),
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
  const _CategoriesView({required this.data});

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
              (category) => ListTile(
                leading: Icon(
                  icon,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                title: Text(category.name),
                trailing: Text(
                  category.count?.toString() ?? '—',
                  style: theme.textTheme.labelLarge,
                ),
                onTap: () {},
              ),
            )
            .toList(),
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
