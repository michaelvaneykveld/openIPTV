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
  });
}
