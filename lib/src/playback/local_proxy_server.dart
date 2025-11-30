import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';

class LocalProxyServer {
  static final Logger _logger = Logger();
  static HttpServer? _server;
  static int _port = 0;

  static int get port => _port;

  static Future<void> start() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      _logger.i('[LocalProxyServer] Started on port $_port');

      _server!.listen(
        _handleRequest,
        onError: (e) {
          _logger.e('[LocalProxyServer] Server error', error: e);
        },
      );
    } catch (e) {
      _logger.e('[LocalProxyServer] Failed to start', error: e);
      rethrow;
    }
  }

  static Future<void> stop() async {
    await _server?.close();
    _server = null;
    _port = 0;
  }

  static String createProxyUrl(String remoteUrl, Map<String, String> headers) {
    if (_server == null) {
      throw StateError('LocalProxyServer not started');
    }
    final encodedUrl = Uri.encodeComponent(remoteUrl);
    final encodedHeaders = base64Url.encode(utf8.encode(jsonEncode(headers)));
    return 'http://127.0.0.1:$_port/proxy?url=$encodedUrl&h=$encodedHeaders';
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    final client = HttpClient();
    // Allow self-signed certs if needed (Xtream often uses them)
    client.badCertificateCallback = (cert, host, port) => true;

    try {
      final uri = request.uri;
      if (uri.path != '/proxy') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final remoteUrlParam = uri.queryParameters['url'];
      final headersParam = uri.queryParameters['h'];

      if (remoteUrlParam == null) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('Missing url parameter');
        await request.response.close();
        return;
      }

      final remoteUrl = Uri.decodeComponent(remoteUrlParam);
      Map<String, String> headers = {};
      if (headersParam != null) {
        try {
          final jsonStr = utf8.decode(base64Url.decode(headersParam));
          headers = Map<String, String>.from(jsonDecode(jsonStr));
        } catch (e) {
          _logger.w('[LocalProxyServer] Failed to decode headers', error: e);
        }
      }

      _logger.d('[LocalProxyServer] Proxying: $remoteUrl');

      // Create outgoing request
      final proxyReq = await client.getUrl(Uri.parse(remoteUrl));

      // Copy headers
      headers.forEach((k, v) {
        // Skip Host header to let HttpClient set it correctly for the target
        if (k.toLowerCase() != 'host') {
          proxyReq.headers.set(k, v);
        }
      });

      // Forward Range header from player if present
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null) {
        proxyReq.headers.set(HttpHeaders.rangeHeader, range);
      }

      final proxyRes = await proxyReq.close();

      _logger.d(
        '[LocalProxyServer] Upstream response: ${proxyRes.statusCode} ${proxyRes.reasonPhrase}',
      );

      // Forward status code
      request.response.statusCode = proxyRes.statusCode;

      // Forward response headers
      proxyRes.headers.forEach((name, values) {
        // Skip encoding headers as we are streaming raw bytes
        if (name.toLowerCase() != 'transfer-encoding' &&
            name.toLowerCase() != 'content-encoding') {
          for (final v in values) {
            request.response.headers.add(name, v);
          }
        }
      });

      // Stream data
      await proxyRes.pipe(request.response);
    } catch (e) {
      _logger.e('[LocalProxyServer] Proxy error', error: e);
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    } finally {
      client.close();
    }
  }
}
