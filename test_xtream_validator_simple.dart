// Quick test of the Xtream validator
// Run with: dart run test_xtream_validator_simple.dart

import 'lib/src/utils/xtream_validator_simple.dart';

void main() async {
  print('Testing Xtream Validator...\n');

  // Test atlas213.xyz
  final validator = XtreamValidator(
    host: 'atlas213.xyz',
    port: 80,
    username: 'd0:d0:03:03:47:aa',
    password: '010101',
  );

  final result = await validator.validate();
  print(result.report);

  // Print recommendations
  print('\nRECOMMENDATIONS:');
  print('────────────────────────────────────────────────────');

  if (result.rawColonsAllowed) {
    print('✓ Use RAW credentials (no encoding)');
  } else if (result.encodedColonsAllowed) {
    print('✓ Use ENCODED credentials (URL encode colons)');
  } else {
    print('✗ Neither raw nor encoded credentials work!');
  }

  if (result.uaRequired) {
    print('✓ Add User-Agent: okhttp/4.9.3 header');
  }

  if (result.proxyRequired) {
    print('✓ Use local proxy to avoid HTML responses');
  }

  if (!result.liveOk || !result.vodOk) {
    print('✗ Server has connectivity issues');
  }

  print('────────────────────────────────────────────────────\n');
}
