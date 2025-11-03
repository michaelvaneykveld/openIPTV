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

enum ContentBucket { live, films, series, radio }

class CategoryEntry {
  CategoryEntry({required this.name, this.count});

  final String name;
  final int? count;
}

typedef CategoryMap = Map<ContentBucket, List<CategoryEntry>>;

class _CategorySeed {
  const _CategorySeed({required this.id, required this.name});

  final String id;
  final String name;
}

final categoriesCoordinatorProvider = Provider<_CategoriesCoordinator>(
  (ref) => _CategoriesCoordinator(ref),
);

final categoriesDataProvider = FutureProvider.autoDispose
    .family<CategoryMap, ResolvedProviderProfile>((ref, profile) async {
      final coordinator = ref.read(categoriesCoordinatorProvider);
      return coordinator.fetch(profile);
    });

@visibleForTesting
Dio Function()? categoriesTestDioFactory;

@visibleForTesting
HttpClientAdapter? categoriesTestHttpClientAdapter;

@visibleForTesting
StalkerHttpClient? categoriesTestStalkerHttpClient;

@visibleForTesting
Future<StalkerSession> Function(StalkerPortalConfiguration config)?
categoriesTestStalkerSessionLoader;

@visibleForTesting
void resetCategoriesTestOverrides() {
  categoriesTestDioFactory = null;
  categoriesTestHttpClientAdapter = null;
  categoriesTestStalkerHttpClient = null;
  categoriesTestStalkerSessionLoader = null;
}

class _CategoriesCoordinator {
  _CategoriesCoordinator(this._ref);

  final Ref _ref;

  Future<CategoryMap> fetch(ResolvedProviderProfile profile) {
    switch (profile.kind) {
      case ProviderKind.xtream:
        return const _XtreamCategoriesFetcher().fetch(profile);
      case ProviderKind.stalker:
        return _StalkerCategoriesFetcher(_ref).fetch(profile);
      case ProviderKind.m3u:
        return const _M3uCategoriesFetcher().fetch(profile);
    }
  }
}

class _XtreamCategoriesFetcher {
  const _XtreamCategoriesFetcher();

  Future<CategoryMap> fetch(ResolvedProviderProfile profile) async {
    final dio =
        categoriesTestDioFactory?.call() ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            followRedirects: true,
            validateStatus: (status) => status != null && status < 600,
            responseType: ResponseType.json,
          ),
        );
    final adapterOverride = categoriesTestHttpClientAdapter;
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

    Future<List<CategoryEntry>> load(String action) async {
      try {
        final response = await dio.getUri(
          _withQuery(playerUri, {
            'username': profile.secrets['username'] ?? '',
            'password': profile.secrets['password'] ?? '',
            'action': action,
          }),
          options: Options(headers: headers),
        );

        final data = response.data;
        if (data is List) {
          return data
              .map((item) {
                if (item is Map) {
                  final name = item['category_name']?.toString();
                  if (name == null || name.trim().isEmpty) {
                    return null;
                  }
                  final countValue =
                      item['category_series_count'] ??
                      item['category_count'] ??
                      item['category_channel_count'];
                  final count = countValue == null
                      ? null
                      : int.tryParse(countValue.toString());
                  return CategoryEntry(name: name.trim(), count: count);
                }
                return null;
              })
              .whereType<CategoryEntry>()
              .toList();
        }
        return const [];
      } on DioException catch (error) {
        if (kDebugMode) {
          debugPrint(
            redactSensitiveText(
              'Xtream categories $action failed: ${error.message}',
            ),
          );
        }
        return const [];
      }
    }

    final results = await Future.wait([
      load('get_live_categories'),
      load('get_vod_categories'),
      load('get_series_categories'),
    ]);

    return {
      ContentBucket.live: results[0],
      ContentBucket.films: results[1],
      ContentBucket.series: results[2],
    }..removeWhere((_, value) => value.isEmpty);
  }
}

class _StalkerCategoriesFetcher {
  _StalkerCategoriesFetcher(this._ref);

  final Ref _ref;

  StalkerHttpClient get _client =>
      categoriesTestStalkerHttpClient ?? _defaultClient;

  static final StalkerHttpClient _defaultClient = StalkerHttpClient();

