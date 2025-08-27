import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/repository/channel_repository.dart';
import 'channel_providers.dart';

/// Provides a singleton instance of Dio for network requests.
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// Provides the ChannelRepository.
/// This repository is stateful and must be signed in before use.
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ChannelRepository(dio);
});

/// A FutureProvider that the UI will use to fetch the list of live channels.
///
/// It automatically handles loading, error, and data states after signing in.
final liveChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final repository = ref.watch(channelRepositoryProvider);
  final credentials = ref.watch(credentialsProvider);
  await repository.signIn(credentials);
  return repository.fetchLiveChannels();
});