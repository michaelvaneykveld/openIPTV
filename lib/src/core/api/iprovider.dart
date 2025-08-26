import '../models/models.dart';

/// Abstract contract for resolving a playable stream URL from a media item.
/// This hides platform-specific logic like token generation or timeshift params.
abstract class StreamUrlResolver {
  Future<String> resolveStreamUrl(String itemId, {Map<String, dynamic>? options});
}

/// Defines the contract for an IPTV data source (M3U, Xtream, Stalker).
/// Each implementation will handle the specifics of its protocol.
abstract class IProvider {
  /// Signs in using the specific credentials for the provider.
  /// Throws an exception on failure.
  Future<void> signIn(Credentials credentials);

  /// Fetches all available live TV channels.
  Future<List<Channel>> fetchLiveChannels();

  /// Fetches the main categories (e.g., Live, VOD, Series).
  Future<List<Category>> fetchCategories();

  /// Fetches Video-on-Demand items, optionally filtered by category.
  Future<List<VodItem>> fetchVod({Category? category});

  /// Fetches TV Series, optionally filtered by category.
  Future<List<Series>> fetchSeries({Category? category});

  /// Fetches EPG (Electronic Program Guide) data for a specific channel within a time range.
  Future<List<EpgEvent>> fetchEpg(String channelId, DateTime from, DateTime to);

  /// Returns a resolver capable of generating playable URLs.
  StreamUrlResolver get resolver;
}