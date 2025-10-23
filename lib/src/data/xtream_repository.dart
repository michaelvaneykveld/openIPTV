import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/database/database_provider.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/vod_category.dart';
import 'package:openiptv/src/core/models/vod_content.dart';
import 'package:openiptv/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

final xtreamRepositoryProvider = Provider<XtreamRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return XtreamRepository(databaseHelper);
});

class XtreamRepository {
  final DatabaseHelper _databaseHelper;

  XtreamRepository(this._databaseHelper);

  Future<void> synchronizeData(
    String portalId,
    List<VodCategory> liveCategories,
    List<VodCategory> vodCategories,
    List<VodCategory> seriesCategories,
    Map<String, List<Channel>> liveStreams,
    Map<String, List<VodContent>> vodStreams,
    Map<String, List<VodContent>> series,
  ) async {
    appLogger.d('Starting Xtream data synchronization for portal: $portalId...');
    try {
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        // Clear existing data for this portal
        await txn.delete(DatabaseHelper.tableChannels, where: '${DatabaseHelper.columnPortalId} = ?', whereArgs: [portalId]);
        await txn.delete(DatabaseHelper.tableVodContent, where: '${DatabaseHelper.columnPortalId} = ?', whereArgs: [portalId]);
        await txn.delete(DatabaseHelper.tableSeries, where: '${DatabaseHelper.columnPortalId} = ?', whereArgs: [portalId]);

        // Insert new data
        final liveBatch = txn.batch();
        for (final category in liveCategories) {
          final streams = liveStreams[category.id] ?? [];
          for (final stream in streams) {
            liveBatch.insert(
              DatabaseHelper.tableChannels,
              {...stream.toMap(), DatabaseHelper.columnPortalId: portalId},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await liveBatch.commit(noResult: true);

        final vodBatch = txn.batch();
        for (final category in vodCategories) {
          final streams = vodStreams[category.id] ?? [];
          for (final stream in streams) {
            vodBatch.insert(
              DatabaseHelper.tableVodContent,
              {...stream.toMap(), DatabaseHelper.columnPortalId: portalId},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await vodBatch.commit(noResult: true);

        final seriesBatch = txn.batch();
        for (final category in seriesCategories) {
          final seriesList = series[category.id] ?? [];
          for (final item in seriesList) {
            seriesBatch.insert(
              DatabaseHelper.tableSeries,
              {...item.toMap(), DatabaseHelper.columnPortalId: portalId},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await seriesBatch.commit(noResult: true);
      });
      await _databaseHelper.markChannelsSynced(portalId);
      await _databaseHelper.markVodSynced(portalId);
      appLogger.d('Xtream data synchronization complete for portal: $portalId.');
    } catch (e, stackTrace) {
      appLogger.e('Error during Xtream data synchronization', error: e, stackTrace: stackTrace);
      throw Exception('Failed to synchronize Xtream data.');
    }
  }
}
