import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/utils/input_classifier.dart';

void main() {
  final classifier = InputClassifier();

  group('InputClassifier', () {
    test('detects Xtream links with credentials', () {
      final input =
          'https://demo.example.com/get.php?username=alice&password=secret&type=m3u';

      final result = classifier.classify(input);

      expect(result.provider, ProviderKind.xtream);
      expect(result.xtream, isNotNull);
      expect(result.xtream!.hasCredentials, isTrue);
      expect(result.xtream!.username, 'alice');
      expect(result.xtream!.password, 'secret');
      expect(result.xtream!.baseUri.toString(), 'https://demo.example.com/');
    });

    test('derives Xtream base path with nested segments', () {
      final input =
          'http://tv.example.net/sub/player_api.php?username=bob&password=pass';

      final result = classifier.classify(input);

      expect(result.provider, ProviderKind.xtream);
      expect(result.xtream!.baseUri.toString(), 'http://tv.example.net/sub/');
    });

    test('detects Xtream links without credentials', () {
      final input = 'https://demo.example.com/player_api.php';

      final result = classifier.classify(input);

      expect(result.provider, ProviderKind.xtream);
      expect(result.xtream!.hasCredentials, isFalse);
    });

    test('detects remote M3U playlists by extension', () {
      final input = 'https://cdn.example.org/playlist/listing.m3u8';

      final result = classifier.classify(input);

      expect(result.provider, ProviderKind.m3u);
      expect(result.m3u, isNotNull);
      expect(result.m3u!.isLocalFile, isFalse);
      expect(result.m3u!.playlistUri!.toString(), input);
    });

    test('detects local M3U playlists by path', () {
      final input = r'C:\iptv\channels.m3u';

      final result = classifier.classify(input);

      expect(result.provider, ProviderKind.m3u);
      expect(result.m3u!.isLocalFile, isTrue);
      expect(result.m3u!.localPath, input);
    });

    test('detects inline M3U content', () {
      const input = '#EXTM3U\n#EXTINF:-1,Channel';

      final result = classifier.classify(input);

      expect(result.provider, ProviderKind.m3u);
      expect(result.m3u!.isLocalFile, isFalse);
    });

    test('defaults to stalker when no heuristic matches', () {
      const input = 'portal.example.net';

      final result = classifier.classify(input);

      expect(result.provider, ProviderKind.stalker);
      expect(result.isConfident, isFalse);
    });

    test('returns no match for empty strings', () {
      final result = classifier.classify('   ');

      expect(result.hasMatch, isFalse);
    });

    group('ambiguous inputs', () {
      test('treats playlist-style get.php links as Xtream with playlist hints',
          () {
        const input =
            'http://1tv41.icu:8080/get.php?username=ahx4CN&password=815233&type=m3u_plus&output=ts';

        final result = classifier.classify(input);

        expect(result.provider, ProviderKind.xtream);
        expect(result.xtream, isNotNull);
        expect(result.xtream!.baseUri.toString(), 'http://1tv41.icu:8080/');
        expect(result.xtream!.hasCredentials, isTrue);
        expect(result.xtream!.username, 'ahx4CN');
        expect(result.xtream!.password, '815233');

        expect(result.m3u, isNotNull, reason: 'playlist hints should persist');
        expect(result.m3u!.playlistUri!.toString(), input);
        expect(result.m3u!.username, 'ahx4CN');
        expect(result.m3u!.password, '815233');
      });

      test('canonicalises scheme for bare Xtream playlist links', () {
        const input =
            'example.org/get.php?username=alice&password=secret&type=m3u_plus';

        final result = classifier.classify(input);

        expect(result.provider, ProviderKind.xtream);
        expect(result.xtream!.baseUri.toString(), 'https://example.org/');
        expect(result.xtream!.originalUri!.toString(),
            'https://example.org/get.php?username=alice&password=secret&type=m3u_plus');
      });

      test('handles bare Xtream host with explicit port', () {
        const input = 'host.example.com:8081';

        final result = classifier.classify(input);

        expect(result.provider, ProviderKind.xtream);
        expect(result.xtream, isNotNull);
        expect(result.xtream!.baseUri.toString(), 'https://host.example.com:8081/');
      });

      test('detects playlist URLs with signed tokens as M3U', () {
        const input =
            'https://cdn.example.com/playlist.m3u8?token=abc123&type=playlist';

        final result = classifier.classify(input);

        expect(result.provider, ProviderKind.m3u);
        expect(result.m3u, isNotNull);
        expect(result.m3u!.playlistUri!.toString(), input);
        expect(result.m3u!.username, isNull);
        expect(result.m3u!.password, isNull);
      });
    });
  });
}
