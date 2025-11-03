import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml.dart' as xml;

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

class _CategoryAccumulator {
  _CategoryAccumulator({required this.name});

  final String name;
  int count = 0;
}

typedef CategoryMap = Map<ContentBucket, List<CategoryEntry>>;

class _CategorySeed {
  const _CategorySeed({
    required this.id,
    required this.name,
    this.initialCount,
  });

  final String id;
  final String name;
  final int? initialCount;

  _CategorySeed copyWith({int? initialCount}) {
    return _CategorySeed(
      id: id,
      name: name,
      initialCount: initialCount ?? this.initialCount,
    );
  }
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

        final moduleTotal = await _loadModuleTotal(
          config: config,
          session: session,
          headers: headers,
          module: module,
        );

        List<CategoryEntry> categories;
        if (seeds.isEmpty) {
          categories = await _deriveCategoriesFromListing(
            config: config,
            session: session,
            headers: headers,
            module: module,
          );
        } else {
          categories = await _attachCategoryCounts(
            config: config,
            session: session,
            headers: headers,
            module: module,
            seeds: seeds,
          );
        }

        if (categories.isEmpty) {
          if (moduleTotal != null && moduleTotal > 0) {
            return [
              CategoryEntry(
                name: _fallbackCategoryLabel(module),
                count: moduleTotal,
              ),
            ];
          }
          return const [];
        }

        if (kDebugMode) {
          debugPrint(
            redactSensitiveText(
              'Stalker $module categories derived: '
              '${categories.map((c) => '${c.name}:${c.count ?? 'n/a'}').join(', ')}',
            ),
          );
        }

        final aggregateCount = moduleTotal ??
            categories.fold<int>(
              0,
              (previousValue, element) =>
                  previousValue + (element.count ?? 0),
            );

        return [
          if (aggregateCount > 0)
            CategoryEntry(
              name: _fallbackCategoryLabel(module),
              count: aggregateCount,
            ),
          ...categories,
        ];
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
    final seedsWithJs = await _requestCategorySeeds(
      config: config,
      session: session,
      headers: headers,
      module: module,
      includeJsEnvelope: true,
    );
    if (seedsWithJs.isNotEmpty) {
      return seedsWithJs;
    }

    final seedsWithoutJs = await _requestCategorySeeds(
      config: config,
      session: session,
      headers: headers,
      module: module,
      includeJsEnvelope: false,
    );
    if (seedsWithoutJs.isNotEmpty) {
      return seedsWithoutJs;
    }

    final seedsFromGenres = await _requestGenreSeeds(
      config: config,
      session: session,
      headers: headers,
      module: module,
    );
    if (seedsFromGenres.isNotEmpty) {
      return seedsFromGenres;
    }

