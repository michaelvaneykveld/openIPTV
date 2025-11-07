import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/db/dao/summary_dao.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/data/db/openiptv_db.dart' show CategoryKind;
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_http_client.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_session.dart';
import 'package:openiptv/src/providers/protocol_auth_providers.dart';
import 'package:openiptv/src/utils/url_normalization.dart';
import 'package:openiptv/src/utils/url_redaction.dart';

/// Resolves the appropriate summary fetcher based on the provider kind.
final summaryCoordinatorProvider = Provider<_SummaryCoordinator>((ref) {
  return _SummaryCoordinator(ref);
});

/// Loads [SummaryData] for the supplied profile via legacy network routes.
final legacySummaryProvider = FutureProvider.autoDispose
    .family<SummaryData, ResolvedProviderProfile>((ref, profile) async {
      final coordinator = ref.read(summaryCoordinatorProvider);
      return coordinator.fetch(profile);
    });

final dbSummaryProvider = StreamProvider.autoDispose
    .family<SummaryData, DbSummaryArgs>((ref, args) {
      final dao = SummaryDao(ref.watch(openIptvDbProvider));
      return dao.watchForProvider(args.providerId).map(
            (counts) => SummaryData(
              kind: args.kind,
              counts: counts.map(
                (key, value) =>
                    MapEntry(_labelForCategoryKind(key), value),
              ),
            ),
          );
    });

class DbSummaryArgs {
  const DbSummaryArgs(this.providerId, this.kind);

  final int providerId;
  final ProviderKind kind;

  @override
  bool operator ==(Object other) {
    return other is DbSummaryArgs &&
        other.providerId == providerId &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(providerId, kind);
}

@visibleForTesting
Dio Function()? summaryTestDioFactory;

@visibleForTesting
HttpClientAdapter? summaryTestHttpClientAdapter;

@visibleForTesting
StalkerHttpClient? summaryTestStalkerHttpClient;

@visibleForTesting
Future<StalkerSession> Function(StalkerPortalConfiguration config)?
summaryTestStalkerSessionLoader;

@visibleForTesting
void resetSummaryTestOverrides() {
  summaryTestDioFactory = null;
  summaryTestHttpClientAdapter = null;
  summaryTestStalkerHttpClient = null;
  summaryTestStalkerSessionLoader = null;
}

const String _mediaUserAgent = 'VLC/3.0.18 LibVLC/3.0.18';
const String _m3uAcceptHeader =
    'application/x-mpegurl, audio/mpegurl;q=0.9, application/vnd.apple.mpegurl;q=0.9, */*;q=0.1';

class _SummaryCoordinator {
  _SummaryCoordinator(this._ref);

  final Ref _ref;

  Future<SummaryData> fetch(ResolvedProviderProfile profile) {
    switch (profile.kind) {
      case ProviderKind.xtream:
        return const _XtreamSummaryFetcher().fetch(profile);
      case ProviderKind.stalker:
        return _StalkerSummaryFetcher(_ref).fetch(profile);
      case ProviderKind.m3u:
        return const _M3uSummaryFetcher().fetch(profile);
    }
  }
}

String _labelForCategoryKind(CategoryKind kind) {
  switch (kind) {
    case CategoryKind.live:
      return 'Live';
    case CategoryKind.vod:
      return 'Films';
    case CategoryKind.series:
      return 'Series';
    case CategoryKind.radio:
      return 'Radio';
  }
}

class _XtreamSummaryFetcher {
  const _XtreamSummaryFetcher();

  Future<SummaryData> fetch(ResolvedProviderProfile profile) async {
    final credentials = _extractCredentials(profile);
    if (credentials.username.isEmpty || credentials.password.isEmpty) {
      return SummaryData(
        kind: ProviderKind.xtream,
        fields: const {'Error': 'Xtream credentials are missing.'},
      );
    }

    final dio =
        summaryTestDioFactory?.call() ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            followRedirects: true,
            validateStatus: (status) => status != null && status < 600,
            responseType: ResponseType.json,
          ),
        );
    final adapterOverride = summaryTestHttpClientAdapter;
    if (adapterOverride != null) {
      dio.httpClientAdapter = adapterOverride;
    }
    _applyTlsOverrides(dio, profile.record.allowSelfSignedTls);

