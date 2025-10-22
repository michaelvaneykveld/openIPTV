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
    final List<Credentials> updatedCredentials = [
      ...currentCredentials.where((c) => c.id != credentials.id),
      credentials,
    ];
    final List<Map<String, dynamic>> jsonList = updatedCredentials
        .map((c) => c.toJson())
        .toList();
    await _storage.write(key: _credentialsListKey, value: jsonEncode(jsonList));
  }

  @override
  Future<List<Credentials>> getCredentialsList() async {
    final String? credentialsJson = await _storage.read(
      key: _credentialsListKey,
    );
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
  Future<void> deleteCredentialById(String credentialId) async {
    final currentCredentials = await getCredentialsList();
    final updated = currentCredentials
        .where((c) => c.id != credentialId)
        .toList();
    final jsonList = updated.map((c) => c.toJson()).toList();
    if (jsonList.isEmpty) {
      await _storage.delete(key: _credentialsListKey);
    } else {
      await _storage.write(
        key: _credentialsListKey,
        value: jsonEncode(jsonList),
      );
    }
  }

  @override
  Future<void> clearAllCredentials() async {
    await _storage.delete(key: _credentialsListKey);
  }
}