    return const [];
  }

  Future<List<_CategorySeed>> _requestCategorySeeds({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String module,
    required bool includeJsEnvelope,
  }) async {
    try {
      final query = <String, dynamic>{
        'type': module,
        'action': 'get_categories',
        'token': session.token,
        'mac': config.macAddress.toLowerCase(),
      };
      if (includeJsEnvelope) {
        query['JsHttpRequest'] = '1-xml';
      }
      final response = await _client
          .getPortal(
            config,
            queryParameters: query,
            headers: headers,
          )
          .timeout(const Duration(seconds: 3));
      final seeds = _parseStalkerCategorySeeds(response.body);
      if (seeds.isNotEmpty) {
        return seeds;
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

  Future<List<_CategorySeed>> _requestGenreSeeds({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String module,
  }) async {
    try {
      for (final includeJs in [true, false]) {
        final query = <String, dynamic>{
          'type': module,
          'action': 'get_genres',
          'token': session.token,
          'mac': config.macAddress.toLowerCase(),
        };
        if (includeJs) {
          query['JsHttpRequest'] = '1-xml';
        }
        final response = await _client
            .getPortal(
              config,
              queryParameters: query,
              headers: headers,
            )
            .timeout(const Duration(seconds: 3));
        if (kDebugMode) {
          final rawBody = response.body;
          final preview = rawBody is String
              ? rawBody
              : jsonEncode(rawBody ?? const {});
          final truncated =
              preview.length > 400 ? '${preview.substring(0, 400)}…' : preview;
          debugPrint(
            redactSensitiveText(
              'Stalker $module get_genres '
              '(${includeJs ? 'with' : 'without'} JsHttpRequest) raw: '
              '$truncated',
            ),
          );
        }
        final seeds = _parseStalkerCategorySeeds(response.body);
        if (seeds.isNotEmpty) {
          return seeds;
        }
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker get_genres $module failed: $error\n$stackTrace',
          ),
        );
      }
    }
    return const [];
  }

  List<_CategorySeed> _parseStalkerCategorySeeds(
    dynamic body, [
    Set<String>? visitedStrings,
  ]) {
    final visited = visitedStrings ?? <String>{};
    final seedMap = <String, _CategorySeed>{};

    void addSeed(_CategorySeed seed) {
      final id = seed.id.trim();
      final name = seed.name.trim();
      if (id.isEmpty && name.isEmpty) {
        return;
      }
      final normalizedId = id.isEmpty ? name : id;
      final normalizedName = name.isEmpty ? normalizedId : name;
      final key =
          '${normalizedId.toLowerCase()}::${normalizedName.toLowerCase()}';
      final existing = seedMap[key];
      if (existing == null) {
        seedMap[key] = _CategorySeed(
          id: normalizedId,
          name: normalizedName,
          initialCount: seed.initialCount,
        );
      } else if (existing.initialCount == null && seed.initialCount != null) {
        seedMap[key] = existing.copyWith(initialCount: seed.initialCount);
      }
    }

    void traverse(dynamic node) {
      if (node == null) {
        return;
      }

      if (node is Map) {
        final unwrapped = _unwrapJsEnvelope(node);
        if (!identical(unwrapped, node)) {
          traverse(unwrapped);
          return;
        }
        final candidate = _categorySeedFromDynamic(node);
        if (candidate != null) {
          addSeed(candidate);
        }
        for (final value in node.values) {
          traverse(value);
        }
        return;
      }

      if (node is Iterable && node is! String) {
        for (final item in node) {
          final candidate = _categorySeedFromDynamic(item);
          if (candidate != null) {
            addSeed(candidate);
          } else {
            traverse(item);
          }
        }
        return;
      }

      if (node is String) {
        final trimmed = node.trim();
        if (trimmed.isEmpty || !visited.add(trimmed)) {
          return;
        }
        final jsonCandidate = _tryDecodeJson(trimmed);
        if (jsonCandidate != null) {
          traverse(jsonCandidate);
          return;
        }
        final xmlSeeds = _parseSeedsFromXmlString(trimmed, visited);
        for (final seed in xmlSeeds) {
          addSeed(seed);
        }
        return;
      }
    }

    traverse(body);
    return seedMap.values.toList(growable: false);
  }

  dynamic _unwrapJsEnvelope(dynamic node) {
    if (node is Map) {
      if (node.containsKey('js') && node.containsKey('data')) {
        final data = node['data'];
        if (data is String) {
          final trimmed = data.trim();
          if (trimmed.isEmpty) {
            return const <dynamic>[];
          }
          final jsonCandidate = _tryDecodeJson(trimmed);
          if (jsonCandidate != null) {
            return _unwrapJsEnvelope(jsonCandidate);
          }
          final seeds = _parseSeedsFromXmlString(trimmed, <String>{});
          if (seeds.isNotEmpty) {
            return seeds;
          }
          return trimmed;
        }
        return _unwrapJsEnvelope(data);
      }
    }
    return node;
  }

  dynamic _tryDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  List<_CategorySeed> _parseSeedsFromXmlString(
    String source,
    Set<String> visitedStrings,
  ) {
    final results = <_CategorySeed>[];
    xml.XmlDocument document;
    try {
      document = xml.XmlDocument.parse(source);
    } catch (_) {
      return results;
    }

    for (final dataNode in document.findAllElements('data')) {
      final inner = dataNode.innerText.trim();
      if (inner.isEmpty || !visitedStrings.add(inner)) {
        continue;
      }
      final jsonCandidate = _tryDecodeJson(inner);
      if (jsonCandidate != null) {
        results
            .addAll(_parseStalkerCategorySeeds(jsonCandidate, visitedStrings));
        continue;
      }
      try {
        final nestedDoc = xml.XmlDocument.parse(inner);
        results.addAll(_extractSeedsFromXmlDocument(nestedDoc));
      } catch (_) {
        // ignore nested parse errors
      }
    }

    results.addAll(_extractSeedsFromXmlDocument(document));
    return results;
  }

  List<_CategorySeed> _extractSeedsFromXmlDocument(xml.XmlDocument document) {
    final seeds = <_CategorySeed>[];

    void collect(Iterable<xml.XmlElement> nodes) {
      for (final node in nodes) {
        final seed = _categorySeedFromXmlElement(node);
        if (seed != null) {
          seeds.add(seed);
        }
      }
    }

    collect(document.findAllElements('category'));
    if (seeds.isEmpty) {
      collect(document.findAllElements('item'));
    }
    if (seeds.isEmpty) {
      collect(document.findAllElements('group'));
    }

    return seeds;
  }

  _CategorySeed? _categorySeedFromXmlElement(xml.XmlElement element) {
    String id = _coerceScalar(
      element.getAttribute('id') ??
          element.getAttribute('category_id') ??
          element.getAttribute('cat_id') ??
          element.getAttribute('cid') ??
          element.getElement('id')?.innerText ??
          element.getElement('category_id')?.innerText ??
          element.getElement('cat_id')?.innerText ??
          element.getElement('cid')?.innerText ??
          element.getElement('genre_id')?.innerText,
    );

  String name = _coerceScalar(
    element.getAttribute('title') ??
        element.getAttribute('name') ??
        element.getAttribute('category_title') ??
        element.getAttribute('category_name') ??
        element.getAttribute('group_title') ??
        element.getElement('title')?.innerText ??
        element.getElement('name')?.innerText ??
        element.getElement('category_title')?.innerText ??
        element.getElement('category_name')?.innerText ??
        element.getElement('group_title')?.innerText,
  );

  final count = _parseCountValue(
    element.getAttribute('items_count') ??
        element.getAttribute('total_items') ??
        element.getElement('items_count')?.innerText ??
        element.getElement('total_items')?.innerText,
  );

  if (name.isEmpty) {
    name = id;
  }
  if (id.isEmpty) {
    id = name;
    }
    id = id.trim();
    name = name.trim();
  if (id.isEmpty && name.isEmpty) {
    return null;
  }
  return _CategorySeed(
    id: id,
    name: name,
    initialCount: count,
  );
}


  Future<List<CategoryEntry>> _attachCategoryCounts({
    required StalkerPortalConfiguration config,
    required StalkerSession session,
    required Map<String, String> headers,
    required String module,
    required List<_CategorySeed> seeds,
  }) async {
    final results = <CategoryEntry>[];
    final seedsNeedingFetch = <_CategorySeed>[];

    for (final seed in seeds) {
      if (seed.initialCount != null) {
        results.add(
          CategoryEntry(name: seed.name, count: seed.initialCount),
        );
      } else {
        seedsNeedingFetch.add(seed);
      }
    }

    if (seedsNeedingFetch.isNotEmpty) {
      final tasks = <Future<CategoryEntry?>>[];

      Future<CategoryEntry?> loadCount(_CategorySeed seed) async {
        try {
          final response = await _client
              .getPortal(
                config,
                queryParameters: {
                  'type': module,
                  'action': 'get_ordered_list',
                  if (seed.id.isNotEmpty) 'genre': seed.id,
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

      for (final seed in seedsNeedingFetch) {
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
    }

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Future<List<CategoryEntry>> _deriveCategoriesFromListing({
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
      final envelope = _decodePortalMap(response.body);
      final data = envelope['data'];
      if (data is! List) {
        return const [];
      }

      final buckets = <String, _CategoryAccumulator>{};

      for (final rawItem in data) {
        if (rawItem is! Map) continue;
        final normalized = rawItem.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        );
        final id = _coerceScalar(
          normalized['genre_id'] ??
              normalized['tv_genre_id'] ??
              normalized['category_id'] ??
              normalized['id'],
        );
        final name = _coerceScalar(
          normalized['tv_genre_title'] ??
              normalized['genre'] ??
              normalized['category_title'] ??
              normalized['title'],
        );
        if (id.isEmpty || name.isEmpty) {
          continue;
        }
        final bucket = buckets.putIfAbsent(
          id,
          () => _CategoryAccumulator(name: name),
        );
        bucket.count += 1;
      }

      if (buckets.isEmpty) {
        return const [];
      }

      final entries = buckets.entries
          .map(
            (entry) => CategoryEntry(
              name: entry.value.name,
              count: entry.value.count > 0 ? entry.value.count : null,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));
      return entries;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          redactSensitiveText(
            'Stalker $module listing derive failed: $error\n$stackTrace',
          ),
        );
      }
      return const [];
    }
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

_CategorySeed? _categorySeedFromDynamic(dynamic entry) {
  if (entry is Map) {
    final normalized = entry.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    var id = _coerceScalar(
      normalized['id'] ??
          normalized['category_id'] ??
          normalized['categoryid'] ??
          normalized['cat_id'] ??
          normalized['cid'] ??
          normalized['tv_genre_id'] ??
          normalized['genre_id'] ??
          normalized['0'],
    );
    var name = _coerceScalar(
      normalized['title'] ??
          normalized['name'] ??
          normalized['category_title'] ??
          normalized['category_name'] ??
          normalized['group_title'] ??
          normalized['tv_genre_title'] ??
          normalized['title_ru'] ??
          normalized['1'],
    );
    final count = _parseCountValue(
      normalized['items_count'] ??
          normalized['total_items'] ??
          normalized['count'] ??
          normalized['channel_count'] ??
          normalized['series_count'] ??
          normalized['movies_count'] ??
          normalized['records_count'],
    );
    if (name.isEmpty) {
      name = id;
    }
    if (id.isEmpty) {
      id = name;
    }
    if (id.isEmpty && name.isEmpty) {
      return null;
    }
    return _CategorySeed(id: id, name: name, initialCount: count);
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
      final count = items.length > 2 ? _parseCountValue(items[2]) : null;
      if (id.isEmpty && name.isEmpty) {
        return null;
      }
      final resolvedId = id.isEmpty ? name : id;
      final resolvedName = name.isEmpty ? resolvedId : name;
      return _CategorySeed(
        id: resolvedId,
        name: resolvedName,
        initialCount: count,
      );
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

int? _parseCountValue(dynamic value) {
  final text = _coerceScalar(value);
  if (text.isEmpty) {
    return null;
  }
  return int.tryParse(text);
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
