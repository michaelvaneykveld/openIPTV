import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/utils/url_normalization.dart';

typedef DiscoveryCacheErrorLogger = void Function(
  String message,
  Object error,
  StackTrace stackTrace,
);

/// Snapshot returned when fetching from the cache.
@immutable
class DiscoveryCacheHit {
  const DiscoveryCacheHit({
    required this.result,
    required this.storedAt,
    required this.shouldRefresh,
  });

  final DiscoveryResult result;
  final DateTime storedAt;
  final bool shouldRefresh;
}

/// Persisted payload for previously discovered portal endpoints.
@immutable
@visibleForTesting
class CachedDiscoveryEntry {
  const CachedDiscoveryEntry({
    required this.kind,
    required this.lockedBase,
    required this.hints,
    required this.storedAt,
  });

  final ProviderKind kind;
  final Uri lockedBase;
  final Map<String, String> hints;
  final DateTime storedAt;

  bool isExpired(Duration ttl, DateTime now) {
    return storedAt.add(ttl).isBefore(now);
  }

  bool shouldRefresh(
    Duration ttl,
    DateTime now,
    Duration refreshLeeway,
  ) {
    final leeway = refreshLeeway > ttl ? ttl : refreshLeeway;
    final refreshPoint = storedAt.add(ttl).subtract(leeway);
    return !refreshPoint.isAfter(now);
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'lockedBase': lockedBase.toString(),
        'hints': hints,
        'storedAt': storedAt.toUtc().toIso8601String(),
      };

  DiscoveryResult toDiscoveryResult() {
    return DiscoveryResult(
      kind: kind,
      lockedBase: lockedBase,
      hints: hints,
    );
  }

  static CachedDiscoveryEntry? fromJson(Map<String, dynamic> json) {
    final kindValue = json['kind'] as String?;
    final lockedBaseValue = json['lockedBase'] as String?;
    final storedAtValue = json['storedAt'] as String?;
    if (kindValue == null ||
        lockedBaseValue == null ||
        lockedBaseValue.isEmpty ||
        storedAtValue == null) {
      return null;
    }

    final kind = ProviderKind.values.firstWhere(
      (value) => value.name == kindValue,
      orElse: () => ProviderKind.m3u,
    );

    final lockedBase = Uri.tryParse(lockedBaseValue);
    if (lockedBase == null || lockedBase.host.isEmpty) {
      return null;
    }

    DateTime? storedAt;
    try {
      storedAt = DateTime.parse(storedAtValue).toUtc();
    } catch (_) {
      return null;
    }

    final hintsValue = json['hints'];
    final hints = <String, String>{};
    if (hintsValue is Map) {
      for (final entry in hintsValue.entries) {
        hints[entry.key.toString()] = entry.value.toString();
      }
    }

    return CachedDiscoveryEntry(
      kind: kind,
      lockedBase: lockedBase,
      hints: Map.unmodifiable(hints),
      storedAt: storedAt,
    );
  }
}

/// Provides TTL-based caching for provider discovery results so login flows
/// can skip redundant probe loops on repeat attempts.
class DiscoveryCacheManager {
  DiscoveryCacheManager({
    SharedPreferences? preferences,
    Duration ttl = const Duration(hours: 24),
    String storageKey = 'discovery_cache_v1',
    DiscoveryCacheErrorLogger? errorLogger,
  })  : _prefsOverride = preferences,
        _ttl = ttl,
        _storageKey = storageKey,
        _errorLogger = errorLogger;

  final SharedPreferences? _prefsOverride;
  final Duration _ttl;
  final String _storageKey;
  final DiscoveryCacheErrorLogger? _errorLogger;

  SharedPreferences? _prefs;
  final Map<String, CachedDiscoveryEntry> _entries =
      <String, CachedDiscoveryEntry>{};
  bool _loaded = false;

  static const Set<String> _sensitiveQueryKeys = {
    'username',
    'password',
    'token',
    'mac',
  };

