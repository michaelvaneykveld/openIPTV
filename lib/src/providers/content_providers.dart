import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/storage/provider_database.dart';
import 'package:drift/drift.dart';

// --- Groups ---

final streamGroupsProvider =
    StreamProvider.family<
      List<StreamGroup>,
      ({String providerId, String type})
    >((ref, args) {
      final db = ref.watch(providerDatabaseProvider);
      return (db.select(db.streamGroups)
            ..where(
              (tbl) =>
                  tbl.providerId.equals(args.providerId) &
                  tbl.type.equals(args.type),
            )
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
          .watch();
    });

// --- Live Streams ---

final liveStreamsProvider =
    StreamProvider.family<
      List<LiveStream>,
      ({String providerId, int? categoryId})
    >((ref, args) {
      final db = ref.watch(providerDatabaseProvider);
      final query = db.select(db.liveStreams)
        ..where((tbl) => tbl.providerId.equals(args.providerId));

      if (args.categoryId != null) {
        query.where((tbl) => tbl.categoryId.equals(args.categoryId!));
      }

      return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.num)]))
          .watch();
    });

// --- VOD Streams ---

final vodStreamsProvider =
    StreamProvider.family<
      List<VodStream>,
      ({String providerId, int? categoryId})
    >((ref, args) {
      final db = ref.watch(providerDatabaseProvider);
      final query = db.select(db.vodStreams)
        ..where((tbl) => tbl.providerId.equals(args.providerId));

      if (args.categoryId != null) {
        query.where((tbl) => tbl.categoryId.equals(args.categoryId!));
      }

      return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
          .watch();
    });

// --- Series ---

final seriesProvider =
    StreamProvider.family<List<Sery>, ({String providerId, int? categoryId})>((
      ref,
      args,
    ) {
      final db = ref.watch(providerDatabaseProvider);
      final query = db.select(db.series)
        ..where((tbl) => tbl.providerId.equals(args.providerId));

      if (args.categoryId != null) {
        query.where((tbl) => tbl.categoryId.equals(args.categoryId!));
      }

      return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
          .watch();
    });

// --- Episodes ---

final episodesProvider =
    StreamProvider.family<List<Episode>, ({String providerId, int seriesId})>((
      ref,
      args,
    ) {
      final db = ref.watch(providerDatabaseProvider);
      return (db.select(db.episodes)
            ..where(
              (tbl) =>
                  tbl.providerId.equals(args.providerId) &
                  tbl.seriesId.equals(args.seriesId),
            )
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.season),
              (tbl) => OrderingTerm(expression: tbl.episode),
            ]))
          .watch();
    });

// --- EPG ---

final epgProvider =
    StreamProvider.family<
      List<EpgEvent>,
      ({String providerId, String channelId})
    >((ref, args) {
      final db = ref.watch(providerDatabaseProvider);
      final now = DateTime.now();
      return (db.select(db.epgEvents)
            ..where(
              (tbl) =>
                  tbl.providerId.equals(args.providerId) &
                  tbl.channelId.equals(args.channelId) &
                  tbl.end.isBiggerThanValue(now),
            )
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.start)])
            ..limit(5)) // Show next 5 programs
          .watch();
    });
