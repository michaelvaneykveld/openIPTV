import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/core/api/iprovider.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/src/core/models/epg_programme.dart';
import 'package:openiptv/utils/app_logger.dart';

final stalkerRepositoryProvider = Provider<StalkerRepository>((ref) {
  final provider = ref.watch(stalkerApiProvider);
  final databaseHelper = DatabaseHelper.instance;
  return StalkerRepository(provider, databaseHelper);
});

class StalkerRepository {
  final IProvider _provider;
  final DatabaseHelper _databaseHelper;

  StalkerRepository(this._provider, this._databaseHelper);

  Future<void> synchronizeData(String portalId) async {
    appLogger.d('Starting data synchronization for portal: $portalId...');
    await _databaseHelper.clearAllData(
      portalId,
    ); // Clear existing data for this portal before syncing

    // Fetch and store Genres
    final genres = await _provider.getGenres(portalId);
    appLogger.d('Fetched ${genres.length} genres for portal: $portalId');
    for (final genre in genres) {
      await _databaseHelper.insertGenre(genre.toMap(), portalId);
    }

    // Fetch all channels once and map them to genres locally
    final channels = await _provider.getAllChannels(portalId, '*');
    appLogger.d(
      'Fetched ${channels.length} live channels for portal: $portalId in a single bulk request.',
    );

    final Map<String, int> genreChannelCounts = {};
    var channelsWithoutGenre = 0;

    for (final channel in channels) {
      await _databaseHelper.insertChannel(channel.toMap(), portalId);
      if (channel.cmds != null && channel.cmds!.isNotEmpty) {
        for (final cmd in channel.cmds!) {
          await _databaseHelper.insertChannelCmd(cmd.toMap(), portalId);
        }
      }

      final genreIds = _extractGenreIds(channel);
      if (genreIds.isEmpty) {
        channelsWithoutGenre++;
      } else {
        for (final genreId in genreIds) {
          genreChannelCounts[genreId] = (genreChannelCounts[genreId] ?? 0) + 1;
        }
      }
    }

    for (final genre in genres) {
      final count = genreChannelCounts[genre.id] ?? 0;
      appLogger.d(
        'Genre ${genre.id} (${genre.title}) associated with $count channels.',
      );
    }
    if (channelsWithoutGenre > 0) {
      appLogger.w(
        '$channelsWithoutGenre channels lacked an explicit genre_id and were stored without a genre association.',
      );
    }

    appLogger.d('Genres and Channels synchronized.');

    // Fetch and store VOD Categories
    final vodCategories = await _provider.fetchVodCategories(portalId);
    appLogger.d(
      'Fetched ${vodCategories.length} VOD categories for portal: $portalId',
    );
    for (final category in vodCategories) {
      await _databaseHelper.insertVodCategory(category.toJson(), portalId);
      if (category.id.trim() == '*') {
        appLogger.d(
          'Skipping wildcard VOD category ${category.id} (${category.title}) during content sync.',
        );
        continue;
      }
      // For each VOD category, fetch and store its content
      try {
        final vodContent = await _provider.fetchVodContent(
          portalId,
          category.id,
        );
        appLogger.d(
          'VOD category ${category.id} (${category.title}) returned ${vodContent.length} items.',
        );
        for (final content in vodContent) {
          await _databaseHelper.insertVodContent(content.toMap(), portalId);
        }
      } catch (error, stackTrace) {
        appLogger.e(
          'Failed to synchronize VOD content for category ${category.id} (${category.title}) on portal $portalId.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    appLogger.d('VOD Categories and Content synchronized.');

    appLogger.d('Data synchronization complete.');

    // Fetch and store EPG data for all channels
    final allChannelsMaps = await _databaseHelper.getAllChannels(portalId);
    appLogger.d(
      'Total channels stored for portal $portalId: ${allChannelsMaps.length}',
    );
    final allChannels = allChannelsMaps
        .map((e) => Channel.fromDbMap(e))
        .toList();
    for (var channel in allChannels) {
      try {
        final epgPrograms = await _provider.getEpgInfo(
          portalId: portalId,
          chId: channel.id,
          period: 24,
        );
        appLogger.d(
          'Fetched ${epgPrograms.length} EPG programs for channel ${channel.id}.',
        ); // Added log
        for (final program in epgPrograms) {
          program.portalId = portalId;
        }
        await _saveEpgPrograms(
          epgPrograms,
          portalId: portalId,
        ); // Call to save EPG programs
      } catch (e, stackTrace) {
        appLogger.e(
          "Could not fetch EPG for channel ${channel.id}",
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    appLogger.d('EPG data synchronized.');
  }

  Set<String> _extractGenreIds(Channel channel) {
    final ids = <String>{};
    final primary = channel.genreId?.trim();
    if (primary != null && primary.isNotEmpty) {
      ids.add(primary);
    }
    final additional = channel.genresStr;
    if (additional != null && additional.isNotEmpty) {
      final parts = additional
          .split(RegExp(r'[|,]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty);
      ids.addAll(parts);
    }
    return ids;
  }

  Future<void> _saveEpgPrograms(
    List<EpgProgramme> epgPrograms, {
    required String portalId,
  }) async {
    final programsAsMaps = epgPrograms.map((p) => p.toMap()).toList();
    await _databaseHelper.insertEpgProgrammes(
      programsAsMaps,
      portalId: portalId,
    );
  }

  Future<List<EpgProgramme>> getEpgForChannel(
    String channelId,
    String portalId,
  ) async {
    final List<Map<String, dynamic>> epgMaps = await _databaseHelper
        .getEpgForChannel(channelId, portalId);
    return epgMaps.map((map) => EpgProgramme.fromDbMap(map)).toList();
  }
}
