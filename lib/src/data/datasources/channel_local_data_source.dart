import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/core/models/channel.dart';

part 'channel_local_data_source.g.dart';

class ChannelLocalDataSource {
  // Placeholder methods
  List<Channel> getChannels() {
    return [];
  }

  Future<void> saveChannels(List<Channel> channels) async {
    // Implement saving logic here
  }
}

@riverpod
ChannelLocalDataSource channelLocalDataSource(ChannelLocalDataSourceRef ref) {
  return ChannelLocalDataSource();
}
