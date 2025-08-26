import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';

/// An implementation of [IProvider] for Stalker Portals.
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

  @override
  Future<List<Channel>> fetchLiveChannels() async {
    final url =
        '$_baseUrl/server/load.php?type=itv&action=get_all_channels&mac=$_macAddress';
    developer.log('Fetching Stalker channels from: $url',
        name: 'StalkerProvider');

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.data == null || response.data!.trim().isEmpty) {
        throw Exception('Received an empty response from the server.');
      }

      if (response.data!.trim().startsWith('<!DOCTYPE html>') ||
          response.data!.trim().startsWith('<html')) {
        throw const FormatException(
            'The server returned an HTML page instead of the expected JSON data. This often means the portal URL is incorrect or requires a different API endpoint (e.g., /portal.php).');
      }

      final Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.data.toString());
      } on FormatException {
        throw const FormatException(
            'The server response was not a valid JSON format, even though it was not detected as HTML.');
      }

      final jsData = jsonResponse['js'];
      if (jsData == null || jsData is! Map<String, dynamic>) {
        throw const FormatException(
            "The JSON response is missing the expected 'js' object.");
      }

      final channelListData = jsData['data'];
      if (channelListData == null || channelListData is! List) {
        developer.log(
          "The 'js' object does not contain a 'data' list. Returning empty channel list.",
          name: 'StalkerProvider',
        );
        return [];
      }

      return channelListData
          .whereType<Map<String, dynamic>>()
          .map((item) {
            // Directly parse the fields we need.
            final id = item['id']?.toString() ?? '';
            final name = item['name']?.toString() ?? 'Unnamed Channel';
            final logoUrl = item['logo']?.toString();
            final cmd = item['cmd']?.toString() ?? '';

            // The 'cmd' field often contains 'ffmpeg ' or similar, followed by the URL.
            final streamUrl = cmd.split(' ').last;

            // Map the parsed data directly to our app's domain model.
            return Channel(
                id: id,
                name: name,
                logoUrl: logoUrl,
                streamUrl: streamUrl,
                // Stalker API doesn't provide group name in this specific call, so we use a placeholder.
                // The EPG ID in Stalker is often the same as the channel ID.
                group: "Live TV",
                epgId: id);
          })
          .toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching Stalker channels',
        error: e,
        stackTrace: stackTrace,
        name: 'StalkerProvider',
      );
      rethrow;
    }
  }
}
