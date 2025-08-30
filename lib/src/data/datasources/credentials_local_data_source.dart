import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:openiptv/src/data/providers/flutter_secure_storage_provider.dart';

import '../../core/models/credentials.dart';
import '../../core/models/m3u_credentials.dart';
import '../../core/models/stalker_credentials.dart';

part 'credentials_local_data_source.g.dart';

/// Manages the storage and retrieval of IPTV provider credentials using FlutterSecureStorage.
class CredentialsLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  static const String _credentialsKey = 'credentials';

  CredentialsLocalDataSource(this._secureStorage);

  /// Saves a new set of credentials to the local database.
  Future<void> saveCredentials(Credentials credentials) async {
    developer.log('Saving credentials with id: ${credentials.id}',
        name: 'CredentialsLocalDataSource');
    
    List<Credentials> currentCredentials = await getCredentials();
    currentCredentials.removeWhere((c) => c.id == credentials.id);
    currentCredentials.add(credentials);

    final String encodedJson = json.encode(currentCredentials.map((c) => c.toJson()).toList());
    await _secureStorage.write(key: _credentialsKey, value: encodedJson);
  }

  /// Retrieves all saved credentials from the local database.
  Future<List<Credentials>> getCredentials() async {
    String? credentialsJson = await _secureStorage.read(key: _credentialsKey);
    if (credentialsJson == null || credentialsJson.isEmpty) {
      developer.log('No credentials found in secure storage.', name: 'CredentialsLocalDataSource');
      return [];
    }

    final List<dynamic> decodedList = json.decode(credentialsJson);
    final List<Credentials> credentials = decodedList.map((json) {
      if (json['type'] == 'm3u') {
        return M3uCredentials.fromJson(json);
      } else if (json['type'] == 'stalker') {
        return StalkerCredentials.fromJson(json);
      } else {
        throw Exception('Unknown credential type');
      }
    }).toList();

    developer.log('Retrieved ${credentials.length} credentials from secure storage.',
        name: 'CredentialsLocalDataSource');
    return credentials;
  }

  /// Deletes a specific set of credentials from the local database using its ID.
  Future<void> deleteCredentials(String id) async {
    developer.log('Deleting credentials with id: $id',
        name: 'CredentialsLocalDataSource');
    List<Credentials> currentCredentials = await getCredentials();
    currentCredentials.removeWhere((c) => c.id == id);

    final String encodedJson = json.encode(currentCredentials.map((c) => c.toJson()).toList());
    await _secureStorage.write(key: _credentialsKey, value: encodedJson);
  }
}

@riverpod
CredentialsLocalDataSource credentialsLocalDataSource(
        Ref ref) =>
    CredentialsLocalDataSource(ref.watch(flutterSecureStorageProvider));