  Future<CategoryMap> fetch(ResolvedProviderProfile profile) async {
    final config = _buildConfiguration(profile);
    if (config.macAddress.isEmpty) {
      return {};
    }

    try {
      final sessionLoader = categoriesTestStalkerSessionLoader;
      final session = sessionLoader != null
          ? await sessionLoader(config)
          : await _ref
              .read(stalkerSessionProvider(config).future)
              .timeout(const Duration(seconds: 3));
      final headers = session.buildAuthenticatedHeaders();

      Future<List<CategoryEntry>> load(String module) async {
        final seeds = await _fetchCategorySeeds(
          config: config,
          session: session,
          headers: headers,
          module: module,
        );
        if (seeds.isEmpty) {
          final total = await _loadModuleTotal(
            config: config,
            session: session,
            headers: headers,
            module: module,
          );
          if (total != null && total > 0) {
            return [
              CategoryEntry(
                name: _fallbackCategoryLabel(module),
                count: total,
              ),
            ];
          }
          return const [];
        }
        return _attachCategoryCounts(
          config: config,
          session: session,
          headers: headers,
          module: module,
          seeds: seeds,
        );
      }

      final live = await load('itv');
      final vod = await load('vod');
      final series = await load('series');
      final radio = await load('radio');

      final map = <ContentBucket, List<CategoryEntry>>{};
      if (live.isNotEmpty) map[ContentBucket.live] = live;
      if (vod.isNotEmpty) map[ContentBucket.films] = vod;
      if (series.isNotEmpty) map[ContentBucket.series] = series;
      if (radio.isNotEmpty) map[ContentBucket.radio] = radio;
      return map;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker categories fetch failed: $error\n$stackTrace',
          ),
        );
      }
      return {};
    }
  }

  Future<List<_CategorySeed>> _fetchCategorySeeds({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String module,
  }) async {
    try {
      final response = await _client
          .getPortal(
            config,
            queryParameters: {
              'type': module,
              'action': 'get_categories',
              'JsHttpRequest': '1-xml',
              'token': session.token,
              'mac': config.macAddress.toLowerCase(),
            },
            headers: headers,
          )
          .timeout(const Duration(seconds: 3));
      final data = _decodePortalMap(response.body);
      final rawItems = _resolveCategoryIterable(
            data['categories'] ??
                data['data'] ??
                data['js'] ??
                data,
          ) ??
          _resolveCategoryIterable(data);
      Iterable<_CategorySeed> seedsFromIterable(Iterable<dynamic> iterable) {
        return iterable.map<_CategorySeed?>((entry) {
          try {
            return _categorySeedFromDynamic(entry);
          } catch (error, stackTrace) {
            if (kDebugMode) {
              debugPrint(
                redactSensitiveText(
                  'Failed to parse category seed: ${entry.runtimeType} '
                  '$entry -> $error\n$stackTrace',
                ),
              );
            }
            return null;
          }
        }).whereType<_CategorySeed>();
      }

      if (rawItems != null) {
        final seeds = seedsFromIterable(rawItems).toList(growable: false);
        if (seeds.isNotEmpty) {
          return seeds;
        }
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker categories $module failed: $error\n$stackTrace',
          ),
        );
      }
    }
    return const [];
  }

  Future<List<CategoryEntry>> _attachCategoryCounts({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String module,
    required List<_CategorySeed> seeds,
  }) async {
    final results = <CategoryEntry>[];
    final tasks = <Future<CategoryEntry?>>[];

    Future<CategoryEntry?> loadCount(_CategorySeed seed) async {
      try {
      final response = await _client
          .getPortal(
            config,
            queryParameters: {
              'type': module,
              'action': 'get_ordered_list',
              'genre': seed.id,
              'p': '1',
              'JsHttpRequest': '1-xml',
              'token': session.token,
              'mac': config.macAddress.toLowerCase(),
            },
            headers: headers,
          )
          .timeout(const Duration(seconds: 3));
      final total = _extractTotalItems(response.body);
      return CategoryEntry(
        name: seed.name,
        count: total > 0 ? total : null,
      );
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            redactSensitiveText(
              'Stalker $module genre ${seed.id} failed: $error\n$stackTrace',
            ),
          );
        }
        return CategoryEntry(name: seed.name, count: null);
      }
    }

    for (final seed in seeds) {
      tasks.add(loadCount(seed));
      if (tasks.length == 4) {
        final chunk = await Future.wait(tasks);
        results.addAll(chunk.whereType<CategoryEntry>());
        tasks.clear();
      }
    }

    if (tasks.isNotEmpty) {
      final chunk = await Future.wait(tasks);
      results.addAll(chunk.whereType<CategoryEntry>());
    }

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Future<int?> _loadModuleTotal({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String module,
  }) async {
    try {
      final response = await _client
          .getPortal(
            config,
            queryParameters: {
              'type': module,
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
            'Stalker $module total fetch failed: $error\n$stackTrace',
          ),
        );
      }
      return null;
    }
  }

  String _fallbackCategoryLabel(String module) {
    switch (module) {
      case 'itv':
        return 'All Live';
      case 'vod':
        return 'All Films';
      case 'series':
        return 'All Series';
      case 'radio':
        return 'All Radio';
      default:
        return 'All';
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
}

class _M3uCategoriesFetcher {
  const _M3uCategoriesFetcher();

  Future<CategoryMap> fetch(ResolvedProviderProfile profile) async {
    final source =
        profile.secrets['playlistUrl'] ?? profile.lockedBase.toString();
    if (source.isEmpty) {
      return {};
    }

    final uri = Uri.tryParse(source);
    if (uri == null) return {};

    if (uri.scheme.startsWith('http')) {
      return _fetchRemote(uri, profile);
    }
    return _fetchLocal(uri);
  }

  Future<CategoryMap> _fetchRemote(
    Uri uri,
    ResolvedProviderProfile profile,
  ) async {
    final dio =
        categoriesTestDioFactory?.call() ??
        Dio(
          BaseOptions(
            followRedirects: profile.record.followRedirects,
            maxRedirects: 5,
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            responseType: ResponseType.stream,
            validateStatus: (status) => status != null && status < 600,
          ),
        );
    final adapterOverride = categoriesTestHttpClientAdapter;
    if (adapterOverride != null) {
      dio.httpClientAdapter = adapterOverride;
    }
    _applyTlsOverrides(dio, profile.record.allowSelfSignedTls);

    try {
      final response = await dio.getUri(
        uri,
        options: Options(headers: _decodeCustomHeaders(profile)),
      );
      final responseBody = response.data;
      if (responseBody is! ResponseBody) {
        throw const FormatException('Unexpected playlist response payload.');
      }
      final stream = responseBody.stream
          .map<List<int>>((chunk) => chunk)
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      return _consumeLines(stream);
    } on FormatException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'M3U categories parse failed: $error\n$stackTrace',
          ),
        );
      }
      return {};
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(redactSensitiveText('M3U categories fetch failed: $error'));
      }
      return {};
    }
  }

  Future<CategoryMap> _fetchLocal(Uri uri) async {
    final file = File.fromUri(uri);
    if (!await file.exists()) return {};
    final stream = file
        .openRead()
        .map<List<int>>((chunk) => chunk)
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    return _consumeLines(stream);
  }

  Future<CategoryMap> _consumeLines(Stream<String> lines) async {
    final buckets = <ContentBucket, Map<String, int>>{
      ContentBucket.live: <String, int>{},
      ContentBucket.films: <String, int>{},
      ContentBucket.series: <String, int>{},
      ContentBucket.radio: <String, int>{},
    };

    await for (final rawLine in lines) {
      final line = rawLine.trim();
      if (!line.startsWith('#EXTINF')) continue;

      final lowered = line.toLowerCase();
      final name = _extractAttribute(line, 'tvg-name')?.toLowerCase() ?? '';
      final groupTitle =
          _extractAttribute(line, 'group-title')?.trim() ?? 'Ungrouped';

      if (lowered.contains('radio="true"') ||
          name.contains('radio') ||
          _looksLikeRadioGroup(groupTitle.toLowerCase())) {
        _increment(buckets[ContentBucket.radio]!, groupTitle);
        continue;
      }

      if (name.contains('series') ||
          _looksLikeSeriesGroup(groupTitle.toLowerCase())) {
        _increment(buckets[ContentBucket.series]!, groupTitle);
        continue;
      }

      if (name.contains('movie') ||
          _looksLikeVodGroup(groupTitle.toLowerCase()) ||
          lowered.contains('catchup="vod"')) {
        _increment(buckets[ContentBucket.films]!, groupTitle);
        continue;
      }

      _increment(buckets[ContentBucket.live]!, groupTitle);
    }

    return buckets.map((key, value) {
      final entries =
          value.entries
              .map(
                (entry) => CategoryEntry(name: entry.key, count: entry.value),
              )
              .toList(growable: false)
            ..sort((a, b) => a.name.compareTo(b.name));
      return MapEntry(key, entries);
    })..removeWhere((_, value) => value.isEmpty);
  }

  void _increment(Map<String, int> bucket, String groupTitle) {
    bucket[groupTitle] = (bucket[groupTitle] ?? 0) + 1;
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
    // ignore malformed payload
  }
  return const {};
}

