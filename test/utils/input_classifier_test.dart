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
  });
}
