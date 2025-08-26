import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/channel_repository.dart'; // Deze import is nu correct!
import '../../data/providers/m3u_provider.dart';
import 'stalker_provider.dart';

/// Provides a singleton instance of Dio for network requests.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  // Add a LogInterceptor to print all network traffic to the console.
  // This is the best way to verify if a network request is being sent at all.
  // It will show the request URL, headers, and the full response or error.
  dio.interceptors.add(LogInterceptor(
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

/// Provides a singleton instance of our M3uProvider implementation.
/// In a real app, you would have a way to switch this to XtreamProvider etc.
final m3uProvider = Provider<M3uProvider>((ref) {
  final dio = ref.watch(dioProvider);
  return M3uProvider(dio: dio);
});

/// Provides a singleton instance of our StalkerProvider implementation.
final stalkerProvider = Provider<StalkerProvider>((ref) {
  final dio = ref.watch(dioProvider);
  return StalkerProvider(dio: dio);
});

/// Provides the ChannelRepository.
/// The UI layer will interact with this repository, not the provider directly.
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  // We are now temporarily hardcoding the StalkerProvider for testing.
  // Later, this will be dynamic based on user's selected account.
  return ChannelRepository(ref.watch(stalkerProvider));
});