  Future<void> ensureLoaded({DateTime? now}) async {
    if (_loaded) {
      return;
    }

    try {
      _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_storageKey);
      var needsPersist = false;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final currentTime = (now ?? DateTime.now()).toUtc();
          decoded.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              final entry = CachedDiscoveryEntry.fromJson(value);
              if (entry == null || entry.isExpired(_ttl, currentTime)) {
                needsPersist = true;
                return;
              }
              _entries[key] = entry;
            } else {
              needsPersist = true;
            }
          });
        } else {
          needsPersist = true;
        }
      }
      _loaded = true;
      if (needsPersist) {
        await _persist();
      }
    } catch (error, stackTrace) {
      _errorLogger?.call('Discovery cache load failure', error, stackTrace);
      _loaded = true;
      _entries.clear();
      await _prefs?.remove(_storageKey);
    }
  }

  Future<DiscoveryCacheHit?> get({
    required String cacheKey,
    DateTime? now,
    Duration refreshLeeway = const Duration(hours: 1),
  }) async {
    await ensureLoaded(now: now);
    final entry = _entries[cacheKey];
    if (entry == null) {
      return null;
    }
    final currentTime = (now ?? DateTime.now()).toUtc();
    if (entry.isExpired(_ttl, currentTime)) {
      _entries.remove(cacheKey);
      await _persist();
      return null;
    }
    final shouldRefresh =
        entry.shouldRefresh(_ttl, currentTime, refreshLeeway);
    return DiscoveryCacheHit(
      result: entry.toDiscoveryResult(),
      storedAt: entry.storedAt,
      shouldRefresh: shouldRefresh,
    );
  }

  Future<void> store({
    required String cacheKey,
    required DiscoveryResult result,
    DateTime? now,
  }) async {
    await ensureLoaded(now: now);
    final entry = CachedDiscoveryEntry(
      kind: result.kind,
      lockedBase: result.lockedBase,
      hints: result.hints,
      storedAt: (now ?? DateTime.now()).toUtc(),
    );
    _entries[cacheKey] = entry;
    await _persist();
  }

  Future<void> purgeExpired({DateTime? now}) async {
    await ensureLoaded(now: now);
    final currentTime = (now ?? DateTime.now()).toUtc();
    var removed = false;
    final keys = List<String>.from(_entries.keys);
    for (final key in keys) {
      final entry = _entries[key];
      if (entry != null && entry.isExpired(_ttl, currentTime)) {
        _entries.remove(key);
        removed = true;
      }
    }
    if (removed) {
      await _persist();
    }
  }

  Future<void> clear() async {
    await ensureLoaded();
    _entries.clear();
    await _prefs?.remove(_storageKey);
  }

  Future<void> _persist() async {
    if (_prefs == null) {
      return;
    }
    final serializable = <String, Map<String, dynamic>>{};
    _entries.forEach((key, value) {
      serializable[key] = value.toJson();
    });
    await _prefs!.setString(_storageKey, jsonEncode(serializable));
  }

  static String buildKey({
    required ProviderKind kind,
    required String identifier,
    Map<String, String>? headers,
    bool allowSelfSignedTls = false,
    String? userAgent,
    String? macAddress,
    bool? followRedirects,
  }) {
    final normalizedIdentifier = _normalizeIdentifier(identifier);
    final descriptor = <String, dynamic>{
      'allowSelfSignedTls': allowSelfSignedTls,
      'userAgentHash': _hashString(userAgent?.trim() ?? ''),
      'headerHash': _hashHeaders(headers ?? const {}),
      'mac': macAddress?.trim().toLowerCase() ?? '',
      if (followRedirects != null) 'followRedirects': followRedirects,
    };
    final descriptorHash = _hashString(jsonEncode(descriptor));
    return '${kind.name}|$normalizedIdentifier|$descriptorHash';
  }

  /// Produces a stable, sanitised identifier that avoids storing secrets while
  /// keeping hosts/schemes comparable across inputs.
  static String _normalizeIdentifier(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final uri = tryParseLenientHttpUri(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return trimmed;
    }

    final sanitizedQuery = <String, String>{};
    uri.queryParameters.forEach((key, value) {
      if (!_sensitiveQueryKeys.contains(key.toLowerCase())) {
        sanitizedQuery[key] = value;
      }
    });

    final lowered = uri.replace(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      queryParameters: sanitizedQuery.isEmpty ? null : sanitizedQuery,
    );

    return ensureTrailingSlash(lowered).toString();
  }

  /// Hashes sorted header pairs so cache keys can respond to changes without
  /// persisting the raw values.
  static String _hashHeaders(Map<String, String> headers) {
    if (headers.isEmpty) {
      return '';
    }
    final entries = headers.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer
        ..write(entry.key.toLowerCase())
        ..write(':')
        ..write(entry.value.trim())
        ..write('\n');
    }
    return _hashString(buffer.toString());
  }

  /// Lightweight SHA-1 wrapper that yields hex digests for cache descriptors.
  static String _hashString(String value) {
    if (value.isEmpty) {
      return '';
    }
    final digest = sha1.convert(utf8.encode(value));
    return digest.toString();
  }
}