    final headers = _decodeCustomHeaders(profile);
    final baseUri = ensureTrailingSlash(
      stripKnownFiles(
        profile.lockedBase,
        knownFiles: const {'player_api.php', 'get.php', 'xmltv.php'},
      ),
    );
    final playerUri = baseUri.resolve('player_api.php');

    final userInfo = await _withRetry(() async {
      final response = await dio.getUri(
        _withQuery(playerUri, {
          'username': credentials.username,
          'password': credentials.password,
        }),
        options: Options(headers: headers),
      );
      return _decodeJson(response.data);
    });

    final fields = <String, String>{};
    final userMap = userInfo['user_info'] as Map<String, dynamic>? ?? const {};
    final serverMap =
        userInfo['server_info'] as Map<String, dynamic>? ?? const {};

    void assign(String label, String? value) {
      if (value == null) return;
      final text = value.trim();
      if (text.isEmpty) return;
      fields[label] = text;
    }

    assign('Status', _stringValue(userMap['status']));
    assign('Expires', _formatDateValue(userMap['exp_date']));
    assign('Trial', _stringValue(userMap['is_trial']));
    assign('Active connections', _stringValue(userMap['active_cons']));
    assign('Created', _formatDateValue(userMap['created_at']));
    assign('Max connections', _stringValue(userMap['max_connections']));

    final formats = userMap['allowed_output_formats'];
    if (formats is List && formats.isNotEmpty) {
      assign('Output formats', formats.join(', '));
    }

    assign('Server', _stringValue(serverMap['url']));
    assign('Protocol', _stringValue(serverMap['server_protocol']));
    assign('Port', _stringValue(serverMap['port']));
    assign('Current time', _formatDateTimeValue(serverMap['time_now']));
    assign('Timezone', _stringValue(serverMap['timezone']));

    final counts = <String, int>{
      'Live': await _countXtreamCategory(
        dio,
        playerUri,
        headers,
        credentials,
        'get_live_streams',
      ),
      'VOD': await _countXtreamCategory(
        dio,
        playerUri,
        headers,
        credentials,
        'get_vod_streams',
      ),
      'Series': await _countXtreamCategory(
        dio,
        playerUri,
        headers,
        credentials,
        'get_series',
      ),
    }..removeWhere((_, value) => value <= 0);

    return SummaryData(
      kind: ProviderKind.xtream,
      fields: fields,
      counts: counts,
    );
  }

  ({String username, String password}) _extractCredentials(
    ResolvedProviderProfile profile,
  ) {
    final username = profile.secrets['username'] ?? '';
    final password = profile.secrets['password'] ?? '';
    return (username: username, password: password);
  }
}

class _StalkerSummaryFetcher {
  _StalkerSummaryFetcher(this._ref);

  final Ref _ref;

  StalkerHttpClient get _client =>
      summaryTestStalkerHttpClient ?? _defaultClient;

  static final StalkerHttpClient _defaultClient = StalkerHttpClient();

  Future<SummaryData> fetch(ResolvedProviderProfile profile) async {
    final config = _buildConfiguration(profile);
    if (config.macAddress.isEmpty) {
      return SummaryData(
        kind: ProviderKind.stalker,
        fields: const {'Error': 'MAC address is missing.'},
      );
    }

    try {
      final sessionLoader = summaryTestStalkerSessionLoader;
      final StalkerSession session = sessionLoader != null
          ? await sessionLoader(config)
          : await _ref
                .read(stalkerSessionProvider(config).future)
                .timeout(const Duration(seconds: 3));
      final headers = session.buildAuthenticatedHeaders();

      final profileResponse = await _client
          .getPortal(
            config,
            queryParameters: {
              'type': 'stb',
              'action': 'get_profile',
              'JsHttpRequest': '1-xml',
              'token': session.token,
              'mac': config.macAddress.toLowerCase(),
            },
            headers: headers,
          )
          .timeout(const Duration(seconds: 3));

      final profileMap = _decodePortalMap(profileResponse.body);
      final fields = <String, String>{};
      _collectIfPresent(profileMap, fields, 'status');
      _collectIfPresent(profileMap, fields, 'parent_password');
      _collectIfPresent(profileMap, fields, 'tariff_plan');
      _collectIfPresent(profileMap, fields, 'subscription_date');
      _collectAdditionalFields(profileMap, fields);

      try {
        final accountResponse = await _client
            .getPortal(
              config,
              queryParameters: {
                'type': 'account_info',
                'action': 'get_main_info',
                'JsHttpRequest': '1-xml',
                'token': session.token,
                'mac': config.macAddress.toLowerCase(),
              },
              headers: headers,
            )
            .timeout(const Duration(seconds: 3));
        final accountMap = _decodePortalMap(accountResponse.body);
        for (final entry in accountMap.entries) {
          final formatted = _formatSummaryValue(entry.key, entry.value);
          if (formatted == null) continue;
          final label = _humanise(entry.key);
          fields.putIfAbsent(label, () => formatted);
        }
        _collectAdditionalFields(accountMap, fields);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            redactSensitiveText(
              'Stalker account info fetch failed: $error\n$stackTrace',
            ),
          );
        }
      }

