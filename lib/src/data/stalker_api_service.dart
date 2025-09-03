import 'package:dio/dio.dart';
import 'package:openiptv/utils/app_logger.dart';
import 'package:openiptv/src/data/models.dart';
import 'package:openiptv/src/data/models/epg_programme.dart';

class StalkerApiService {
  final Dio _dio;
  final String _baseUrl;

  StalkerApiService(this._baseUrl) : _dio = Dio();

  Future<Map<String, dynamic>?> handshake() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/portal.php',
        queryParameters: {
          'type': 'stb',
          'action': 'handshake',
          'JsHttpRequest': '1-xml',
        },
      );
      appLogger.d('Handshake response: \${response.data}');
      return response.data;
    } on DioException catch (e) {
      appLogger.e('Error during handshake', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/portal.php',
        queryParameters: {
          'type': 'stb',
          'action': 'get_profile',
          'JsHttpRequest': '1-xml',
        },
      );
      appLogger.d('Get profile response: \${response.data}');
      return response.data;
    } on DioException catch (e) {
      appLogger.e('Error getting profile', error: e);
      return null;
    }
  }

  Future<List<Genre>> getGenres() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'itv',
          'action': 'get_genres',
        },
      );
      appLogger.d('Get genres response: ${response.data}');
      if (response.data is Map && response.data['js'] is List) {
        return (response.data['js'] as List)
            .map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      appLogger.e('Error getting genres', error: e);
      return [];
    }
  }

  Future<List<Channel>> getAllChannels(String genreId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'itv',
          'action': 'get_all_channels',
          'genre': genreId,
        },
      );
      appLogger.d('Get all channels response for genre $genreId: ${response.data}');
      if (response.data is Map && response.data['js'] is List) {
        return (response.data['js'] as List)
            .map((e) => Channel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      appLogger.e('Error getting all channels for genre $genreId', error: e);
      return [];
    }
  }

  Future<List<VodCategory>> getVodCategories() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'vod',
          'action': 'get_categories',
        },
      );
      appLogger.d('Get VOD categories response: ${response.data}');
      if (response.data is Map && response.data['js'] is List) {
        return (response.data['js'] as List)
            .map((e) => VodCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      appLogger.e('Error getting VOD categories', error: e);
      return [];
    }
  }

  Future<List<VodContent>> getVodContent(String categoryId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'vod',
          'action': 'get_content',
          'category_id': categoryId,
        },
      );
      appLogger.d('Get VOD content response for category $categoryId: ${response.data}');
      if (response.data is Map && response.data['js'] is List) {
        return (response.data['js'] as List)
            .map((e) => VodContent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      appLogger.e('Error getting VOD content for category $categoryId', error: e);
      return [];
    }
  }

  Future<List<EpgProgramme>> getEpgInfo({required String chId, required int period}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'itv',
          'action': 'get_epg_info',
          'ch_id': chId,
          'period': period,
          'JsHttpRequest': '1-xml',
        },
      );
      appLogger.d('Get EPG info response for channel $chId, period $period: ${response.data}');
      if (response.data is Map && response.data['js'] is List) {
        return (response.data['js'] as List)
            .map((e) => EpgProgramme.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      appLogger.e('Error getting EPG info for channel $chId, period $period', error: e);
      return [];
    }
  }
}
