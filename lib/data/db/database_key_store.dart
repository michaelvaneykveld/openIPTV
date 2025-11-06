import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction used to load or generate the SQLCipher encryption key.
abstract class DatabaseKeyStore {
  /// Returns an existing key or null when not yet provisioned.
  Future<String?> readKey();

  /// Persists the provided key value.
  Future<void> writeKey(String key);

  /// Removes the stored key (primarily used for destructive resets).
  Future<void> deleteKey();

  /// Helper that returns the existing key or creates and saves a new one.
  Future<String> obtainOrCreateKey() async {
    final existing = await readKey();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _generateKey();
    await writeKey(generated);
    return generated;
  }

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}

/// Secure-storage backed implementation used in production builds.
class SecureDatabaseKeyStore extends DatabaseKeyStore {
  SecureDatabaseKeyStore({
    FlutterSecureStorage? storage,
    String keyName = _defaultKeyName,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _keyName = keyName;

  final FlutterSecureStorage _storage;
  final String _keyName;

  static const String _defaultKeyName = 'openiptv_db_encryption_key';

  @override
  Future<void> deleteKey() {
    return _storage.delete(key: _keyName);
  }

  @override
  Future<String?> readKey() {
    return _storage.read(key: _keyName);
  }

  @override
  Future<void> writeKey(String key) {
    return _storage.write(key: _keyName, value: key);
  }
}

/// In-memory key store used for tests that validate encrypted path wiring.
class MemoryDatabaseKeyStore extends DatabaseKeyStore {
  String? _key;

  @override
  Future<void> deleteKey() async {
    _key = null;
  }

  @override
  Future<String?> readKey() async {
    return _key;
  }

  @override
  Future<void> writeKey(String key) async {
    _key = key;
  }
}

