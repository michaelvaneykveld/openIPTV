import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_normalizer.dart';

void main() {
  group('StalkerPortalDiscovery', () {
    test(
      'retries transient base-directory failures before succeeding',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        var hits = 0;
        server.listen((request) async {
          hits += 1;
          if (hits == 1) {
            request.response.statusCode = HttpStatus.serviceUnavailable;
          } else {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write('<html>stalker_portal</html>');
          }
          await request.response.close();
        });

        final normalized = normalizeStalkerPortalInput(
          'http://127.0.0.1:${server.port}/stalker_portal/',
        );
        final discovery = StalkerPortalDiscovery();

        final result = await discovery.discoverFromNormalized(
          normalized,
          options: DiscoveryOptions.defaults,
        );

        expect(result.kind, ProviderKind.stalker);
        expect(result.lockedBase.path, '/stalker_portal/');
        expect(
          result.hints['matchedStage']?.startsWith('base-directory'),
          isTrue,
        );
        final baseDirectoryProbes = result.telemetry.probes
            .where((probe) => probe.stage.startsWith('base-directory'))
            .toList();
        expect(baseDirectoryProbes.length, greaterThanOrEqualTo(2));
        expect(
          baseDirectoryProbes.first.statusCode,
          equals(HttpStatus.serviceUnavailable),
        );
        expect(baseDirectoryProbes.last.statusCode, equals(HttpStatus.ok));
      },
    );

    test(
      'flips scheme to http when https candidate fails',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        server.listen((request) async {
          if (request.uri.path.endsWith('/stalker_portal/')) {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write('<html>stalker_portal</html>');
          } else {
            request.response.statusCode = HttpStatus.notFound;
          }
          await request.response.close();
        });

        final discovery = StalkerPortalDiscovery();
        final result = await discovery.discover(
          'https://127.0.0.1:${server.port}/stalker_portal/',
          options: DiscoveryOptions.defaults,
        );

        expect(result.kind, ProviderKind.stalker);
        expect(result.lockedBase.scheme, equals('http'));
        expect(result.lockedBase.path, equals('/stalker_portal/'));
        final probeSchemes =
            result.telemetry.probes.map((probe) => probe.uri.scheme).toSet();
        expect(
          probeSchemes.contains('https'),
          isTrue,
          reason: 'https candidate should be attempted first',
        );
        expect(
          probeSchemes.contains('http'),
          isTrue,
          reason: 'http fallback should be attempted after https failure',
        );
      },
    );

    test(
      'retries base-directory with fallback User-Agent after 403',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        final observedAgents = <String>[];
        server.listen((request) async {
          observedAgents
              .add(request.headers.value(HttpHeaders.userAgentHeader) ?? '<none>');
          if (request.uri.path.endsWith('/stalker_portal/')) {
            final ua = request.headers.value(HttpHeaders.userAgentHeader) ?? '';
            if (ua.contains('QtEmbedded')) {
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.html
                ..write('<html>stalker_portal</html>');
            } else {
              request.response.statusCode = HttpStatus.forbidden;
            }
          } else {
            request.response.statusCode = HttpStatus.notFound;
          }
          await request.response.close();
        });

        final discovery = StalkerPortalDiscovery();
        final result = await discovery.discover(
          'http://127.0.0.1:${server.port}/stalker_portal/',
          options: DiscoveryOptions.defaults,
        );

        expect(result.kind, ProviderKind.stalker);
        expect(result.lockedBase.path, equals('/stalker_portal/'));
        expect(result.hints['needsUserAgent'], equals('true'));
        expect(result.hints['matchedStage'], equals('base-directory (UA retry)'));
        expect(
          observedAgents.first,
          isNot(contains('QtEmbedded')),
          reason: 'initial attempt uses default UA',
        );
        expect(
          observedAgents.any((ua) => ua.contains('QtEmbedded')),
          isTrue,
          reason: 'fallback UA should be used on retry',
        );
      },
    );
  });
}
