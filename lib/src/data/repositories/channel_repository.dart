import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';

/// The ChannelRepository is the single source of truth for channel data.
///
/// It abstracts away the data source (network or local cache) from the UI.
/// The UI will ask this repository for channels, and the repository decides
/// where to get them from.
class ChannelRepository {
  final IProvider _provider;
  // TODO: Add a local database service (e.g., IsarService) here.

  ChannelRepository({required IProvider provider}) : _provider = provider;

  /// Fetches live channels.
  ///
  /// In a full implementation, this would first check a local database cache.
  /// If the cache is stale or empty, it would then call the [_provider]
  /// to fetch from the network and update the cache.
  Future<List<Channel>> getLiveChannels(Credentials credentials) async {
    // 1. (Later) Check local database for channels associated with these credentials.
    // 2. If cache is valid, return cached channels.

    // 3. For now, always fetch from the network.
    await _provider.signIn(credentials);
    return await _provider.fetchLiveChannels();
  }
}