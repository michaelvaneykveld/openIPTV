import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/db/dao/playback_history_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/data/repositories/channel_repository.dart';

final playbackHistoryDaoProvider = Provider<PlaybackHistoryDao>((ref) {
  return PlaybackHistoryDao(ref.watch(openIptvDbProvider));
});

final providerFavoritesProvider =
    StreamProvider.autoDispose.family<List<ChannelWithFlags>, int>((ref, providerId) {
      final repository = ref.watch(channelRepositoryProvider);
      return repository.watchFavoriteChannels(providerId);
    });

final providerRecentPlaybackProvider =
    StreamProvider.autoDispose.family<List<RecentChannelPlayback>, int>((ref, providerId) {
      final historyDao = ref.watch(playbackHistoryDaoProvider);
      final db = ref.watch(openIptvDbProvider);
      final channels = db.channels;
      final flags = db.userFlags;

      return historyDao
          .watchRecent(providerId: providerId, limit: 15)
          .asyncMap((histories) async {
        if (histories.isEmpty) {
          return const <RecentChannelPlayback>[];
        }
        final ids = histories.map((h) => h.channelId).toSet().toList();
        if (ids.isEmpty) {
          return const <RecentChannelPlayback>[];
        }
        final joined = await (db.select(channels)
              ..where((tbl) => tbl.id.isIn(ids)))
            .join([
          leftOuterJoin(
            flags,
            flags.channelId.equalsExp(channels.id),
          ),
        ]).get();
        final mapping = <int, (ChannelRecord, UserFlagRecord?)>{};
        for (final row in joined) {
          mapping[row.readTable(channels).id] = (
            row.readTable(channels),
            row.readTableOrNull(flags),
          );
        }
        return [
          for (final record in histories)
            RecentChannelPlayback(
              history: record,
              channel: mapping[record.channelId]?.$1,
              flags: mapping[record.channelId]?.$2,
            ),
        ];
      });
    });

class RecentChannelPlayback {
  RecentChannelPlayback({
    required this.history,
    this.channel,
    this.flags,
  });

  final PlaybackHistoryRecord history;
  final ChannelRecord? channel;
  final UserFlagRecord? flags;

  bool get isFavorite => flags?.isFavorite ?? false;
  double? get progress {
    final duration = history.durationSec;
    if (duration == null || duration <= 0) return null;
    return history.positionSec / duration;
  }
}
