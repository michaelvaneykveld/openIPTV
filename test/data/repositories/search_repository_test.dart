import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/category_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/user_flag_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/repositories/search_repository.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

void main() {
  late OpenIptvDb db;
  late ProviderDao providerDao;
  late ChannelDao channelDao;
  late SearchRepository repository;
  late int providerId;
  late int channelA;
  late int channelB;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    providerDao = ProviderDao(db);
    channelDao = ChannelDao(db);
    repository = SearchRepository(
      db: db,
      userFlagDao: UserFlagDao(db),
    );

    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://demo',
        displayName: const Value('Demo'),
      ),
    );

    channelA = await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'A',
      name: 'Channel Alpha',
      number: 1,
      isRadio: false,
      logoUrl: null,
      streamUrlTemplate: null,
    );

    channelB = await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'B',
      name: 'Channel Beta',
      number: 2,
      isRadio: false,
      logoUrl: null,
      streamUrlTemplate: null,
    );

    await repository.setChannelFlags(
      providerId: providerId,
      channelId: channelB,
      isFavorite: true,
    );

    final now = DateTime.now().toUtc();
    await db.into(db.epgPrograms).insert(
      EpgProgramsCompanion.insert(
        channelId: channelA,
        startUtc: now,
        endUtc: now.add(const Duration(hours: 1)),
        title: const Value('Morning News'),
        description: const Value('Morning top stories from around the world'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('searchChannels respects favorites, hidden flags, and highlights', () async {
    final all = await repository.searchChannels(
      providerId: providerId,
      query: 'channel',
    );
    expect(all, hasLength(2));
    expect(
      all.first.highlightedName?.toLowerCase(),
      contains('<mark>channel</mark>'),
    );

    final favorites = await repository.searchChannels(
      providerId: providerId,
      favoritesOnly: true,
    );
    expect(favorites, hasLength(1));
    expect(favorites.single.channel.id, channelB);

    await repository.setChannelFlags(
      providerId: providerId,
      channelId: channelB,
      isFavorite: true,
      isHidden: true,
    );

    final visible = await repository.searchChannels(
      providerId: providerId,
    );
    expect(visible.any((entry) => entry.channel.id == channelB), isFalse);
  });

  test('searchPrograms queries FTS table', () async {
    final results = await repository.searchPrograms(
      providerId: providerId,
      query: 'Morning',
    );
    expect(results, hasLength(1));
    expect(results.single.channelName, 'Channel Alpha');
    expect(results.single.program.title, 'Morning News');
    expect(results.single.highlightedTitle, contains('<mark>Morning</mark>'));
    expect(
      results.single.highlightedDescription,
      contains('<mark>Morning</mark>'),
    );
  });

  test('searchChannels supports category and recency filters', () async {
    final categoryDao = CategoryDao(db);
    final categoryId = await categoryDao.upsertCategory(
      providerId: providerId,
      kind: CategoryKind.live,
      providerKey: 'live-all',
      name: 'Live - All',
    );

    await db.into(db.channelCategories).insert(
          ChannelCategoriesCompanion.insert(
            channelId: channelA,
            categoryId: categoryId,
          ),
        );

    final now = DateTime.now().toUtc();
    await db.into(db.playbackHistory).insert(
          PlaybackHistoryCompanion.insert(
            providerId: providerId,
            channelId: channelA,
            startedAt: now.subtract(const Duration(minutes: 30)),
            updatedAt: now,
            positionSec: const Value(120),
            durationSec: const Value(3600),
            completed: const Value(false),
          ),
        );

    final results = await repository.searchChannels(
      providerId: providerId,
      categoryId: categoryId,
      updatedAfter: now.subtract(const Duration(hours: 1)),
      mostRecentFirst: true,
    );

    expect(results, hasLength(1));
    final entry = results.single;
    expect(entry.channel.id, channelA);
    expect(entry.hasWatchHistory, isTrue);
    final deltaMs = entry.lastWatchedAt!
        .difference(now)
        .inMilliseconds
        .abs();
    expect(deltaMs, lessThan(1000));
  });

  test('searchVod returns movie and series matches with highlights', () async {
    final movieCategoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            providerId: providerId,
            kind: CategoryKind.vod,
            providerCategoryKey: 'vod-main',
            name: 'Blockbusters',
          ),
        );

    final movieId = await db.into(db.movies).insert(
          MoviesCompanion.insert(
            providerId: providerId,
            providerVodKey: 'mov-1',
            categoryId: Value(movieCategoryId),
            title: 'Action Hero',
            overview: const Value('An unstoppable hero saves the city.'),
          ),
        );

    final seriesCategoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            providerId: providerId,
            kind: CategoryKind.series,
            providerCategoryKey: 'series-main',
            name: 'Drama',
          ),
        );

    final seriesId = await db.into(db.series).insert(
          SeriesCompanion.insert(
            providerId: providerId,
            providerSeriesKey: 'series-1',
            categoryId: Value(seriesCategoryId),
            title: 'City Stories',
            overview: const Value('A hero\'s tale of life in the big city.'),
          ),
        );

    final results = await repository.searchVod(
      providerId: providerId,
      query: 'city hero',
    );

    expect(results, hasLength(2));
    final movieResult =
        results.firstWhere((result) => result.kind == VodItemKind.movie);
    final seriesResult =
        results.firstWhere((result) => result.kind == VodItemKind.series);

    expect(movieResult.movie?.id, movieId);
    expect(
      movieResult.highlightedTitle?.toLowerCase(),
      contains('<mark>hero</mark>'),
    );
    expect(seriesResult.series?.id, seriesId);
    expect(
      seriesResult.highlightedDescription?.toLowerCase(),
      contains('<mark>city</mark>'),
    );
  });

  test('loadDashboardSummary aggregates channel, VOD, and user metrics', () async {
    await db.into(db.summaries).insert(
          SummariesCompanion.insert(
            providerId: providerId,
            kind: CategoryKind.live,
            totalItems: const Value(80),
          ),
        );
    await db.into(db.summaries).insert(
          SummariesCompanion.insert(
            providerId: providerId,
            kind: CategoryKind.vod,
            totalItems: const Value(120),
          ),
        );
    await db.into(db.summaries).insert(
          SummariesCompanion.insert(
            providerId: providerId,
            kind: CategoryKind.series,
            totalItems: const Value(45),
          ),
        );

    await repository.setChannelFlags(
      providerId: providerId,
      channelId: channelA,
      isFavorite: true,
    );
    await repository.setChannelFlags(
      providerId: providerId,
      channelId: channelB,
      isFavorite: true,
      isHidden: true,
    );

    final now = DateTime.now().toUtc();
    await db.into(db.playbackHistory).insert(
          PlaybackHistoryCompanion.insert(
            providerId: providerId,
            channelId: channelA,
            startedAt: now.subtract(const Duration(minutes: 10)),
            updatedAt: now,
            positionSec: const Value(30),
            durationSec: const Value(3600),
            completed: const Value(false),
          ),
        );

    final summary = await repository.loadDashboardSummary(providerId: providerId);
    expect(summary.liveChannels, 80);
    expect(summary.vodItems, 120);
    expect(summary.seriesItems, 45);
    expect(summary.favoriteChannels, 2); // channelA + channelB
    expect(summary.hiddenChannels, 1); // channelB hidden here
    expect(summary.recentlyWatchedChannels, 1);
  });
}
