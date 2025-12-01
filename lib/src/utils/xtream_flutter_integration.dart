import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// -----------------------
// SmartUrlBuilder
// -----------------------
class SmartUrlBuilder {
  /// Build an Xtream URL while handling credential encoding edge-cases.
  ///
  /// Rules applied:
  /// - The path structure remains: `/<type>/<username>/<password>/<id>.<ext>`
  /// - Username: RAW (no encoding) - servers expect MAC addresses as-is (d0:d0:...)
  /// - Password: RAW (no encoding) - keep as-is to match reference apps
  /// - Extension: trusted from API; do NOT change
  static String build({
    required String host,
    required int port,
    required String type, // 'movie' | 'series' | 'live'
    required String username,
    required String password,
    required String id,
    required String ext,
    bool forceHttps = false,
  }) {
    final scheme = forceHttps ? 'https' : 'http';

    // Username: Use RAW - servers expect MAC addresses with colons (d0:d0:...)
    // The proxy will handle these correctly even though they confuse URI parsers
    final safeUser = username;

    // Password: Use RAW - match reference app behavior
    final safePass = password;

    // ID should normally be numeric/string safe
    final safeId = id;

    // Use string interpolation to avoid Uri() constructor normalization
    // NOTE: We omit the port if it is 80 or 443 to avoid issues with some servers
    // that reject the Host header with a port or the URL with a port.
    final portPart = (port == 80 || port == 443) ? '' : ':$port';
    final url =
        '$scheme://$host$portPart/$type/$safeUser/$safePass/$safeId.$ext';

    return url;
  }
}

// -----------------------
// Device ID helper
// -----------------------
class DeviceId {
  static const _key = 'xtream_device_id';

  static Future<String> getId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    return id;
  }
}

// -----------------------
// DebugLogger
// -----------------------
class DebugLogger {
  final bool verbose;
  DebugLogger({this.verbose = false});

  void log(String tag, String message) {
    final time = DateTime.now().toIso8601String();
    if (verbose) stdout.writeln('[$time] [$tag] $message');
  }

  void logRequestOptions(RequestOptions opts) {
    log('HTTP-REQ', '${opts.method} ${opts.uri}');
    opts.headers.forEach((k, v) => log('HTTP-REQ', 'H: $k: $v'));
  }

  void logResponse(Response response) {
    log('HTTP-RES', '${response.statusCode} ${response.realUri}');
    response.headers.forEach(
      (k, v) => log('HTTP-RES', 'H: $k: ${v.join(',')}'),
    );
  }
}

// -----------------------
// ProxyDetector
// -----------------------
class ProxyDetector {
  final Dio _dio;
  final DebugLogger logger;

  ProxyDetector({Dio? dio, DebugLogger? logger})
    : _dio = dio ?? Dio(),
      logger = logger ?? DebugLogger(verbose: false);

  /// Tries to HEAD the VOD URL using the provided headers.
  /// If we get 200/206, direct connection is OK. Otherwise, suggests using proxy.
  Future<bool> directWorks(
    String url,
    Map<String, String> headers, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      logger.log('PROBE', 'HEAD $url');
      final resp = await _dio.head(
        url,
        options: Options(
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
          responseType: ResponseType.plain,
        ),
      );

      logger.log('PROBE', 'Status: ${resp.statusCode}');
      if (resp.statusCode == 200 || resp.statusCode == 206) return true;
      return false;
    } catch (e) {
      logger.log('PROBE-ERR', e.toString());
      return false;
    }
  }

  /// Quick live detector: try to fetch first segment (range request) and verify we receive 206/200.
  Future<bool> liveDirectWorks(String url, Map<String, String> headers) async {
    try {
      final resp = await _dio.get(
        url,
        options: Options(
          headers: {...headers, 'Range': 'bytes=0-65535'},
          responseType: ResponseType.stream,
          followRedirects: true,
        ),
      );
      logger.log('PROBE', 'LIVE Status: ${resp.statusCode}');
      return resp.statusCode == 200 || resp.statusCode == 206;
    } catch (e) {
      logger.log('PROBE-ERR', e.toString());
      return false;
    }
  }
}

// -----------------------
// MediaKitManager
// -----------------------
class MediaKitManager {
  final DebugLogger logger;

  MediaKitManager({DebugLogger? logger})
    : logger = logger ?? DebugLogger(verbose: false);

