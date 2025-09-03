import 'package:openiptv/src/data/stalker_repository.dart';
import 'package:openiptv/utils/app_logger.dart';

class ChannelSyncService {
  final StalkerRepository _stalkerRepository;

  ChannelSyncService(this._stalkerRepository);

  Future<void> syncChannels(String portalId) async {
    appLogger.d('ChannelSyncService: Starting channel synchronization for portal: $portalId');
    try {
      // The synchronizeData method in StalkerRepository already handles fetching and saving.
      await _stalkerRepository.synchronizeData(portalId);
      appLogger.d('ChannelSyncService: Channel synchronization complete for portal: $portalId');
    } catch (e, stackTrace) {
      appLogger.e('ChannelSyncService: Error during channel synchronization for portal $portalId', error: e, stackTrace: stackTrace);
    }
  }
}
