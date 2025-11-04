import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';
import 'import_context.dart';

final stalkerImporterProvider = r.Provider<StalkerImporter>((ref) {
  final db = ref.watch(openIptvDbProvider);
  final categoryDao = CategoryDao(db);
  final summaryDao = SummaryDao(db);
  final providerDao = ProviderDao(db);
  final channelDao = ChannelDao(db);
  final epgDao = EpgDao(db);
  final context = ImportContext(
    db: db,
    providerDao: providerDao,
    channelDao: channelDao,
    categoryDao: categoryDao,
    summaryDao: summaryDao,
    epgDao: epgDao,
  );
  return StalkerImporter(context);
});

class StalkerImporter {
  StalkerImporter(this.context);

  final ImportContext context;

  Future<ImportMetrics> importCategories({
    required int providerId,
    required List<Map<String, dynamic>> live,
    required List<Map<String, dynamic>> vod,
    List<Map<String, dynamic>>? series,
    List<Map<String, dynamic>>? radio,
    Map<String, int>? totalsByCategory,
  }) {
    return context.runWithRetry((txn) async {
      final metrics = ImportMetrics();

      await _upsertCategorySet(
        txn,
        providerId: providerId,
        kind: CategoryKind.live,
        payload: live,
        metrics: metrics,
      );
      await _upsertCategorySet(
        txn,
        providerId: providerId,
        kind: CategoryKind.vod,
        payload: vod,
        metrics: metrics,
      );
      if (series != null) {
        await _upsertCategorySet(
          txn,
          providerId: providerId,
          kind: CategoryKind.series,
          payload: series,
          metrics: metrics,
        );
      }
      if (radio != null) {
        await _upsertCategorySet(
          txn,
          providerId: providerId,
          kind: CategoryKind.radio,
          payload: radio,
          metrics: metrics,
        );
      }

      if (totalsByCategory != null && totalsByCategory.isNotEmpty) {
        await txn.summaries.upsertSummary(
          providerId: providerId,
          kind: CategoryKind.live,
          totalItems: totalsByCategory.values.fold(0, (a, b) => a + b),
        );
      }

      await txn.providers.setLastSyncAt(
        providerId: providerId,
        lastSyncAt: DateTime.now().toUtc(),
      );

      return metrics;
    });
  }

  Future<void> _upsertCategorySet(
    ImportTxn txn, {
    required int providerId,
    required CategoryKind kind,
    required List<Map<String, dynamic>> payload,
    required ImportMetrics metrics,
  }) async {
    for (final item in payload) {
      final key = _coerceString(
        item['id'] ??
            item['category_id'] ??
            item['tv_genre_id'] ??
            item['alias'],
      );
      final name = _coerceString(
        item['title'] ??
            item['name'] ??
            item['category_name'] ??
            item['tv_genre_title'],
      );
      if (key == null || key.isEmpty || name == null || name.isEmpty) {
        continue;
      }

      await txn.categories.upsertCategory(
        providerId: providerId,
        kind: kind,
        providerKey: key,
        name: name,
        position: _parseInt(item['number'] ?? item['position']),
      );
      metrics.categoriesUpserted += 1;
    }

    await txn.summaries.upsertSummary(
      providerId: providerId,
      kind: kind,
      totalItems: payload.length,
    );
  }

  String? _coerceString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final text = value.toString();
    return int.tryParse(text);
  }
}