  /// Creates a Player for VOD with the correct headers set in the player configuration.
  /// This ensures the HTTP client used by MediaKit forwards the UA and X-Device-ID.
  Future<Player> createVodPlayer({
    required String url,
    required String userAgent,
    required String deviceId,
    bool autoplay = true,
  }) async {
    // NOTE: media_kit's PlayerConfiguration exposes httpHeaders on some platforms
    // The exact API may vary by package version. Adjust if your media_kit version differs.

    final player = Player(
      configuration: PlayerConfiguration(
        title: 'Xtream VOD',
        // httpHeaders: {
        //   'User-Agent': userAgent,
        //   'X-Device-ID': deviceId,
        //   'Connection': 'keep-alive',
        // },
      ),
    );
    // Note: PlayerConfiguration in some versions doesn't have httpHeaders directly.
    // If so, we might need to use (Media(url, httpHeaders: ...))

    logger.log('PLAYER', 'Opening VOD $url with UA $userAgent');
    await player.open(
      Media(
        url,
        httpHeaders: {
          'User-Agent': userAgent,
          'X-Device-ID': deviceId,
          'Connection': 'keep-alive',
        },
      ),
      play: autoplay,
    );
    return player;
  }

  /// Creates a Player for Live. If proxyNeeded==true you should route via proxy.
  Future<Player> createLivePlayer({
    required String url,
    required String userAgent,
    required String deviceId,
    bool autoplay = true,
  }) async {
    final player = Player(
      configuration: PlayerConfiguration(title: 'Xtream LIVE'),
    );

    logger.log('PLAYER', 'Opening LIVE $url with UA $userAgent');
    await player.open(
      Media(
        url,
        httpHeaders: {
          'User-Agent': userAgent,
          'X-Device-ID': deviceId,
          'Connection': 'keep-alive',
        },
      ),
      play: autoplay,
    );
    return player;
  }
}

// -----------------------
// CompatibilityChecker
// -----------------------
class CompatibilityReport {
  final bool apiOk;
  final bool vodDirectOk;
  final bool liveDirectOk;
  final String vodContentType;
  final int vodStatusCode;
  final String notes;

  CompatibilityReport({
    required this.apiOk,
    required this.vodDirectOk,
    required this.liveDirectOk,
    required this.vodContentType,
    required this.vodStatusCode,
    required this.notes,
  });

  @override
  String toString() {
    return 'CompatibilityReport(apiOk: $apiOk, vodDirectOk: $vodDirectOk, liveDirectOk: $liveDirectOk, contentType: $vodContentType, status: $vodStatusCode, notes: $notes)';
  }
}

class CompatibilityChecker {
  final Dio _dio;
  final DebugLogger logger;

  CompatibilityChecker({Dio? dio, DebugLogger? logger})
    : _dio = dio ?? Dio(),
      logger = logger ?? DebugLogger(verbose: false);

  /// Run a small test battery:
  /// 1) call player_api.php (login)
  /// 2) HEAD the VOD URL (direct)
  /// 3) GET a small LIVE range
  Future<CompatibilityReport> run({
    required String apiUrl,
    required String vodUrl,
    required String liveUrl,
    required Map<String, String> headers,
  }) async {
    bool apiOk = false;
    bool vodOk = false;
    bool liveOk = false;
    String contentType = '';
    int status = 0;
    final sb = StringBuffer();

    // 1) API login
    try {
      logger.log('CHK', 'Calling API $apiUrl');
      final apiResp = await _dio.get(
        apiUrl,
        options: Options(headers: headers),
      );
      if (apiResp.statusCode == 200) {
        apiOk = true;
      }
      sb.writeln('API: ${apiResp.statusCode}');
    } catch (e) {
      sb.writeln('API-ERR: $e');
    }

    // 2) VOD HEAD
    try {
      logger.log('CHK', 'HEAD $vodUrl');
      final vodResp = await _dio.head(
        vodUrl,
        options: Options(headers: headers, followRedirects: true),
      );
      status = vodResp.statusCode ?? 0;
      contentType = vodResp.headers.value('content-type') ?? '';
      vodOk = status == 200 || status == 206;
      sb.writeln('VOD: $status $contentType');
    } catch (e) {
      sb.writeln('VOD-ERR: $e');
    }

    // 3) LIVE small range
    try {
      logger.log('CHK', 'LIVE GET range');
      final liveResp = await _dio.get(
        liveUrl,
        options: Options(
          headers: {...headers, 'Range': 'bytes=0-65535'},
          responseType: ResponseType.stream,
        ),
      );
      liveOk = liveResp.statusCode == 200 || liveResp.statusCode == 206;
      sb.writeln('LIVE: ${liveResp.statusCode}');
    } catch (e) {
      sb.writeln('LIVE-ERR: $e');
    }

    return CompatibilityReport(
      apiOk: apiOk,
      vodDirectOk: vodOk,
      liveDirectOk: liveOk,
      vodContentType: contentType,
      vodStatusCode: status,
      notes: sb.toString(),
    );
  }
}
