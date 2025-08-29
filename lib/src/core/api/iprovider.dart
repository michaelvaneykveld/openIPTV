import '../models/models.dart';

/// Defines the contract for all IPTV data providers.
///
/// Each provider (e.g., Stalker, M3U) must implement this interface.
abstract class IProvider {
  Future<List<Channel>> fetchLiveChannels();
  Future<List<Genre>> getGenres();
}