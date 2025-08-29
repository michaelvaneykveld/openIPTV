import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_interface.dart';

/// Concrete implementatie van SecureStorageInterface
/// die FlutterSecureStorage gebruikt. Werkt cross-platform.
class FlutterSecureStorageAdapter implements SecureStorageInterface {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter() : _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
