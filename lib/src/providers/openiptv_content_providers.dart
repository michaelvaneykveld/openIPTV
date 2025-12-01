import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/playback/playable_resolver.dart';
import 'package:openiptv/src/player/summary_models.dart';

// --- Resolver ---

final playableResolverProvider =
    Provider.family<PlayableResolver, ResolvedProviderProfile>((ref, profile) {
      return PlayableResolver(profile);
    });

// --- Channels ---

final channelsProvider =
    StreamProvider.family<
      List<ChannelRecord>,
      ({int providerId, int? categoryId, CategoryKind? kind})
    >((ref, args) {
      final db = ref.watch(openIptvDbProvider);

      if (args.categoryId != null) {
        final query = db.select(db.channels).join([
          innerJoin(
            db.channelCategories,
            db.channelCategories.channelId.equalsExp(db.channels.id),
          ),
        ]);
        query.where(
          db.channels.providerId.equals(args.providerId) &
              db.channelCategories.categoryId.equals(args.categoryId!),
        );
        query.orderBy([
          OrderingTerm(expression: db.channels.number),
          OrderingTerm(expression: db.channels.name),
        ]);
        return query.map((row) => row.readTable(db.channels)).watch();
      }

      if (args.kind != null) {
        final query = db.select(db.channels).join([
          innerJoin(
            db.channelCategories,
            db.channelCategories.channelId.equalsExp(db.channels.id),
          ),
          innerJoin(
            db.categories,
            db.categories.id.equalsExp(db.channelCategories.categoryId),
          ),
        ]);
        query.where(
          db.channels.providerId.equals(args.providerId) &
              db.categories.kind.equalsValue(args.kind!),
        );
        query.orderBy([
          OrderingTerm(expression: db.channels.number),
          OrderingTerm(expression: db.channels.name),
        ]);
        query.groupBy([db.channels.id]);
        return query.map((row) => row.readTable(db.channels)).watch();
      }

      final query = db.select(db.channels)
        ..where((tbl) => tbl.providerId.equals(args.providerId))
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.number),
          (tbl) => OrderingTerm(expression: tbl.name),
        ]);
      return query.watch();
    });

// --- Movies ---

final moviesProvider =
    StreamProvider.family<
      List<MovieRecord>,
      ({int providerId, int? categoryId})
    >((ref, args) {
      final db = ref.watch(openIptvDbProvider);
      final query = db.select(db.movies)
        ..where((tbl) => tbl.providerId.equals(args.providerId));

      if (args.categoryId != null) {
        query.where((tbl) => tbl.categoryId.equals(args.categoryId!));
      }

      return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .watch();
    });

// --- Series ---

final seriesProvider =
    StreamProvider.family<
      List<SeriesRecord>,
      ({int providerId, int? categoryId})
    >((ref, args) {
      final db = ref.watch(openIptvDbProvider);
      final query = db.select(db.series)
        ..where((tbl) => tbl.providerId.equals(args.providerId));

      if (args.categoryId != null) {
        query.where((tbl) => tbl.categoryId.equals(args.categoryId!));
      }

      return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .watch();
    });

// --- Episodes ---

final episodesProvider =
    StreamProvider.family<
      List<EpisodeRecord>,
      ({int providerId, int seriesId})
    >((ref, args) {
      final db = ref.watch(openIptvDbProvider);
      return (db.select(db.episodes)
            ..where((tbl) => tbl.seriesId.equals(args.seriesId))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.seasonNumber),
              (tbl) => OrderingTerm(expression: tbl.episodeNumber),
            ]))
          .watch();
    });

// --- EPG ---

final epgProvider =
    StreamProvider.family<List<EpgProgramRecord>, ({int channelId})>((
      ref,
      args,
    ) {
      final db = ref.watch(openIptvDbProvider);
      final now = DateTime.now().toUtc();
      return (db.select(db.epgPrograms)
            ..where(
              (tbl) =>
                  tbl.channelId.equals(args.channelId) &
                  tbl.endUtc.isBiggerThanValue(now),
            )
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.startUtc)])
            ..limit(5))
          .watch();
    });
