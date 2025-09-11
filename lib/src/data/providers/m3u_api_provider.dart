import 'package:dio/dio.dart';
import 'package:openiptv/src/core/models/m3u_credentials.dart';
import 'package:openiptv/utils/app_logger.dart';

class M3uApiService {
  final Dio _dio;
  final M3uCredentials _credentials;

  M3uApiService(this._dio, this._credentials);

  Future<String> getRawM3uContent() async {
    try {
      appLogger.d('Fetching M3U content from: ${_credentials.m3uUrl}');
      final response = await _dio.get(_credentials.m3uUrl);
      if (response.statusCode == 200 && response.data != null) {
        appLogger.d('Successfully fetched M3U content.');
        return response.data as String;
      } else {
        throw Exception('Failed to fetch M3U content: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      appLogger.e('Error fetching M3U content', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
