import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';
import 'import_context.dart';

final m3uImporterProvider = r.Provider<M3uImporter>((ref) {
  final db = ref.watch(openIptvDbProvider);
  final providerDao = ProviderDao(db);
  final channelDao = ChannelDao(db);
  final categoryDao = CategoryDao(db);
  final summaryDao = SummaryDao(db);
  final epgDao = EpgDao(db);
  final context = ImportContext(
    db: db,
    providerDao: providerDao,
    channelDao: channelDao,
    categoryDao: categoryDao,
    summaryDao: summaryDao,
    epgDao: epgDao,
  );
  return M3uImporter(context);
});

class M3uEntry {
  M3uEntry({
    required this.key,
    required this.name,
    required this.group,
    required this.isRadio,
    this.logoUrl,
  });

  final String key;
  final String name;
  final String group;
  final bool isRadio;
  final String? logoUrl;
}

class M3uImporter {
  M3uImporter(this.context);

  final ImportContext context;

  Future<ImportMetrics> importEntries({
    required int providerId,
    required Stream<M3uEntry> entries,
  }) {
    return context.runWithRetry((txn) async {
      final metrics = ImportMetrics();

      await txn.channels.markAllAsCandidateForDelete(providerId);

      final categoryCache = <String, int>{};
      var liveCount = 0;
      var radioCount = 0;

      await for (final entry in entries) {
        final channelId = await txn.channels.upsertChannel(
          providerId: providerId,
          providerKey: entry.key,
          name: entry.name,
          logoUrl: entry.logoUrl,
          isRadio: entry.isRadio,
          streamUrlTemplate: entry.key,
        );
        metrics.channelsUpserted += 1;

        final categoryKind =
            entry.isRadio ? CategoryKind.radio : CategoryKind.live;
        final cacheKey = '${categoryKind.name}:${entry.group}';
        var categoryId = categoryCache[cacheKey];
        if (categoryId == null) {
          categoryId = await txn.categories.upsertCategory(
            providerId: providerId,
            kind: categoryKind,
            providerKey: entry.group,
            name: entry.group,
            position: null,
          );
          categoryCache[cacheKey] = categoryId;
          metrics.categoriesUpserted += 1;
        }
        await txn.channels.linkChannelToCategory(
          channelId: channelId,
          categoryId: categoryId,
        );

        if (entry.isRadio) {
          radioCount += 1;
        } else {
          liveCount += 1;
        }
      }

      final purgeCutoff = DateTime.now()
          .subtract(const Duration(days: 3));
      metrics.channelsDeleted = await txn.channels.purgeStaleChannels(
        providerId: providerId,
        olderThan: purgeCutoff,
      );

      await txn.summaries.upsertSummary(
        providerId: providerId,
        kind: CategoryKind.live,
        totalItems: liveCount,
      );
      await txn.summaries.upsertSummary(
        providerId: providerId,
        kind: CategoryKind.radio,
        totalItems: radioCount,
      );

      await txn.providers.setLastSyncAt(
        providerId: providerId,
        lastSyncAt: DateTime.now().toUtc(),
      );

      return metrics;
    });
  }
}


