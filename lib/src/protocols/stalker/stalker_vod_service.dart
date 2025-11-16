import 'dart:convert';

import 'stalker_http_client.dart';
import 'stalker_portal_configuration.dart';
import 'stalker_session.dart';

class StalkerVodService {
  StalkerVodService({
    required StalkerPortalConfiguration configuration,
    required StalkerSession session,
    StalkerHttpClient? httpClient,
  }) : _configuration = configuration,
       _session = session,
       _httpClient = httpClient ?? StalkerHttpClient();

  final StalkerPortalConfiguration _configuration;
  final StalkerSession _session;
  final StalkerHttpClient _httpClient;

  /// Fetches seasons for a series from the Stalker portal
  Future<List<StalkerSeason>> getSeasons(int seriesId) async {
    print('[Stalker VOD] Fetching seasons for series $seriesId');

    final response = await _httpClient.getPortal(
      _configuration,
      queryParameters: {
        'type': 'series',
        'action': 'get_ordered_list',
        'movie_id': seriesId.toString(),
        'season_id': '0',
        'episode_id': '0',
        'JsHttpRequest': '1-xml',
        'token': _session.token,
        'mac': _configuration.macAddress.toLowerCase(),
      },
      headers: _session.buildAuthenticatedHeaders(),
    );

    print('[Stalker VOD] Seasons response status: ${response.statusCode}');
    print('[Stalker VOD] Seasons response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch seasons: HTTP ${response.statusCode}');
    }

    final data = _decodePortalResponse(response.body);
    print('[Stalker VOD] Decoded data: $data');

    // The response structure has seasons directly in the data array
    final seasonsData = data['data'];
    if (seasonsData is List) {
      print('[Stalker VOD] Seasons data array: ${seasonsData.length} items');

      if (seasonsData.isEmpty) {
        return [];
      }

      final seasons = seasonsData
          .map((item) => _parseSeasonFromItem(item, seriesId))
          .whereType<StalkerSeason>()
          .toList();

      print('[Stalker VOD] Parsed ${seasons.length} seasons');
      return seasons;
    }

