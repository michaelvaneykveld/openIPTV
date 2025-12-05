import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/providers/openiptv_content_providers.dart';
import 'package:openiptv/src/ui/player/mini_player.dart';
import 'package:openiptv/src/ui/vod/series_details_screen.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_vod_service.dart';
import 'package:openiptv/src/providers/protocol_auth_providers.dart';
import 'package:openiptv/src/utils/profile_header_utils.dart';

class VodGridScreen extends ConsumerStatefulWidget {
  final ResolvedProviderProfile profile;
  final String type; // 'movie' or 'series'

  const VodGridScreen({super.key, required this.profile, required this.type});

  @override
  ConsumerState<VodGridScreen> createState() => _VodGridScreenState();
}

class _VodGridScreenState extends ConsumerState<VodGridScreen> {
  int? _selectedCategoryId;
  String? _selectedCategoryKey;

  @override
  Widget build(BuildContext context) {
    final providerId = widget.profile.providerDbId;
    if (providerId == null) {
      return const Center(child: Text('Provider not initialized in new DB'));
    }

    final bucket = widget.type == 'movie'
        ? ContentBucket.films
        : ContentBucket.series;
    final groupsAsync = ref.watch(dbCategoriesProvider(providerId));

    return Row(
      children: [
        // Categories
        Expanded(
          flex: 1,
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: groupsAsync.when(
              data: (categoryMap) {
                final groups = categoryMap[bucket] ?? [];
                return ListView.builder(
                  itemCount: groups.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: const Text('All'),
                        selected: _selectedCategoryId == null,
                        onTap: () => setState(() {
                          _selectedCategoryId = null;
                          _selectedCategoryKey = null;
                        }),
                      );
                    }
                    final group = groups[index - 1];
                    final groupId = int.tryParse(group.id);
                    if (groupId == null) return const SizedBox.shrink();

                    return ListTile(
                      title: Text('${group.name} (${group.count ?? 0})'),
                      selected: _selectedCategoryId == groupId,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = groupId;
                          _selectedCategoryKey = group.providerKey;
                        });
                        if (widget.profile.kind == ProviderKind.stalker &&
                            group.providerKey != null) {
                          _fetchCategoryContent(
                            providerId,
                            group.providerKey!,
                            widget.type,
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Grid
        Expanded(
          flex: 4,
          child: Column(
            children: [
              if (_selectedCategoryId != null &&
                  widget.profile.kind == ProviderKind.stalker &&
                  _selectedCategoryKey != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () => _fetchCategoryContent(
                      providerId,
                      _selectedCategoryKey!,
                      widget.type,
                      forceRefresh: true,
                    ),
                  ),
                ),
              Expanded(
                child: widget.type == 'movie'
                    ? _buildMovieGrid(context, ref, providerId)
                    : _buildSeriesGrid(context, ref, providerId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovieGrid(BuildContext context, WidgetRef ref, int providerId) {
    final moviesAsync = ref.watch(
      moviesProvider((providerId: providerId, categoryId: _selectedCategoryId)),
    );

    return moviesAsync.when(
      data: (movies) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _buildCard(
            movie.title,
            movie.posterUrl,
            onTap: () => _playMovie(context, ref, movie),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSeriesGrid(BuildContext context, WidgetRef ref, int providerId) {
    final seriesAsync = ref.watch(
      seriesProvider((providerId: providerId, categoryId: _selectedCategoryId)),
    );

    return seriesAsync.when(
      data: (seriesList) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: seriesList.length,
        itemBuilder: (context, index) {
          final series = seriesList[index];
          return _buildCard(
            series.title,
            series.posterUrl,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeriesDetailsScreen(
                  profile: widget.profile,
                  series: series,
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildCard(String title, String? imageUrl, {VoidCallback? onTap}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, size: 48),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playMovie(
    BuildContext context,
    WidgetRef ref,
    MovieRecord movie,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resolver = ref.read(playableResolverProvider(widget.profile));
      final source = await resolver.movie(movie);

      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading

        if (source != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: const BackButton(color: Colors.white),
                ),
                extendBodyBehindAppBar: true,
                body: Center(child: MiniPlayer(source: source, autoPlay: true)),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to resolve movie URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _fetchCategoryContent(
    int providerId,
    String categoryId,
    String type, {
    bool forceRefresh = false,
  }) async {
    final config = StalkerPortalConfiguration(
      baseUri: widget.profile.lockedBase,
      macAddress: widget.profile.record.configuration['macAddress'] ?? '',
      userAgent: widget.profile.record.configuration['userAgent'],
      allowSelfSignedTls: widget.profile.record.allowSelfSignedTls,
      extraHeaders: decodeProfileCustomHeaders(widget.profile),
    );

    try {
      final session = await ref.read(stalkerSessionProvider(config).future);
      final service = StalkerVodService(
        configuration: config,
        session: session,
      );

      // 1=VOD, 2=Series (matching CategoryKind enum index)
      final kindIndex = type == 'series' ? 2 : 1;

      await service.fetchCategoryContent(
        db: ref.read(openIptvDbProvider),
        providerId: providerId,
        categoryId: categoryId,
        categoryKindIndex: kindIndex,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Failed to fetch category content: $e');
    }
  }
}
