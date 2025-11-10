import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:path/path.dart' as p;

class ImportResumeStore {
  ImportResumeStore._(this._file);

  final File _file;
  Map<String, dynamic>? _cache;
  final _AsyncMutex _mutex = _AsyncMutex();
  static const _ttl = Duration(hours: 12);

  static Future<ImportResumeStore> openDefault() async {
    final dbFile = await OpenIptvDb.resolveDatabaseFile();
    final file = File(p.join(dbFile.parent.path, 'import_resume.json'));
    return ImportResumeStore._(file);
  }

  static Future<ImportResumeStore> openAtDirectory(String directoryPath) async {
    final file = File(p.join(directoryPath, 'import_resume.json'));
    return ImportResumeStore._(file);
  }

  Future<int?> readNextPage(
    int providerId,
    String module,
    String categoryKey,
  ) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      final key = _hash(providerId, module, categoryKey);
      final entry = _cache![key];
      if (entry is! Map) {
        return null;
      }
      final updatedAtMs = entry['updatedAt'] as int? ?? 0;
      final updatedAt =
          DateTime.fromMillisecondsSinceEpoch(updatedAtMs, isUtc: true);
      if (DateTime.now().toUtc().difference(updatedAt) > _ttl) {
        _cache!.remove(key);
        await _persist();
        return null;
      }
      final nextPage = entry['nextPage'] as int?;
      if (nextPage == null || nextPage <= 1) {
        return null;
      }
      return nextPage;
    });
  }

  Future<void> writeNextPage(
    int providerId,
    String module,
    String categoryKey,
    int nextPage,
  ) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      final key = _hash(providerId, module, categoryKey);
      _cache![key] = {
        'providerId': providerId,
        'module': module,
        'category': categoryKey,
        'nextPage': nextPage,
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      };
      await _persist();
    });
  }

  Future<void> clearProvider(int providerId) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      _cache!.removeWhere(
        (key, value) => key.startsWith('$providerId::'),
      );
      await _persist();
    });
  }

  Future<void> _ensureCache() async {
    if (_cache != null) return;
    if (await _file.exists()) {
      try {
        final contents = await _file.readAsString();
        if (contents.trim().isEmpty) {
          _cache = <String, dynamic>{};
          return;
        }
        final decoded = jsonDecode(contents);
        if (decoded is Map<String, dynamic>) {
          _cache = decoded;
          return;
        }
      } catch (_) {
        // fall through to reset cache.
      }
    }
    _cache = <String, dynamic>{};
  }

  Future<void> _persist() async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode(_cache));
    } catch (_) {
      // Best-effort; ignore persistence failures.
    }
  }

  String _hash(int providerId, String module, String categoryKey) {
    return '$providerId::$module::$categoryKey';
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
