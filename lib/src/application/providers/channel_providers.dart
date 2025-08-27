import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';

/// A provider for the currently selected credentials.
///
/// This is hardcoded for now for testing purposes. In a real app, this would
/// be a StateNotifierProvider that holds the credentials of the logged-in user.
final credentialsProvider = Provider<Credentials>((ref) {
  // You can switch between these two to test different providers.
  // return const M3uCredentials(m3uUrl: 'YOUR_M3U_URL_HERE');
  return const StalkerCredentials(
    baseUrl: 'http://line.4k-iptv.com:80',
    macAddress: '00:1A:79:A7:6B:41',
  );
});