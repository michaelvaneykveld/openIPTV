
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';
import 'import_context.dart';

final xtreamImporterProvider = r.Provider<XtreamImporter>((ref) {
  final db = ref.watch(openIptvDbProvider);
  final categoryDao = CategoryDao(db);
  final channelDao = ChannelDao(db);
  final summaryDao = SummaryDao(db);
  final providerDao = ProviderDao(db);
  final epgDao = EpgDao(db);
  final context = ImportContext(
    db: db,
    providerDao: providerDao,
    channelDao: channelDao,
    categoryDao: categoryDao,
    summaryDao: summaryDao,
    epgDao: epgDao,
  );
  return XtreamImporter(context);
});

class XtreamImporter {
  XtreamImporter(this.context);

  final ImportContext context;

  Future<ImportMetrics> importAll({
    required int providerId,
    required List<Map<String, dynamic>> live,
    required List<Map<String, dynamic>> vod,
    required List<Map<String, dynamic>> series,
    required List<Map<String, dynamic>> liveCategories,
    required List<Map<String, dynamic>> vodCategories,
    required List<Map<String, dynamic>> seriesCategories,
  }) {
    return context.runWithRetry((txn) async {
      final metrics = ImportMetrics();

      await txn.channels.markAllAsCandidateForDelete(providerId);

      final liveCatMap = await _upsertCategories(
        txn,
        providerId: providerId,
        kind: CategoryKind.live,
        raw: liveCategories,
        metrics: metrics,
      );
      final vodCatMap = await _upsertCategories(
        txn,
        providerId: providerId,
        kind: CategoryKind.vod,
        raw: vodCategories,
        metrics: metrics,
      );
      final seriesCatMap = await _upsertCategories(
        txn,
        providerId: providerId,
        kind: CategoryKind.series,
        raw: seriesCategories,
        metrics: metrics,
      );

      metrics.channelsUpserted += await _upsertChannelPayload(
        txn,
        providerId: providerId,
        raw: live,
        categoryIndex: liveCatMap,
        kind: CategoryKind.live,
        isRadio: false,
      );
      metrics.channelsUpserted += await _upsertChannelPayload(
        txn,
        providerId: providerId,
        raw: vod,
        categoryIndex: vodCatMap,
        kind: CategoryKind.vod,
        isRadio: false,
      );
      metrics.channelsUpserted += await _upsertChannelPayload(
        txn,
        providerId: providerId,
        raw: series,
        categoryIndex: seriesCatMap,
        kind: CategoryKind.series,
        isRadio: false,
      );

      final purgeCutoff = DateTime.now()
          .subtract(const Duration(days: 7)); // retention window
      metrics.channelsDeleted = await txn.channels.purgeStaleChannels(
        providerId: providerId,
        olderThan: purgeCutoff,
      );

      await _upsertSummary(
        txn,
        providerId: providerId,
        kind: CategoryKind.live,
        total: live.length,
      );
      await _upsertSummary(
        txn,
        providerId: providerId,
        kind: CategoryKind.vod,
        total: vod.length,
      );
      await _upsertSummary(
        txn,
        providerId: providerId,
        kind: CategoryKind.series,
        total: series.length,
      );

      await txn.providers.setLastSyncAt(
        providerId: providerId,
        lastSyncAt: DateTime.now().toUtc(),
      );

      return metrics;
    });
  }

  Future<Map<String, int>> _upsertCategories(
    ImportTxn txn, {
    required int providerId,
    required CategoryKind kind,
    required List<Map<String, dynamic>> raw,
    required ImportMetrics metrics,
  }) async {
    final result = <String, int>{};
    for (final item in raw) {
      final key = _resolveCategoryKey(item);
      final name = _resolveCategoryName(item);
      final position = _parsePosition(item['position']);
      if (key.isEmpty || name.isEmpty) continue;
      final id = await txn.categories.upsertCategory(
        providerId: providerId,
        kind: kind,
        providerKey: key,
        name: name,
        position: position,
      );
      result[key] = id;
      metrics.categoriesUpserted += 1;
    }
    return result;
  }

  Future<int> _upsertChannelPayload(
    ImportTxn txn, {
    required int providerId,
    required List<Map<String, dynamic>> raw,
    required Map<String, int> categoryIndex,
    required CategoryKind kind,
    required bool isRadio,
  }) async {
    var upserts = 0;
    for (final item in raw) {
      final key = _resolveChannelKey(item);
      final name = _coerceString(item['name']) ?? '';
      if (key.isEmpty || name.isEmpty) continue;
      final channelId = await txn.channels.upsertChannel(
        providerId: providerId,
        providerKey: key,
        name: name,
        logoUrl: _coerceString(item['stream_icon']) ??
            _coerceString(item['logo']) ??
            _coerceString(item['thumbnail']),
        number: _parseInt(item['num']),
        isRadio: isRadio,
        streamUrlTemplate: null,
        seenAt: DateTime.now().toUtc(),
      );
      final categoryId = _resolveCategoryId(item, kind, categoryIndex);
      if (categoryId != null) {
        await txn.channels.linkChannelToCategory(
          channelId: channelId,
          categoryId: categoryId,
        );
      }
      upserts += 1;
    }
    return upserts;
  }

  Future<void> _upsertSummary(
    ImportTxn txn, {
    required int providerId,
    required CategoryKind kind,
    required int total,
  }) {
    return txn.summaries.upsertSummary(
      providerId: providerId,
      kind: kind,
      totalItems: total,
    );
  }

  String _resolveCategoryKey(Map<String, dynamic> item) {
    return _coerceString(
      item['category_id'] ?? item['id'] ?? item['parent_id'],
    ) ?? ''; 
  }

  String _resolveCategoryName(Map<String, dynamic> item) {
    return _coerceString(
      item['category_name'] ?? item['name'] ?? item['title'],
    ) ?? ''; 
  }

  int? _parsePosition(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  String _resolveChannelKey(Map<String, dynamic> item) {
    return _coerceString(
          item['stream_id'] ??
              item['id'] ??
              item['num'] ??
              item['series_id'] ??
              item['vod_id'],
        ) ??
        '';
  }

  int? _resolveCategoryId(
    Map<String, dynamic> item,
    CategoryKind kind,
    Map<String, int> categories,
  ) {
    final key = switch (kind) {
      CategoryKind.live => _coerceString(item['category_id']),
      CategoryKind.vod => _coerceString(item['category_id']),
      CategoryKind.series => _coerceString(item['category_id']),
      CategoryKind.radio => _coerceString(item['category_id']),
    };
    if (key == null) return null;
    return categories[key];
  }

  String? _coerceString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed;
  }
}





