import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/category_dao.dart';
import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/epg_dao.dart';
import 'package:openiptv/data/db/dao/import_run_dao.dart';
import 'package:openiptv/data/db/dao/movie_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/series_dao.dart';
import 'package:openiptv/data/db/dao/summary_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/import/epg_importer.dart';
import 'package:openiptv/data/import/import_context.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  group('EpgImporter', () {
    late OpenIptvDb db;
    late ProviderDao providerDao;
    late ChannelDao channelDao;
    late EpgImporter importer;
    late int providerId;
    late int channelId;

    setUp(() async {
      db = OpenIptvDb.inMemory();
      providerDao = ProviderDao(db);
      channelDao = ChannelDao(db);
      final context = ImportContext(
        db: db,
        providerDao: providerDao,
        channelDao: channelDao,
        categoryDao: CategoryDao(db),
        movieDao: MovieDao(db),
        seriesDao: SeriesDao(db),
        summaryDao: SummaryDao(db),
        epgDao: EpgDao(db),
        importRunDao: ImportRunDao(db),
      );
      importer = EpgImporter(context);
      providerId = await providerDao.createProvider(
        ProvidersCompanion.insert(
          kind: ProviderKind.xtream,
          lockedBase: 'https://seeded.example/',
          displayName: const Value('Seeded Provider'),
        ),
      );
      channelId = await channelDao.upsertChannel(
        providerId: providerId,
        providerKey: 'seeded-channel',
        name: 'Seeded Channel',
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('updates channel program window from EPG payload', () async {
      final programs = [
        {
          'start': '2024-01-01T08:00:00Z',
          'end': '2024-01-01T09:00:00Z',
          'title': 'Breakfast Show',
        },
        {
          'start': '2024-01-03T12:00:00Z',
          'end': '2024-01-03T13:30:00Z',
          'title': 'Lunch Special',
        },
      ];

      await importer.importPrograms(
        providerId: providerId,
        programsByChannel: {
          channelId: programs,
        },
      );

      final row = await (db.select(db.channels)
            ..where((tbl) => tbl.id.equals(channelId)))
          .getSingle();
      expect(row.firstProgramAt?.toUtc(), DateTime.parse('2024-01-01T08:00:00Z'));
      expect(row.lastProgramAt?.toUtc(), DateTime.parse('2024-01-03T13:30:00Z'));
    });
  });
}
