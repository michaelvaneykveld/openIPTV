import 'package:dio/dio.dart';
import 'package:openiptv/utils/app_logger.dart';

/// A utility class to find the correct base API URL for a Stalker portal
/// from user-provided input.
class StalkerUrlResolver {
  final Dio _dio;

  StalkerUrlResolver(this._dio);

  /// Takes a user-provided URL and tries to find a working Stalker API endpoint.
  ///
  /// It normalizes the URL, constructs a base URL, and then tests a list of
  /// known API paths.
  ///
  /// Returns the correct base URL (e.g., `http://portal.example.com:8080`) if found.
  /// Throws an [Exception] if no working endpoint can be found.
  Future<String> resolve(String userInputUrl) async {
    appLogger.d('Attempting to resolve Stalker URL: $userInputUrl');

    // 1. Normalize the URL
    String normalizedUrl = userInputUrl.trim();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'http://$normalizedUrl';
    }

    // 2. Parse and construct the base URL (scheme://host:port)
    final Uri uri;
    try {
      uri = Uri.parse(normalizedUrl);
    } catch (e) {
      throw FormatException('Invalid URL format: $userInputUrl');
    }
    final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';

    // 3. List of known API paths to test
    final List<String> knownApiPaths = [
      '/server/load.php',
      '/portal.php',
    ];

    // 4. Test each path
    for (final path in knownApiPaths) {
      final testUrl = '$baseUrl$path';
      try {
        // Corrected the syntax by removing an extra parenthesis and formatted for readability.
        final response = await _dio.get<String>(
          testUrl,
          options: Options(
              responseType: ResponseType.plain,
              validateStatus: (status) => status! < 500),
        );
        // A valid endpoint will return JSON (even a JSON error), not HTML.
        if (response.data != null && !response.data!.trim().toLowerCase().startsWith('<!doctype html')) {
          appLogger.d('Found working Stalker API at: $baseUrl');
          return baseUrl;
        }
      } catch (e) {
        // Log the error for debugging purposes and try the next path.
        appLogger.w('Test for path "$path" failed. Error: $e');
      }
    }

    throw Exception('Could not find a valid Stalker API endpoint for the provided URL.');
  }
}
