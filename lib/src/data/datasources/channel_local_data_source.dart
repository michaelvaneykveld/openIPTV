import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models/channel.dart';

part 'channel_local_data_source.g.dart';

/// Provides access to the local channel data stored in Hive.
class ChannelLocalDataSource {
  static const String _boxName = 'channels';

  /// Returns the Hive box for channels.
  Box<Channel> get _channelBox => Hive.box<Channel>(_boxName);

  /// Saves a list of channels to the local database.
  /// This will clear all existing channels before saving the new list.
  Future<void> saveChannels(List<Channel> channels) async {
    developer.log('Saving ${channels.length} channels to local database.',
        name: 'ChannelLocalDataSource');
    await _channelBox.clear();
    // Hive's putAll is efficient for bulk inserts.
    // We use the channel's unique ID as the key.
    await _channelBox.putAll({for (var channel in channels) channel.id: channel});
    developer.log('Finished saving channels.', name: 'ChannelLocalDataSource');
  }

  /// Retrieves all channels from the local database.
  List<Channel> getChannels() {
    final channels = _channelBox.values.toList();
    developer.log('Retrieved ${channels.length} channels from local database.',
        name: 'ChannelLocalDataSource');
    return channels;
  }
}

@riverpod
ChannelLocalDataSource channelLocalDataSource(ChannelLocalDataSourceRef ref) =>
    ChannelLocalDataSource();
