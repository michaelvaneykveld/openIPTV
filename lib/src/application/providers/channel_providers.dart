import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import 'repository_providers.dart';

/// This provider will hold the credentials for the active account.
/// For now, we hardcode Stalker Portal credentials for analysis.
final credentialsProvider = Provider<Credentials>((ref) {
  // This is a common public test portal.
  // IMPORTANT: Use a fictional or temporary MAC address for testing.
  return StalkerCredentials(
      portalUrl: 'http://z1mag.xyz:8080/c/',
      macAddress: '00:1A:79:08:ED:E9');
});

/// A FutureProvider that fetches the list of live channels.
/// It uses the [channelRepositoryProvider] to get the data and automatically
/// handles loading/error states for the UI.
final liveChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final repository = ref.watch(channelRepositoryProvider);
  final credentials = ref.watch(credentialsProvider);
  return repository.getLiveChannels(credentials);
});