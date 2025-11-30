import 'dart:async';
import 'dart:convert';
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
    String currentUrl = initialUrl;
    int redirectCount = 0;
    const int maxRedirects = 10;
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;

    try {
      while (redirectCount < maxRedirects) {
        _logger.d('[StreamProbe] Probing: $currentUrl');

        final request = await client.headUrl(Uri.parse(currentUrl));
        request.followRedirects = false;
        if (headers != null) {
          headers.forEach((k, v) {
            if (k.toLowerCase() != 'host') {
              request.headers.set(k, v);
            }
          });
        }

        final response = await request.close();
        await response.drain(); // Drain body for HEAD

        if (response.statusCode >= 300 && response.statusCode < 400) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location != null && location.isNotEmpty) {
            _logger.d('[StreamProbe] Redirect found: $location');
            currentUrl = _resolveLocation(currentUrl, location);
            redirectCount++;
            continue;
          }
        }

        if (response.statusCode == 200) {
          break;
        }
        break;
      }

      // 2. Verify with Ranged GET
      _logger.d('[StreamProbe] Verifying with Ranged GET: $currentUrl');
      final rangeReq = await client.getUrl(Uri.parse(currentUrl));
      rangeReq.followRedirects = false;
      if (headers != null) {
        headers.forEach((k, v) {
          if (k.toLowerCase() != 'host') {
            rangeReq.headers.set(k, v);
          }
        });
      }
      rangeReq.headers.set(HttpHeaders.rangeHeader, 'bytes=0-255');

      final rangeResponse = await rangeReq.close();

      if (rangeResponse.statusCode >= 300 && rangeResponse.statusCode < 400) {
        final location = rangeResponse.headers.value(
          HttpHeaders.locationHeader,
        );
        if (location != null) {
          _logger.d('[StreamProbe] GET Redirect found: $location');
          return resolve(
            _resolveLocation(currentUrl, location),
            headers: headers,
          );
        }
      }

      if (rangeResponse.statusCode != 200 && rangeResponse.statusCode != 206) {
        throw StreamProbeException(
          'Stream probe failed with status ${rangeResponse.statusCode}',
          url: currentUrl,
          statusCode: rangeResponse.statusCode,
        );
      }

      // Check body for HTML
      final bytes = await rangeResponse.cast<List<int>>().first;
      final prefix = utf8.decode(bytes.take(50).toList(), allowMalformed: true);

      if (prefix.trim().toLowerCase().startsWith('<html') ||
          prefix.trim().toLowerCase().startsWith('<!doctype')) {
        throw StreamProbeException(
          'Stream returned HTML (likely blocked)',
          url: currentUrl,
          isBlocked: true,
        );
      }

      _logger.i('[StreamProbe] Successfully resolved: $currentUrl');
      return currentUrl;
    } catch (e) {
      _logger.e('[StreamProbe] Error resolving stream', error: e);
      rethrow;
    } finally {
      client.close();
    }
  }

  static String _resolveLocation(String originalUrl, String location) {
    final uri = Uri.parse(location);
    if (uri.hasScheme) {
      return location;
    }
    // Handle root-relative or relative
    final originalUri = Uri.parse(originalUrl);
    return originalUri.resolve(location).toString();
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