      final counts = <String, int>{};

      final liveCount = await _loadTotalSafe(
        config: config,
        session: session,
        headers: headers,
        portalType: 'itv',
      );
      if (liveCount != null) {
        counts['Live'] = liveCount;
      }

      final vodCount = await _loadTotalSafe(
        config: config,
        session: session,
        headers: headers,
        portalType: 'vod',
      );
      if (vodCount != null) {
        counts['VOD'] = vodCount;
      }

      final seriesCount = await _loadTotalSafe(
        config: config,
        session: session,
        headers: headers,
        portalType: 'series',
      );
      if (seriesCount != null) {
        counts['Series'] = seriesCount;
      }

      final radioCount = await _loadTotalSafe(
        config: config,
        session: session,
        headers: headers,
        portalType: 'radio',
      );
      if (radioCount != null) {
        counts['Radio'] = radioCount;
      }
      counts.removeWhere((_, value) => value <= 0);

      return SummaryData(
        kind: ProviderKind.stalker,
        fields: fields,
        counts: counts,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText('Stalker summary failed: $error\n$stackTrace'),
        );
      }
      return SummaryData(
        kind: ProviderKind.stalker,
        fields: {'Error': redactSensitiveText(error.toString())},
      );
    }
  }

  Future<int?> _loadTotalSafe({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String portalType,
  }) async {
    try {
      final response = await _client
          .getPortal(
            config,
            queryParameters: {
              'type': portalType,
              'action': 'get_ordered_list',
              'p': '1',
              'JsHttpRequest': '1-xml',
              'token': session.token,
              'mac': config.macAddress.toLowerCase(),
            },
            headers: headers,
          )
          .timeout(const Duration(seconds: 3));
      final total = _extractTotalItems(response.body);
      return total >= 0 ? total : null;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker $portalType total fetch failed: $error\n$stackTrace',
          ),
        );
      }
      return null;
    }
  }

  StalkerPortalConfiguration _buildConfiguration(
    ResolvedProviderProfile profile,
  ) {
    final config = profile.record.configuration;
    final headers = _decodeCustomHeaders(profile);
    final userAgent = config['userAgent'];
    final mac = config['macAddress'] ?? '';

    return StalkerPortalConfiguration(
      baseUri: profile.lockedBase,
      macAddress: mac,
      userAgent: userAgent?.isNotEmpty == true ? userAgent : null,
      allowSelfSignedTls: profile.record.allowSelfSignedTls,
      extraHeaders: headers,
    );
  }

  void _collectIfPresent(
    Map<String, dynamic> source,
    Map<String, String> target,
    String key,
  ) {
    final value = source[key];
    final formatted = _formatSummaryValue(key, value);
    if (formatted == null) return;
    target[_humanise(key)] = formatted;
  }

  void _collectAdditionalFields(
    Map<String, dynamic> source,
    Map<String, String> target,
  ) {
    const ignoredKeys = {
      'status',
      'parent_password',
      'tariff_plan',
      'subscription_date',
    };
    const sensitiveKeys = {'password', 'pass', 'token', 'pin'};

    for (final entry in source.entries) {
      final key = entry.key;
      final lowerKey = key.toLowerCase();
      if (ignoredKeys.contains(lowerKey)) continue;
      if (sensitiveKeys.any((s) => lowerKey.contains(s))) continue;
      final value = entry.value;
      if (value is Map || value is Iterable) continue;
      final formatted = _formatSummaryValue(key, value);
      if (formatted == null) continue;
      final label = _humanise(key);
      target.putIfAbsent(label, () => formatted);
    }
  }

  String _humanise(String key) {
    return key
        .split('_')
        .map(
          (segment) => segment.isEmpty
              ? segment
              : '${segment[0].toUpperCase()}${segment.substring(1)}',
        )
        .join(' ');
  }
}

