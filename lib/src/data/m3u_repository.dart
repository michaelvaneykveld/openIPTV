import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/data/m3u_parser.dart';
import 'package:openiptv/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

final m3uRepositoryProvider = Provider<M3uRepository>((ref) {
  final databaseHelper = DatabaseHelper.instance;
  return M3uRepository(databaseHelper);
});

class M3uRepository {
  final DatabaseHelper _databaseHelper;

  M3uRepository(this._databaseHelper);

  Future<void> synchronizeData(String portalId, String m3uContent) async {
    appLogger.d('Starting M3U data synchronization for portal: $portalId...');

    try {
      // Clear existing data for this portal before syncing
      await _databaseHelper.clearAllData(portalId);

      // Parse the M3U content
      final channels = M3uParser.parse(m3uContent);
      appLogger.d('Parsed ${channels.length} channels from M3U content.');

      // Insert all channels in a single transaction for efficiency
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        for (final channel in channels) {
          await txn.insert(
            DatabaseHelper.tableChannels,
            {...channel.toMap(), DatabaseHelper.columnPortalId: portalId},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      appLogger.d('Successfully inserted ${channels.length} channels into the database.');

    } catch (e, stackTrace) {
      appLogger.e('Error during M3U data synchronization', error: e, stackTrace: stackTrace);
      // Optionally re-throw or handle the error as needed
      rethrow;
    }

    appLogger.d('M3U data synchronization complete for portal: $portalId.');
  }
}
