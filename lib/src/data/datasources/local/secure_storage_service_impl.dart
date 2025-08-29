import 'dart:convert';
import 'dart:io'; // Added for File operations
import 'dart:developer' as developer; // Added for logging
import 'package:path_provider/path_provider.dart'; // Added for path_provider
import 'package:openiptv/src/core/models/credential.dart';
import 'package:openiptv/src/core/utils/secure_storage.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';

class SecureStorageServiceImpl implements SecureStorageInterface {
  final SecureStorage _secureStorage;
  static const String _credentialsKey = 'credentials';
  static const String _tokenKey = 'stalker_token'; // Key for the token

  SecureStorageServiceImpl(this._secureStorage);

  // --- Old file handling methods from WindowsSecureStorage for migration ---
  Future<File> get _oldLocalFile async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/credentials.json');
    return file;
  }

  Future<Map<String, dynamic>> _readOldRawData() async {
    try {
      final file = await _oldLocalFile;
      if (!await file.exists()) {
        return {'credentials': [], 'token': null};
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return {'credentials': [], 'token': null};
      }

      final Map<String, dynamic> parsedData = json.decode(contents) as Map<String, dynamic>;
      // bool dataMigrated = false; // Removed unused variable

      // Check for old individual portal_url and mac_address keys
      if (parsedData.containsKey('portal_url') && parsedData.containsKey('mac_address')) {
        final oldPortalUrl = parsedData['portal_url'] as String;
        final oldMacAddress = parsedData['mac_address'] as String;

        final oldCredential = Credential(portalUrl: oldPortalUrl, macAddress: oldMacAddress);

        List<dynamic> currentCredentials = parsedData['credentials'] as List<dynamic>? ?? [];
        if (!currentCredentials.any((c) => c['portalUrl'] == oldPortalUrl && c['macAddress'] == oldMacAddress)) {
          currentCredentials.add(oldCredential.toJson());
          parsedData['credentials'] = currentCredentials;
          // dataMigrated = true; // Removed unused variable assignment
        }

        parsedData.remove('portal_url');
        parsedData.remove('mac_address');
        // dataMigrated = true; // Removed unused variable assignment
      }
      return parsedData;
    } catch (e) {
      developer.log('Error reading old raw data from credentials file: $e', name: 'SecureStorageServiceImpl');
      return {'credentials': [], 'token': null};
    }
  }
  // --- End old file handling methods ---

  @override
  Future<String?> read({required String key}) {
    return _secureStorage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String? value}) {
    return _secureStorage.write(key: key, value: value!);
  }

  @override
  Future<void> delete({required String key}) {
    return _secureStorage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _secureStorage.delete(key: _credentialsKey);
    await _secureStorage.delete(key: _tokenKey); // Also delete the token
  }

  @override
  Future<List<Credential>> getCredentialsList() async {
    developer.log('Attempting to read credentials from secure storage.', name: 'SecureStorageServiceImpl');
    String? credentialsJson = await _secureStorage.read(key: _credentialsKey);

    if (credentialsJson == null || credentialsJson.isEmpty) {
      developer.log('No credentials found in secure storage. Checking for old file for migration.', name: 'SecureStorageServiceImpl');
      final oldData = await _readOldRawData();
      final oldCredentialsJson = oldData['credentials'] as List<dynamic>?;
      final oldToken = oldData['token'] as String?;

      if (oldCredentialsJson != null && oldCredentialsJson.isNotEmpty) {
        developer.log('Old credentials found in file. Attempting migration.', name: 'SecureStorageServiceImpl');
        final List<Credential> migratedCredentials = oldCredentialsJson.map((json) => Credential.fromJson(json)).toList();
        await saveCredentialsList(migratedCredentials); // Save to secure storage
        developer.log('Migrated ${migratedCredentials.length} credentials from old file to secure storage. Saved to secure storage.', name: 'SecureStorageServiceImpl');

        // Migrate token if exists
        if (oldToken != null && oldToken.isNotEmpty) {
          await _secureStorage.write(key: _tokenKey, value: oldToken);
          developer.log('Migrated token from old file to secure storage.', name: 'SecureStorageServiceImpl');
        }

        // Delete the old file after successful migration
        try {
          final file = await _oldLocalFile;
          if (await file.exists()) {
            await file.delete();
            developer.log('Deleted old credentials.json file after successful migration.', name: 'SecureStorageServiceImpl');
          }
        } catch (e) {
          developer.log('Error deleting old credentials.json file: $e', name: 'SecureStorageServiceImpl');
        }

        return migratedCredentials;
      } else {
        developer.log('No credentials found in old file either. Returning empty list.', name: 'SecureStorageServiceImpl');
      }
    } else {
      developer.log('Credentials found in secure storage. Attempting to decode.', name: 'SecureStorageServiceImpl');
    }

    // If found in secure storage or after migration
    if (credentialsJson != null && credentialsJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(credentialsJson);
        developer.log('Successfully decoded credentials from secure storage. Found ${decodedList.length} credentials.', name: 'SecureStorageServiceImpl');
        return decodedList.map((json) => Credential.fromJson(json)).toList();
      } catch (e) {
        developer.log('Error decoding credentials from secure storage: $e. Returning empty list.', name: 'SecureStorageServiceImpl');
        return [];
      }
    }
    developer.log('No credentials found after all attempts. Returning empty list.', name: 'SecureStorageServiceImpl');
    return [];
  }

  @override
  Future<void> saveCredentialsList(List<Credential> credentials) async {
    final String encodedJson = json.encode(credentials.map((c) => c.toJson()).toList());
    await _secureStorage.write(key: _credentialsKey, value: encodedJson);
  }
}