import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:openiptv/src/utils/playback_logger.dart';
import 'xtream_raw_client.dart';

/// DEPRECATED: TiviMate-style session manager - BLOCKED BY CLOUDFLARE
///
/// This class uses RAW TCP sockets for keepalive which Cloudflare blocks.
/// DO NOT USE - kept for reference only.
///
/// Cloudflare blocks:
/// 1. RAW TCP keepalive pings (live_clients polling)
/// 2. Extended handshake sequences
/// 3. Session management via raw sockets
/// 4. Any non-standard HTTP patterns
///
/// Use simple HTTP API calls instead - no session management needed.
class XtreamSessionManager {
  final XtreamRawClient _rawClient;
  final Random _random = Random();
  Timer? _keepaliveTimer;
  DateTime? _lastHandshake;
  Map<String, dynamic>? _sessionData;

  // TiviMate timing patterns
  static const Duration _keepaliveInterval = Duration(seconds: 12);
  static const Duration _sessionTimeout = Duration(minutes: 5);

  XtreamSessionManager({XtreamRawClient? rawClient})
    : _rawClient = rawClient ?? XtreamRawClient();

  /// Check if we have a valid active session
  bool get hasActiveSession {
    if (_sessionData == null || _lastHandshake == null) return false;
    return DateTime.now().difference(_lastHandshake!) < _sessionTimeout;
  }

  /// Perform full TiviMate-style handshake sequence
  ///
  /// This replicates TiviMate's exact API call order:
  /// 1. GET player_api.php (basic auth check)
  /// 2. Sleep 400-700ms (random jitter)
  /// 3. GET player_api.php?action=get_live_streams
  /// 4. GET player_api.php?action=get_vod_streams
  /// 5. GET player_api.php?action=get_series
  /// 6. Start keepalive timer
  Future<Map<String, dynamic>> performHandshake({
    required String host,
    required int port,
    required String username,
    required String password,
    bool enableLogging = true,
  }) async {
    if (enableLogging) {
      PlaybackLogger.log(
        '🚀 Starting TiviMate handshake sequence',
        tag: 'xtream-session',
      );
    }

    // Step 1: Initial player_api.php call (basic auth)
    final playerApiResponse = await _callPlayerApi(
      host: host,
      port: port,
      username: username,
      password: password,
      action: null,
      enableLogging: enableLogging,
    );

    // Verify authentication
    final userInfo = playerApiResponse['user_info'] as Map<String, dynamic>?;
    if (userInfo == null) {
      throw Exception('No user_info in player_api response');
    }

    final auth = userInfo['auth'];
    final status = userInfo['status']?.toString();

    if (auth != 1 && auth != '1') {
      throw Exception('Authentication failed: auth=$auth');
    }

    if (status?.toLowerCase() != 'active') {
      throw Exception('Account not active: status=$status');
    }

    if (enableLogging) {
      PlaybackLogger.log(
        '✅ Step 1/5: Authentication successful',
        tag: 'xtream-session',
      );
      PlaybackLogger.log('  Username: $username', tag: 'xtream-session');
      PlaybackLogger.log('  Status: $status', tag: 'xtream-session');
      PlaybackLogger.log(
        '  Expiry: ${userInfo['exp_date']}',
        tag: 'xtream-session',
      );
      PlaybackLogger.log(
        '  Max connections: ${userInfo['max_connections']}',
        tag: 'xtream-session',
      );
    }

    // Step 2: Random delay (TiviMate timing pattern)
    final delayMs = 400 + _random.nextInt(300); // 400-700ms
    if (enableLogging) {
      PlaybackLogger.log(
        '⏱️  Step 2/5: Random delay ${delayMs}ms',
        tag: 'xtream-session',
      );
    }
    await Future.delayed(Duration(milliseconds: delayMs));

    // Step 3: Get live streams (establishes session context)
    if (enableLogging) {
      PlaybackLogger.log(
        '📡 Step 3/5: Fetching live streams',
        tag: 'xtream-session',
      );
    }
    final liveStreams = await _callPlayerApi(
      host: host,
      port: port,
      username: username,
      password: password,
      action: 'get_live_streams',
      enableLogging: false,
    );

    // Step 4: Get VOD streams
    if (enableLogging) {
      PlaybackLogger.log(
        '🎬 Step 4/5: Fetching VOD streams',
        tag: 'xtream-session',
      );
    }
    final vodStreams = await _callPlayerApi(
      host: host,
      port: port,
      username: username,
      password: password,
      action: 'get_vod_streams',
      enableLogging: false,
    );

    // Step 5: Get series
    if (enableLogging) {
      PlaybackLogger.log('📺 Step 5/5: Fetching series', tag: 'xtream-session');
    }
    final series = await _callPlayerApi(
      host: host,
      port: port,
      username: username,
      password: password,
      action: 'get_series',
      enableLogging: false,
    );

    // Store session data
    _sessionData = {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'player_api': playerApiResponse,
      'live_count': (liveStreams as List?)?.length ?? 0,
      'vod_count': (vodStreams as List?)?.length ?? 0,
      'series_count': (series as List?)?.length ?? 0,
    };
    _lastHandshake = DateTime.now();

    if (enableLogging) {
      PlaybackLogger.log('✅ Handshake complete!', tag: 'xtream-session');
      PlaybackLogger.log(
        '  Live channels: ${_sessionData!['live_count']}',
        tag: 'xtream-session',
      );
      PlaybackLogger.log(
        '  VOD items: ${_sessionData!['vod_count']}',
        tag: 'xtream-session',
      );
      PlaybackLogger.log(
        '  Series: ${_sessionData!['series_count']}',
        tag: 'xtream-session',
      );
    }

    // DISABLED: Keepalive timer (RAW TCP blocked by Cloudflare)
    // _startKeepalive(
    //   host: host,
    //   port: port,
    //   username: username,
    //   password: password,
    //   enableLogging: enableLogging,
    // );

    if (enableLogging) {
      PlaybackLogger.log(
        '⚠️  Keepalive DISABLED (Cloudflare blocks RAW TCP)',
        tag: 'xtream-session',
      );
    }

    return playerApiResponse;
  }

