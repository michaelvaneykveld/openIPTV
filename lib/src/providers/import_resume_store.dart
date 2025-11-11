import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_dialect.dart';
import 'package:path/path.dart' as p;

class ImportResumeStore {
  ImportResumeStore._(this._file);

  final File _file;
  Map<String, dynamic>? _cache;
  final _AsyncMutex _mutex = _AsyncMutex();
  static const _ttl = Duration(hours: 12);
  static const _dialectPrefix = 'dialect:stalker:';

  static Future<ImportResumeStore> openDefault() async {
    final dbFile = await OpenIptvDb.resolveDatabaseFile();
    final file = File(p.join(dbFile.parent.path, 'import_resume.json'));
    return ImportResumeStore._(file);
  }

  static Future<ImportResumeStore> openAtDirectory(String directoryPath) async {
    final file = File(p.join(directoryPath, 'import_resume.json'));
    return ImportResumeStore._(file);
  }

  Future<int?> readNextPage(int providerId, String module, String categoryKey) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      final key = _hash(providerId, module, categoryKey);
      final entry = _cache![key];
      if (entry is! Map) {
        return null;
      }
      final updatedAtMs = entry['updatedAt'] as int? ?? 0;
      final updatedAt = DateTime.fromMillisecondsSinceEpoch(
        updatedAtMs,
        isUtc: true,
      );
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
      _cache!.removeWhere((key, value) => key.startsWith('$providerId::'));
      await _persist();
    });
  }

  Future<StalkerPortalDialect?> readStalkerDialect(int providerId) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      final key = '$_dialectPrefix$providerId';
      final entry = _cache![key];
      if (entry is! Map) {
        return null;
      }
      final dialect = StalkerPortalDialect.fromJson(
        entry.map((entryKey, value) => MapEntry('$entryKey', value)),
      );
      if (dialect.isExpired(_ttl)) {
        _cache!.remove(key);
        await _persist();
        return null;
      }
      return dialect;
    });
  }

  Future<void> writeStalkerDialect(
    int providerId,
    StalkerPortalDialect dialect,
  ) {
    return _mutex.synchronized(() async {
      await _ensureCache();
      _cache!['$_dialectPrefix$providerId'] = dialect.toJson();
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
          await _pruneExpiredEntries();
          return;
        }
      } catch (_) {
        // fall through to reset cache.
      }
    }
    _cache = <String, dynamic>{};
    await _pruneExpiredEntries();
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

  Future<void> _pruneExpiredEntries() async {
    if (_cache == null || _cache!.isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    final expiredKeys = <String>[];
    _cache!.forEach((key, value) {
      if (key.startsWith(_dialectPrefix)) {
        if (value is Map) {
          final dialect = StalkerPortalDialect.fromJson(
            value.map(
              (entryKey, entryValue) => MapEntry('$entryKey', entryValue),
            ),
          );
          if (dialect.isExpired(_ttl)) {
            expiredKeys.add(key);
          }
        }
        return;
      }
      if (value is Map) {
        final updatedAtMs = value['updatedAt'] as int? ?? 0;
        final updatedAt = DateTime.fromMillisecondsSinceEpoch(
          updatedAtMs,
          isUtc: true,
        );
        if (now.difference(updatedAt) > _ttl) {
          expiredKeys.add(key);
        }
      }
    });
    if (expiredKeys.isEmpty) {
      return;
    }
    for (final key in expiredKeys) {
      _cache!.remove(key);
    }
    await _persist();
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
