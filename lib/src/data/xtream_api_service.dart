import 'package:dio/dio.dart';
import 'package:openiptv/utils/app_logger.dart';

class XtreamApiService {
  final Dio _dio;
  final String _baseUrl;

  XtreamApiService(this._baseUrl) : _dio = Dio();

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/player_api.php',
        queryParameters: {
          'username': username,
          'password': password,
        },
      );
      appLogger.d('Xtream login response: ${response.data}');

      // Basic check for success. Xtream API usually returns user info on success.
      // You might need to refine this based on actual Xtream API response structure.
      if (response.statusCode == 200 && response.data != null && response.data['user_info'] != null) {
        appLogger.d('Xtream login successful for user: $username');
        return true;
      } else {
        appLogger.e('Xtream login failed: ${response.data}');
        return false;
      }
    } on DioException catch (e, stackTrace) {
      appLogger.e('Error during Xtream login', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
