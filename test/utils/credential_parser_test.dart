import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/utils/credential_parser.dart';

void main() {
  group('CredentialParser', () {
    test('parses simple Stalker credential', () {
      const message = '''
Portal: http://portal.com/c/
Mac: 00:1A:79:00:00:01
''';
      final result = CredentialParser.parse(message);
      expect(result.stalker.length, 1);
      expect(result.stalker.first.url, 'http://portal.com/c/');
      expect(result.stalker.first.mac, '00:1A:79:00:00:01');
    });

    test('parses Stalker with multiple MACs', () {
      const message = '''
http://portal.com/c/
00:1A:79:00:00:01
00:1A:79:00:00:02
''';
      final result = CredentialParser.parse(message);
      expect(result.stalker.length, 2);
      expect(result.stalker[0].url, 'http://portal.com/c/');
      expect(result.stalker[0].mac, '00:1A:79:00:00:01');
      expect(result.stalker[1].url, 'http://portal.com/c/');
      expect(result.stalker[1].mac, '00:1A:79:00:00:02');
    });

    test('parses Xtream full URL', () {
      const message =
          'http://portal.com:8080/get.php?username=user1&password=pass1';
      final result = CredentialParser.parse(message);
      expect(result.xtream.length, 1);
      expect(result.xtream.first.url, 'http://portal.com:8080');
      expect(result.xtream.first.username, 'user1');
      expect(result.xtream.first.password, 'pass1');
    });

    test('parses Xtream separate fields', () {
      const message = '''
Host: http://portal.com:8080
User: user1
Pass: pass1
''';
      final result = CredentialParser.parse(message);
      expect(result.xtream.length, 1);
      expect(result.xtream.first.url, 'http://portal.com:8080');
      expect(result.xtream.first.username, 'user1');
      expect(result.xtream.first.password, 'pass1');
    });

    test('parses mixed content', () {
      const message = '''
Here is a stalker portal:
http://stalker.com/c/
00:1A:79:AA:BB:CC

And here is an xtream one:
http://xtream.com:80
u: user2
p: pass2
''';
      final result = CredentialParser.parse(message);
      expect(result.stalker.length, 1);
      expect(result.xtream.length, 1);

      expect(result.stalker.first.url, 'http://stalker.com/c/');
      expect(result.stalker.first.mac, '00:1A:79:AA:BB:CC');

      expect(result.xtream.first.url, 'http://xtream.com:80');
      expect(result.xtream.first.username, 'user2');
      expect(result.xtream.first.password, 'pass2');
    });
  });
}
