import 'dart:convert';
import 'xtream_raw_client.dart';
import 'xtream_session_manager.dart';

/// High-level Xtream API client using raw sockets
class XtreamApiClient {
  final XtreamRawClient _rawClient;
  final XtreamSessionManager _sessionManager;

  XtreamApiClient({XtreamRawClient? rawClient})
    : _rawClient = rawClient ?? XtreamRawClient(),
      _sessionManager = XtreamSessionManager(rawClient: rawClient);

  /// Authenticate and load player API data
  ///
  /// Now performs full TiviMate handshake sequence!
  /// Returns parsed JSON response from player_api.php
  Future<Map<String, dynamic>> loadPlayerApi({
    required String host,
    required int port,
    required String username,
    required String password,
    bool performFullHandshake = true,
  }) async {
    print('[xtream-api] Loading player API: $host:$port');

    try {
      if (performFullHandshake) {
        // Use TiviMate handshake sequence
        print('[xtream-api] 🔐 Performing TiviMate handshake sequence...');
        return await _sessionManager.performHandshake(
          host: host,
          port: port,
          username: username,
          password: password,
          enableLogging: true,
        );
      } else {
        // Simple API call (old behavior)
        final path = '/player_api.php?username=$username&password=$password';
        final response = await _rawClient.get(host, port, path, {});
        final json = jsonDecode(response) as Map<String, dynamic>;
        print('[xtream-api] Player API loaded successfully');
        return json;
      }
    } catch (e) {
      print('[xtream-api] Player API failed: $e');
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

    print('[xtream-api] Loading live streams');

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

    print('[xtream-api] Loading VOD streams');

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

    print('[xtream-api] Loading series');

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

  /// Open streaming connection for Live TV or VOD
  ///
  /// Returns raw socket for feeding to media player
  Future<StreamingConnection> openStreamingConnection({
    required String host,
    required int port,
    required String type,
    required String username,
    required String password,
    required String streamId,
    String extension = 'ts',
  }) async {
    final path = buildXtreamPath(
      type: type,
      username: username,
      password: password,
      streamId: streamId,
      extension: extension,
    );

    print('[xtream-api] Opening streaming connection: $host:$port$path');

    final socket = await _rawClient.openStream(
      host,
      port,
      path,
      {}, // Use default TiviMate headers
    );

    return StreamingConnection(
      socket: socket,
      host: host,
      port: port,
      path: path,
    );
  }
}

/// Represents an open streaming connection
class StreamingConnection {
  final dynamic socket; // Socket from dart:io
  final String host;
  final int port;
  final String path;

  StreamingConnection({
    required this.socket,
    required this.host,
    required this.port,
    required this.path,
  });

  /// Get full URL for display purposes
  String get url => 'http://$host:$port$path';

  /// Close the streaming connection
  Future<void> close() async {
    await socket.close();
  }
}
