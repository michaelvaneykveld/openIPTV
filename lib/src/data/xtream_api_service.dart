import 'package:dio/dio.dart';
import 'package:openiptv/utils/app_logger.dart';
import 'package:openiptv/src/core/exceptions/api_exceptions.dart'; // New import

import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/vod_category.dart';
import 'package:openiptv/src/core/models/vod_content.dart';

class XtreamApiService {
  final Dio _dio;
  final String _baseUrl;

  XtreamApiService(this._baseUrl) : _dio = Dio();

  Future<bool> login(String username, String password) async {
    appLogger.d('Attempting Xtream login for user: $username');
    try {
      final response = await _dio.get(
        '$_baseUrl/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
        },
      );
      appLogger.d('Xtream login response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw InvalidApiResponseException(
              'Expected JSON response, but received non-JSON data.');
        }
        if (response.data['user_info'] != null) {
          appLogger.d('Xtream login successful for user: $username');
          return true;
        }
      }
      appLogger.e('Xtream login failed: ${response.data}');
      return false;
    } on DioException catch (e, stackTrace) {
      appLogger.e('Error during Xtream login', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<List<VodCategory>> getLiveCategories(
      String username, String password) async {
    return _getCategories(username, password, 'get_live_categories');
  }

  Future<List<VodCategory>> getVodCategories(
      String username, String password) async {
    return _getCategories(username, password, 'get_vod_categories');
  }

  Future<List<VodCategory>> getSeriesCategories(
      String username, String password) async {
    return _getCategories(username, password, 'get_series_categories');
  }

  Future<List<Channel>> getLiveStreams(
      String username, String password, String categoryId) async {
    appLogger.d('Fetching live streams for category: $categoryId');
    try {
      final response = await _dio.get(
        '$_baseUrl/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
          'action': 'get_live_streams',
          'category_id': categoryId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final streams = (response.data as List)
            .map((stream) => Channel.fromXtreamJson(stream))
            .toList();
        appLogger.d('Fetched ${streams.length} live streams');
        return streams;
      }
      appLogger.e('Failed to fetch live streams: ${response.data}');
      return [];
    } on DioException catch (e, stackTrace) {
      appLogger.e('Error fetching live streams', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<VodContent>> getVodStreams(
      String username, String password, String categoryId) async {
    appLogger.d('Fetching VOD streams for category: $categoryId');
    try {
      final response = await _dio.get(
        '$_baseUrl/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
          'action': 'get_vod_streams',
          'category_id': categoryId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final streams = (response.data as List)
            .map((stream) => VodContent.fromJson(stream, categoryId: categoryId))
            .toList();
        appLogger.d('Fetched ${streams.length} VOD streams');
        return streams;
      }
      appLogger.e('Failed to fetch VOD streams: ${response.data}');
      return [];
    } on DioException catch (e, stackTrace) {
      appLogger.e('Error fetching VOD streams', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<VodContent>> getSeries(
      String username, String password, String categoryId) async {
    appLogger.d('Fetching series for category: $categoryId');
    try {
      final response = await _dio.get(
        '$_baseUrl/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
          'action': 'get_series',
          'category_id': categoryId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final series = (response.data as List)
            .map((stream) => VodContent.fromJson(stream, categoryId: categoryId))
            .toList();
        appLogger.d('Fetched ${series.length} series');
        return series;
      }
      appLogger.e('Failed to fetch series: ${response.data}');
      return [];
    } on DioException catch (e, stackTrace) {
      appLogger.e('Error fetching series', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<VodCategory>> _getCategories(
      String username, String password, String action) async {
    appLogger.d('Fetching categories with action: $action');
    try {
      final response = await _dio.get(
        '$_baseUrl/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
          'action': action,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final categories = (response.data as List)
            .map((category) => VodCategory.fromJson({
                  'id': category['category_id'],
                  'title': category['category_name'],
                }))
            .toList();
        appLogger.d('Fetched ${categories.length} categories');
        return categories;
      }
      appLogger.e('Failed to fetch categories: ${response.data}');
      return [];
    } on DioException catch (e, stackTrace) {
      appLogger.e('Error fetching categories', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
