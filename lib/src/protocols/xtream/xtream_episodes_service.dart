import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/protocols/xtream/xtream_http_client.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';

final xtreamEpisodesServiceProvider = Provider<XtreamEpisodesService>((ref) {
  final db = ref.watch(openIptvDbProvider);
  return XtreamEpisodesService(db);
});

class XtreamEpisodesService {
  final OpenIptvDb _db;
  final XtreamHttpClient _client = XtreamHttpClient();

  XtreamEpisodesService(this._db);

  Future<void> fetchAndSaveEpisodes({
    required XtreamPortalConfiguration config,
    required int providerId,
    required int seriesId,
    required String seriesProviderKey,
  }) async {
    try {
      final response = await _client.getPlayerApi(
        config,
        queryParameters: {
          'action': 'get_series_info',
          'series_id': seriesProviderKey,
        },
      );

      if (response.statusCode != 200) {
        return;
      }

      final dynamic body = response.body;
      Map<String, dynamic> data = {};

      if (body is Map) {
        data = body.map((key, value) => MapEntry(key.toString(), value));
      } else if (body is String) {
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            data = decoded.map((key, value) => MapEntry(key.toString(), value));
          }
        } catch (_) {}
      }

      final episodesData = data['episodes'];
      if (episodesData == null) return;

      final List<Map<String, dynamic>> allEpisodes = [];

      if (episodesData is Map) {
        // Xtream sometimes returns Map<String, List> where key is season number
        episodesData.forEach((key, value) {
          if (value is List) {
            for (var ep in value) {
              if (ep is Map) {
                allEpisodes.add(ep.map((k, v) => MapEntry(k.toString(), v)));
              }
            }
          }
        });
      } else if (episodesData is List) {
        for (var ep in episodesData) {
          if (ep is Map) {
            allEpisodes.add(ep.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      }

      if (allEpisodes.isEmpty) return;

      await _db.transaction(() async {
        // Cache seasons to avoid repeated lookups
        final seasonCache = <int, int>{};

        // Pre-fetch existing seasons
        final existingSeasons = await (_db.select(
          _db.seasons,
        )..where((tbl) => tbl.seriesId.equals(seriesId))).get();

        for (final s in existingSeasons) {
          seasonCache[s.seasonNumber] = s.id;
        }

        for (final rawEpisode in allEpisodes) {
          final episodeKey = _coerceString(
            rawEpisode['id'] ??
                rawEpisode['episode_id'] ??
                rawEpisode['stream_id'] ??
                rawEpisode['file_id'],
          );
          if (episodeKey == null || episodeKey.isEmpty) continue;

          final seasonNumber =
              _parseInt(rawEpisode['season'] ?? rawEpisode['season_number']) ??
              1;
          final episodeNumber = _parseInt(
            rawEpisode['episode'] ?? rawEpisode['episode_num'],
          );

          var seasonId = seasonCache[seasonNumber];
          if (seasonId == null) {
            // Create season
            final seasonCompanion = SeasonsCompanion(
              seriesId: Value(seriesId),
              seasonNumber: Value(seasonNumber),
              name: Value(_coerceString(rawEpisode['season_name'])),
            );

            // Check if it exists (race condition check)
            final existing =
                await (_db.select(_db.seasons)..where(
                      (tbl) =>
                          tbl.seriesId.equals(seriesId) &
                          tbl.seasonNumber.equals(seasonNumber),
                    ))
                    .getSingleOrNull();

            if (existing != null) {
              seasonId = existing.id;
            } else {
              seasonId = await _db.into(_db.seasons).insert(seasonCompanion);
            }
            seasonCache[seasonNumber] = seasonId;
          }

          final containerExt = _coerceString(
            rawEpisode['container_extension'] ?? rawEpisode['extension'],
          );

          final episodeCompanion = EpisodesCompanion(
            seriesId: Value(seriesId),
            seasonId: Value(seasonId),
            providerEpisodeKey: Value(episodeKey),
            seasonNumber: Value(seasonNumber),
            episodeNumber: Value(episodeNumber),
            title: Value(
              _coerceString(rawEpisode['title'] ?? rawEpisode['name']),
            ),
            overview: Value(
              _coerceString(
                rawEpisode['plot'] ??
                    rawEpisode['description'] ??
                    rawEpisode['overview'],
              ),
            ),
            durationSec: Value(_parseDurationSeconds(rawEpisode['duration'])),
            streamUrlTemplate: Value(
              containerExt != null && containerExt.isNotEmpty
                  ? '.$containerExt'
                  : _coerceString(
                      rawEpisode['stream_url'] ??
                          rawEpisode['direct_source'] ??
                          rawEpisode['url'],
                    ),
            ),
            lastSeenAt: Value(DateTime.now().toUtc()),
          );

          await _db.into(_db.episodes).insertOnConflictUpdate(episodeCompanion);
        }
      });
    } catch (e) {
      // Log error
      if (kDebugMode) {
        print('Error fetching episodes: $e');
      }
    }
  }

  String? _coerceString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed;
  }

  int? _parseDurationSeconds(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    if (text.contains(':')) {
      final parts = text.split(':');
      final reversed = parts.reversed.toList();
      var seconds = 0;
      for (var index = 0; index < reversed.length; index++) {
        final component = int.tryParse(reversed[index]) ?? 0;
        final multiplier = switch (index) {
          0 => 1,
          1 => 60,
          2 => 3600,
          _ => 3600,
        };
        seconds += component * multiplier;
      }
      return seconds;
    }
    return int.tryParse(text);
  }
}
