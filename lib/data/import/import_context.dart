import 'dart:async';

import '../db/dao/category_dao.dart';
import '../db/dao/channel_dao.dart';
import '../db/dao/provider_dao.dart';
import '../db/dao/summary_dao.dart';
import '../db/openiptv_db.dart';

class ImportMetrics {
  int channelsUpserted = 0;
  int categoriesUpserted = 0;
  int channelsDeleted = 0;
  Duration duration = Duration.zero;
}

typedef ImportAction<T> = Future<T> Function(ImportTxn txn);

class ImportTxn {
  ImportTxn(
    this.db,
    this.providers,
    this.channels,
    this.categories,
    this.summaries,
  );

  final OpenIptvDb db;
  final ProviderDao providers;
  final ChannelDao channels;
  final CategoryDao categories;
  final SummaryDao summaries;
}

class ImportContext {
  ImportContext({
    required this.db,
    required this.providerDao,
    required this.channelDao,
    required this.categoryDao,
    required this.summaryDao,
  });

  final OpenIptvDb db;
  final ProviderDao providerDao;
  final ChannelDao channelDao;
  final CategoryDao categoryDao;
  final SummaryDao summaryDao;

  Future<T> run<T>(ImportAction<T> action) async {
    final start = DateTime.now();
    final txn = ImportTxn(
      db,
      providerDao,
      channelDao,
      categoryDao,
      summaryDao,
    );
    final result = await db.transaction(() => action(txn));
    final duration = DateTime.now().difference(start);
    if (result is ImportMetrics) {
      result.duration = duration;
    }
    return result;
  }

  Future<T> runWithRetry<T>(
    ImportAction<T> action, {
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 200),
  }) async {
    var attempt = 0;
    Object? lastError;
    while (attempt < maxAttempts) {
      attempt += 1;
      try {
        return await run(action);
      } catch (error) {
        lastError = error;
        if (attempt >= maxAttempts) break;
        await Future<void>.delayed(delay * attempt);
      }
    }
    throw lastError ?? StateError('Import failed without error.');
  }
}