class _M3uSummaryFetcher {
  const _M3uSummaryFetcher();

  Future<SummaryData> fetch(ResolvedProviderProfile profile) async {
    final playlistInput =
        profile.secrets['playlistUrl'] ?? profile.lockedBase.toString();
    if (playlistInput.isEmpty) {
      return SummaryData(
        kind: ProviderKind.m3u,
        fields: const {'Error': 'Playlist input is missing.'},
      );
    }

    final uri = Uri.tryParse(playlistInput);
    if (uri != null &&
        uri.scheme.startsWith('http') &&
        _looksLikeXtreamPlaylist(uri)) {
      final username = uri.queryParameters['username'] ?? '';
      final password = uri.queryParameters['password'] ?? '';
      if (username.isNotEmpty && password.isNotEmpty) {
        final rewrittenProfile = ResolvedProviderProfile(
          record: profile.record,
          secrets: {
            ...profile.secrets,
            'username': username,
            'password': password,
          },
        );
        return const _XtreamSummaryFetcher().fetch(rewrittenProfile);
      }
    }

    if (uri == null) {
      return SummaryData(
        kind: ProviderKind.m3u,
        fields: const {'Error': 'Playlist URI is invalid.'},
      );
    }

    if (uri.scheme.startsWith('http')) {
      return _fetchRemotePlaylist(profile, uri);
    }
    return _fetchLocalPlaylist(uri);
  }

  Future<SummaryData> _fetchRemotePlaylist(
    ResolvedProviderProfile profile,
    Uri playlistUri,
  ) async {
    final dio = Dio(
      BaseOptions(
        followRedirects: profile.record.followRedirects,
        maxRedirects: 5,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        responseType: ResponseType.stream,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    final adapterOverride = summaryTestHttpClientAdapter;
    if (adapterOverride != null) {
      dio.httpClientAdapter = adapterOverride;
    }
    _applyTlsOverrides(dio, profile.record.allowSelfSignedTls);

    final baseHeaders = _decodeCustomHeaders(profile);
    final probe = await _attemptPlaylistHead(
      dio: dio,
      uri: playlistUri,
      headers: baseHeaders,
    );

    final effectiveHeaders = Map<String, String>.from(baseHeaders);
    if (probe.needsMediaUserAgent && !_hasUserAgent(effectiveHeaders)) {
      effectiveHeaders['User-Agent'] = _mediaUserAgent;
      await _attemptPlaylistHead(
        dio: dio,
        uri: playlistUri,
        headers: effectiveHeaders,
      );
    }

    final response = await _performPlaylistGet(
      dio: dio,
      uri: playlistUri,
      headers: effectiveHeaders,
    );

    final responseBody = response.data;
    if (responseBody is! ResponseBody) {
      throw const FormatException('Unexpected playlist response payload.');
    }

    final stream = responseBody.stream
        .map<List<int>>((chunk) => chunk)
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final counts = await _countPlaylist(stream);

    return SummaryData(
      kind: ProviderKind.m3u,
      fields: {
        'Source': playlistUri.host.isNotEmpty
            ? playlistUri.host
            : playlistUri.toString(),
      },
      counts: counts,
    );
  }

  Future<SummaryData> _fetchLocalPlaylist(Uri playlistUri) async {
    final file = File.fromUri(playlistUri);
    if (!await file.exists()) {
      return SummaryData(
        kind: ProviderKind.m3u,
        fields: const {'Error': 'Playlist file not found.'},
      );
    }

    final stream = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final counts = await _countPlaylist(stream);

    return SummaryData(
      kind: ProviderKind.m3u,
      fields: {'Source': playlistUri.toFilePath()},
      counts: counts,
    );
  }

  Future<Map<String, int>> _countPlaylist(Stream<String> lines) async {
    var live = 0;
    var vod = 0;
    var series = 0;
    var radio = 0;

    await for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('#EXTINF')) continue;

      final lowered = trimmed.toLowerCase();
      final name = _extractAttribute(trimmed, 'tvg-name')?.toLowerCase() ?? '';
      final groupTitle =
          _extractAttribute(trimmed, 'group-title')?.toLowerCase() ?? '';
      if (lowered.contains('radio="true"') ||
          _looksLikeRadioGroup(groupTitle) ||
          name.contains('radio')) {
        radio++;
        continue;
      }
      if (_looksLikeSeriesGroup(groupTitle) || name.contains('series')) {
        series++;
      } else if (_looksLikeVodGroup(groupTitle) ||
          lowered.contains('catchup="vod"') ||
          name.contains('movie') ||
          name.contains('film') ||
          name.contains('vod')) {
        vod++;
      } else {
        live++;
      }
    }

    final counts = <String, int>{
      'Live': live,
      'VOD': vod,
      'Series': series,
      'Radio': radio,
    };
    counts.removeWhere((_, value) => value <= 0);
    return counts;
  }

