import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/db/dao/category_dao.dart';
import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/playback_history_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/summary_dao.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/repositories/channel_repository.dart';
import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/providers/player_library_providers.dart';
import 'package:openiptv/src/providers/provider_import_service.dart';
import 'package:openiptv/src/ui/player/player_shell.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerShell integration', () {
    late OpenIptvDb db;
    late ProviderContainer container;
    late ProviderDao providerDao;
    late SummaryDao summaryDao;
    late CategoryDao categoryDao;
    late ChannelDao channelDao;
    late PlaybackHistoryDao playbackHistoryDao;
    late int providerId;
    late ResolvedProviderProfile resolvedProfile;

    late _FakeImportService importService;

    setUp(() async {
      db = OpenIptvDb.inMemory();
      providerDao = ProviderDao(db);
      summaryDao = SummaryDao(db);
      categoryDao = CategoryDao(db);
      channelDao = ChannelDao(db);
      playbackHistoryDao = PlaybackHistoryDao(db);

      importService = _FakeImportService();

      container = ProviderContainer(
        overrides: [
          openIptvDbProvider.overrideWithValue(db),
          providerImportServiceProvider.overrideWithValue(importService),
        ],
      );

      providerId = await providerDao.createProvider(
        ProvidersCompanion.insert(
          kind: ProviderKind.xtream,
          lockedBase: 'https://seeded.example/',
          displayName: const Value('Seeded Provider'),
        ),
      );

      resolvedProfile = _buildProfile(providerId);
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    testWidgets('renders favorites and recent playback using seeded DB',
        (tester) async {
      await categoryDao.upsertCategory(
        providerId: providerId,
        kind: CategoryKind.live,
        providerKey: 'live',
        name: 'Live',
      );

      final favoriteChannelId = await channelDao.upsertChannel(
        providerId: providerId,
        providerKey: 'fav-1',
        name: 'Favorite One',
        number: 1,
        // Leave empty to avoid artwork fetches during widget tests.
        logoUrl: '',
        seenAt: DateTime.now().toUtc(),
      );
      final recentChannelId = await channelDao.upsertChannel(
        providerId: providerId,
        providerKey: 'recent-1',
        name: 'Recent Channel',
        number: 2,
        seenAt: DateTime.now().toUtc(),
      );

      await ChannelRepository(
        channelDao: channelDao,
        categoryDao: categoryDao,
        userFlagDao: container.read(userFlagDaoProvider),
      ).setChannelFlags(
        providerId: providerId,
        channelId: favoriteChannelId,
        isFavorite: true,
      );

      await playbackHistoryDao.upsertProgress(
        providerId: providerId,
        channelId: recentChannelId,
        positionSec: 120,
        durationSec: 3600,
      );

      await summaryDao.upsertSummary(
        providerId: providerId,
        kind: CategoryKind.live,
        totalItems: 1,
      );

      await _pumpShell(tester, container, resolvedProfile);
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Favorite One'), findsOneWidget);
      expect(find.text('Recent Channel'), findsOneWidget);
      expect(find.text('Seeded Provider'), findsOneWidget);
    });

    testWidgets('shows DB-backed category previews when expanded',
        (tester) async {
      final categoryId = await categoryDao.upsertCategory(
        providerId: providerId,
        kind: CategoryKind.live,
        providerKey: 'live',
        name: 'Seeded Live',
      );
      final channelId = await channelDao.upsertChannel(
        providerId: providerId,
        providerKey: 'preview-1',
        name: 'Preview Channel',
        logoUrl: '',
        number: 10,
        seenAt: DateTime.now().toUtc(),
      );
      await channelDao.linkChannelToCategory(
        channelId: channelId,
        categoryId: categoryId,
      );
      await summaryDao.upsertSummary(
        providerId: providerId,
        kind: CategoryKind.live,
        totalItems: 1,
      );

      await _pumpShell(tester, container, resolvedProfile);
      await tester.pumpAndSettle();

      expect(find.text('Seeded Live'), findsOneWidget);

      await tester.tap(find.text('Seeded Live'));
      await tester.pumpAndSettle();

      expect(find.text('Preview Channel'), findsOneWidget);
    });

    testWidgets('toggles summary view using DB snapshot', (tester) async {
      await categoryDao.upsertCategory(
        providerId: providerId,
        kind: CategoryKind.live,
        providerKey: 'live',
        name: 'Live',
      );
      await summaryDao.upsertSummary(
        providerId: providerId,
        kind: CategoryKind.live,
        totalItems: 1,
      );

      await _pumpShell(tester, container, resolvedProfile);
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);

      await tester.tap(find.byTooltip('Show summary'));
      await tester.pumpAndSettle();

      expect(find.text('Xtream Portal Summary'), findsOneWidget);
      expect(find.text('Live: 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Hide summary'));
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('shows syncing placeholder when database is empty',
        (tester) async {
      final localImportService = _FakeImportService();
      final placeholderContainer = ProviderContainer(
        overrides: [
          openIptvDbProvider.overrideWithValue(db),
          providerImportServiceProvider.overrideWithValue(localImportService),
          dbCategoriesProvider(providerId).overrideWith(
            (ref) => Stream.value(
              const <ContentBucket, List<CategoryEntry>>{},
            ),
          ),
          dbSummaryProvider(DbSummaryArgs(providerId, ProviderKind.xtream))
              .overrideWith(
            (ref) => Stream.value(
              SummaryData(kind: ProviderKind.xtream),
            ),
          ),
          providerFavoritesProvider(providerId).overrideWith(
            (ref) => const Stream< List<ChannelWithFlags> >.empty(),
          ),
          providerRecentPlaybackProvider(providerId).overrideWith(
            (ref) => const Stream<List<RecentChannelPlayback>>.empty(),
          ),
        ],
      );

      addTearDown(placeholderContainer.dispose);

      await _pumpShell(tester, placeholderContainer, resolvedProfile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Syncing provider library...'), findsOneWidget);
      expect(localImportService.called, isTrue);

      await _unmountShell(tester);
    });

    testWidgets('shows summary syncing placeholder when no counts are ready',
        (tester) async {
      final localImportService = _FakeImportService();
      final placeholderContainer = ProviderContainer(
        overrides: [
          openIptvDbProvider.overrideWithValue(db),
          providerImportServiceProvider.overrideWithValue(localImportService),
          dbCategoriesProvider(providerId).overrideWith(
            (ref) => Stream.value({
              ContentBucket.live: [
                CategoryEntry(id: '1', name: 'Live', count: 0),
              ],
            }),
          ),
          dbSummaryProvider(DbSummaryArgs(providerId, ProviderKind.xtream))
              .overrideWith(
            (ref) => Stream.value(
              SummaryData(kind: ProviderKind.xtream),
            ),
          ),
          providerFavoritesProvider(providerId).overrideWith(
            (ref) => const Stream<List<ChannelWithFlags>>.empty(),
          ),
          providerRecentPlaybackProvider(providerId).overrideWith(
            (ref) => const Stream<List<RecentChannelPlayback>>.empty(),
          ),
        ],
      );
      addTearDown(placeholderContainer.dispose);

      await _pumpShell(tester, placeholderContainer, resolvedProfile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip('Show summary'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Syncing provider summary...'), findsOneWidget);
      expect(localImportService.called, isTrue);

      await _unmountShell(tester);
    });
  });
}

Future<void> _pumpShell(
  WidgetTester tester,
  ProviderContainer container,
  ResolvedProviderProfile profile,
) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PlayerShell(profile: profile),
      ),
    ),
  );
}

Future<void> _unmountShell(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

ResolvedProviderProfile _buildProfile(int providerId) {
  final now = DateTime.now().toUtc();
  return ResolvedProviderProfile(
    record: ProviderProfileRecord(
      id: 'seeded',
      kind: ProviderKind.xtream,
      displayName: 'Seeded Provider',
      lockedBase: Uri.parse('https://seeded.example/'),
      needsUserAgent: false,
      allowSelfSignedTls: false,
      followRedirects: true,
      configuration: const {},
      hints: const {},
      createdAt: now,
      updatedAt: now,
      hasSecrets: false,
    ),
    secrets: const {},
    providerDbId: providerId,
  );
}

class _FakeImportService implements ProviderImportService {
  bool called = false;

  @override
  Future<void> runInitialImport(
    ResolvedProviderProfile profile, {
    bool forceRefresh = false,
  }) async {
    called = true;
  }

  @override
  Stream<ProviderImportEvent> watchProgress(int providerId) =>
      const Stream<ProviderImportEvent>.empty();

  @override
  Future<void> cancelImport(int providerId) async {}
}
