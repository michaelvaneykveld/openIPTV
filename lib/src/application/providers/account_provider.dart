import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivePortalController extends StateNotifier<String?> {
  ActivePortalController() : super(null) {
    _load();
  }

  static const _activePortalKey = 'active_portal_id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activePortalKey);
    state = value;
  }

  Future<void> setActivePortal(String? portalId) async {
    state = portalId;
    final prefs = await SharedPreferences.getInstance();
    if (portalId == null) {
      await prefs.remove(_activePortalKey);
    } else {
      await prefs.setString(_activePortalKey, portalId);
    }
  }
}

final activePortalProvider =
    StateNotifierProvider<ActivePortalController, String?>(
      (ref) => ActivePortalController(),
    );
