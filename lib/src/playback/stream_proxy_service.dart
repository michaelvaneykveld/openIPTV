import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:openiptv/src/utils/playback_logger.dart';

class StreamProxyService {
  static HttpServer? _server;
  static final Map<String, _ProxySession> _sessions = {};

  static Future<String> start() async {
    if (_server != null) return 'http://127.0.0.1:${_server!.port}';

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
    return 'http://127.0.0.1:${_server!.port}';
  }

  static String createProxyUrl(
    String targetUrl,
    Map<String, String> headers, {
    Map<String, String>? cookies,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _sessions[id] = _ProxySession(targetUrl, headers, cookies ?? {});
    return 'http://127.0.0.1:${_server!.port}/proxy?id=$id';
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    final id = request.uri.queryParameters['id'];
    final session = _sessions[id];

    if (session == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final client = http.Client();
    try {
      final proxyReq = http.Request('GET', Uri.parse(session.url));
      proxyReq.headers.addAll(session.headers);
      if (session.cookies.isNotEmpty) {
        proxyReq.headers['Cookie'] = session.cookies.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');
      }

      final range = request.headers.value('range');
      if (range != null) {
        proxyReq.headers['range'] = range;
      }

      final response = await client.send(proxyReq);

      request.response.statusCode = response.statusCode;
      response.headers.forEach((name, values) {
        if (name.toLowerCase() != 'content-encoding' &&
            name.toLowerCase() != 'content-length' &&
            name.toLowerCase() != 'transfer-encoding') {
          request.response.headers.set(name, values);
        }
      });

      if (response.contentLength != null) {
        request.response.contentLength = response.contentLength!;
      }

      await request.response.addStream(response.stream);
    } catch (e) {
      PlaybackLogger.videoError('proxy-error', error: e);
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
      client.close();
    }
  }
}

class _ProxySession {
  final String url;
  final Map<String, String> headers;
  final Map<String, String> cookies;
  _ProxySession(this.url, this.headers, this.cookies);
}
