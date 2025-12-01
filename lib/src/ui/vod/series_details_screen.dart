import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/xtream/xtream_episodes_service.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';
import 'package:openiptv/src/providers/openiptv_content_providers.dart';
import 'package:openiptv/src/ui/player/mini_player.dart';

class SeriesDetailsScreen extends ConsumerStatefulWidget {
  final ResolvedProviderProfile profile;
  final SeriesRecord series;

  const SeriesDetailsScreen({
    super.key,
    required this.profile,
    required this.series,
  });

  @override
  ConsumerState<SeriesDetailsScreen> createState() =>
      _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends ConsumerState<SeriesDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchEpisodesIfNeeded();
  }

  Future<void> _fetchEpisodesIfNeeded() async {
    if (widget.profile.kind == ProviderKind.xtream) {
      final providerId = widget.profile.providerDbId;
      if (providerId == null) return;

      final config = XtreamPortalConfiguration.fromCredentials(
        url: widget.profile.lockedBase.toString(),
        username: widget.profile.secrets['username'] ?? '',
        password: widget.profile.secrets['password'] ?? '',
      );

      await ref
          .read(xtreamEpisodesServiceProvider)
          .fetchAndSaveEpisodes(
            config: config,
            providerId: providerId,
            seriesId: widget.series.id,
            seriesProviderKey: widget.series.providerSeriesKey,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerId = widget.profile.providerDbId;
    if (providerId == null) {
      return const Center(child: Text('Provider not initialized in new DB'));
    }

    final episodesAsync = ref.watch(
      episodesProvider((providerId: providerId, seriesId: widget.series.id)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.series.title)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Series Info
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (widget.series.posterUrl != null)
                    Image.network(
                      widget.series.posterUrl!,
                      width: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.tv, size: 100),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    widget.series.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (widget.series.overview != null)
                    Text(widget.series.overview!),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Right: Episodes List
          Expanded(
            flex: 2,
            child: episodesAsync.when(
              data: (episodes) {
                if (episodes.isEmpty) {
                  return const Center(
                    child: Text('No episodes found. Fetching...'),
                  );
                }
                return ListView.builder(
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    return ListTile(
                      title: Text(
                        episode.title ?? 'Episode ${episode.episodeNumber}',
                      ),
                      subtitle: Text(
                        'S${episode.seasonNumber} E${episode.episodeNumber} • ${episode.durationSec != null ? (episode.durationSec! / 60).round() : '?'} min',
                      ),
                      onTap: () => _playEpisode(context, ref, episode),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playEpisode(
    BuildContext context,
    WidgetRef ref,
    EpisodeRecord episode,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resolver = ref.read(playableResolverProvider(widget.profile));
      final source = await resolver.episode(
        episode,
        seriesTitle: widget.series.title,
      );

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
            const SnackBar(content: Text('Failed to resolve episode URL')),
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
