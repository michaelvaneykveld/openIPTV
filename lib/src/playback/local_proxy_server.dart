import 'dart:async';
import 'dart:io';

import 'package:openiptv/src/utils/playback_logger.dart';
import 'package:openiptv/src/networking/xtream_raw_client.dart';

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
      extra: {'proxyUrl': proxyUrl, 'targetUrl': targetUrl, 'port': _port},
    );
    return proxyUrl;
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    // Use raw TCP sockets instead of HttpClient to avoid automatic header injection
    final rawClient = XtreamRawClient(
      timeout: const Duration(seconds: 30),
      enableLogging: true,
    );

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

      PlaybackLogger.videoInfo(
        'proxy-sending-to-upstream-raw',
        extra: {
          'scheme': targetUri.scheme,
          'host': targetUri.host,
          'port': targetUri.port,
          'path': targetUri.path,
          'fullUrl': targetUri.toString(),
          'method': 'RAW-TCP-SOCKET',
        },
      );

      // Collect custom headers from query params (h_ prefix)
      final customHeaders = <String, String>{};
      for (final entry in request.uri.queryParameters.entries) {
        if (entry.key.startsWith('h_')) {
          final headerName = entry.key.substring(2);
          customHeaders[headerName] = entry.value;
        }
      }

      // Log headers being sent
      PlaybackLogger.videoInfo('proxy-raw-headers-sent', extra: customHeaders);

      // Open raw socket stream for media content
      final streamWithHeaders = await rawClient.openStream(
        targetUri.host,
        targetUri.port,
        '${targetUri.path}${targetUri.query.isNotEmpty ? '?' : ''}${targetUri.query}',
        customHeaders,
      );

      request.response.statusCode = streamWithHeaders.statusCode;

      PlaybackLogger.videoInfo(
        'proxy-raw-upstream-connected',
        extra: {
          'statusCode': streamWithHeaders.statusCode,
          'reasonPhrase': streamWithHeaders.reasonPhrase,
          'method': 'streaming-from-raw-socket',
          'headers': streamWithHeaders.headers.toString(),
        },
      );

      // Set appropriate headers for streaming
      request.response.headers.set('Content-Type', 'video/MP2T');
      request.response.headers.set('Connection', 'keep-alive');

      // Pipe raw socket stream directly to HTTP response
      await streamWithHeaders.stream.pipe(request.response);
    } catch (e) {
      PlaybackLogger.videoError(
        'proxy-raw-error',
        error: e,
        description: 'Failed to proxy request via raw socket',
      );
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Proxy error: $e');
        await request.response.close();
      } catch (_) {}
    }
  }
}
