import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/application/services/channel_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncSettings {
  const SyncSettings({
    required this.enabled,
    required this.intervalMinutes,
    required this.wifiOnly,
  });

  final bool enabled;
  final int intervalMinutes;
  final bool wifiOnly;

  SyncSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
    bool? wifiOnly,
  }) {
    return SyncSettings(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      wifiOnly: wifiOnly ?? this.wifiOnly,
    );
  }
}

class SyncScheduler extends StateNotifier<SyncSettings> {
  SyncScheduler(this._ref)
      : super(const SyncSettings(enabled: false, intervalMinutes: 120, wifiOnly: true)) {
    _restore();
  }

  static const _enabledKey = 'sync_enabled';
  static const _intervalKey = 'sync_interval_minutes';
  static const _wifiOnlyKey = 'sync_wifi_only';

  final Ref _ref;
  Timer? _timer;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? state.enabled;
    final interval = prefs.getInt(_intervalKey) ?? state.intervalMinutes;
    final wifiOnly = prefs.getBool(_wifiOnlyKey) ?? state.wifiOnly;
    state = state.copyWith(enabled: enabled, intervalMinutes: interval, wifiOnly: wifiOnly);
    _restartTimer();
  }

  Future<void> updateSettings(SyncSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_intervalKey, settings.intervalMinutes);
    await prefs.setBool(_wifiOnlyKey, settings.wifiOnly);
    state = settings;
    _restartTimer();
  }

  Future<void> _performSync() async {
    final credentials = await _ref.read(credentialsRepositoryProvider).getSavedCredentials();
    if (credentials.isEmpty) {
      return;
    }

    if (state.wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) {
        return;
      }
    }

    final syncService = _ref.read(channelSyncServiceProvider);
    for (final credential in credentials) {
      await syncService.syncChannels(credential.id);
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!state.enabled) {
      return;
    }
    final duration = Duration(minutes: state.intervalMinutes);
    _timer = Timer.periodic(duration, (_) => _performSync());
    // kick off an immediate sync when settings change
    unawaited(_performSync());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final syncSchedulerProvider = StateNotifierProvider<SyncScheduler, SyncSettings>((ref) {
  final scheduler = SyncScheduler(ref);
  ref.onDispose(scheduler.dispose);
  return scheduler;
});


