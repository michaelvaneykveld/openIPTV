import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';

class PlayerShell extends ConsumerWidget {
  const PlayerShell({super.key, required this.profile});

  final ResolvedProviderProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesDataProvider(profile));
    final isLoading = categoriesAsync.isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(profile.record.displayName)),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading
            ? null
            : () {
                ref.invalidate(categoriesDataProvider(profile));
              },
        tooltip: 'Reload categories',
        child: const Icon(Icons.refresh),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: categoriesAsync.when(
          data: (data) => _CategoriesView(data: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              _CategoriesError(message: error.toString()),
        ),
      ),
    );
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
