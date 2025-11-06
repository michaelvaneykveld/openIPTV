import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/artwork/artwork_fetcher.dart';
import 'package:openiptv/data/db/dao/artwork_cache_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';

void main() {
  late OpenIptvDb db;
  late ArtworkCacheDao dao;
  late Dio dio;
  late Directory cacheDir;

  setUp(() {
    db = OpenIptvDb.inMemory();
    dao = ArtworkCacheDao(db);
    dio = Dio();
    cacheDir = Directory.systemTemp.createTempSync('artwork-cache-test');
  });

  tearDown(() async {
    dio.close(force: true);
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
    await db.close();
  });

  test('fetch stores bytes and leverages conditional requests', () async {
    final server = await _TestServer.start(bytes: Uint8List.fromList([1, 2, 3]));
    addTearDown(server.close);

    final fetcher = ArtworkFetcher(
      cacheDao: dao,
      client: dio,
      cacheDirectory: cacheDir,
    );

    final url = server.url;
    final first = await fetcher.fetch(url);
    expect(first.fromCache, isFalse);
    expect(first.bytes, equals([1, 2, 3]));

    // Trigger second fetch - server should emit 304 and fetcher should
    // serve cached bytes.
    server.enableConditionalResponses();
    final second = await fetcher.fetch(
      url,
      maxAge: Duration.zero,
    );
    expect(second.fromCache, isTrue);
    expect(second.bytes, equals([1, 2, 3]));
    expect(server.requestCount, equals(2));
  });

  test('fetch stores oversized payloads on disk and prunes extras', () async {
    final largeBytes = Uint8List.fromList(List<int>.filled(512, 7));
    final server =
        await _TestServer.start(bytes: largeBytes, etag: '"large-v1"');
    addTearDown(server.close);

    final fetcher = ArtworkFetcher(
      cacheDao: dao,
      client: dio,
      cacheDirectory: cacheDir,
      inlineThresholdBytes: 128,
      maxEntries: 1,
      maxBytes: 1024,
    );

    final urlA = server.url;
    final resultA = await fetcher.fetch(urlA);
    expect(resultA.record.filePath, isNotNull);
    expect(File(resultA.record.filePath!).existsSync(), isTrue);

    // Add a second entry to trigger pruning by entry count.
    final serverB =
        await _TestServer.start(bytes: Uint8List.fromList([9, 9, 9]));
    addTearDown(serverB.close);

    await fetcher.fetch(serverB.url);

    final remaining = await dao.findByUrl(urlA);
    // Should have been pruned due to entry budget of 1.
    expect(remaining, isNull);
  });
}

class _TestServer {
  _TestServer._(this._server, this.bytes, this._etag);

  final HttpServer _server;
  final Uint8List bytes;
  final String _etag;
  bool _conditional = false;
  int requestCount = 0;

  String get url => 'http://127.0.0.1:${_server.port}/artwork.png';

  static Future<_TestServer> start({
    required Uint8List bytes,
    String etag = '"v1"',
  }) async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    final instance = _TestServer._(server, bytes, etag);
    server.listen(instance._handle);
    return instance;
  }

  void enableConditionalResponses() {
    _conditional = true;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    requestCount += 1;
    request.response.headers.add(HttpHeaders.etagHeader, _etag);
    if (_conditional) {
      final ifNoneMatch = request.headers.value(HttpHeaders.ifNoneMatchHeader);
      if (ifNoneMatch == _etag) {
        request.response.statusCode = HttpStatus.notModified;
        await request.response.close();
        return;
      }
    }
    request.response.headers.contentType = ContentType('image', 'png');
    request.response.add(bytes);
    await request.response.close();
  }
}
