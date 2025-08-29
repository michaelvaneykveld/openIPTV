import 'dart:convert';
import 'dart:developer' as developer; // Added for logging
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/src/core/models/credential.dart'; // Import Credential model

class FlutterSecureStorageWrapper implements SecureStorageInterface {
  final FlutterSecureStorage storage;

  const FlutterSecureStorageWrapper({required this.storage});

  static const _credentialsListKey = 'saved_credentials_list';
  static const _tokenKey = 'stalker_token'; // Assuming token is still stored separately

  @override
  Future<String?> read({required String key}) async {
    // If the key is for the token, read it directly
    if (key == _tokenKey) {
      return await storage.read(key: key);
    }
    // For other keys, we might need to rethink if they are still used individually.
    // For now, assume individual keys are for token only.
    return null;
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    // If the key is for the token, write it directly
    if (key == _tokenKey) {
      await storage.write(key: key, value: value);
    }
    // For other keys, we might need to rethink if they are still used individually.
  }

  @override
  Future<void> delete({required String key}) async {
    // If the key is for the token, delete it directly
    if (key == _tokenKey) {
      await storage.delete(key: key);
    }
    // For other keys, we might need to rethink if they are still used individually.
  }

  @override
  Future<void> deleteAll() async {
    await storage.deleteAll();
  }

  @override
  Future<List<Credential>> getCredentialsList() async {
    try {
      final String? credentialsJsonString = await storage.read(key: _credentialsListKey);
      developer.log('FlutterSecureStorageWrapper: Raw data read: $credentialsJsonString', name: 'FlutterSecureStorageWrapper');
      if (credentialsJsonString == null || credentialsJsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(credentialsJsonString);
      return jsonList.map((json) => Credential.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error reading credentials list from FlutterSecureStorage: $e');
      return [];
    }
  }

  @override
  Future<void> saveCredentialsList(List<Credential> credentials) async {
    try {
      final List<Map<String, dynamic>> jsonList = credentials.map((c) => c.toJson()).toList();
      final String credentialsJsonString = json.encode(jsonList);
      developer.log('FlutterSecureStorageWrapper: Raw data written: $credentialsJsonString', name: 'FlutterSecureStorageWrapper');
      await storage.write(key: _credentialsListKey, value: credentialsJsonString);
    } catch (e) {
      print('Error saving credentials list to FlutterSecureStorage: $e');
    }
  }
}
