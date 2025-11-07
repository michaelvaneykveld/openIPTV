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
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
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

    setUp(() async {
      db = OpenIptvDb.inMemory();
      providerDao = ProviderDao(db);
      summaryDao = SummaryDao(db);
      categoryDao = CategoryDao(db);
      channelDao = ChannelDao(db);
      playbackHistoryDao = PlaybackHistoryDao(db);

      container = ProviderContainer(
        overrides: [
          openIptvDbProvider.overrideWithValue(db),
        ],
      );

      providerId = await providerDao.createProvider(
        ProvidersCompanion.insert(
          kind: ProviderKind.xtream,
          lockedBase: 'https://seeded.example/',
          displayName: const Value('Seeded Provider'),
        ),
      );
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

      final resolvedProfile = ResolvedProviderProfile(
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
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          hasSecrets: false,
        ),
        secrets: const {},
        providerDbId: providerId,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: PlayerShell(profile: resolvedProfile),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Favorite One'), findsOneWidget);
      expect(find.text('Recent Channel'), findsOneWidget);
      expect(find.text('Seeded Provider'), findsOneWidget);
    });
  });
}
