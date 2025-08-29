import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/src/core/models/credential.dart';

/// Concrete implementatie die FlutterSecureStorage gebruikt
class FlutterSecureStorageAdapter implements SecureStorageInterface {
  final FlutterSecureStorage _storage;
  static const String _credentialsListKey = 'saved_credentials_list';

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
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  @override
  Future<List<Credential>> getCredentialsList() async {
    final String? credentialsJson = await _storage.read(key: _credentialsListKey);
    if (credentialsJson == null || credentialsJson.isEmpty) {
      return [];
    }
    final List<dynamic> decodedList = json.decode(credentialsJson);
    return decodedList.map((json) => Credential.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveCredentialsList(List<Credential> credentials) async {
    final String encodedJson = json.encode(credentials.map((c) => c.toJson()).toList());
    await _storage.write(key: _credentialsListKey, value: encodedJson);
  }
}