Map<String, dynamic> _decodePortalMap(dynamic body) {
  if (body == null) {
    return const {};
  }
  if (body is Map<String, dynamic>) {
    return body;
  }
  if (body is String) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const {};
    }
    final cleaned = trimmed.startsWith('{')
        ? trimmed
        : trimmed
            .replaceAll(RegExp(r'^\ufeff'), '')
            .replaceAll(RegExp(r'^\s*<!--|-->\s*$'), '');
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final js = decoded['js'];
        if (js is Map<String, dynamic>) {
          return js;
        }
        return decoded;
      }
    } on FormatException {
      return const {};
    }
  }
  return const {};
}

String? _extractAttribute(String line, String name) {
  final pattern = RegExp('$name="([^"]+)"');
  final match = pattern.firstMatch(line);
  return match?.group(1);
}

bool _looksLikeVodGroup(String group) {
  return group.contains('vod') ||
      group.contains('movie') ||
      group.contains('film') ||
      group.contains('filme');
}

bool _looksLikeSeriesGroup(String group) {
  return group.contains('series') ||
      group.contains('shows') ||
      group.contains('serial');
}

bool _looksLikeRadioGroup(String group) {
  return group.contains('radio') || group.contains('audio');
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

Iterable<dynamic>? _resolveCategoryIterable(dynamic root) {
  final queue = <dynamic>[];

  void enqueue(dynamic value) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    queue.add(value);
  }

  enqueue(root);

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (current == null) continue;
    if (current is Iterable && current is! String) {
      final iterable = current.toList(growable: false);
      if (iterable.isEmpty) {
        continue;
      }
      return iterable;
    }
    if (current is Map) {
      final normalized = current.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
      enqueue(normalized['categories']);
      enqueue(normalized['data']);
      enqueue(normalized['js']);
      if (normalized.isNotEmpty) {
        enqueue(
          normalized.entries.map(
            (entry) => [entry.key, entry.value],
          ),
        );
      }
      continue;
    }
    if (current is String) {
      final trimmed = current.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      return [trimmed];
    }
    // Fallback: treat as single value
    return [current];
  }

  return null;
}

