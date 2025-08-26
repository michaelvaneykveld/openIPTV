import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import 'repository_providers.dart';

/// A provider that asynchronously fetches the list of live channels.
///
/// The UI will 'watch' this provider. When watched, it automatically:
/// 1. Signs in to the portal.
/// 2. Fetches the channel list.
/// 3. Provides the result (data, loading, or error state) to the UI.
final liveChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  // Get the repository that knows how to talk to the backend.
  final repository = ref.watch(channelRepositoryProvider);

  // Step 1: Sign in. This is a temporary setup.
  // In the future, this will come from a user settings screen.
  await repository.signIn(
    StalkerCredentials(
      // The '/c/' path is for the web page. Let's try the standard
      // Stalker API endpoint, which is typically '/portal.php'.
      portalUrl: 'http://z1mag.xyz:8080/portal.php',
      macAddress: '00:1A:79:08:ED:E9',
    ),
  );

  // Step 2: Fetch the channels. This is the call that will trigger your logs.
  return repository.fetchLiveChannels();
});
