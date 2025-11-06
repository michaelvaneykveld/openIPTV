import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../db/dao/artwork_cache_dao.dart';
import '../db/openiptv_db.dart';

class ArtworkFetchResult {
  ArtworkFetchResult({
    required this.record,
    required this.bytes,
    required this.fromCache,
  });

  final ArtworkCacheRecord record;
  final Uint8List bytes;
  final bool fromCache;
}

class ArtworkFetcher {
  ArtworkFetcher({
    required ArtworkCacheDao cacheDao,
    required Dio client,
    required Directory cacheDirectory,
    int inlineThresholdBytes = 128 * 1024,
    int maxEntries = 200,
    int maxBytes = 100 * 1024 * 1024,
  })  : _dao = cacheDao,
        _client = client,
        _cacheDir = cacheDirectory,
        _inlineThresholdBytes = inlineThresholdBytes,
        _maxEntries = maxEntries,
        _maxBytes = maxBytes;

  final ArtworkCacheDao _dao;
  final Dio _client;
  final Directory _cacheDir;
  final int _inlineThresholdBytes;
  final int _maxEntries;
  final int _maxBytes;

  Future<ArtworkFetchResult> fetch(
    String url, {
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    final existing = await _dao.findByUrl(url);
    final now = DateTime.now().toUtc();

    if (existing != null && !forceRefresh) {
      final isExpired = _isExpired(existing, now, maxAge);
      if (!isExpired) {
        await _dao.updateAccessTime(existing.id);
        final bytes = await _loadBytes(existing);
        return ArtworkFetchResult(
          record: existing.copyWith(lastAccessedAt: now),
          bytes: bytes,
          fromCache: true,
        );
      }
    }

    final headers = <String, String>{
      'Accept': 'image/*',
    };
    if (existing?.etag != null) {
      headers['If-None-Match'] = existing!.etag!;
    }

    Response<List<int>> response;
    try {
      response = await _client.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 304 && existing != null) {
        await _dao.updateAccessTime(existing.id);
        final bytes = await _loadBytes(existing);
        return ArtworkFetchResult(
          record: existing.copyWith(
            fetchedAt: now,
            lastAccessedAt: now,
            needsRefresh: false,
          ),
          bytes: bytes,
          fromCache: true,
        );
      }
      rethrow;
    }

    if (response.statusCode == 304 && existing != null) {
      await _dao.updateAccessTime(existing.id);
      final bytes = await _loadBytes(existing);
      return ArtworkFetchResult(
        record: existing.copyWith(
          fetchedAt: now,
          lastAccessedAt: now,
          needsRefresh: false,
        ),
        bytes: bytes,
        fromCache: true,
      );
    }

    final payload = response.data;
    if (payload == null) {
      throw StateError('Artwork response for $url did not contain a body.');
    }

    final bytes = Uint8List.fromList(payload);
    final hash = sha1.convert(bytes).toString();
    final etag = response.headers.value('etag');
    final expiresAt = _deriveExpiry(response.headers, now);

    final storage = await _persistBytes(
      url: url,
      bytes: bytes,
    );

    if (existing?.filePath != null && existing!.filePath != storage.filePath) {
      _deleteFileSilently(existing.filePath!);
    }

    await _dao.upsertEntry(
      url: url,
      etag: etag,
      hash: hash,
      bytes: storage.inlineBytes,
      filePath: storage.filePath,
      byteSize: bytes.length,
      width: null,
      height: null,
      expiresAt: expiresAt,
      needsRefresh: false,
    );

    await _enforceBudgets();

    final updated = await _dao.findByUrl(url);
    if (updated == null) {
      throw StateError('Failed to store artwork cache entry for $url');
    }

    return ArtworkFetchResult(
      record: updated,
      bytes: storage.inlineBytes ?? bytes,
      fromCache: false,
    );
  }

  bool _isExpired(
    ArtworkCacheRecord record,
    DateTime now,
    Duration? maxAge,
  ) {
    if (record.needsRefresh) return true;
    if (record.expiresAt != null && !record.expiresAt!.isAfter(now)) {
      return true;
    }
    if (maxAge != null) {
      final threshold = now.subtract(maxAge);
      if (record.fetchedAt.isBefore(threshold)) {
        return true;
      }
    }
    return false;
  }

  Future<_StorageResult> _persistBytes({
    required String url,
    required Uint8List bytes,
  }) async {
    if (bytes.length <= _inlineThresholdBytes) {
      return _StorageResult(inlineBytes: bytes);
    }

    if (!_cacheDir.existsSync()) {
      await _cacheDir.create(recursive: true);
    }

    final filename = base64Url.encode(sha1.convert(utf8.encode(url)).bytes);
    final file = File('${_cacheDir.path}/$filename.img');
    await file.writeAsBytes(bytes, flush: true);
    return _StorageResult(filePath: file.path);
  }

  DateTime? _deriveExpiry(Headers headers, DateTime now) {
    final cacheControl = headers.value('cache-control');
    if (cacheControl == null) return null;
    final directives = cacheControl.split(',').map((e) => e.trim()).toList();
    for (final directive in directives) {
      if (directive.startsWith('max-age=')) {
        final seconds = int.tryParse(directive.substring(8));
        if (seconds != null) {
          return now.add(Duration(seconds: seconds));
        }
      }
    }
    return null;
  }

  Future<void> _enforceBudgets() async {
    final removedByCount = await _dao.pruneToEntryBudget(_maxEntries);
    for (final record in removedByCount) {
      if (record.filePath != null) {
        _deleteFileSilently(record.filePath!);
      }
    }

    final removedBySize = await _dao.pruneToSizeBudget(_maxBytes);
    for (final record in removedBySize) {
      if (record.filePath != null) {
        _deleteFileSilently(record.filePath!);
      }
    }
  }

  Future<Uint8List> _loadBytes(ArtworkCacheRecord record) async {
    if (record.bytes != null) {
      return Uint8List.fromList(record.bytes!);
    }
    if (record.filePath != null) {
      final file = File(record.filePath!);
      if (await file.exists()) {
        final data = await file.readAsBytes();
        return Uint8List.fromList(data);
      }
    }
    throw StateError('No data available for artwork ${record.url}');
  }

  void _deleteFileSilently(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // Ignore cleanup errors.
    }
  }
}

class _StorageResult {
  const _StorageResult({this.inlineBytes, this.filePath});

  final Uint8List? inlineBytes;
  final String? filePath;
}

