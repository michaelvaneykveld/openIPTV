import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/src/protocols/stalker/stalker_portal_normalizer.dart';

void main() {
  group('generateStalkerPortalCandidates', () {
    test('preserves classic path when provided', () {
      final normalized = normalizeStalkerPortalInput(
        'https://example.com/stalker_portal/c/',
      );

      final candidates = generateStalkerPortalCandidates(normalized);

      expect(candidates, isNotEmpty);
      expect(
        candidates.first.baseUri.toString(),
        'https://example.com/stalker_portal/c/',
      );
      expect(
        candidates.first.portalPhpUri.toString(),
        'https://example.com/stalker_portal/c/portal.php',
      );
      expect(
        candidates.first.serverLoadUri?.toString(),
        'https://example.com/stalker_portal/server/load.php',
      );
    });

    test('builds ordered fallbacks from bare host', () {
      final normalized = normalizeStalkerPortalInput('example.com');

      final candidates = generateStalkerPortalCandidates(normalized);
      final paths = candidates.map((c) => c.baseUri.path).toList();

      expect(
        paths,
        containsAllInOrder(<String>[
          '/stalker_portal/c/',
          '/c/',
          '/stalker_portal/',
          '/',
        ]),
      );
    });

    test('keeps custom sub-directory as first attempt when present', () {
      final normalized = normalizeStalkerPortalInput(
        'https://example.com/custom/path/',
      );

      final candidates = generateStalkerPortalCandidates(normalized);

      expect(candidates.first.baseUri.path, '/custom/path/');
      expect(candidates.length, greaterThanOrEqualTo(4));
    });
  });
}
