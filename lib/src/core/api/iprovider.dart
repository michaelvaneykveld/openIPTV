import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/src/core/models/epg_programme.dart';

/// Defines the contract for all IPTV data providers.
///
/// Each provider (e.g., Stalker, M3U) must implement this interface.
abstract class IProvider {
  Future<List<Channel>> fetchLiveChannels();
  Future<List<Genre>> getGenres();
  Future<List<Channel>> getAllChannels(String genreId);
  Future<List<VodCategory>> fetchVodCategories();
  Future<List<VodContent>> fetchVodContent(String categoryId);
  Future<List<Genre>> fetchRadioGenres();
  Future<List<Channel>> fetchRadioChannels(String genreId);
  Future<List<EpgProgramme>> getEpgInfo({required String chId, required int period});
}