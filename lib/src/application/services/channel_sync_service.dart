import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/src/data/m3u_repository.dart';
import 'package:openiptv/src/data/providers/m3u_api_provider.dart';
import 'package:openiptv/src/data/stalker_repository.dart';
import 'package:openiptv/utils/app_logger.dart';

final channelSyncServiceProvider = Provider<ChannelSyncService>((ref) {
  return ChannelSyncService(ref);
});

class ChannelSyncService {
  final Ref _ref;

  ChannelSyncService(this._ref);

  Future<void> syncChannels(String portalId) async {
    appLogger.d('ChannelSyncService: Starting channel synchronization for portal: $portalId');
    try {
      final credentialsList = await _ref.read(credentialsRepositoryProvider).getSavedCredentials();
      final credential = credentialsList.firstWhere((c) => c.id == portalId, orElse: () => throw Exception("Credential not found"));

      if (credential is StalkerCredentials) {
        final stalkerRepository = _ref.read(stalkerRepositoryProvider);
        await stalkerRepository.synchronizeData(portalId);
      } else if (credential is M3uCredentials) {
        final m3uRepository = _ref.read(m3uRepositoryProvider);
        final M3uApiService m3uProvider = _ref.read(m3uApiProvider(credential));
        final m3uContent = await m3uProvider.getRawM3uContent();
        await m3uRepository.synchronizeData(portalId, m3uContent);
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
