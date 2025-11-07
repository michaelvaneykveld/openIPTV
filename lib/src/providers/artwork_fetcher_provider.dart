import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:openiptv/data/artwork/artwork_fetcher.dart';
import 'package:openiptv/data/db/dao/artwork_cache_dao.dart';
import 'package:openiptv/data/db/database_locator.dart';
import 'package:openiptv/src/providers/telemetry_service.dart';

final artworkFetcherProvider = FutureProvider<ArtworkFetcher>((ref) async {
  final db = ref.watch(openIptvDbProvider);
  final cacheDao = ArtworkCacheDao(db);
  final tempDir = await getTemporaryDirectory();
  final cacheDir = Directory(p.join(tempDir.path, 'artwork_cache'));
  final telemetry = await ref.watch(telemetryServiceProvider.future);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
    ),
  );
  return ArtworkFetcher(
    cacheDao: cacheDao,
    client: dio,
    cacheDirectory: cacheDir,
    maxEntries: 400,
    maxBytes: 150 * 1024 * 1024,
    onTelemetry: (event) {
      telemetry.logCacheEvent(
        cache: 'artwork',
        key: event.url,
        fromCache: event.fromCache,
        byteSize: event.byteSize,
      );
      if (!event.success && event.error != null) {
        telemetry.logCrashSafeError(
          category: 'artwork',
          message: 'Artwork fetch error',
          metadata: {
            'url': event.url,
            'error': event.error,
          },
        );
      }
    },
  );
});

final artworkImageProvider =
    FutureProvider.family<Uint8List?, String>((ref, url) async {
      if (url.isEmpty) {
        return null;
      }
      final fetcher = await ref.watch(artworkFetcherProvider.future);
      try {
        final result = await fetcher.fetch(
          url,
          maxAge: const Duration(days: 7),
        );
        return result.bytes;
      } catch (_) {
        return null;
      }
    });
