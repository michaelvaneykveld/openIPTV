import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repository/channel_repository.dart';
import '../../core/models/channel.dart';

part 'channel_list_provider.g.dart';

/// A provider that fetches and provides the list of channels.
///
/// It depends on the [channelRepositoryProvider] to get the data.
/// The UI can watch this provider to get the channel list asynchronously
/// and handle loading/error states.
@riverpod
Future<List<Channel>> channelList(Ref ref) {
  final repository = ref.watch(channelRepositoryProvider);
  // The forceRefresh parameter is now handled by invalidating the provider.
  return repository.getLiveChannels();
}
