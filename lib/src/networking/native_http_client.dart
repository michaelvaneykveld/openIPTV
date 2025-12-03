import 'dart:io';
import 'package:openiptv/src/networking/winhttp_client.dart';

/// Native HTTP client that uses platform-specific implementations
///
/// On Android: Uses OkHttp (same as TiviMate) with BoringSSL
/// On Windows: Uses WinHTTP (Windows native client)
///
/// This bypasses Cloudflare's TLS fingerprinting by using the
/// exact same HTTP client stack as native platform apps.
class NativeHttpClient {
  /// Test if a URL is accessible using native HTTP client
  ///
  /// Returns a map with:
  /// - statusCode: HTTP status code
  /// - statusMessage: HTTP status message
  /// - headers: Response headers (may be limited on some platforms)
  /// - success: true if 2xx response
  static Future<Map<String, dynamic>> testConnection(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError(
        'Native HTTP client only supported on Android and Windows',
      );
    }

    if (Platform.isWindows) {
      // Use WinHTTP on Windows
      return WinHttpClient.testConnection(url, headers: headers);
    } else if (Platform.isAndroid) {
      // Use OkHttp on Android (via platform channel - not implemented yet)
      throw UnimplementedError('Android platform channel not yet implemented');
    }

    throw UnsupportedError('Platform not supported');
  }

  /// Check if native HTTP client is available on current platform
  static bool get isAvailable {
    return Platform.isAndroid || Platform.isWindows;
  }

  /// Get a description of the native HTTP client being used
  static String get clientDescription {
    if (Platform.isAndroid) {
      return 'OkHttp (Android native, same as TiviMate)';
    } else if (Platform.isWindows) {
      return 'WinHTTP (Windows native)';
    } else {
      return 'Not available';
    }
  }
}
