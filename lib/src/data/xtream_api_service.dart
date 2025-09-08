import 'package:dio/dio.dart';
import 'package:openiptv/utils/app_logger.dart';
import 'package:openiptv/src/core/exceptions/api_exceptions.dart'; // New import

class XtreamApiService {
  final Dio _dio;
  final String _baseUrl;

  XtreamApiService(this._baseUrl) : _dio = Dio();

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'username': username,
          'password': password,
        },
      );
      appLogger.d('Xtream login response: ${response.data}');

      // Basic check for success. Xtream API usually returns user info on success.
      // You might need to refine this based on actual Xtream API response structure.
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is! Map<String, dynamic>) {
          throw InvalidApiResponseException('Expected JSON response, but received non-JSON data.');
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
}