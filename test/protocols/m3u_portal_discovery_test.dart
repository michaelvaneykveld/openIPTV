import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_portal_discovery.dart';

void main() {
  group('M3uPortalDiscovery', () {
    test('accepts playlists when HEAD advertises M3U content-type', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        if (request.method == 'HEAD') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType('application', 'x-mpegurl');
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('#EXTM3U\n');
        }
        await request.response.close();
      });

      final discovery = M3uPortalDiscovery();
      final uri = 'http://127.0.0.1:${server.port}/playlist.m3u8';

      final result = await discovery.discover(
        uri,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.m3u);
      expect(result.lockedBase.toString(), uri);
      expect(result.hints['matchedStage'], 'HEAD');
    });

    test('retries transient HEAD failures once before succeeding', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      var headHits = 0;
      server.listen((request) async {
        if (request.method == 'HEAD') {
          headHits += 1;
          if (headHits == 1) {
            request.response.statusCode = HttpStatus.serviceUnavailable;
          } else {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType('application', 'x-mpegurl');
          }
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('#EXTM3U\n');
        }
        await request.response.close();
      });

      final discovery = M3uPortalDiscovery();
      final uri = 'http://127.0.0.1:${server.port}/playlist.m3u8';

      final result = await discovery.discover(
        uri,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.m3u);
      expect(result.lockedBase.toString(), uri);
      expect(result.hints['matchedStage'], 'HEAD (retry)');
    });

    test('falls back to range GET with media UA on 403', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        if (request.method == 'HEAD') {
          request.response.statusCode = HttpStatus.forbidden;
        } else if (request.method == 'GET') {
          final ua = request.headers.value(HttpHeaders.userAgentHeader) ?? '';
          if (ua.contains('VLC/3.0.18')) {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType('audio', 'x-mpegurl')
              ..write('#EXTM3U\n#EXTINF:-1,Channel');
          } else {
            request.response.statusCode = HttpStatus.forbidden;
          }
        } else {
          request.response.statusCode = HttpStatus.methodNotAllowed;
        }
        await request.response.close();
      });

      final discovery = M3uPortalDiscovery();
      final uri = 'http://127.0.0.1:${server.port}/secure.m3u';

      final result = await discovery.discover(
        uri,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.m3u);
      expect(result.hints['needsMediaUserAgent'], 'true');
      expect(result.hints['matchedStage'], 'RANGE (UA retry)');
    });

    test('flips schemes to http when https handshake fails', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        if (request.method == 'HEAD') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType('application', 'x-mpegurl');
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('#EXTM3U\n');
        }
        await request.response.close();
      });

      final discovery = M3uPortalDiscovery();
      final result = await discovery.discover(
        'https://127.0.0.1:${server.port}/channels.m3u',
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.m3u);
      expect(result.lockedBase.scheme, 'http');
    });

    test('validates local playlist files before import', () async {
      final tempDir = await Directory.systemTemp.createTemp('m3u-test');
      addTearDown(() async => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}${Platform.pathSeparator}list.m3u');
      await file.writeAsString('#EXTM3U\n#EXTINF:-1,Test Channel\nhttp://url');

      final discovery = M3uPortalDiscovery();
      final result = await discovery.discover(
        file.path,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.m3u);
      expect(result.lockedBase, Uri.file(file.path));
      expect(result.hints['fileBytes'], isNotEmpty);
      expect(result.hints['modifiedAt'], isNotEmpty);
    });

    test('reclassifies Xtream-style playlists', () async {
      final discovery = M3uPortalDiscovery();

      final result = await discovery.discover(
        'http://example.com/get.php?username=demo&password=demo',
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.xtream);
      expect(result.lockedBase.toString(), 'http://example.com/');
      expect(result.hints['redirect'], 'xtream');
    });

    test('retries when connection closes before headers complete', () async {
      final adapter = _HeadRetryAdapter();
      final dio = Dio()..httpClientAdapter = adapter;

      final discovery = M3uPortalDiscovery(dio: dio);

      final result = await discovery.discover(
        'http://playlist.example.com/list.m3u8',
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.m3u);
      expect(adapter.headAttempts, greaterThan(1));
      final headProbes = result.telemetry.probes
          .where((probe) => probe.stage.startsWith('HEAD'))
          .toList();
      expect(headProbes.length, greaterThan(1));
      expect(
        headProbes.any((probe) => probe.stage.contains('(retry)')),
        isTrue,
      );
    });

    test('follows redirects to signed playlist URLs', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        if (request.requestedUri.path == '/playlist.m3u') {
          request.response
            ..statusCode = HttpStatus.found
            ..headers.set(
              HttpHeaders.locationHeader,
              '/signed/playlist.m3u?token=secret',
            );
        } else if (request.requestedUri.path == '/signed/playlist.m3u') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType('application', 'x-mpegurl')
            ..write('#EXTM3U\n#EXTINF:-1,Channel\nhttp://example.com/stream');
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });

      final discovery = M3uPortalDiscovery();
      final uri = 'http://127.0.0.1:${server.port}/playlist.m3u';

      final result = await discovery.discover(
        uri,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.m3u);
      expect(result.lockedBase.toString(), contains('/signed/playlist.m3u'));
      final sanitized = result.hints['sanitizedPlaylist'];
      expect(sanitized, isNotNull);
      expect(sanitized, contains('/signed/playlist.m3u'));
      expect(sanitized, isNot(contains('token')));
      expect(
        result.hints['matchedStage'],
        anyOf('HEAD', 'RANGE', 'RANGE (UA retry)'),
      );
    });
  });
}

class _HeadRetryAdapter implements HttpClientAdapter {
  int headAttempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'HEAD') {
      headAttempts += 1;
      if (headAttempts == 1) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'Connection closed before full header',
          error: const SocketException('Connection closed before full header'),
        );
      }
      return ResponseBody.fromBytes(
        const <int>[],
        200,
        headers: {
          Headers.contentTypeHeader: ['application/x-mpegurl'],
        },
      );
    }

    if (options.method == 'GET') {
      return ResponseBody.fromString(
        '#EXTM3U\n#EXTINF:-1,Channel\nhttp://example.com/stream',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/x-mpegurl'],
        },
      );
    }

    return ResponseBody.fromBytes(const <int>[], 404);
  }

  @override
  void close({bool force = false}) {}
}
