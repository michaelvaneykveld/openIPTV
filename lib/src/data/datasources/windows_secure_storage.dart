import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer; // Added for logging
import 'package:path_provider/path_provider.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/src/core/models/credential.dart'; // Import the Credential model

class WindowsSecureStorage implements SecureStorageInterface {
  const WindowsSecureStorage();

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    // Ensure the directory exists
    if (!await directory.exists()) {
      try {
        await directory.create(recursive: true);
      } catch (e) {
        // Log error if directory creation fails
        print('Error creating directory: $e');
      }
    }

    final file = File('\${directory.path}/credentials.json');
    return file;
  }

  // Internal method to read the raw JSON data from the file
  Future<Map<String, dynamic>> _readRawData() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(json.encode({'credentials': [], 'token': null})); // Initialize with empty JSON structure
        developer.log('WindowsSecureStorage: Created new credentials.json and initialized.', name: 'WindowsSecureStorage');
        return {'credentials': [], 'token': null};
      }
      final contents = await file.readAsString();
      developer.log('WindowsSecureStorage: Raw data read: $contents', name: 'WindowsSecureStorage');
      if (contents.isEmpty) {
        developer.log('WindowsSecureStorage: Raw data is empty, returning empty structure.', name: 'WindowsSecureStorage');
        return {'credentials': [], 'token': null};
      }

      final Map<String, dynamic> parsedData = json.decode(contents) as Map<String, dynamic>;
      bool dataMigrated = false;

      // --- Migration Logic ---
      // Check for old individual portal_url and mac_address keys
      if (parsedData.containsKey('portal_url') && parsedData.containsKey('mac_address')) {
        final oldPortalUrl = parsedData['portal_url'] as String;
        final oldMacAddress = parsedData['mac_address'] as String;

        final oldCredential = Credential(portalUrl: oldPortalUrl, macAddress: oldMacAddress);

        // Add old credential to the new 'credentials' list if not already present
        List<dynamic> currentCredentials = parsedData['credentials'] as List<dynamic>? ?? [];
        if (!currentCredentials.any((c) => c['portalUrl'] == oldPortalUrl && c['macAddress'] == oldMacAddress)) {
          currentCredentials.add(oldCredential.toJson());
          parsedData['credentials'] = currentCredentials;
          developer.log('WindowsSecureStorage: Migrated old credentials to new list.', name: 'WindowsSecureStorage');
          dataMigrated = true;
        }

        // Remove old individual keys
        parsedData.remove('portal_url');
        parsedData.remove('mac_address');
        dataMigrated = true;
      }
      // --- End Migration Logic ---

      // If data was migrated, write the updated data back to the file
      if (dataMigrated) {
        await _writeRawData(parsedData);
      }

      return parsedData;
    } catch (e) {
      print('Error reading raw data from credentials file: $e');
      developer.log('WindowsSecureStorage: Error reading raw data: $e', name: 'WindowsSecureStorage');
      return {'credentials': [], 'token': null};
    }
  }

  // Internal method to write the raw JSON data to the file
  Future<void> _writeRawData(Map<String, dynamic> data) async {
    final file = await _localFile;
    try {
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      developer.log('WindowsSecureStorage: Raw data written: $data', name: 'WindowsSecureStorage');
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('Error writing raw data to credentials file: $e');
      developer.log('WindowsSecureStorage: Error writing raw data: $e', name: 'WindowsSecureStorage');
    }
  }

  @override
  Future<String?> read({required String key}) async {
    final rawData = await _readRawData();
    if (key == 'stalker_token') {
      return rawData['token'] as String?;
    }
    // For other keys, we might need to rethink if they are still used individually
    // For now, assume individual keys are for token only.
    return null;
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    final rawData = await _readRawData();
    if (key == 'stalker_token') {
      rawData['token'] = value;
    }
    // For other keys, we might need to rethink if they are still used individually
    await _writeRawData(rawData);
  }

  @override
  Future<void> delete({required String key}) async {
    final rawData = await _readRawData();
    if (key == 'stalker_token') {
      rawData.remove('token');
    }
    // For other keys, we might need to rethink if they are still used individually
    await _writeRawData(rawData);
  }

  @override
  Future<void> deleteAll() async {
    await _writeRawData({'credentials': [], 'token': null});
  }

  @override
  Future<List<Credential>> getCredentialsList() async {
    final rawData = await _readRawData();
    final credentialsJson = rawData['credentials'] as List<dynamic>?;
    if (credentialsJson == null) {
      developer.log('WindowsSecureStorage: Credentials list is null, returning empty.', name: 'WindowsSecureStorage');
      return [];
    }
    developer.log('WindowsSecureStorage: Retrieved credentials list: $credentialsJson', name: 'WindowsSecureStorage');
    return credentialsJson.map((json) => Credential.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveCredentialsList(List<Credential> credentials) async {
    final rawData = await _readRawData();
    rawData['credentials'] = credentials.map((c) => c.toJson()).toList();
    developer.log('WindowsSecureStorage: Saving credentials list: ${rawData['credentials']}', name: 'WindowsSecureStorage');
    await _writeRawData(rawData);
  }
}