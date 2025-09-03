import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openiptv/src/core/models/credentials.dart';
import 'package:openiptv/src/core/models/m3u_credentials.dart';
import 'package:openiptv/src/core/models/stalker_credentials.dart';
import 'package:openiptv/src/core/models/xtream_credentials.dart'; // New import
import 'secure_storage_interface.dart';

/// Concrete implementatie van SecureStorageInterface
/// die FlutterSecureStorage gebruikt. Werkt cross-platform.
class FlutterSecureStorageAdapter implements SecureStorageInterface {
  final FlutterSecureStorage _storage;
  static const String _credentialsListKey = 'credentials_list';

  FlutterSecureStorageAdapter() : _storage = const FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> saveCredentials(Credentials credentials) async {
    final List<Credentials> currentCredentials = await getCredentialsList();
    // Remove existing credential with the same ID to avoid duplicates
    currentCredentials.removeWhere((c) => c.id == credentials.id);
    currentCredentials.add(credentials);
    final List<Map<String, dynamic>> jsonList = currentCredentials.map((c) => c.toJson()).toList();
    await _storage.write(key: _credentialsListKey, value: jsonEncode(jsonList));
  }

  @override
  Future<List<Credentials>> getCredentialsList() async {
    final String? credentialsJson = await _storage.read(key: _credentialsListKey);
    if (credentialsJson == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(credentialsJson) as List<dynamic>;
    return jsonList.map((json) {
      final type = json['type'] as String;
      if (type == 'stalker') {
        return StalkerCredentials.fromJson(json as Map<String, dynamic>);
      } else if (type == 'm3u') {
        return M3uCredentials.fromJson(json as Map<String, dynamic>);
      } else if (type == 'xtream') {
        return XtreamCredentials.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Unknown credential type: $type');
      }
    }).toList();
  }

  @override
  Future<void> clearAllCredentials() async {
    await _storage.delete(key: _credentialsListKey);
  }
}
