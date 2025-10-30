import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_discovery.dart';

void main() {
  group('XtreamPortalDiscovery', () {
    test(
      'treats XUI invalid credential banner as a valid Xtream signature',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        server.listen((request) async {
          if (request.uri.path.endsWith('/player_api.php')) {
            const htmlResponse = '''
<!DOCTYPE html>
<html lang="en">
  <head><title>XUI.one - Debug Mode</title></head>
  <body>
    <div>INVALID_CREDENTIALS</div>
    <p>Username or password is invalid.</p>
  </body>
</html>
''';
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(htmlResponse);
          } else {
            request.response.statusCode = HttpStatus.notFound;
          }
          await request.response.close();
        });

        final baseUri = Uri.parse('http://127.0.0.1:${server.port}/');
        final discovery = XtreamPortalDiscovery();

        final result = await discovery.discoverFromUri(
          baseUri,
          options: DiscoveryOptions.defaults,
        );

        expect(result.kind, ProviderKind.xtream);
        expect(result.lockedBase, baseUri);
        expect(result.hints['matchedEndpoint'], equals('player_api.php'));
      },
    );

    test('retries transient server errors once before succeeding', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      var hits = 0;
      server.listen((request) async {
        if (request.uri.path.endsWith('/player_api.php')) {
          hits += 1;
          if (hits == 1) {
            request.response.statusCode = HttpStatus.serviceUnavailable;
          } else {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write('{"server_info":{},"user_info":{}}');
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });

      final baseUri = Uri.parse('http://127.0.0.1:${server.port}/');
      final discovery = XtreamPortalDiscovery();

      final result = await discovery.discoverFromUri(
        baseUri,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.xtream);
      expect(result.lockedBase, baseUri);
      expect(result.telemetry.probes.length, greaterThanOrEqualTo(2));
      final statuses = result.telemetry.probes
          .where((probe) => probe.stage.startsWith('player_api.php'))
          .map((probe) => probe.statusCode)
          .whereType<int>()
          .toList();
      expect(statuses.first, equals(HttpStatus.serviceUnavailable));
      expect(statuses.last, equals(HttpStatus.ok));
    });

    test('follows redirects to resolved player_api endpoint', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        if (request.uri.path == '/player_api.php') {
          request.response
            ..statusCode = HttpStatus.found
            ..headers.set(
              HttpHeaders.locationHeader,
              'http://127.0.0.1:${server.port}/redirect/player_api.php',
            );
        } else if (request.uri.path == '/redirect/player_api.php') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write('{"server_info":{},"user_info":{}}');
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });

      final discovery = XtreamPortalDiscovery();
      final baseUri = Uri.parse('http://127.0.0.1:${server.port}/');

      final result = await discovery.discoverFromUri(
        baseUri,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.xtream);
      expect(
        result.lockedBase.toString(),
        'http://127.0.0.1:${server.port}/redirect/',
      );
      expect(result.hints['matchedEndpoint'], 'player_api.php');
      final playerApiProbes = result.telemetry.probes
          .where((record) => record.stage.contains('player_api.php'))
          .toList();
      expect(playerApiProbes, isNotEmpty);
      expect(playerApiProbes.first.uri.path, '/redirect/player_api.php');
      expect(playerApiProbes.first.statusCode, HttpStatus.ok);
    });

    test('retries with fallback user-agent after 403 response', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      final userAgents = <String>[];
      server.listen((request) async {
        userAgents.add(
          request.headers.value(HttpHeaders.userAgentHeader) ?? '<none>',
        );
        if (request.uri.path.endsWith('/player_api.php')) {
          final ua = request.headers.value(HttpHeaders.userAgentHeader) ?? '';
          if (ua.contains('XtreamProbe')) {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write('{"server_info":{},"user_info":{}}');
          } else {
            request.response.statusCode = HttpStatus.forbidden;
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });

      final discovery = XtreamPortalDiscovery();
      final baseUri = Uri.parse('http://127.0.0.1:${server.port}/');

      final result = await discovery.discoverFromUri(
        baseUri,
        options: DiscoveryOptions.defaults,
      );

      expect(result.kind, ProviderKind.xtream);
      expect(result.lockedBase, baseUri);
      expect(result.hints['needsUserAgent'], 'true');
      expect(
        userAgents.any((ua) => ua.contains('XtreamProbe')),
        isTrue,
        reason: 'Fallback user-agent should be used on retry',
      );
      final statusCodes = result.telemetry.probes
          .where((probe) => probe.stage.startsWith('player_api.php'))
          .map((probe) => probe.statusCode)
          .whereType<int>()
          .toList();
      expect(statusCodes.first, HttpStatus.forbidden);
      expect(statusCodes.last, HttpStatus.ok);
    });
  });
}
