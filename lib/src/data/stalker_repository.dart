import 'package:openiptv/src/core/database/database_helper.dart';
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
  }
}