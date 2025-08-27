import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../core/api/iprovider.dart';
import '../../core/models/channel.dart';

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
  Future<List<Channel>> fetchLiveChannels() async {
    developer.log('Fetching M3U playlist from: $_m3uUrl', name: 'M3uProvider');
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
      developer.log('Error fetching or parsing M3U playlist',
          error: e, stackTrace: stackTrace, name: 'M3uProvider');
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
                  logoUrl: attributes['tvg-logo'] ?? '',
                  streamUrl: streamUrl,
                  group: attributes['group-title'] ?? 'Uncategorized',
                  // Use tvg-id for EPG mapping, fall back to name if not present.
                  epgId: tvgId ?? name,
                ),
              );
            } else {
              developer.log('Skipping invalid URL: $streamUrl', name: 'M3uProvider');
            }
          }
        } catch (e, stackTrace) {
          developer.log('Failed to parse M3U line: "$line"',
              error: e, stackTrace: stackTrace, name: 'M3uProvider');
          // Continue to the next line
        }
      }
    }
    developer.log('Parsed ${channels.length} channels from M3U playlist.',
        name: 'M3uProvider');
    return channels;
  }

  /// Extracts key-value attributes and the title from an #EXTINF line.
  Map<String, String> _extractAttributes(String extinfLine) {
    final attributes = <String, String>{};

    // Regex to find key="value" pairs.
    final regex = RegExp(r'(\w+-?\w+)="([^"]*)"');
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
}
