import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../core/api/iprovider.dart';
import '../../core/models/channel.dart';

/// An implementation of [IProvider] for Stalker Portals.
///
/// This provider handles the two-step process of fetching channels from a Stalker Portal:
/// 1. It first fetches a list of genres.
/// 2. It then fetches the full channel list and uses the genre list to map
///    the correct group name to each channel.
class StalkerProvider implements IProvider {
  final Dio _dio;
  final String _baseUrl;
  final String _macAddress;

  StalkerProvider({
    required Dio dio,
    required String baseUrl,
    required String macAddress,
  })  : _dio = dio,
        _baseUrl = baseUrl,
        _macAddress = macAddress;

  /// Fetches the complete list of live TV channels from the Stalker Portal.
  @override
  Future<List<Channel>> fetchLiveChannels() async {
    try {
      // Step 1: Fetch the genre mapping first.
      final genreMap = await _fetchGenres();
      developer.log('Successfully fetched ${genreMap.length} genres.',
          name: 'StalkerProvider');

      // Step 2: Fetch all channels.
      final url =
          '$_baseUrl/server/load.php?type=itv&action=get_all_channels&mac=$_macAddress';
      developer.log('Fetching Stalker channels from: $url',
          name: 'StalkerProvider');

      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      // Step 3: Parse channels using the genre map.
      return _parseChannelsFromJson(response.data.toString(), genreMap);
    } catch (e, stackTrace) {
      developer.log('Error in fetchLiveChannels sequence',
          error: e, stackTrace: stackTrace, name: 'StalkerProvider');
      // Re-throw the exception to be caught by the repository and UI layers.
      rethrow;
    }
  }

  /// Fetches the list of genres to map genre IDs to human-readable names.
  /// Returns a Map where the key is the genre ID and the value is the genre title.
  Future<Map<String, String>> _fetchGenres() async {
    final url =
        '$_baseUrl/server/load.php?type=itv&action=get_genres&mac=$_macAddress';
    developer.log('Fetching Stalker genres from: $url', name: 'StalkerProvider');

    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Accept': 'application/json'},
      ),
    );

    if (response.data == null || response.data!.trim().isEmpty) {
      throw Exception('Received an empty response from the server for genres.');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.data!);
    final List<dynamic>? genreListData = jsonResponse['js'];

    if (genreListData == null || genreListData.isEmpty) {
      developer.log('Genre list is empty or not in the expected format.', name: 'StalkerProvider');
      return {};
    }

    // Create a map of genre IDs to titles.
    return {
      for (var item in genreListData.whereType<Map<String, dynamic>>())
        if (item['id'] != null && item['title'] != null)
          item['id'].toString(): item['title'].toString()
    };
  }

  /// Parses the JSON channel list and enriches it with genre names.
  List<Channel> _parseChannelsFromJson(
      String responseBody, Map<String, String> genreMap) {
    if (responseBody.trim().startsWith('<!DOCTYPE html>') ||
        responseBody.trim().startsWith('<html')) {
      throw const FormatException(
          'The server returned an HTML page instead of JSON. Check the portal URL.');
    }
      
    final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

    final jsData = jsonResponse['js'];
    if (jsData == null || jsData is! Map<String, dynamic>) {
      throw const FormatException("JSON response is missing the 'js' object.");
    }

    final channelListData = jsData['data'];
    if (channelListData == null || channelListData is! List) {
      developer.log("No 'data' list found in JSON. Returning empty channel list.",
          name: 'StalkerProvider');
      return [];
    }

    // Parse the raw JSON directly into the app's domain models.
    return channelListData.whereType<Map<String, dynamic>>().map((item) {
      final id = item['id']?.toString() ?? '';
      final name = item['name']?.toString() ?? 'Unnamed Channel';
      final logoUrl = item['logo']?.toString();
      final cmd = item['cmd']?.toString() ?? '';
      final parts = cmd.split(' ');
      final streamUrl = parts.isNotEmpty ? parts.last : '';

      // Use the genre map to find the group name.
      final genreId = item['tv_genre_id']?.toString() ?? '';
      final groupName = genreMap[genreId] ?? 'Uncategorized';

      return Channel(
        id: id,
        name: name,
        logoUrl: logoUrl,
        streamUrl: streamUrl,
        group: groupName,
        // Use the 'xmltv_id' for EPG mapping if available, otherwise fall back to the channel ID.
        epgId: item['xmltv_id']?.toString() ?? id,
      );
    }).toList();
  }
}
