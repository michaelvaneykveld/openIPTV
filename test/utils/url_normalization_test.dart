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

  group('tryParseLenientHttpUri', () {
    test('parses bare domains by adding default scheme', () {
      final uri = tryParseLenientHttpUri('open.iptv.me');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'open.iptv.me');
    });

    test('recognises IPv4 with explicit port', () {
      final uri = tryParseLenientHttpUri('192.168.1.20:8080/api');
      expect(uri, isNotNull);
      expect(uri!.host, '192.168.1.20');
      expect(uri.port, 8080);
      expect(uri.path, '/api');
    });

    test('recognises IPv6 hosts without brackets', () {
      final uri = tryParseLenientHttpUri('2001:db8::1:8443/playlist.m3u8');
      expect(uri, isNotNull);
      expect(uri!.host, '2001:db8::1');
      expect(uri.port, 8443);
      expect(uri.path, '/playlist.m3u8');
    });

    test('rejects filesystem-looking paths', () {
      final uri = tryParseLenientHttpUri(r'C:\iptv\channels.m3u');
      expect(uri, isNull);
    });
  });

  group('isLikelyFilesystemPath', () {
    test('detects windows drive paths', () {
      expect(isLikelyFilesystemPath(r'D:\media\playlist.m3u8'), isTrue);
    });

    test('detects unix absolute paths', () {
      expect(isLikelyFilesystemPath('/var/media/playlist.m3u8'), isTrue);
    });

    test('detects UNC paths', () {
      expect(isLikelyFilesystemPath(r'\\nas\iptv\playlist.m3u'), isTrue);
    });

    test('ignores remote hosts', () {
      expect(isLikelyFilesystemPath('open.iptv.me'), isFalse);
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
