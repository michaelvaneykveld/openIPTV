import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/openiptv_db.dart';

void main() {
  group('Schema phase 1', () {
    late OpenIptvDb db;

    setUp(() {
      db = OpenIptvDb.inMemory();
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertProvider({
      ProviderKind kind = ProviderKind.xtream,
      String base = 'https://demo.xtream/',
    }) {
      return db.into(db.providers).insert(
            ProvidersCompanion.insert(
              kind: kind,
              lockedBase: base,
              displayName: const Value('Demo Provider'),
            ),
          );
    }

    test('channels enforce provider-scoped uniqueness', () async {
      final providerId = await insertProvider();

      final insertChannel = ChannelsCompanion.insert(
        providerId: providerId,
        providerChannelKey: 'stream-001',
        name: 'Demo Channel',
      );

      await db.into(db.channels).insert(insertChannel);

      await expectLater(
        db.into(db.channels).insert(insertChannel),
        throwsA(
          predicate(
            (dynamic error) =>
                error.toString().contains('UNIQUE constraint failed'),
          ),
        ),
      );
    });

    test('categories enforce provider/kind scoped uniqueness', () async {
      final providerId = await insertProvider();

      final insertCategory = CategoriesCompanion.insert(
        providerId: providerId,
        kind: CategoryKind.live,
        providerCategoryKey: 'news',
        name: 'News',
      );

      await db.into(db.categories).insert(insertCategory);

      await expectLater(
        db.into(db.categories).insert(insertCategory),
        throwsA(
          predicate(
            (dynamic error) =>
                error.toString().contains('UNIQUE constraint failed'),
          ),
        ),
      );
    });

    test('channel_categories has composite primary key', () async {
      final providerId = await insertProvider();
      final channelId = await db.into(db.channels).insert(
            ChannelsCompanion.insert(
              providerId: providerId,
              providerChannelKey: 'stream-002',
              name: 'Another Channel',
            ),
          );
      final categoryId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              providerId: providerId,
              kind: CategoryKind.live,
              providerCategoryKey: 'general',
              name: 'General',
            ),
          );

      final link = ChannelCategoriesCompanion.insert(
        channelId: channelId,
        categoryId: categoryId,
      );
      await db.into(db.channelCategories).insert(link);

      await expectLater(
        db.into(db.channelCategories).insert(link),
        throwsA(
          predicate(
            (dynamic error) =>
                error.toString().contains('UNIQUE constraint failed'),
          ),
        ),
      );
    });

    test('summaries enforce provider scoped uniqueness', () async {
      final providerId = await insertProvider();

      final insertSummary = SummariesCompanion.insert(
        providerId: providerId,
        kind: CategoryKind.live,
        totalItems: const Value(5),
      );

      await db.into(db.summaries).insert(insertSummary);

      await expectLater(
        db.into(db.summaries).insert(insertSummary),
        throwsA(
          predicate(
            (dynamic error) =>
                error.toString().contains('UNIQUE constraint failed'),
          ),
        ),
      );
    });

    test('foreign keys cascade when provider deleted', () async {
      final providerId = await insertProvider();
      final channelId = await db.into(db.channels).insert(
            ChannelsCompanion.insert(
              providerId: providerId,
              providerChannelKey: 'stream-003',
              name: 'Cascade Channel',
            ),
          );
      final categoryId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              providerId: providerId,
              kind: CategoryKind.live,
              providerCategoryKey: 'sports',
              name: 'Sports',
            ),
          );
      await db.into(db.channelCategories).insert(
            ChannelCategoriesCompanion.insert(
              channelId: channelId,
              categoryId: categoryId,
            ),
          );
      await db.into(db.summaries).insert(
            SummariesCompanion.insert(
              providerId: providerId,
              kind: CategoryKind.live,
              totalItems: const Value(1),
            ),
          );

      await (db.delete(db.providers)
            ..where((tbl) => tbl.id.equals(providerId)))
          .go();

      final remainingChannels = await (db.select(db.channels)
            ..where((tbl) => tbl.providerId.equals(providerId)))
          .get();
      final remainingCategories = await (db.select(db.categories)
            ..where((tbl) => tbl.providerId.equals(providerId)))
          .get();
      final remainingLinks = await (db.select(db.channelCategories)
            ..where((tbl) => tbl.channelId.equals(channelId)))
          .get();
      final remainingSummaries = await (db.select(db.summaries)
            ..where((tbl) => tbl.providerId.equals(providerId)))
          .get();

      expect(remainingChannels, isEmpty);
      expect(remainingCategories, isEmpty);
      expect(remainingLinks, isEmpty);
      expect(remainingSummaries, isEmpty);
    });

    test('channels enforce foreign key to providers', () async {
      await expectLater(
        db.into(db.channels).insert(
              ChannelsCompanion.insert(
                providerId: 999,
                providerChannelKey: 'missing-provider',
                name: 'Orphan Channel',
              ),
            ),
        throwsA(
          predicate(
            (dynamic error) =>
                error.toString().contains('FOREIGN KEY constraint failed'),
          ),
        ),
      );
    });
  });
}
