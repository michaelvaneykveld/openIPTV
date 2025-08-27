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
            'The server returned an HTML page instead of JSON. Check the portal URL.');
      }

      return _parseChannelsFromJson(response.data.toString());
    } catch (e, stackTrace) {
      developer.log('Error fetching Stalker channels',
          error: e, stackTrace: stackTrace, name: 'StalkerProvider');
      rethrow;
    }
  }

  List<Channel> _parseChannelsFromJson(String responseBody) {
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

    return channelListData.whereType<Map<String, dynamic>>().map((item) {
      final id = item['id']?.toString() ?? '';
      final name = item['name']?.toString() ?? 'Unnamed Channel';
      final logoUrl = item['logo']?.toString();
      final cmd = item['cmd']?.toString() ?? '';

      final parts = cmd.split(' ');
      final streamUrl = parts.isNotEmpty ? parts.last : '';

      return Channel(
        id: id,
        name: name,
        logoUrl: logoUrl,
        streamUrl: streamUrl,
        group: "Live TV", // Placeholder group
        epgId: id, // EPG ID is often the same as the channel ID
      );
    }).toList();
  }
}
