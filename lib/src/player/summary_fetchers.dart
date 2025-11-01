import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Loads [SummaryData] for the supplied profile.
final summaryDataProvider = FutureProvider.autoDispose
    .family<SummaryData, ResolvedProviderProfile>((ref, profile) async {
      final coordinator = ref.read(summaryCoordinatorProvider);
      return coordinator.fetch(profile);
    });

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

    void recordField(String label, dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      fields[label] = text;
    }

    recordField('Status', userMap['status']);
    recordField('Expires', userMap['exp_date']);
    recordField('Trial', userMap['is_trial']);
    recordField('Active connections', userMap['active_cons']);
    recordField('Created', userMap['created_at']);
    recordField('Max connections', userMap['max_connections']);

    final formats = userMap['allowed_output_formats'];
    if (formats is List && formats.isNotEmpty) {
      recordField('Output formats', formats.join(', '));
    }

    recordField('Server', serverMap['url']);
    recordField('Protocol', serverMap['server_protocol']);
    recordField('Port', serverMap['port']);
    recordField('Current time', serverMap['time_now']);
    recordField('Timezone', serverMap['timezone']);

    Future<int> countAction(String action) async {
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

    final counts = <String, int>{
      'Live': await countAction('get_live_streams'),
      'VOD': await countAction('get_vod_streams'),
      'Series': await countAction('get_series'),
    };

    if (!fields.containsKey('Radio')) {
      fields['Radio'] = 'Not available via player_api';
    }

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
                .timeout(const Duration(seconds: 10));
      final headers = session.buildAuthenticatedHeaders();

      final profileResponse = await _client.getPortal(
        config,
        queryParameters: const {
          'type': 'stb',
          'action': 'get_profile',
          'JsHttpRequest': '1-xml',
        },
        headers: headers,
      );

      final profileMap = _decodePortalMap(profileResponse.body);
      final fields = <String, String>{};
      _collectIfPresent(profileMap, fields, 'status');
      _collectIfPresent(profileMap, fields, 'parent_password');
      _collectIfPresent(profileMap, fields, 'tariff_plan');
      _collectIfPresent(profileMap, fields, 'subscription_date');

      try {
        final accountResponse = await _client.getPortal(
          config,
          queryParameters: const {
            'type': 'account_info',
            'action': 'get_main_info',
            'JsHttpRequest': '1-xml',
          },
          headers: headers,
        );
        final accountMap = _decodePortalMap(accountResponse.body);
        for (final entry in accountMap.entries) {
          final value = entry.value;
          if (value == null) continue;
          final text = value.toString().trim();
          if (text.isEmpty) continue;
          final label = _humanise(entry.key);
          fields.putIfAbsent(label, () => text);
        }
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
        headers: headers,
        category: 'itv',
      );
      if (liveCount != null) {
        counts['Live'] = liveCount;
      }

      final vodCount = await _loadTotalSafe(
        config: config,
        headers: headers,
        category: 'vod',
      );
      if (vodCount != null) {
        counts['VOD'] = vodCount;
      }

      final seriesCount = await _loadTotalSafe(
        config: config,
        headers: headers,
        category: 'series',
      );
      if (seriesCount != null) {
        counts['Series'] = seriesCount;
      } else {
        fields.putIfAbsent('Series catalogue', () => 'Not available');
      }

      final radioCount = await _loadTotalSafe(
        config: config,
        headers: headers,
        category: 'radio',
      );
      if (radioCount != null) {
        counts['Radio'] = radioCount;
      }

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
    required Map<String, String> headers,
    required String category,
  }) async {
    try {
      final response = await _client.getPortal(
        config,
        queryParameters: {
          'type': category,
          'action': 'get_ordered_list',
          'p': '1',
          'JsHttpRequest': '1-xml',
        },
        headers: headers,
      );
      final total = _extractTotalItems(response.body);
      return total >= 0 ? total : null;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker $category total fetch failed: $error\n$stackTrace',
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
    if (value == null) return;
    final text = value.toString().trim();
    if (text.isEmpty) return;
    target[_humanise(key)] = text;
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
    _applyTlsOverrides(dio, profile.record.allowSelfSignedTls);

    final response = await dio.getUri(
      playlistUri,
      options: Options(headers: _decodeCustomHeaders(profile)),
    );

    final stream = response.data.stream
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
          name.contains('vod')) {
        vod++;
      } else {
        live++;
      }
    }

    return {'Live': live, 'VOD': vod, 'Series': series, 'Radio': radio};
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
        group.contains('vod') ||
        group.contains('film') ||
        group.contains('filme');
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
