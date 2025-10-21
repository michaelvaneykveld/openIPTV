import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel_override.dart';

class ChannelOverrideRepository {
  ChannelOverrideRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<List<ChannelOverride>> getOverrides(String portalId) async {
    final rows = await _databaseHelper.getChannelOverrides(portalId);
    return rows.map(ChannelOverride.fromMap).toList();
  }

  Future<void> saveOverride(ChannelOverride override) async {
    await _databaseHelper.upsertChannelOverride(override);
  }

  Future<void> removeOverride(String portalId, String channelId) async {
    await _databaseHelper.deleteChannelOverride(portalId, channelId);
  }

  Future<void> reorder(String portalId, List<ChannelOverride> ordered) async {
    await _databaseHelper.updateChannelOverridePositions(portalId, ordered);
  }
}

final channelOverrideRepositoryProvider = Provider<ChannelOverrideRepository>((ref) {
  return ChannelOverrideRepository(DatabaseHelper.instance);
});