  String? _extractAttribute(String line, String name) {
    final pattern = RegExp('$name="([^"]+)"');
    final match = pattern.firstMatch(line);
    return match?.group(1);
  }

  bool _looksLikeXtreamPlaylist(Uri uri) {
    final path = uri.path.toLowerCase();
    if (!path.contains('get.php')) {
      return false;
    }
    final params = uri.queryParameters;
    return params.containsKey('username') && params.containsKey('password');
  }

  bool _looksLikeVodGroup(String group) {
    if (group.isEmpty) return false;
    return group.contains('movie') ||
        group.contains('film') ||
        group.contains('vod') ||
        group.contains('catchup');
  }

  bool _looksLikeSeriesGroup(String group) {
    if (group.isEmpty) return false;
    return group.contains('series') ||
        group.contains('show') ||
        group.contains('serial');
  }

  bool _looksLikeRadioGroup(String group) {
    if (group.isEmpty) return false;
    return group.contains('radio') || group.contains('audio');
  }
}

class _HeadProbeResult {
  const _HeadProbeResult({
    required this.accepted,
    this.statusCode,
    this.needsMediaUserAgent = false,
  });

  final bool accepted;
  final int? statusCode;
  final bool needsMediaUserAgent;
}

Future<_HeadProbeResult> _attemptPlaylistHead({
  required Dio dio,
  required Uri uri,
  required Map<String, String> headers,
}) async {
  final requestHeaders = _augmentPlaylistHeaders(headers, includeRange: false);
  try {
    final response = await dio.headUri(
      uri,
      options: Options(
        headers: requestHeaders,
        responseType: ResponseType.plain,
      ),
    );
    final status = response.statusCode;
    final contentType =
        response.headers.value('content-type')?.toLowerCase() ?? '';
    final accepted = status != null &&
        status >= 200 &&
        status < 400 &&
        (contentType.isEmpty ||
            contentType.contains('mpegurl') ||
            contentType.contains('audio/mpegurl') ||
            contentType.contains('application/octet-stream'));

    final needsMediaUa = status != null &&
        (status == 403 || status == 406) &&
        !_hasUserAgent(headers);

    return _HeadProbeResult(
      accepted: accepted,
      statusCode: status,
      needsMediaUserAgent: needsMediaUa,
    );
  } on DioException catch (error) {
    final status = error.response?.statusCode;
    final needsMediaUa = status != null &&
        (status == 403 || status == 406) &&
        !_hasUserAgent(headers);
    return _HeadProbeResult(
      accepted: false,
      statusCode: status,
      needsMediaUserAgent: needsMediaUa,
    );
  }
}

Future<Response<ResponseBody>> _performPlaylistGet({
  required Dio dio,
  required Uri uri,
  required Map<String, String> headers,
}) async {
  final requestHeaders = _augmentPlaylistHeaders(headers);
  try {
    return await dio.getUri(
      uri,
      options: Options(headers: requestHeaders),
    );
  } on DioException catch (error) {
    final status = error.response?.statusCode;
    if (status != null &&
        (status == 403 || status == 406) &&
        !_hasUserAgent(headers)) {
      final fallbackHeaders = Map<String, String>.from(headers)
        ..['User-Agent'] = _mediaUserAgent;
      return await dio.getUri(
        uri,
        options: Options(headers: _augmentPlaylistHeaders(fallbackHeaders)),
      );
    }
    rethrow;
  }
}

Map<String, String> _augmentPlaylistHeaders(
  Map<String, String> headers, {
  bool includeRange = true,
}) {
  final normalized = <String, String>{};
  headers.forEach((key, value) {
    normalized[key] = value;
  });

  if (!_hasHeader(normalized, 'accept')) {
    normalized['Accept'] = _m3uAcceptHeader;
  }
  if (includeRange && !_hasHeader(normalized, 'range')) {
    normalized['Range'] = 'bytes=0-16383';
  }
  if (!_hasHeader(normalized, 'connection')) {
    normalized['Connection'] = 'close';
  }
  return normalized;
}

