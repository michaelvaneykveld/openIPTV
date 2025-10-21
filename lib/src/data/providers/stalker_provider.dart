import 'dart:convert';
import 'package:openiptv/utils/app_logger.dart';

import 'package:dio/dio.dart';

import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';
import '../../core/models/epg_programme.dart';

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
  Future<List<Channel>> fetchLiveChannels(String portalId) async {
    try {
      // Step 1: Fetch the genre mapping first.
      final genreMap = await _fetchGenres('itv');
      appLogger.d('Successfully fetched ${genreMap.length} genres.');

      // Step 2: Fetch all channels.
      final url =
          '$_baseUrl/server/load.php?type=itv&action=get_all_channels&mac=$_macAddress';
      appLogger.d('Fetching Stalker channels from: $url');

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
      appLogger.e('Error in fetchLiveChannels sequence',
          error: e, stackTrace: stackTrace);
      // Re-throw the exception to be caught by the repository and UI layers.
      rethrow;
    }
  }

  /// Fetches the list of genres to map genre IDs to human-readable names.
  /// Returns a Map where the key is the genre ID and the value is the genre title.
  Future<Map<String, String>> _fetchGenres(String type) async {
    final url =
        '$_baseUrl/server/load.php?type=$type&action=get_genres&mac=$_macAddress';
    appLogger.d('Fetching Stalker genres from: $url');

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
      appLogger.w('Genre list is empty or not in the expected format.');
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
      appLogger.w("No 'data' list found in JSON. Returning empty channel list.");
      return [];
    }

    // Parse the raw JSON directly into the app's domain models.
    return channelListData.whereType<Map<String, dynamic>>().map((item) {
      final genreId = item['tv_genre_id']?.toString() ?? '';
      final groupName = genreMap[genreId] ?? 'Uncategorized';
      item['group_title'] = groupName;
      return Channel.fromStalkerJson(item);
    }).toList();
  }

  @override
  Future<List<Genre>> getGenres(String portalId) async {
    final genres = await _fetchGenres('itv');
    return genres.entries.map((entry) => Genre(id: entry.key, title: entry.value)).toList();
  }

  @override
  Future<List<VodCategory>> fetchVodCategories(String portalId) async {
    try {
      final url =
          '$_baseUrl/server/load.php?type=vod&action=get_categories&mac=$_macAddress';
      appLogger.d('Fetching Stalker VOD categories from: $url');

      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.data == null || response.data!.trim().isEmpty) {
        throw Exception('Received an empty response from the server for VOD categories.');
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.data!);
      final List<dynamic>? categoriesData = jsonResponse['js']?['data'];

      if (categoriesData == null || categoriesData.isEmpty) {
        appLogger.w('VOD categories list is empty or not in the expected format.');
        return [];
      }

      return categoriesData.map((item) => VodCategory.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      appLogger.e('Error fetching VOD categories',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<VodContent>> fetchVodContent(String portalId, String categoryId) async {
    try {
      final url =
          '$_baseUrl/server/load.php?type=vod&action=get_content&category_id=$categoryId&mac=$_macAddress';
      appLogger.d('Fetching Stalker VOD content from: $url');

      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.data == null || response.data!.trim().isEmpty) {
        throw Exception('Received an empty response from the server for VOD content.');
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.data!);
      final List<dynamic>? contentData = jsonResponse['js']?['data'];

      if (contentData == null || contentData.isEmpty) {
        appLogger.w('VOD content list is empty or not in the expected format.');
        return [];
      }

      return contentData.map((item) => VodContent.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      appLogger.e('Error fetching VOD content',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Genre>> fetchRadioGenres(String portalId) async {
    final genres = await _fetchGenres('radio');
    return genres.entries.map((entry) => Genre(id: entry.key, title: entry.value)).toList();
  }

  @override
  Future<List<Channel>> fetchRadioChannels(String portalId, String genreId) async {
    try {
      final genreMap = await _fetchGenres('radio');
      final url =
          '$_baseUrl/server/load.php?type=radio&action=get_all_channels&genre=$genreId&mac=$_macAddress';
      appLogger.d('Fetching Stalker radio channels from: $url');

      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      return _parseChannelsFromJson(response.data.toString(), genreMap);
    } catch (e, stackTrace) {
      appLogger.e('Error in fetchRadioChannels sequence',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Channel>> getAllChannels(String portalId, String genreId) async {
    try {
      final genreMap = await _fetchGenres('itv');
      final url =
          '$_baseUrl/server/load.php?type=itv&action=get_all_channels&genre=$genreId&mac=$_macAddress';
      appLogger.d('Fetching Stalker channels from: $url');

      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      return _parseChannelsFromJson(response.data.toString(), genreMap);
    } catch (e, stackTrace) {
      appLogger.e('Error in getAllChannels sequence',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

    @override
  Future<List<EpgProgramme>> getEpgInfo({
    required String portalId,
    required String chId,
    required int period,
  }) async {
    try {
      final url =
          '$_baseUrl/server/load.php?type=epg&action=get_epg_info&ch_id=$chId&period=$period&mac=$_macAddress';
      appLogger.d('Fetching Stalker EPG info from: $url');

      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.data == null || response.data!.trim().isEmpty) {
        throw Exception('Received an empty response from the server for EPG info.');
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.data!);
      final List<dynamic>? epgData = jsonResponse['js']?['data'];

      if (epgData == null || epgData.isEmpty) {
        appLogger.w('EPG data is empty or not in the expected format.');
        return [];
      }

      return epgData.map((item) => EpgProgramme.fromStalkerJson(item as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      appLogger.e('Error fetching EPG info', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
