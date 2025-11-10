import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:path/path.dart' as p;

class PortalSummaryCache {
  PortalSummaryCache._(this._file);

  final File _file;
  Map<String, dynamic>? _cache;
  final _AsyncMutex _mutex = _AsyncMutex();

  static Future<PortalSummaryCache> openDefault() async {
    final dbFile = await OpenIptvDb.resolveDatabaseFile();
    final cacheFile = File(p.join(dbFile.parent.path, 'portal_summary_cache.json'));
    return PortalSummaryCache._(cacheFile);
  }

  Future<SummaryData?> read(int providerId) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      final entry = _cache?['$providerId'];
      if (entry is! Map<String, dynamic>) {
        return null;
      }
      try {
        return SummaryData.fromJson(entry);
      } catch (_) {
        _cache?.remove('$providerId');
        unawaited(_persist());
        return null;
      }
    });
  }

  Future<void> write(int providerId, SummaryData summary) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      _cache!['$providerId'] = summary.toJson();
      await _persist();
    });
  }

  Future<void> _ensureCache() async {
    if (_cache != null) return;
    if (await _file.exists()) {
      try {
        final contents = await _file.readAsString();
        final decoded = jsonDecode(contents);
        if (decoded is Map<String, dynamic>) {
          _cache = decoded;
          return;
        }
      } catch (_) {
        // fall through to reset cache
      }
    }
    _cache = <String, dynamic>{};
  }

  Future<void> _persist() async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode(_cache));
    } catch (_) {
      // best effort
    }
  }
}

class _AsyncMutex {
  Future<void> _pending = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<void>();
    final previous = _pending;
    _pending = completer.future;
    return previous.then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
  }
}
