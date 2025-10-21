import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/src/core/models/epg_programme.dart';

/// Defines the contract for all IPTV data providers.
///
/// Each provider (e.g., Stalker, M3U) must implement this interface.
abstract class IProvider {
  Future<List<Channel>> fetchLiveChannels(String portalId);
  Future<List<Genre>> getGenres(String portalId);
  Future<List<Channel>> getAllChannels(String portalId, String genreId);
  Future<List<VodCategory>> fetchVodCategories(String portalId);
  Future<List<VodContent>> fetchVodContent(String portalId, String categoryId);
  Future<List<Genre>> fetchRadioGenres(String portalId);
  Future<List<Channel>> fetchRadioChannels(String portalId, String genreId);
  Future<List<EpgProgramme>> getEpgInfo({
    required String portalId,
    required String chId,
    required int period,
  });
}
