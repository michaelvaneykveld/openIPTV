
import 'package:shared_preferences/shared_preferences.dart';

class SyncManager {
  static const _lastSyncKey = 'last_sync_timestamp';
  static const _syncInterval = Duration(hours: 24);

  const SyncManager();

  Future<bool> needsSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMillis = prefs.getInt(_lastSyncKey);

    if (lastSyncMillis == null) {
      return true; // Never synced before
    }

    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    final now = DateTime.now();

    return now.difference(lastSync) > _syncInterval;
  }

  Future<void> updateSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
}
