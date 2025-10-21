import 'package:openiptv/utils/app_logger.dart';
import 'package:dio/dio.dart';

import '../../core/api/iprovider.dart';
import '../../core/models/models.dart'; // Ensure models.dart is imported for VodCategory, VodContent, Genre, Channel
import '../../core/models/epg_programme.dart';

/// An implementation of [IProvider] for M3U playlists.
///
/// This provider fetches an M3U playlist from a given URL and parses it
/// to extract channel information.
class M3uProvider implements IProvider {
  final Dio _dio;
  final String _m3uUrl;

  M3uProvider({required Dio dio, required String m3uUrl})
      : _dio = dio,
        _m3uUrl = m3uUrl;

  @override
  Future<List<Channel>> fetchLiveChannels(String portalId) async {
    appLogger.d('Fetching M3U playlist from: $_m3uUrl');
    try {
      final response = await _dio.get<String>(
        _m3uUrl,
        options: Options(responseType: ResponseType.plain),
      );

      if (response.data == null || response.data!.trim().isEmpty) {
        throw Exception('Received an empty M3U playlist.');
      }

      return _parseM3UContent(response.data!);
    } catch (e, stackTrace) {
      appLogger.e('Error fetching or parsing M3U playlist',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Parses the M3U playlist content into a list of [Channel] objects.
  List<Channel> _parseM3UContent(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    final iterator = lines.iterator;

    while (iterator.moveNext()) {
      final line = iterator.current;
      if (line.startsWith('#EXTINF:')) {
        try {
          // The next line should be the stream URL
          if (iterator.moveNext()) {
            final streamUrl = iterator.current;
            // Ensure the next line is a valid URL before processing
            if (Uri.tryParse(streamUrl)?.isAbsolute ?? false) {
              final attributes = _extractAttributes(line);
              final name = attributes['title'] ?? 'Unnamed Channel';
              final tvgId = attributes['tvg-id'];

              channels.add(
                Channel(
                  // Use tvg-id for a more stable unique ID if available,
                  // otherwise fall back to the stream URL.
                  id: (tvgId != null && tvgId.isNotEmpty) ? tvgId : streamUrl,
                  name: name,
                  logo: attributes['tvg-logo'] ?? '',
                  streamUrl: streamUrl,
                  group: attributes['group-title'] ?? 'Uncategorized',
                  // Use tvg-id for EPG mapping, fall back to name if not present.
                  epgId: tvgId ?? name,
                ),
              );
            } else {
              appLogger.w('Skipping invalid URL: $streamUrl');
            }
          }
        } catch (e, stackTrace) {
          appLogger.e('Failed to parse M3U line: "$line"',
              error: e, stackTrace: stackTrace);
          // Continue to the next line
        }
      }
    }
    appLogger.d('Parsed ${channels.length} channels from M3U playlist.');
    return channels;
  }

  /// Extracts key-value attributes and the title from an #EXTINF line.
  Map<String, String> _extractAttributes(String extinfLine) {
    final attributes = <String, String>{};

    // Regex to find key="value" pairs.
    final regex = RegExp(r'(\w+-?\w+)=\"([^\"]*)\"');
    regex.allMatches(extinfLine).forEach((match) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        attributes[key] = value;
      }
    });

    // The title is typically the last part of the line, after the final comma.
    final lastCommaIndex = extinfLine.lastIndexOf(',');
    if (lastCommaIndex != -1 && lastCommaIndex < extinfLine.length - 1) {
      attributes['title'] = extinfLine.substring(lastCommaIndex + 1).trim();
    }

    // A common fallback for the name is the 'tvg-name' attribute.
    // This also handles cases where the title might be empty.
    if (attributes['title']?.isEmpty ?? true) {
      final tvgName = attributes['tvg-name'];
      if (tvgName != null) {
        attributes['title'] = tvgName;
      }
    }

    return attributes;
  }

  @override
  Future<List<Genre>> getGenres(String portalId) async {
    // M3U playlists don't typically have a separate genre list.
    // Genres are usually extracted from the 'group-title' attribute of each channel.
    return [];
  }

  @override
  Future<List<VodCategory>> fetchVodCategories(String portalId) async {
    return [];
  }

  @override
  Future<List<VodContent>> fetchVodContent(String portalId, String categoryId) async {
    return [];
  }

  @override
  Future<List<Genre>> fetchRadioGenres(String portalId) async {
    return [];
  }

  @override
  Future<List<Channel>> fetchRadioChannels(String portalId, String genreId) async {
    return [];
  }

  @override
  Future<List<Channel>> getAllChannels(String portalId, String genreId) async {
    return [];
  }

  @override
  Future<List<EpgProgramme>> getEpgInfo({
    required String portalId,
    required String chId,
    required int period,
  }) async {
    return [];
  }
}
