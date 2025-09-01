import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/data/models.dart';
import 'package:openiptv/src/data/models/epg_programme.dart';
import 'package:openiptv/src/data/stalker_api_service.dart';
import 'package:openiptv/utils/app_logger.dart';

class StalkerRepository {
  final StalkerApiService _apiService;
  final DatabaseHelper _databaseHelper;
  final String portalId;

  StalkerRepository(this._apiService, this._databaseHelper, this.portalId);

  Future<void> synchronizeData(String portalId) async {
    appLogger.d('Starting data synchronization for portal: $portalId...');
    await _databaseHelper.clearAllData(portalId); // Clear existing data for this portal before syncing

    // Fetch and store Genres
    final genres = await _apiService.getGenres();
    for (var genre in genres) {
      await _databaseHelper.insertGenre(genre.toMap(), portalId);
      // For each genre, fetch and store its channels
      final channels = await _apiService.getAllChannels(genre.id);
      for (var channel in channels) {
        await _databaseHelper.insertChannel(channel.toMap(), portalId);
      }
    }
    appLogger.d('Genres and Channels synchronized.');

    // Fetch and store VOD Categories
    final vodCategories = await _apiService.getVodCategories();
    for (var category in vodCategories) {
      await _databaseHelper.insertVodCategory(category.toMap(), portalId);
      // For each VOD category, fetch and store its content
      final vodContent = await _apiService.getVodContent(category.id);
      for (var content in vodContent) {
        await _databaseHelper.insertVodContent(content.toMap(), portalId);
      }
    }
    appLogger.d('VOD Categories and Content synchronized.');

    appLogger.d('Data synchronization complete.');

    // Fetch and store EPG data for all channels
    final allChannelsMaps = await _databaseHelper.getAllChannels(portalId);
    final allChannels = allChannelsMaps.map((e) => Channel.fromJson(e)).toList();
    for (var channel in allChannels) {
      try {
        final epgPrograms = await _apiService.getEpgInfo(channel.id, 24);
        for (var program in epgPrograms) {
          program.portalId = int.parse(portalId);
        }
        await saveEpgPrograms(epgPrograms, portalId);
      } catch (e) {
        appLogger.e("Could not fetch EPG for channel ${channel.id}", e);
      }
    }
    appLogger.d('EPG data synchronized.');
  }

  Future<void> saveEpgPrograms(List<EpgProgramme> epgPrograms, String portalId) async {
    final programsAsMaps = epgPrograms.map((p) => p.toMap()).toList();
    await _databaseHelper.insertEpgProgrammes(programsAsMaps, portalId);
  }

  Future<List<EpgProgramme>> getEpgForChannel(String channelId, String portalId) async {
    final List<Map<String, dynamic>> epgMaps = await _databaseHelper.getEpgForChannel(channelId, portalId);
    return epgMaps.map((map) {
      final program = EpgProgramme.fromJson(map);
      program.portalId = int.parse(portalId);
      return program;
    }).toList();
  }
}
