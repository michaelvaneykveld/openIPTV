import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/providers/openiptv_content_providers.dart';
import 'package:openiptv/src/ui/player/mini_player.dart';
import 'package:openiptv/src/ui/vod/series_details_screen.dart';

class VodGridScreen extends ConsumerWidget {
  final ResolvedProviderProfile profile;
  final String type; // 'movie' or 'series'

  const VodGridScreen({super.key, required this.profile, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerId = profile.providerDbId;
    if (providerId == null) {
      return const Center(child: Text('Provider not initialized in new DB'));
    }

    return type == 'movie'
        ? _buildMovieGrid(context, ref, providerId)
        : _buildSeriesGrid(context, ref, providerId);
  }

  Widget _buildMovieGrid(BuildContext context, WidgetRef ref, int providerId) {
    final moviesAsync = ref.watch(
      moviesProvider((providerId: providerId, categoryId: null)),
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
      seriesProvider((providerId: providerId, categoryId: null)),
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
                builder: (_) =>
                    SeriesDetailsScreen(profile: profile, series: series),
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
      final resolver = ref.read(playableResolverProvider(profile));
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
}
