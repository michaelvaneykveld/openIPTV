import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../application/providers/api_provider.dart';
import '../../core/api/iprovider.dart';
import '../../core/models/channel.dart';
import '../datasources/channel_local_data_source.dart';

part 'channel_repository.g.dart';

/// The repository is the single source of truth for channel data.
/// It abstracts the data source (local or remote) from the rest of the app.
class ChannelRepository {
  final IProvider _remoteProvider;
  final ChannelLocalDataSource _localDataSource;

  ChannelRepository(this._remoteProvider, this._localDataSource);

  /// Fetches the list of live TV channels.
  ///
  /// It first attempts to load channels from the local Hive database.
  /// If the database is empty, it fetches the channels from the remote provider,
  /// saves them to the local database for future use, and then returns them.
  Future<List<Channel>> getLiveChannels({bool forceRefresh = false}) async {
    // The 'forceRefresh' logic is now primarily handled by invalidating the
    // provider that calls this method. We keep the parameter for direct calls.
    if (!forceRefresh) {
      final localChannels = _localDataSource.getChannels();
      if (localChannels.isNotEmpty) {
        developer.log('Returning ${localChannels.length} channels from cache.',
            name: 'ChannelRepository');
        return localChannels;
      }
    }

    // If local database is empty or refresh is forced, fetch from remote.
    developer.log('Cache is empty or refresh is forced. Fetching from remote.',
        name: 'ChannelRepository');
    final remoteChannels = await _remoteProvider.fetchLiveChannels();

    // Save the fetched channels to the local database for next time.
    await _localDataSource.saveChannels(remoteChannels);

    return remoteChannels;
  }
}

@riverpod
ChannelRepository channelRepository(Ref ref) {
  // Watch the apiProviderProvider to get the correct remote data source.
  final remoteProvider = ref.watch(stalkerApiProvider);
  final localDataSource = ref.watch(channelLocalDataSourceProvider);
  return ChannelRepository(remoteProvider, localDataSource);
}