  /// Call player_api.php with optional action parameter
  Future<dynamic> _callPlayerApi({
    required String host,
    required int port,
    required String username,
    required String password,
    String? action,
    bool enableLogging = false,
  }) async {
    final queryParams = <String, String>{
      'username': username,
      'password': password,
    };
    if (action != null) {
      queryParams['action'] = action;
    }

    final query = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final path = '/player_api.php?$query';

    if (enableLogging) {
      PlaybackLogger.log('GET $host:$port$path', tag: 'xtream-session');
    }

    final body = await _rawClient.get(host, port, path, {});
    return jsonDecode(body);
  }

  /// DEPRECATED: TiviMate-style keepalive timer - BLOCKED BY CLOUDFLARE
  ///
  /// Cloudflare blocks RAW TCP keepalive patterns:
  /// - action=live_clients (every 12-15 seconds) ❌ BLOCKED
  /// - action=keep_alive (fallback) ❌ BLOCKED
  ///
  /// DO NOT USE - This method is disabled and should not be called.
  // ignore: unused_element
  void _startKeepalive({
    required String host,
    required int port,
    required String username,
    required String password,
    bool enableLogging = false,
  }) {
    _keepaliveTimer?.cancel();

    if (enableLogging) {
      PlaybackLogger.log(
        '💓 Starting keepalive timer (${_keepaliveInterval.inSeconds}s)',
        tag: 'xtream-session',
      );
    }

    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (timer) async {
      try {
        if (enableLogging) {
          PlaybackLogger.log(
            '💓 Sending keepalive ping',
            tag: 'xtream-session',
          );
        }

        // Try live_clients first (TiviMate pattern)
        try {
          await _callPlayerApi(
            host: host,
            port: port,
            username: username,
            password: password,
            action: 'live_clients',
            enableLogging: false,
          );
        } catch (e) {
          // Fallback to basic keep_alive
          await _callPlayerApi(
            host: host,
            port: port,
            username: username,
            password: password,
            action: 'keep_alive',
            enableLogging: false,
          );
        }
      } catch (e) {
        if (enableLogging) {
          PlaybackLogger.error(
            '⚠️ Keepalive failed',
            error: e,
            tag: 'xtream-session',
          );
        }
      }
    });
  }

  /// Stop keepalive timer
  void stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    PlaybackLogger.log('💓 Keepalive stopped', tag: 'xtream-session');
  }

  /// Clear session data
  void clearSession() {
    stopKeepalive();
    _sessionData = null;
    _lastHandshake = null;
    PlaybackLogger.log('🗑️ Session cleared', tag: 'xtream-session');
  }

  /// Dispose resources
  void dispose() {
    stopKeepalive();
    clearSession();
  }

  /// Get current session data (if available)
  Map<String, dynamic>? get sessionData => _sessionData;

  /// Get last handshake time
  DateTime? get lastHandshake => _lastHandshake;
}
