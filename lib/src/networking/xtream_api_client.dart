import 'dart:convert';
import 'package:openiptv/src/utils/playback_logger.dart';
import 'xtream_raw_client.dart';
// REMOVED: import 'xtream_session_manager.dart'; (RAW keepalive disabled)

/// High-level Xtream API client using raw sockets
class XtreamApiClient {
  final XtreamRawClient _rawClient;
  // REMOVED: _sessionManager (RAW keepalive disabled)

  XtreamApiClient({XtreamRawClient? rawClient})
    : _rawClient = rawClient ?? XtreamRawClient();

  /// Authenticate and load player API data
  ///
  /// DISABLED: TiviMate handshake (RAW TCP blocked by Cloudflare)
  /// Uses simple HTTP API call only - no session management, no keepalive
  /// Returns parsed JSON response from player_api.php
  Future<Map<String, dynamic>> loadPlayerApi({
    required String host,
    required int port,
    required String username,
    required String password,
    bool performFullHandshake = false, // DISABLED by default
  }) async {
    PlaybackLogger.log('Loading player API: $host:$port', tag: 'xtream-api');

    try {
      if (performFullHandshake) {
        // DEPRECATED: TiviMate handshake (RAW TCP blocked by Cloudflare)
        PlaybackLogger.log(
          '⚠️  WARNING: RAW handshake requested but deprecated',
          tag: 'xtream-api',
        );
        PlaybackLogger.log(
          '⚠️  Cloudflare blocks RAW TCP keepalive - using simple HTTP instead',
          tag: 'xtream-api',
        );
      }

      // ALWAYS use simple HTTP API call (Cloudflare-compatible)
      // No handshake sequence, no keepalive, no session management
      final path = '/player_api.php?username=$username&password=$password';
      final response = await _rawClient.get(host, port, path, {});
      final json = jsonDecode(response) as Map<String, dynamic>;
      PlaybackLogger.log(
        'Player API loaded successfully (simple HTTP)',
        tag: 'xtream-api',
      );
      return json;
    } catch (e) {
      PlaybackLogger.error('Player API failed', error: e, tag: 'xtream-api');
      rethrow;
    }
  }

  /// Get live streams list
  Future<List<dynamic>> getLiveStreams({
    required String host,
    required int port,
    required String username,
    required String password,
    String? category,
  }) async {
    final categoryParam = category != null ? '&category_id=$category' : '';
    final path =
        '/player_api.php?username=$username&password=$password&action=get_live_streams$categoryParam';

    PlaybackLogger.log('Loading live streams', tag: 'xtream-api');

    final response = await _rawClient.get(host, port, path, {});
    return jsonDecode(response) as List<dynamic>;
  }

  /// Get VOD streams list
  Future<List<dynamic>> getVodStreams({
    required String host,
    required int port,
    required String username,
    required String password,
    String? category,
  }) async {
    final categoryParam = category != null ? '&category_id=$category' : '';
    final path =
        '/player_api.php?username=$username&password=$password&action=get_vod_streams$categoryParam';

    PlaybackLogger.log('Loading VOD streams', tag: 'xtream-api');

    final response = await _rawClient.get(host, port, path, {});
    return jsonDecode(response) as List<dynamic>;
  }

  /// Get series list
  Future<List<dynamic>> getSeries({
    required String host,
    required int port,
    required String username,
    required String password,
    String? category,
  }) async {
    final categoryParam = category != null ? '&category_id=$category' : '';
    final path =
        '/player_api.php?username=$username&password=$password&action=get_series$categoryParam';

    PlaybackLogger.log('Loading series', tag: 'xtream-api');

    final response = await _rawClient.get(host, port, path, {});
    return jsonDecode(response) as List<dynamic>;
  }

  /// Build Xtream streaming URL
  ///
  /// Returns path component only (not full URL) for use with raw socket
  String buildXtreamPath({
    required String type, // 'live', 'movie', 'series'
    required String username,
    required String password,
    required String streamId,
    String extension = 'ts',
  }) {
    return '/$type/$username/$password/$streamId.$extension';
  }
}
