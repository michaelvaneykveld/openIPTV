import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:openiptv/src/protocols/xtream/xtream_http_client.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';
import 'package:openiptv/storage/provider_database.dart';

final xtreamRepositoryProvider = Provider<XtreamRepository>((ref) {
  final db = ref.watch(providerDatabaseProvider);
  return XtreamRepository(db: db, client: XtreamHttpClient());
});

class XtreamRepository {
  final ProviderDatabase _db;
  final XtreamHttpClient _client;
  final Logger _logger = Logger();

  XtreamRepository({
    required ProviderDatabase db,
    required XtreamHttpClient client,
  }) : _db = db,
       _client = client;

  /// Fetches and saves all categories (Live, VOD, Series).
  Future<void> syncCategories(
    XtreamPortalConfiguration config,
    String providerId,
  ) async {
    await Future.wait([
      _syncCategories(config, providerId, 'get_live_categories', 'live'),
      _syncCategories(config, providerId, 'get_vod_categories', 'movie'),
      _syncCategories(config, providerId, 'get_series_categories', 'series'),
    ]);
  }

  Future<void> _syncCategories(
    XtreamPortalConfiguration config,
    String providerId,
    String action,
    String type,
  ) async {
    try {
      final response = await _client.getPlayerApi(
        config,
        queryParameters: {'action': action},
      );
      if (response.statusCode == 200 && response.body is List) {
        final List<dynamic> data = response.body;
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(
            _db.streamGroups,
            data.map((item) {
              return StreamGroupsCompanion(
                id: Value(int.tryParse(item['category_id'].toString()) ?? 0),
                providerId: Value(providerId),
                name: Value(item['category_name'] ?? 'Unknown'),
                type: Value(type),
              );
            }),
          );
        });
      }
    } catch (e) {
      // Log error or rethrow? For now silent fail or log.
      _logger.e('Error syncing categories ($type): $e');
    }
  }

  /// Fetches and saves Live Streams.
  Future<void> syncLiveStreams(
    XtreamPortalConfiguration config,
    String providerId, {
    int? categoryId,
  }) async {
    final params = {'action': 'get_live_streams'};
    if (categoryId != null) {
      params['category_id'] = categoryId.toString();
    }
    try {
      final response = await _client.getPlayerApi(
        config,
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.body is List) {
        final List<dynamic> data = response.body;
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(
            _db.liveStreams,
            data.map((item) {
              return LiveStreamsCompanion(
                streamId: Value(
                  int.tryParse(item['stream_id'].toString()) ?? 0,
                ),
                providerId: Value(providerId),
                name: Value(item['name'] ?? 'Unknown'),
                streamIcon: Value(item['stream_icon']),
                epgChannelId: Value(item['epg_channel_id']),
                categoryId: Value(int.tryParse(item['category_id'].toString())),
                num: Value(int.tryParse(item['num'].toString())),
              );
            }),
          );
        });
      }
    } catch (e) {
      _logger.e('Error syncing live streams: $e');
    }
  }

  /// Fetches and saves VOD Streams.
  Future<void> syncVodStreams(
    XtreamPortalConfiguration config,
    String providerId, {
    int? categoryId,
  }) async {
    final params = {'action': 'get_vod_streams'};
    if (categoryId != null) {
      params['category_id'] = categoryId.toString();
    }
    try {
      final response = await _client.getPlayerApi(
        config,
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.body is List) {
        final List<dynamic> data = response.body;
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(
            _db.vodStreams,
            data.map((item) {
              return VodStreamsCompanion(
                streamId: Value(
                  int.tryParse(item['stream_id'].toString()) ?? 0,
                ),
                providerId: Value(providerId),
                name: Value(item['name'] ?? 'Unknown'),
                streamIcon: Value(item['stream_icon']),
                containerExtension: Value(item['container_extension']),
                categoryId: Value(int.tryParse(item['category_id'].toString())),
                rating: Value(
                  double.tryParse(item['rating'].toString()) ?? 0.0,
                ),
                added: Value(
                  DateTime.tryParse(item['added'].toString()) ?? DateTime.now(),
                ),
              );
            }),
          );
        });
      }
    } catch (e) {
      _logger.e('Error syncing vod streams: $e');
    }
  }

  /// Fetches and saves Series.
  Future<void> syncSeries(
    XtreamPortalConfiguration config,
    String providerId, {
    int? categoryId,
  }) async {
    final params = {'action': 'get_series'};
    if (categoryId != null) {
      params['category_id'] = categoryId.toString();
    }
    try {
      final response = await _client.getPlayerApi(
        config,
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.body is List) {
        final List<dynamic> data = response.body;
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(
            _db.series,
            data.map((item) {
              return SeriesCompanion(
                seriesId: Value(
                  int.tryParse(item['series_id'].toString()) ?? 0,
                ),
                providerId: Value(providerId),
                name: Value(item['name'] ?? 'Unknown'),
                cover: Value(item['cover']),
                plot: Value(item['plot']),
                cast: Value(item['cast']),
                director: Value(item['director']),
                genre: Value(item['genre']),
                releaseDate: Value(item['releaseDate']),
                lastModified: Value(
                  DateTime.tryParse(item['last_modified'].toString()) ??
                      DateTime.now(),
                ),
                categoryId: Value(int.tryParse(item['category_id'].toString())),
              );
            }),
          );
        });
      }
    } catch (e) {
      _logger.e('Error syncing series: $e');
    }
  }

  /// Lazy loads episodes for a series.
  Future<List<Episode>> getEpisodes(
    XtreamPortalConfiguration config,
    String providerId,
    int seriesId,
  ) async {
    // Check DB first
    final cached =
        await (_db.select(_db.episodes)..where(
              (tbl) =>
                  tbl.seriesId.equals(seriesId) &
                  tbl.providerId.equals(providerId),
            ))
            .get();

    if (cached.isNotEmpty) {
      return cached;
    }

    try {
      // Fetch from API
      final response = await _client.getPlayerApi(
        config,
        queryParameters: {
          'action': 'get_series_info',
          'series_id': seriesId.toString(),
        },
      );

      if (response.statusCode == 200 && response.body is Map) {
        final Map<String, dynamic> data = response.body;
        final episodesData = data['episodes']; // Can be Map or List
        final List<EpisodesCompanion> episodes = [];

        if (episodesData is Map) {
          // Xtream sometimes returns Map<String, List> where key is season number
          episodesData.forEach((key, value) {
            if (value is List) {
              for (var ep in value) {
                episodes.add(_parseEpisode(ep, providerId, seriesId));
              }
            }
          });
        } else if (episodesData is List) {
          for (var ep in episodesData) {
            episodes.add(_parseEpisode(ep, providerId, seriesId));
          }
        }

        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.episodes, episodes);
        });

        return (_db.select(_db.episodes)..where(
              (tbl) =>
                  tbl.seriesId.equals(seriesId) &
                  tbl.providerId.equals(providerId),
            ))
            .get();
      }
    } catch (e) {
      _logger.e('Error fetching episodes: $e');
    }
    return [];
  }

  EpisodesCompanion _parseEpisode(
    dynamic item,
    String providerId,
    int seriesId,
  ) {
    return EpisodesCompanion(
      id: Value(int.tryParse(item['id'].toString()) ?? 0), // Xtream episode ID
      seriesId: Value(seriesId),
      providerId: Value(providerId),
      title: Value(item['title'] ?? 'Unknown'),
      containerExtension: Value(item['container_extension']),
      info: Value(item['info']?.toString()),
      season: Value(int.tryParse(item['season'].toString())),
      episode: Value(int.tryParse(item['episode_num'].toString())),
      duration: Value(
        int.tryParse(item['duration_secs'].toString()) ??
            int.tryParse(item['duration'].toString()),
      ),
    );
  }
}