    print('[Stalker VOD] No seasons found in response');
    return [];
  }

  /// Fetches episodes for a season from the Stalker portal
  Future<List<StalkerEpisode>> getEpisodes(
    int seriesId,
    String seasonId,
  ) async {
    print(
      '[Stalker VOD] Fetching episodes for season $seasonId of series $seriesId',
    );

    final response = await _httpClient.getPortal(
      _configuration,
      queryParameters: {
        'type': 'vod',
        'action': 'get_episodes',
        'season_id': seasonId,
        'JsHttpRequest': '1-xml',
        'token': _session.token,
        'mac': _configuration.macAddress.toLowerCase(),
      },
      headers: _session.buildAuthenticatedHeaders(),
    );

    print('[Stalker VOD] Episodes response status: ${response.statusCode}');
    print('[Stalker VOD] Episodes response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch episodes: HTTP ${response.statusCode}');
    }

    final data = _decodePortalResponse(response.body);

    // Get episodes from the 'episodes' array in the response
    final episodesData = data['episodes'];
    print('[Stalker VOD] Episodes data: $episodesData');

    if (episodesData is List && episodesData.isNotEmpty) {
      final episodes = episodesData
          .map((item) => _parseEpisodeFromItem(item, seriesId, seasonId))
          .whereType<StalkerEpisode>()
          .toList();

      print('[Stalker VOD] Parsed ${episodes.length} episodes');
      return episodes;
    }

    print('[Stalker VOD] No episodes found in response');
    return [];
  }

  StalkerSeason? _parseSeasonFromItem(dynamic item, int seriesId) {
    if (item is! Map) return null;

    final map = item.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));

    final id = map['id']?.toString();
    final name = map['name']?.toString() ?? map['title']?.toString();

    if (id == null || name == null) return null;

    // Extract season number from name or from the ID (e.g., "21737:2" means season 2)
    int? seasonNum = _extractSeasonNumber(name);
    if (seasonNum == null && id.contains(':')) {
      final parts = id.split(':');
      if (parts.length == 2) {
        seasonNum = int.tryParse(parts[1]);
      }
    }

    return StalkerSeason(
      id: id,
      name: name,
      seriesId: seriesId.toString(),
      seasonNumber: seasonNum,
    );
  }

  StalkerEpisode? _parseEpisodeFromItem(
    dynamic item,
    int seriesId,
    String seasonId,
  ) {
    // Handle if item is just an integer episode number
    if (item is int) {
      return StalkerEpisode(
        id: '$seasonId:$item',
        name: 'Episode $item',
        cmd: null,
        seasonId: seasonId,
        seriesId: seriesId.toString(),
        episodeNumber: item,
        duration: null,
      );
    }

    if (item is! Map) return null;

    final map = item.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));

    final id = map['id']?.toString();
    final name = map['name']?.toString() ?? map['title']?.toString();
    final cmd = map['cmd']?.toString();

    if (id == null) return null;

    // Get episode number from episode_num field, or extract from name/ID
    int? episodeNum = map['episode_num'] as int?;
    if (episodeNum == null) {
      episodeNum = _extractEpisodeNumber(name ?? '');
    }
    if (episodeNum == null && id.contains(':')) {
      final parts = id.split(':');
      if (parts.length >= 2) {
        episodeNum = int.tryParse(parts.last);
      }
    }

    return StalkerEpisode(
      id: id,
      name: name ?? 'Episode $episodeNum',
      cmd: cmd ?? id, // Use ID as cmd if cmd field not present
      seasonId: seasonId,
      seriesId: seriesId.toString(),
      episodeNumber: episodeNum,
      duration: _parseDuration(map['duration'] ?? map['length']),
    );
  }

  int? _extractSeasonNumber(String name) {
    final seasonMatch = RegExp(
      r'[Ss]eason\s*(\d+)|[Ss](\d+)',
      caseSensitive: false,
    ).firstMatch(name);
    if (seasonMatch != null) {
      return int.tryParse(seasonMatch.group(1) ?? seasonMatch.group(2) ?? '');
    }
    return null;
  }

  int? _extractEpisodeNumber(String name) {
    final episodeMatch = RegExp(
      r'[Ee]pisode\s*(\d+)|[Ee](\d+)',
      caseSensitive: false,
    ).firstMatch(name);
    if (episodeMatch != null) {
      return int.tryParse(episodeMatch.group(1) ?? episodeMatch.group(2) ?? '');
    }
    return null;
  }

  int? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // Try parsing as seconds
      final seconds = int.tryParse(value);
      if (seconds != null) return seconds;

      // Try parsing HH:MM:SS format
      final parts = value.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return hours * 3600 + minutes * 60 + seconds;
      }
    }
    return null;
  }

  Map<String, dynamic> _decodePortalResponse(dynamic body) {
    if (body == null) {
      return const {};
    }
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) {
        return const {};
      }
      // Remove HTML comments that some portals wrap JSON in
      final cleaned = trimmed
          .replaceAll(RegExp(r'^\ufeff'), '')
          .replaceAll(RegExp(r'^\s*<!--|-->\s*$'), '');
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map<String, dynamic>) {
          // Some portals wrap the response in a 'js' key
          final js = decoded['js'];
          if (js is Map<String, dynamic>) {
            return js;
          }
          return decoded;
        }
      } on FormatException {
        return const {};
      }
    }
    return const {};
  }
}

class StalkerSeason {
  const StalkerSeason({
    required this.id,
    required this.name,
    this.seriesId,
    this.seasonNumber,
  });

  final String id;
  final String name;
  final String? seriesId;
  final int? seasonNumber;
}

class StalkerEpisode {
  const StalkerEpisode({
    required this.id,
    required this.name,
    this.cmd,
    this.seasonId,
    this.seriesId,
    this.episodeNumber,
    this.duration,
  });

  final String id;
  final String name;
  final String? cmd;
  final String? seasonId;
  final String? seriesId;
  final int? episodeNumber;
  final int? duration;
}
