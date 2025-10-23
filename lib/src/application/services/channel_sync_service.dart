import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/src/data/m3u_repository.dart';
import 'package:openiptv/src/data/providers/m3u_api_provider.dart';
import 'package:openiptv/src/data/stalker_repository.dart';
import 'package:openiptv/src/data/xtream_repository.dart';
import 'package:openiptv/src/core/models/xtream_credentials.dart';
import 'package:openiptv/utils/app_logger.dart';

final channelSyncServiceProvider = Provider<ChannelSyncService>((ref) {
  return ChannelSyncService(ref);
});

class ChannelSyncService {
  final Ref _ref;

  ChannelSyncService(this._ref);

  Future<void> syncChannels(
    String portalId, {
    bool forceRefresh = false,
  }) async {
    appLogger.d('ChannelSyncService: Starting channel synchronization for portal: $portalId');
    try {
      final credentialsList = await _ref.read(credentialsRepositoryProvider).getSavedCredentials();
      final credential = credentialsList.firstWhere((c) => c.id == portalId, orElse: () => throw Exception("Credential not found"));

      final databaseHelper = DatabaseHelper.instance;
      if (!forceRefresh) {
        final hasExistingData = await databaseHelper.hasChannelData(portalId);
        final lastSync = await databaseHelper.getLastChannelSync(portalId);
        if (hasExistingData &&
            lastSync != null &&
            DateTime.now().difference(lastSync) < const Duration(minutes: 15)) {
          appLogger.d('ChannelSyncService: Skipping synchronization for portal: $portalId because data was refreshed at $lastSync.');
          return;
        }
      }

      if (credential is StalkerCredentials) {
        final stalkerRepository = _ref.read(stalkerRepositoryProvider);
        await stalkerRepository.synchronizeData(portalId);
      } else if (credential is M3uCredentials) {
        final m3uRepository = _ref.read(m3uRepositoryProvider);
        final M3uApiService m3uProvider = _ref.read(m3uApiProvider(credential));
        final m3uContent = await m3uProvider.getRawM3uContent();
        appLogger.d("M3U Content in ChannelSyncService:\n$m3uContent");
        await m3uRepository.synchronizeData(portalId, m3uContent);
      } else if (credential is XtreamCredentials) {
        final xtreamApi = _ref.read(xtreamApiProvider(credential));
        final xtreamRepository = _ref.read(xtreamRepositoryProvider);

        final liveCategories = await xtreamApi.getLiveCategories(credential.username, credential.password);
        final vodCategories = await xtreamApi.getVodCategories(credential.username, credential.password);
        final seriesCategories = await xtreamApi.getSeriesCategories(credential.username, credential.password);

        final liveStreams = <String, List<Channel>>{};
        for (final category in liveCategories) {
          liveStreams[category.id] = await xtreamApi.getLiveStreams(credential.username, credential.password, category.id);
        }

        final vodStreams = <String, List<VodContent>>{};
        for (final category in vodCategories) {
          vodStreams[category.id] = await xtreamApi.getVodStreams(credential.username, credential.password, category.id);
        }

        final series = <String, List<VodContent>>{};
        for (final category in seriesCategories) {
          series[category.id] = await xtreamApi.getSeries(credential.username, credential.password, category.id);
        }

        await xtreamRepository.synchronizeData(
          portalId,
          liveCategories,
          vodCategories,
          seriesCategories,
          liveStreams,
          vodStreams,
          series,
        );
      } else {
        // Handle other credential types if necessary
        throw Exception('Unsupported credential type for sync: ${credential.runtimeType}');
      }

      appLogger.d('ChannelSyncService: Channel synchronization complete for portal: $portalId');
    } catch (e, stackTrace) {
      appLogger.e('ChannelSyncService: Error during channel synchronization for portal $portalId', error: e, stackTrace: stackTrace);
    }
  }
}
