import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';

/// An implementation of [IProvider] for M3U playlists.
class M3uProvider implements IProvider {
  final Dio _dio;
  final String _m3uUrl; // The URL to the .m3u file

  M3uProvider({
    required Dio dio,
    required String m3uUrl,
  })  : _dio = dio,
        _m3uUrl = m3uUrl;

  @override
  Future<List<Channel>> fetchLiveChannels() async {
    try {
      final response = await _dio.get<String>(_m3uUrl);
      final m3uContent = response.data;

      if (m3uContent == null || !m3uContent.trim().startsWith('#EXTM3U')) {
        throw const FormatException('Invalid M3U file format.');
      }

      return _parseM3uContent(m3uContent);
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching or parsing M3U file',
        error: e,
        stackTrace: stackTrace,
        name: 'M3uProvider',
      );
      rethrow;
    }
  }

  List<Channel> _parseM3uContent(String content) {
    final channels = <Channel>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('#EXTINF:')) {
        final infoLine = lines[i];
        // Ensure there is a next line for the URL
        if (i + 1 < lines.length) {
          final urlLine = lines[i + 1].trim();
          if (urlLine.isNotEmpty && !urlLine.startsWith('#')) {
            // Extract attributes
            final name = _getAttribute(infoLine, 'name') ?? 'Unnamed Channel';
            final logo = _getAttribute(infoLine, 'tvg-logo');
            final group = _getAttribute(infoLine, 'group-title') ?? 'General';
            // Use tvg-id for both id and epgId. Fallback to name if tvg-id is missing.
            final id = _getAttribute(infoLine, 'tvg-id') ?? name;

            channels.add(
              Channel(
                id: id,
                name: name,
                logoUrl: logo,
                streamUrl: urlLine,
                group: group,
                epgId: id,
              ),
            );
            // Increment i to skip the URL line in the next iteration
            i++;
          }
        }
      }
    }
    return channels;
  }

  /// Extracts an attribute value from an #EXTINF line.
  /// e.g., #EXTINF:-1 tvg-id="id1" group-title="News",Channel 1
  String? _getAttribute(String line, String key) {
    // Handle the channel name, which is typically after the last comma.
    if (key == 'name') {
      final commaIndex = line.lastIndexOf(',');
      if (commaIndex != -1) {
        return line.substring(commaIndex + 1).trim();
      }
      // Some M3U files use tvg-name
      return _getAttribute(line, 'tvg-name');
    }

    // Handle other attributes like tvg-id, tvg-logo, group-title
    final regExp = RegExp('$key="(.*?)"', caseSensitive: false);
    final match = regExp.firstMatch(line);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    return null;
  }
}

