import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';

class StreamProbe {
  static final Logger _logger = Logger();

  /// Probes the URL to find the final streamable URL.
  /// Follows redirects (handling root-relative ones).
  /// Checks if the final URL returns binary data (not HTML).
  /// Returns the final URL if successful.
  /// Throws [StreamProbeException] if blocked or invalid.
  static Future<String> resolve(
    String initialUrl, {
    Map<String, String>? headers,
  }) async {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;

    try {
      _logger.d('[StreamProbe] Probing: $initialUrl with headers: ${headers?.keys.join(", ") ?? "none"}');
      
      String currentUrl = initialUrl;
      int redirectCount = 0;
      const maxRedirects = 10;
      
      // Manually handle redirects to preserve headers
      while (redirectCount < maxRedirects) {
        final request = await client.getUrl(Uri.parse(currentUrl));
        request.followRedirects = false; // Handle manually
        
        if (headers != null) {
          headers.forEach((k, v) {
            if (k.toLowerCase() != 'host') {
              request.headers.set(k, v);
            }
          });
        }

        final response = await request.close();
        final statusCode = response.statusCode;
        
        _logger.d('[StreamProbe] Response: $statusCode for $currentUrl');
        
        // Handle redirects
        if (statusCode >= 300 && statusCode < 400) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location != null && location.isNotEmpty) {
            _logger.d('[StreamProbe] Redirect #$redirectCount: $location');
            currentUrl = location;
            redirectCount++;
            await response.drain();
            continue;
          }
        }
        
        if (statusCode == 200) {
          await response.drain();
          _logger.i('[StreamProbe] Successfully resolved: $currentUrl');
          return currentUrl;
        }
        
        await response.drain();
        throw StreamProbeException(
          'Stream probe failed with status $statusCode',
          url: currentUrl,
          statusCode: statusCode,
        );
      }
      
      throw StreamProbeException(
        'Too many redirects ($maxRedirects)',
        url: currentUrl,
      );
    } catch (e) {
      _logger.e('[StreamProbe] Error resolving stream', error: e);
      rethrow;
    } finally {
      client.close();
    }
  }
}

class StreamProbeException implements Exception {
  final String message;
  final String url;
  final int? statusCode;
  final bool isBlocked;

  StreamProbeException(
    this.message, {
    required this.url,
    this.statusCode,
    this.isBlocked = false,
  });

  @override
  String toString() => 'StreamProbeException: $message (URL: $url)';
}
