import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_http_client.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_session.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';

void main() {
  setUp(() {
    resetSummaryTestOverrides();
  });

  tearDown(() {
    resetSummaryTestOverrides();
  });

  test(
    'Xtream summary retries once when initial player_api call fails',
    () async {
      var attempts = 0;

      summaryTestDioFactory = () {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            followRedirects: true,
            validateStatus: (status) => status != null && status < 600,
            responseType: ResponseType.json,
          ),
        );
        dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
          final params = options.uri.queryParameters;
          final action = params['action'];
          if (action == null) {
            attempts++;
            if (attempts == 1) {
              throw DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 503,
                  statusMessage: 'Service Unavailable',
                ),
                type: DioExceptionType.badResponse,
                error: '503',
              );
            }
            return ResponseBody.fromString(
              jsonEncode({
                'user_info': {
                  'status': 'Active',
                  'exp_date': '2030-01-01',
                  'max_connections': '1',
                },
                'server_info': {
                  'url': 'demo.example',
                  'port': '80',
                  'server_protocol': 'http',
                  'time_now': '2024-11-04 12:00:00',
                  'timezone': 'UTC',
                },
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }

          return ResponseBody.fromString(
            jsonEncode(<dynamic>[]),
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

      final summary = await container.read(summaryDataProvider(profile).future);

      expect(attempts, 2);
      expect(summary.fields['Status'], 'Active');
      expect(summary.fields['Port'], '80');
    },
  );

  test('Xtream summary surfaces account metadata and counts', () async {
    final requestLog = <Uri>[];

    summaryTestDioFactory = () {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          followRedirects: true,
          validateStatus: (status) => status != null && status < 600,
          responseType: ResponseType.json,
        ),
      );
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        requestLog.add(options.uri);
        final params = options.uri.queryParameters;
        final action = params['action'];
        if (action == null) {
          return ResponseBody.fromString(
            jsonEncode({
              'user_info': {
                'status': 'Active',
                'exp_date': '2030-01-01',
                'is_trial': '0',
                'active_cons': '1',
                'created_at': '2022-01-01',
                'max_connections': '2',
                'allowed_output_formats': ['ts', 'm3u8'],
              },
              'server_info': {
                'url': 'demo.example',
                'port': '8080',
                'server_protocol': 'http',
                'time_now': '2024-11-04 12:00:00',
                'timezone': 'UTC',
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        List<dynamic> payload;
        switch (action) {
          case 'get_live_streams':
            payload = [
              {'stream_id': 1},
              {'stream_id': 2},
              {'stream_id': 3},
            ];
            break;
          case 'get_vod_streams':
            payload = [
              {'stream_id': 10},
              {'stream_id': 11},
            ];
            break;
          case 'get_series':
            payload = [
              {'series_id': 100},
            ];
            break;
          default:
            payload = const [];
        }

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
        allowSelfSignedTls: false,
      ),
      secrets: const {'username': 'demo', 'password': 'secret'},
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final summary = await container.read(summaryDataProvider(profile).future);

    expect(requestLog.length, 4);
    expect(summary.counts['Live'], 3);
    expect(summary.counts['VOD'], 2);
    expect(summary.counts['Series'], 1);
    expect(summary.fields['Status'], 'Active');
    expect(summary.fields['Expires'], '2030-01-01');
    expect(summary.fields['Port'], '8080');
    expect(summary.fields.containsKey('Radio'), isFalse);
  });

  test(
    'Stalker summary merges profile/account info and module totals',
    () async {
      summaryTestStalkerSessionLoader = (config) async => StalkerSession(
        configuration: config,
        token: 'token',
        establishedAt: DateTime.utc(2024),
      );
      summaryTestStalkerHttpClient = _FakeStalkerHttpClient();

      final profile = ResolvedProviderProfile(
        record: _record(
          kind: ProviderKind.stalker,
          lockedBase: Uri.parse('http://portal.example/stalker_portal/'),
          configuration: const {'macAddress': 'AA:BB:CC:DD:EE:FF'},
        ),
        secrets: const {'customHeaders': '{}'},
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final summary = await container.read(summaryDataProvider(profile).future);

      expect(summary.counts['Live'], 120);
      expect(summary.counts['VOD'], 42);
      expect(summary.counts['Series'], 12);
      expect(summary.counts['Radio'], 18);

      expect(summary.fields['Status'], 'Active');
      expect(summary.fields['Tariff Plan'], 'Ultimate');
      expect(summary.fields['Balance'], '15.75');
      expect(summary.fields['Subscription Date'], '2024-01-15');
    },
  );

  test('M3U summary classifies playlist entries by heuristics', () async {
    final tempDir = await Directory.systemTemp.createTemp('m3u-test');
    addTearDown(() => tempDir.delete(recursive: true));

    final playlistFile = File('${tempDir.path}/sample.m3u');
    await playlistFile.writeAsString('''
#EXTM3U
#EXTINF:-1 tvg-name="Movie A" group-title="Movies",Movie A
http://example.com/movie1.ts
#EXTINF:-1 tvg-name="Series Pilot" group-title="Series",Series Pilot
http://example.com/series1.m3u8
#EXTINF:-1 radio="true" group-title="Radio",Radio One
http://example.com/radio1.mp3
#EXTINF:-1 tvg-name="Live Sports" group-title="Sports",Live Sports
http://example.com/live1.ts
''');

    final playlistUri = playlistFile.uri;

    final profile = ResolvedProviderProfile(
      record: _record(kind: ProviderKind.m3u, lockedBase: playlistUri),
      secrets: {'playlistUrl': playlistUri.toString()},
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final summary = await container.read(summaryDataProvider(profile).future);

    expect(summary.counts['Live'], 1);
    expect(summary.counts['VOD'], 1);
    expect(summary.counts['Series'], 1);
    expect(summary.counts['Radio'], 1);
    expect(summary.fields['Source'], playlistUri.toFilePath());
  });
}

ProviderProfileRecord _record({
  required ProviderKind kind,
  required Uri lockedBase,
  Map<String, String> configuration = const {},
  Map<String, String> hints = const {},
  bool allowSelfSignedTls = false,
  bool followRedirects = true,
}) {
  final now = DateTime.utc(2024, 1, 1);
  return ProviderProfileRecord(
    id: 'test-${kind.name}',
    kind: kind,
    displayName: 'Test ${kind.name}',
    lockedBase: lockedBase,
    needsUserAgent: false,
    allowSelfSignedTls: allowSelfSignedTls,
    followRedirects: followRedirects,
    configuration: configuration,
    hints: hints,
    createdAt: now,
    updatedAt: now,
    lastOkAt: now,
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
    final action = queryParameters['action']?.toString();

    if (action == 'get_profile') {
      return PortalResponseEnvelope(
        body: <String, dynamic>{
          'status': 'Active',
          'parent_password': '0000',
          'tariff_plan': 'Ultimate',
          'subscription_date': '2024-01-15',
        },
        statusCode: 200,
        headers: const {},
        cookies: const [],
      );
    }

    if (action == 'get_main_info') {
      return PortalResponseEnvelope(
        body: <String, dynamic>{'balance': '15.75', 'status': 'active'},
        statusCode: 200,
        headers: const {},
        cookies: const [],
      );
    }

    final totals = {'itv': 120, 'vod': 42, 'series': 12, 'radio': 18};
    final type = queryParameters['type']?.toString() ?? '';
    return PortalResponseEnvelope(
      body: <String, dynamic>{'total_items': totals[type] ?? 0},
      statusCode: 200,
      headers: const {},
      cookies: const [],
    );
  }
}

