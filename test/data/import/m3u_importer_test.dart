import 'dart:async';

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
import 'package:openiptv/data/import/import_context.dart';
import 'package:openiptv/data/import/m3u_importer.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  late OpenIptvDb db;
  late M3uImporter importer;
  late ChannelDao channelDao;
  late ProviderDao providerDao;
  late SummaryDao summaryDao;
  late int providerId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    channelDao = ChannelDao(db);
    providerDao = ProviderDao(db);
    summaryDao = SummaryDao(db);
    final context = ImportContext(
      db: db,
      providerDao: providerDao,
      channelDao: channelDao,
      categoryDao: CategoryDao(db),
      movieDao: MovieDao(db),
      seriesDao: SeriesDao(db),
      summaryDao: summaryDao,
      epgDao: EpgDao(db),
      importRunDao: ImportRunDao(db),
    );
    importer = M3uImporter(context);
    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.m3u,
        lockedBase: 'file://local',
        displayName: const Value('Demo Playlist'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('importEntries seeds categories and purges stale channels', () async {
    Future<void> runImport(List<M3uEntry> entries) {
      return importer.importEntries(
        providerId: providerId,
        entries: Stream.fromIterable(entries),
      );
    }

    await runImport([
      M3uEntry(
        key: 'http://stream/live1',
        name: 'Live One',
        group: 'Live',
        isRadio: false,
      ),
      M3uEntry(
        key: 'http://stream/radio',
        name: 'Radio One',
        group: 'Radio',
        isRadio: true,
      ),
    ]);

    var channels = await db.select(db.channels).get();
    expect(channels, hasLength(2));
    var summaries = await summaryDao.mapForProvider(providerId);
    expect(summaries[CategoryKind.live], 1);
    expect(summaries[CategoryKind.radio], 1);

    // Age existing channels beyond the retention window so they can be purged.
    final past = DateTime.now().toUtc().subtract(const Duration(days: 5));
    await (db.update(db.channels)
          ..where((tbl) => tbl.providerId.equals(providerId)))
        .write(ChannelsCompanion(lastSeenAt: Value(past)));

    await runImport([
      M3uEntry(
        key: 'http://stream/live2',
        name: 'Live Two',
        group: 'Live',
        isRadio: false,
      ),
    ]);

    channels = await db.select(db.channels).get();
    expect(channels.length, 1);
    expect(channels.single.providerChannelKey, 'http://stream/live2');
    summaries = await summaryDao.mapForProvider(providerId);
    expect(summaries[CategoryKind.live], 1);
    expect(summaries[CategoryKind.radio], 0);
  });

  test('importEntries classifies VOD and series entries', () async {
    await importer.importEntries(
      providerId: providerId,
      entries: Stream.fromIterable([
        M3uEntry(
          key: 'http://playlist/live',
          name: 'Live Channel',
          group: 'Live',
          isRadio: false,
        ),
        M3uEntry(
          key: 'http://playlist/radio',
          name: 'Radio Chill',
          group: 'Audio',
          isRadio: false,
        ),
        M3uEntry(
          key: 'http://playlist/movie',
          name: 'Movie Night',
          group: 'Movies',
          isRadio: false,
          logoUrl: 'http://logo/movie.png',
        ),
        M3uEntry(
          key: 'http://playlist/series',
          name: 'Series Pilot',
          group: 'Shows',
          isRadio: false,
          logoUrl: 'http://logo/series.png',
        ),
      ]),
    );

    final summaries = await summaryDao.mapForProvider(providerId);
    expect(summaries[CategoryKind.live], 1);
    expect(summaries[CategoryKind.radio], 1);
    expect(summaries[CategoryKind.vod], 1);
    expect(summaries[CategoryKind.series], 1);

    final categories = await db.select(db.categories).get();
    expect(
      categories.map((record) => record.kind).toSet(),
      containsAll({
        CategoryKind.live,
        CategoryKind.radio,
        CategoryKind.vod,
        CategoryKind.series,
      }),
    );

    final movies = await db.select(db.movies).get();
    expect(movies, hasLength(1));
    expect(movies.single.title, 'Movie Night');
    expect(movies.single.streamUrlTemplate, 'http://playlist/movie');

    final series = await db.select(db.series).get();
    expect(series, hasLength(1));
    expect(series.single.title, 'Series Pilot');

    final seasons = await db.select(db.seasons).get();
    expect(seasons, hasLength(1));
    expect(seasons.single.seriesId, series.single.id);

    final episodes = await db.select(db.episodes).get();
    expect(episodes, hasLength(1));
    expect(episodes.single.seriesId, series.single.id);
    expect(episodes.single.streamUrlTemplate, 'http://playlist/series');
  });
}
