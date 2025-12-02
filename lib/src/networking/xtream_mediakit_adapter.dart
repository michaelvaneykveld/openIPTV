import 'dart:async';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'xtream_api_client.dart';

/// Adapter that feeds raw TCP socket stream into media_kit player
///
/// This bridges the gap between our raw socket implementation and
/// media_kit's expectation of a media source URL.
class XtreamMediaKitAdapter {
  /// Create a Media object from raw streaming connection
  ///
  /// Since media_kit requires a URL/URI and doesn't accept raw streams directly,
  /// we need to use a local HTTP proxy that serves the raw socket data.
  static Media fromStreamingConnection(
    StreamingConnection connection, {
    Map<String, String>? httpHeaders,
  }) {
    // For now, construct a standard HTTP URL
    // The actual streaming will be handled by our raw socket proxy
    // which will be integrated into LocalProxyServer
    return Media(connection.url, httpHeaders: httpHeaders);
  }

  /// Create a streaming proxy server that serves raw socket data
  ///
  /// This starts a local HTTP server that:
  /// 1. Accepts requests from media_kit
  /// 2. Opens raw TCP socket to Xtream server
  /// 3. Pipes data from socket to HTTP response
  static Future<StreamingProxyServer> createProxyServer() async {
    return StreamingProxyServer._create();
  }
}

/// Local HTTP proxy server that serves raw socket streams to media_kit
class StreamingProxyServer {
  late HttpServer _server;
  String? _currentHost;
  int? _currentPort;
  String? _currentPath;

  static Future<StreamingProxyServer> _create() async {
    final proxy = StreamingProxyServer();

    // Start server on random available port
    proxy._server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    print(
      '[xtream-proxy] Streaming proxy server started on port ${proxy._server.port}',
    );

    // Handle incoming requests
    proxy._server.listen(proxy._handleRequest);

    return proxy;
  }

  /// Get the local proxy URL for a streaming connection
  String getProxyUrl(StreamingConnection connection) {
    _currentHost = connection.host;
    _currentPort = connection.port;
    _currentPath = connection.path;

    return 'http://127.0.0.1:${_server.port}/stream';
  }

  /// Handle proxy request from media_kit
  Future<void> _handleRequest(HttpRequest request) async {
    print('[xtream-proxy] Received request: ${request.uri}');

    if (_currentHost == null || _currentPort == null || _currentPath == null) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('No streaming connection configured');
      await request.response.close();
      return;
    }

    try {
      // Open raw socket connection to Xtream server
      final client = XtreamApiClient();
      final connection = await client.openStreamingConnection(
        host: _currentHost!,
        port: _currentPort!,
        type: 'live', // Will be parameterized later
        username: '', // Will be parameterized later
        password: '',
        streamId: '',
      );

      // Set response headers
      request.response.headers.set('Content-Type', 'video/MP2T');
      request.response.headers.set('Connection', 'keep-alive');

      // Pipe socket data to HTTP response
      await request.response.addStream(connection.socket);
      await request.response.close();

      print('[xtream-proxy] Stream completed successfully');
    } catch (e) {
      print('[xtream-proxy] Stream failed: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Streaming failed: $e');
      await request.response.close();
    }
  }

  /// Close the proxy server
  Future<void> close() async {
    await _server.close();
    print('[xtream-proxy] Streaming proxy server closed');
  }
}

/// Extension methods for easy integration
extension XtreamMediaExtension on Media {
  /// Check if this media uses raw socket streaming
  bool get isXtreamRawSocket {
    return uri.startsWith('xtream-raw://');
  }
}
