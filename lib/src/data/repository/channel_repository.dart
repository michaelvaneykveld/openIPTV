import 'package:dio/dio.dart';

import '../providers/m3u_provider.dart';
import '../providers/stalker_provider.dart';
import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';
import '../utils/stalker_url_resolver.dart';

/// A repository that handles channel-related data operations.
///
/// This repository is stateful: it holds the current provider instance
/// which is created after a successful `signIn`.
class ChannelRepository {
  final Dio _dio;
  IProvider? _provider; // Internal provider instance, initially null.

  ChannelRepository(this._dio);

  /// Creates and stores a provider instance using the given credentials.
  /// This method determines which provider to use based on the type of credentials.
  Future<void> signIn(Credentials credentials) async {
    if (credentials is StalkerCredentials) {
      // Use the resolver to find the correct base URL
      final resolver = StalkerUrlResolver(_dio);
      final resolvedBaseUrl = await resolver.resolve(credentials.baseUrl);

      _provider = StalkerProvider(
        dio: _dio,
        baseUrl: resolvedBaseUrl,
        macAddress: credentials.macAddress,
      );
    } else if (credentials is M3uCredentials) {
      _provider = M3uProvider(
        dio: _dio,
        m3uUrl: credentials.m3uUrl,
      );
    } else {
      throw ArgumentError('Unsupported credentials type: ${credentials.runtimeType}');
    }

    // Optional: You could add a check here to see if the provider can connect
    // before considering the sign-in successful. For example, by fetching a token.
  }

  /// Signs out the current user by clearing the active provider.
  Future<void> signOut() async {
    _provider = null;
    // In a real app, you might also clear any stored tokens or user data here.
  }

  /// Fetches a list of live channels from the current provider.
  Future<List<Channel>> fetchLiveChannels() {
    // Assign the provider to a local variable to allow type promotion.
    final currentProvider = _provider;
    if (currentProvider == null) {
      return Future.error(
          StateError('You must call signIn() before fetching channels.'));
    }
    return currentProvider.fetchLiveChannels();
  }
}