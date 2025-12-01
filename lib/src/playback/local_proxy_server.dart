import 'dart:async';
import 'dart:io';

import 'package:openiptv/src/utils/playback_logger.dart';

class LocalProxyServer {
  static HttpServer? _server;
  static int _port = 0;

  static Future<void> start() async {
    if (_server != null) return;

    // Bind to any available port on loopback
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;

    PlaybackLogger.videoInfo('proxy-started', extra: {'port': _port});

    _server!.listen(_handleRequest);
  }

  static String createProxyUrl(String targetUrl, Map<String, String> headers) {
    if (_server == null) {
      throw StateError('LocalProxyServer not started');
    }
    // We encode headers into the URL to keep it stateless
    final uri = Uri.parse('http://127.0.0.1:$_port/proxy');
    final queryParams = <String, String>{'url': targetUrl};
    // Add headers as query params prefixed with h_
    for (final entry in headers.entries) {
      queryParams['h_${entry.key}'] = entry.value;
    }

    final proxyUrl = uri.replace(queryParameters: queryParams).toString();
    PlaybackLogger.videoInfo(
      'proxy-url-created',
      extra: {
        'proxyUrl': proxyUrl,
        'targetUrl': targetUrl,
        'port': _port,
      },
    );
    return proxyUrl;
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    final client = HttpClient();
    // Allow self-signed certs
    client.badCertificateCallback = (cert, host, port) => true;
    // Auto-uncompress
    client.autoUncompress = true;

    try {
      final targetUrl = request.uri.queryParameters['url'];
      PlaybackLogger.videoInfo(
        'proxy-request-received',
        extra: {
          'method': request.method,
          'targetUrl': targetUrl ?? 'MISSING',
          'clientAddress': request.connectionInfo?.remoteAddress.address,
        },
      );
      
      if (targetUrl == null) {
        PlaybackLogger.videoError(
          'proxy-bad-request',
          description: 'Missing url parameter',
        );
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final targetUri = Uri.parse(targetUrl);
      final proxyRequest = await client.openUrl(request.method, targetUri);

      // Copy headers from query params (h_ prefix)
      for (final entry in request.uri.queryParameters.entries) {
        if (entry.key.startsWith('h_')) {
          final headerName = entry.key.substring(2);
          proxyRequest.headers.set(headerName, entry.value);
        }
      }

      // Also copy standard headers from the incoming request (Range, etc.)
      request.headers.forEach((name, values) {
        if (!_isExcludedHeader(name)) {
          for (final value in values) {
            proxyRequest.headers.add(name, value);
          }
        }
      });

      // Ensure User-Agent is set if not already
      // NOTE: We must be careful not to add it if it's already there, to avoid "More than one value" error.
      if (proxyRequest.headers.value(HttpHeaders.userAgentHeader) == null) {
        proxyRequest.headers.set(HttpHeaders.userAgentHeader, 'okhttp/4.9.3');
      } else {
        // Force override to ensure it's the one we want, and only one.
        proxyRequest.headers.set(HttpHeaders.userAgentHeader, 'okhttp/4.9.3');
      }

      // Ensure Connection: keep-alive
      proxyRequest.headers.set(HttpHeaders.connectionHeader, 'keep-alive');

      final proxyResponse = await proxyRequest.close();

      request.response.statusCode = proxyResponse.statusCode;
      
      PlaybackLogger.videoInfo(
        'proxy-upstream-response',
        extra: {
          'statusCode': proxyResponse.statusCode,
          'contentLength': proxyResponse.headers.value('content-length') ?? 'unknown',
          'contentType': proxyResponse.headers.value('content-type') ?? 'unknown',
        },
      );

      // Copy response headers
      proxyResponse.headers.forEach((name, values) {
        if (!_isExcludedResponseHeader(name)) {
          for (final value in values) {
            request.response.headers.add(name, value);
          }
        }
      });

      // Stream the data
      await proxyResponse.pipe(request.response);
    } catch (e) {
      PlaybackLogger.videoError('proxy-error', error: e, description: 'Failed to proxy request');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Proxy error: $e');
        await request.response.close();
      } catch (_) {}
    } finally {
      client.close();
    }
  }

  static bool _isExcludedHeader(String name) {
    final lower = name.toLowerCase();
    return lower == 'host' ||
        lower == 'connection' ||
        lower == 'upgrade' ||
        lower == 'content-length' ||
        lower == 'user-agent' || // We handle UA explicitly
        lower ==
            'referer' || // Exclude Referer to avoid leaking proxy URL or triggering anti-leech
        lower ==
            'accept' || // Exclude Accept to avoid triggering strict server checks
        lower.startsWith('h_'); // Don't copy our internal params
  }

  static bool _isExcludedResponseHeader(String name) {
    final lower = name.toLowerCase();
    return lower == 'connection' ||
        lower == 'transfer-encoding' ||
        lower == 'content-length'; // Let the server calculate this
  }
}