bool _hasUserAgent(Map<String, String> headers) =>
    _hasHeader(headers, 'user-agent');

bool _hasHeader(Map<String, String> headers, String target) {
  final lowerTarget = target.toLowerCase();
  return headers.keys.any((key) => key.toLowerCase() == lowerTarget);
}

Future<int> _countXtreamCategory(
  Dio dio,
  Uri playerUri,
  Map<String, String> headers,
  ({String username, String password}) credentials,
  String action,
) async {
  final data = await _withRetry(() async {
    final response = await dio.getUri(
      _withQuery(playerUri, {
        'username': credentials.username,
        'password': credentials.password,
        'action': action,
      }),
      options: Options(headers: headers),
    );
    return response.data;
  });

  if (data is List) {
    return data.length;
  }
  if (data is Map && data['data'] is List) {
    return (data['data'] as List).length;
  }
  return 0;
}

String? _stringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _formatDateValue(dynamic value) {
  final dt = _parseDateTime(value);
  if (dt == null) return _stringValue(value);
  return '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}';
}

String? _formatDateTimeValue(dynamic value) {
  final dt = _parseDateTime(value);
  if (dt == null) return _stringValue(value);
  final date =
      '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}';
  return '$date ${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is int) {
    if (value > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    if (value > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
          .toLocal();
    }
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final numeric = int.tryParse(text);
  if (numeric != null) {
    if (numeric > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(numeric, isUtc: true)
          .toLocal();
    }
    if (numeric > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000, isUtc: true)
          .toLocal();
    }
  }
  try {
    return DateTime.parse(text).toLocal();
  } catch (_) {
    final normalized = text.replaceAll('/', '-').replaceAll('.', '-');
    try {
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String? _formatSummaryValue(String key, dynamic value) {
  final lower = key.toLowerCase();
  if (lower.contains('time')) {
    return _formatDateTimeValue(value);
  }
  if (lower.contains('date') ||
      lower.contains('expire') ||
      lower.contains('expiry')) {
    return _formatDateValue(value);
  }
  return _stringValue(value);
}

Future<T> _withRetry<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on DioException catch (error) {
    final status = error.response?.statusCode;
    if (status == 503 || status == 512) {
      return await operation();
    }
    rethrow;
  }
}

void _applyTlsOverrides(Dio dio, bool allowSelfSigned) {
  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter && allowSelfSigned) {
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }
}

Map<String, String> _decodeCustomHeaders(ResolvedProviderProfile profile) {
  final encoded = profile.secrets['customHeaders'];
  if (encoded == null || encoded.isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is Map) {
      return Map<String, String>.fromEntries(
        decoded.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value.toString()),
        ),
      );
    }
  } catch (_) {
    // Ignore malformed payloads.
  }
  return const {};
}

Map<String, dynamic> _decodeJson(dynamic body) {
  if (body is Map<String, dynamic>) {
    return body;
  }
  if (body is String) {
    return jsonDecode(body) as Map<String, dynamic>;
  }
  throw const FormatException('Unexpected Xtream response payload.');
}

Map<String, dynamic> _decodePortalMap(dynamic body) {
  if (body is String) {
    final cleaned = body.trim();
    final jsonText = cleaned.startsWith('{')
        ? cleaned
        : cleaned.replaceAll(RegExp(r'^\s*<!--|-->\s*$'), '');
    final decoded = jsonDecode(jsonText);
    if (decoded is Map<String, dynamic>) {
      final js = decoded['js'];
      if (js is Map<String, dynamic>) {
        return js;
      }
      return decoded;
    }
  } else if (body is Map<String, dynamic>) {
    return body;
  }
  return const {};
}

Uri _withQuery(Uri base, Map<String, dynamic> params) {
  final merged = Map<String, String>.from(base.queryParameters);
  params.forEach((key, value) {
    if (value != null) {
      merged[key] = value.toString();
    }
  });
  return base.replace(queryParameters: merged);
}

int _extractTotalItems(dynamic body) {
  final map = _decodePortalMap(body);
  final total = map['total_items'];
  if (total is int) return total;
  if (total is String) {
    return int.tryParse(total) ?? 0;
  }
  return 0;
}
