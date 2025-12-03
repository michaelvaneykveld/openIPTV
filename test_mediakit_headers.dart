// Test if media_kit httpHeaders works on Windows
// Run: dart run test_mediakit_headers.dart

import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  print('Testing media_kit httpHeaders on Windows...');

  MediaKit.ensureInitialized();

  final player = Player();

  // Test with a URL that requires custom headers (will fail without them)
  // Using httpbin.org which echoes back the request headers
  final testUrl = 'https://httpbin.org/headers';
  final testHeaders = {
    'X-Test-Header': 'CustomValue123',
    'User-Agent': 'TestClient/1.0',
  };

  print('Opening URL: $testUrl');
  print('With headers: $testHeaders');

  player.stream.error.listen((error) {
    print('ERROR: $error');
  });

  try {
    await player.open(Media(testUrl, httpHeaders: testHeaders));
    print('✓ Media.open() succeeded');

    await Future.delayed(Duration(seconds: 2));

    print('Player state: ${player.state.playing}');
  } catch (e) {
    print('✗ Exception: $e');
  }

  await player.dispose();
  print(
    '\nNote: This test only verifies that httpHeaders parameter is accepted.',
  );
  print(
    'To verify headers are actually sent, we need network capture (Wireshark/Fiddler).',
  );
}
