import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_http_client.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_session.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';

void main() {
  setUp(() {
    resetCategoriesTestOverrides();
  });

  tearDown(() {
    resetCategoriesTestOverrides();
  });

  test('Xtream categories fetcher groups live/vod/series entries', () async {
    final seenActions = <String>[];
    categoriesTestDioFactory = () {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        final action = options.uri.queryParameters['action'] ?? '';
        seenActions.add(action);
        final payload = switch (action) {
          'get_live_categories' => [
            {'category_name': 'News', 'category_channel_count': '10'},
            {'category_name': 'Sports', 'category_channel_count': '5'},
          ],
          'get_vod_categories' => [
            {'category_name': 'Movies', 'category_count': '20'},
          ],
          'get_series_categories' => [
            {'category_name': 'Shows', 'category_series_count': '8'},
          ],
          _ => [],
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      return dio;
    };

    final profile = ResolvedProviderProfile(
      record: _record(
        kind: ProviderKind.xtream,
        lockedBase: Uri.parse('http://demo.example/'),
      ),
      secrets: const {'username': 'demo', 'password': 'secret'},
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(categoriesDataProvider(profile).future);

    expect(
      seenActions,
      containsAll([
        'get_live_categories',
        'get_vod_categories',
        'get_series_categories',
      ]),
    );
    expect(result[ContentBucket.live]!.length, 2);
    expect(result[ContentBucket.films]!.single.count, 20);
    expect(result[ContentBucket.series]!.single.name, 'Shows');
    expect(result.containsKey(ContentBucket.radio), isFalse);
  });

  test('Stalker categories fetcher returns live/vod/radio buckets', () async {
    categoriesTestStalkerSessionLoader = (config) async => StalkerSession(
      configuration: config,
      token: 'token',
      establishedAt: DateTime.utc(2024),
    );
    categoriesTestStalkerHttpClient = _FakeStalkerHttpClient();

    final profile = ResolvedProviderProfile(
      record: _record(
        kind: ProviderKind.stalker,
        lockedBase: Uri.parse('http://portal.example/stalker_portal/'),
        configuration: const {'macAddress': '00:11:22:33:44:55'},
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(categoriesDataProvider(profile).future);

    expect(
      result[ContentBucket.live]!.map((e) => e.name),
      containsAll(['General', 'Kids']),
    );
    expect(result[ContentBucket.films]!.first.count, 15);
    expect(result[ContentBucket.radio]!.length, 1);
    expect(result.containsKey(ContentBucket.series), isFalse);
  });

  test('M3U categories derived from group-title heuristics', () async {
    final dir = await Directory.systemTemp.createTemp('categories-m3u');
    addTearDown(() => dir.delete(recursive: true));

    final file = File('${dir.path}/playlist.m3u');
    await file.writeAsString('''
#EXTM3U
#EXTINF:-1 tvg-name="Movie" group-title="Movies",Movie
http://example.com/movie.m3u8
#EXTINF:-1 tvg-name="Serie" group-title="Series",Serie
http://example.com/serie.m3u8
#EXTINF:-1 radio="true" group-title="Radio",Radio
http://example.com/radio.mp3
#EXTINF:-1 tvg-name="Live Show" group-title="Live",Live
http://example.com/live.m3u8
''');

    final profile = ResolvedProviderProfile(
      record: _record(kind: ProviderKind.m3u, lockedBase: file.uri),
      secrets: {'playlistUrl': file.uri.toString()},
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(categoriesDataProvider(profile).future);

    expect(result[ContentBucket.films]!.single.count, 1);
    expect(result[ContentBucket.series]!.single.name, 'Series');
    expect(result[ContentBucket.radio]!.single.count, 1);
    expect(result[ContentBucket.live]!.single.name, 'Live');
  });
}

ProviderProfileRecord _record({
  required ProviderKind kind,
  required Uri lockedBase,
  Map<String, String> configuration = const {},
}) {
  final now = DateTime.utc(2024);
  return ProviderProfileRecord(
    id: 'test-${kind.name}',
    kind: kind,
    displayName: 'Test ${kind.name}',
    lockedBase: lockedBase,
    needsUserAgent: false,
    allowSelfSignedTls: false,
    followRedirects: true,
    configuration: configuration,
    hints: const {},
    createdAt: now,
    updatedAt: now,
    hasSecrets: true,
  );
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<dynamic>? cancelFuture,
  ) {
    return _handler(options);
  }
}

class _FakeStalkerHttpClient extends StalkerHttpClient {
  @override
  Future<PortalResponseEnvelope> getPortal(
    StalkerPortalConfiguration configuration, {
    required Map<String, dynamic> queryParameters,
    required Map<String, String> headers,
  }) async {
    final type = queryParameters['type']?.toString();
    final action = queryParameters['action']?.toString();

    if (action == 'get_categories') {
      final categories = switch (type) {
        'itv' => [
          {'title': 'General', 'items_count': '30'},
          {'title': 'Kids', 'items_count': '12'},
        ],
        'vod' => [
          {'title': 'Films', 'total_items': '15'},
        ],
        'radio' => [
          {'title': 'Radio', 'items_count': '8'},
        ],
        _ => [],
      };
      return PortalResponseEnvelope(
        body: <String, dynamic>{'categories': categories},
        statusCode: 200,
        headers: const {},
        cookies: const [],
      );
    }

    return PortalResponseEnvelope(
      body: const {},
      statusCode: 200,
      headers: const {},
      cookies: const [],
    );
  }
}
