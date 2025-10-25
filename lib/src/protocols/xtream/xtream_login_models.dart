import 'dart:convert';

/// Represents the full response returned by `player_api.php` when supplied
/// with valid credentials (no `action` parameter). The payload mirrors the
/// structure described in the `@iptv/xtream-api` documentation.
class XtreamLoginPayload {
  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;

  /// Stores any additional fields the portal emitted (some vendors add
  /// `settings` or `categories`). Keeping a copy ensures we never discard
  /// useful data during the rewrite.
  final Map<String, dynamic> raw;

  XtreamLoginPayload({
    required this.userInfo,
    required this.serverInfo,
    Map<String, dynamic>? raw,
  }) : raw = Map.unmodifiable(raw ?? const {});

  /// Parses the raw response, accepting either JSON strings or decoded maps.
  factory XtreamLoginPayload.parse(dynamic raw) {
    final dynamic decoded =
        raw is String ? jsonDecode(raw) : raw;

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Xtream login payload is not a JSON object.',
      );
    }

    final userSection = decoded['user_info'];
    final serverSection = decoded['server_info'];

    if (userSection is! Map<String, dynamic>) {
      throw const FormatException('Xtream login payload missing user_info.');
    }
    if (serverSection is! Map<String, dynamic>) {
      throw const FormatException('Xtream login payload missing server_info.');
    }

    final userInfo = XtreamUserInfo.fromJson(userSection);
    final serverInfo = XtreamServerInfo.fromJson(serverSection);

    return XtreamLoginPayload(
      userInfo: userInfo,
      serverInfo: serverInfo,
      raw: Map<String, dynamic>.from(decoded),
    );
  }
}

/// Describes the `user_info` section returned by Xtream.
class XtreamUserInfo {
  final bool authenticated;
  final String status;
  final DateTime? expiresAt;
  final bool? isTrial;
  final int? activeConnections;
  final int? maxConnections;
  final int? allowedOutputFormats;
  final Map<String, dynamic> raw;

  XtreamUserInfo({
    required this.authenticated,
    required this.status,
    this.expiresAt,
    this.isTrial,
    this.activeConnections,
    this.maxConnections,
    this.allowedOutputFormats,
    Map<String, dynamic>? raw,
  }) : raw = Map.unmodifiable(raw ?? const {});

  factory XtreamUserInfo.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'Disabled';
    final auth =
        json['auth'] is String ? json['auth'] == '1' : json['auth'] == 1 || json['auth'] == true;
    return XtreamUserInfo(
      authenticated: auth,
      status: status,
      expiresAt: _parseExpiry(json['exp_date']),
      isTrial: _parseBool(json['is_trial']),
      activeConnections: _parseInt(json['active_cons']),
      maxConnections: _parseInt(json['max_connections']),
      allowedOutputFormats: _parseInt(json['allowed_output_formats']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  static DateTime? _parseExpiry(dynamic value) {
    if (value == null) return null;
    final seconds = _parseInt(value);
    if (seconds == null || seconds == 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }
}

/// Describes the `server_info` section returned by Xtream.
class XtreamServerInfo {
  final String serverUrl;
  final String serverProtocol;
  final int? port;
  final int? httpsPort;
  final DateTime? serverTime;
  final String timezone;
  final Map<String, dynamic> raw;

  XtreamServerInfo({
    required this.serverUrl,
    required this.serverProtocol,
    this.port,
    this.httpsPort,
    this.serverTime,
    required this.timezone,
    Map<String, dynamic>? raw,
  }) : raw = Map.unmodifiable(raw ?? const {});

  factory XtreamServerInfo.fromJson(Map<String, dynamic> json) {
    final timeNow = _parseInt(json['server_time_now']);
    final serverTime =
        timeNow != null ? DateTime.fromMillisecondsSinceEpoch(timeNow * 1000, isUtc: true) : null;
    return XtreamServerInfo(
      serverUrl: json['url']?.toString() ?? '',
      serverProtocol: json['server_protocol']?.toString() ?? 'http',
      port: _parseInt(json['port']),
      httpsPort: _parseInt(json['https_port']),
      serverTime: serverTime,
      timezone: json['timezone']?.toString() ?? 'UTC',
      raw: Map<String, dynamic>.from(json),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    if (value == '1' || value.toLowerCase() == 'true') return true;
    if (value == '0' || value.toLowerCase() == 'false') return false;
  }
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  return null;
}

