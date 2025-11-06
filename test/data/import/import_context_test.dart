import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/category_dao.dart';
import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/import_run_dao.dart';
import 'package:openiptv/data/db/dao/movie_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/series_dao.dart';
import 'package:openiptv/data/db/dao/summary_dao.dart';
import 'package:openiptv/data/db/dao/epg_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/import/import_context.dart';

void main() {
  late OpenIptvDb db;
  late ImportContext context;
  late int providerId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    final providerDao = ProviderDao(db);
    final channelDao = ChannelDao(db);
    final categoryDao = CategoryDao(db);
    final movieDao = MovieDao(db);
    final seriesDao = SeriesDao(db);
    final summaryDao = SummaryDao(db);
    final epgDao = EpgDao(db);
    final importRunDao = ImportRunDao(db);

    context = ImportContext(
      db: db,
      providerDao: providerDao,
      channelDao: channelDao,
      categoryDao: categoryDao,
      movieDao: movieDao,
      seriesDao: seriesDao,
      summaryDao: summaryDao,
      epgDao: epgDao,
      importRunDao: importRunDao,
    );

    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://example.com',
        displayName: const Value('Demo Provider'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('runWithRetry logs successful import metrics', () async {
    final metrics = await context.runWithRetry(
      (txn) async {
        final result = ImportMetrics()
          ..channelsUpserted = 5
          ..categoriesUpserted = 2;
        return result;
      },
      providerId: providerId,
      importType: 'xtream',
      metricsSelector: (result) => result,
    );

    expect(metrics.channelsUpserted, 5);

    final runs = await db.select(db.importRuns).get();
    expect(runs, hasLength(1));
    final run = runs.first;
    expect(run.providerId, providerId);
    expect(run.providerKind, ProviderKind.xtream);
    expect(run.importType, 'xtream');
    expect(run.channelsUpserted, 5);
    expect(run.categoriesUpserted, 2);
    expect(run.durationMs, isNotNull);
    expect(run.error, isNull);
  });

  test('runWithRetry logs failures and rethrows', () async {
    await expectLater(
      context.runWithRetry<void>(
        (txn) async => throw StateError('boom'),
        providerId: providerId,
        importType: 'xtream',
      ),
      throwsA(isA<StateError>()),
    );

    final runs = await db.select(db.importRuns).get();
    expect(runs, hasLength(1));
    final run = runs.first;
    expect(run.error, contains('boom'));
    expect(run.channelsUpserted, isNull);
  });
}
