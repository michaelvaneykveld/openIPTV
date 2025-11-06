import 'dart:io';

import 'package:flutter/foundation.dart';

import 'dao/artwork_cache_dao.dart';
import 'dao/channel_dao.dart';
import 'dao/maintenance_log_dao.dart';
import 'openiptv_db.dart';

class DatabaseMaintenanceConfig {
  const DatabaseMaintenanceConfig({
    this.vacuumInterval = const Duration(days: 3),
    this.analyzeInterval = const Duration(days: 1),
    this.minFileBytesForVacuum = 16 * 1024 * 1024,
    this.minFileBytesForAnalyze = 8 * 1024 * 1024,
    this.tombstoneRetention = const Duration(days: 14),
    this.artworkEntryBudget = 500,
    this.artworkSizeBudgetBytes = 200 * 1024 * 1024,
  });

  final Duration vacuumInterval;
  final Duration analyzeInterval;
  final int minFileBytesForVacuum;
  final int minFileBytesForAnalyze;
  final Duration tombstoneRetention;
  final int artworkEntryBudget;
  final int artworkSizeBudgetBytes;
}

class DatabaseMaintenance {
  DatabaseMaintenance({
    required this.db,
    required this.logDao,
    required this.channelDao,
    required this.artworkDao,
    required this.config,
    this.databaseFile,
  });

  final OpenIptvDb db;
  final MaintenanceLogDao logDao;
  final ChannelDao channelDao;
  final ArtworkCacheDao artworkDao;
  final DatabaseMaintenanceConfig config;
  final File? databaseFile;

  Future<void> run({DateTime? now, bool force = false}) async {
    final clock = now ?? DateTime.now().toUtc();
    await runVacuum(now: clock, force: force);
    await runAnalyze(now: clock, force: force);
    await runRetentionSweep(now: clock);
    await runArtworkPrune(force: force);
  }

  Future<void> runVacuum({DateTime? now, bool force = false}) async {
    final timestamp = now ?? DateTime.now().toUtc();
    final lastRun = await logDao.lastRun(_Tasks.vacuum);
    if (!force &&
        lastRun != null &&
        timestamp.difference(lastRun) < config.vacuumInterval) {
      return;
    }
    if (!force && !await _meetsFileSize(config.minFileBytesForVacuum)) {
      return;
    }
    try {
      await db.customStatement('VACUUM;');
      await logDao.markRun(_Tasks.vacuum, timestamp);
    } catch (error, stackTrace) {
      debugPrint('VACUUM failed: $error\n$stackTrace');
    }
  }

  Future<void> runAnalyze({DateTime? now, bool force = false}) async {
    final timestamp = now ?? DateTime.now().toUtc();
    final lastRun = await logDao.lastRun(_Tasks.analyze);
    if (!force &&
        lastRun != null &&
        timestamp.difference(lastRun) < config.analyzeInterval) {
      return;
    }
    if (!force && !await _meetsFileSize(config.minFileBytesForAnalyze)) {
      return;
    }
    try {
      await db.customStatement('ANALYZE;');
      await logDao.markRun(_Tasks.analyze, timestamp);
    } catch (error, stackTrace) {
      debugPrint('ANALYZE failed: $error\n$stackTrace');
    }
  }

  Future<void> runRetentionSweep({DateTime? now}) async {
    final timestamp = now ?? DateTime.now().toUtc();
    final cutoff = timestamp.subtract(config.tombstoneRetention);
    try {
      final removed =
          await channelDao.purgeAllStaleChannels(olderThan: cutoff);
      if (removed > 0) {
        debugPrint('Purged $removed stale channel rows.');
      }
    } catch (error, stackTrace) {
      debugPrint('Retention sweep failed: $error\n$stackTrace');
    }
  }

  Future<void> runArtworkPrune({bool force = false}) async {
    try {
      final removedByCount =
          await artworkDao.pruneToEntryBudget(config.artworkEntryBudget);
      final removedBySize = await artworkDao
          .pruneToSizeBudget(config.artworkSizeBudgetBytes);
      final removed = removedByCount.length + removedBySize.length;
      if (removed > 0) {
        debugPrint('Pruned $removed artwork cache entries.');
      }
    } catch (error, stackTrace) {
      debugPrint('Artwork prune failed: $error\n$stackTrace');
    }
  }

  Future<bool> _meetsFileSize(int requiredBytes) async {
    if (requiredBytes <= 0) {
      return true;
    }
    final file = databaseFile;
    if (file == null) {
      return false;
    }
    try {
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size >= requiredBytes;
      }
    } catch (error) {
      debugPrint('Unable to check database file size: $error');
    }
    return false;
  }
}

class _Tasks {
  static const vacuum = 'vacuum';
  static const analyze = 'analyze';
}
