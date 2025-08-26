import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';

/// A repository that handles channel-related data operations.
///
/// It uses a specific [IProvider] (like StalkerProvider or M3uProvider)
/// to fetch data, abstracting the data source from the UI and application layers.
class ChannelRepository {
  final IProvider _provider;

  ChannelRepository(this._provider);

  /// Fetches a list of live channels from the current provider.
  Future<List<Channel>> fetchLiveChannels() {
    // Delegate the call to the injected provider.
    return _provider.fetchLiveChannels();
  }
}

