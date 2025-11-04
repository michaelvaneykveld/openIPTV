import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import '../db/dao/category_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/epg_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/openiptv_db.dart';
import '../db/database_locator.dart';
import 'import_context.dart';

final epgImporterProvider = r.Provider<EpgImporter>((ref) {
  final db = ref.watch(openIptvDbProvider);
  final context = ImportContext(
    db: db,
    providerDao: ProviderDao(db),
    channelDao: ChannelDao(db),
    categoryDao: CategoryDao(db),
    summaryDao: SummaryDao(db),
    epgDao: EpgDao(db),
  );
  return EpgImporter(context);
});

class EpgImporter {
  EpgImporter(this.context);

  final ImportContext context;

  Future<ImportMetrics> importPrograms({
    required int providerId,
    required Map<int, List<Map<String, dynamic>>> programsByChannel,
    DateTime? retentionCutoffUtc,
  }) {
    return context.runWithRetry(
      (txn) async {
        final metrics = ImportMetrics();
        final companions = <EpgProgramsCompanion>[];

        programsByChannel.forEach((channelId, rawPrograms) {
          for (final raw in rawPrograms) {
            final start = _parseDateTime(raw['start']);
            final end = _parseDateTime(raw['end']);
            if (start == null || end == null || !end.isAfter(start)) continue;
            companions.add(
              EpgProgramsCompanion.insert(
                channelId: channelId,
                startUtc: start,
                endUtc: end,
                title: Value(_string(raw['title'])),
                subtitle: Value(_string(raw['subtitle'])),
                description: Value(_string(raw['description'])),
                season: Value(_int(raw['season'])),
                episode: Value(_int(raw['episode'])),
              ),
            );
          }
        });

        await txn.epg.bulkUpsert(companions);
        metrics.programsUpserted = companions.length;

        if (retentionCutoffUtc != null) {
          await txn.epg.purgeOlderThan(
            retentionCutoffUtc,
            providerId: providerId,
          );
        }

        await txn.providers.setLastSyncAt(
          providerId: providerId,
          lastSyncAt: DateTime.now().toUtc(),
        );

        return metrics;
      },
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toUtc();
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
