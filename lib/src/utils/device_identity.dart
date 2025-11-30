import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Manages a persistent, unique identifier for this installation.
/// This allows the app to present a consistent identity to Xtream portals,
/// mimicking the behavior of "real" IPTV apps (TiviMate, Smarters) which
/// generate an install ID on first launch.
class DeviceIdentity {
  static const _storageKey = 'openiptv_device_id';
  static String? _cachedId;

  /// Returns the persistent device ID for this installation.
  /// If one does not exist, it is generated and stored.
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_storageKey);

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_storageKey, id);
    }

    _cachedId = id;
    return id;
  }
}
