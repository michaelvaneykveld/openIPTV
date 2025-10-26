import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/utils/url_normalization.dart';

void main() {
  group('canonicalizeScheme', () {
    test('adds default scheme when missing', () {
      expect(canonicalizeScheme('example.com'), equals('https://example.com'));
    });

    test('retains existing scheme', () {
      expect(
        canonicalizeScheme('http://example.com'),
        equals('http://example.com'),
      );
    });
  });

  group('normalizePort', () {
    test('preserves explicit port', () {
      final uri = Uri.parse('https://example.com:8443/path');
      expect(normalizePort(uri).port, 8443);
    });

    test('defaults https to 443', () {
      final uri = Uri.parse('https://example.com/path');
      expect(normalizePort(uri).port, 443);
    });

    test('defaults http to 80', () {
      final uri = Uri.parse('http://example.com/path');
      expect(normalizePort(uri).port, 80);
    });
  });

  group('stripKnownFiles', () {
    test('removes trailing known file', () {
      final uri = Uri.parse(
        'https://example.com/stalker_portal/portal.php?token=abc',
      );
      final result = stripKnownFiles(uri);
      expect(result.path, '/stalker_portal');
      expect(result.hasQuery, isFalse);
    });

    test('keeps non-matching segments', () {
      final uri = Uri.parse('https://example.com/custom/path/');
      final result = stripKnownFiles(uri);
      expect(result.path, '/custom/path');
    });
  });

  group('ensureTrailingSlash', () {
    test('adds trailing slash to directory path', () {
      final uri = Uri.parse('https://example.com/custom/path');
      expect(ensureTrailingSlash(uri).path, '/custom/path/');
    });

    test('handles root path', () {
      final uri = Uri.parse('https://example.com');
      expect(ensureTrailingSlash(uri).path, '/');
    });
  });
}