_CategorySeed? _categorySeedFromDynamic(dynamic entry) {
  if (entry is Map) {
    final normalized = entry.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    final id = _coerceScalar(
      normalized['id'] ??
          normalized['category_id'] ??
          normalized['categoryid'] ??
          normalized['genre_id'] ??
          normalized['0'],
    );
    var name = _coerceScalar(
      normalized['title'] ??
          normalized['name'] ??
          normalized['category_name'] ??
          normalized['1'],
    );
    if (name.isEmpty) {
      name = id;
    }
    if (id.isEmpty || name.isEmpty) {
      return null;
    }
    return _CategorySeed(id: id, name: name);
  }
  if (entry is Iterable) {
    final items = entry.toList(growable: false);
    final nestedSeeds = items
        .map(_categorySeedFromDynamic)
        .whereType<_CategorySeed>()
        .toList(growable: false);
    if (nestedSeeds.length == 1) {
      return nestedSeeds.first;
    }
    if (nestedSeeds.isEmpty) {
      final id = _coerceScalar(
        items.isEmpty ? null : items.first,
      );
      final name = _coerceScalar(
        items.length > 1 ? items[1] : null,
      );
      if (id.isEmpty && name.isEmpty) {
        return null;
      }
      final resolvedId = id.isEmpty ? name : id;
      final resolvedName = name.isEmpty ? resolvedId : name;
      return _CategorySeed(id: resolvedId, name: resolvedName);
    }
    return nestedSeeds.first;
  }
  if (entry is String) {
    final id = entry.trim();
    if (id.isEmpty) return null;
    return _CategorySeed(id: id, name: id);
  }
  return null;
}

String _coerceScalar(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value.trim();
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  if (value is Iterable) {
    for (final element in value) {
      final candidate = _coerceScalar(element);
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }
  if (value is Map) {
    for (final element in value.values) {
      final candidate = _coerceScalar(element);
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }
  return value.toString().trim();
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
