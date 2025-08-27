import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models/credentials.dart';
import '../../core/models/m3u_credentials.dart';
import '../../core/models/stalker_credentials.dart';

part 'credentials_local_data_source.g.dart';

/// Manages the storage and retrieval of IPTV provider credentials using Hive.
class CredentialsLocalDataSource {
  static const String _boxName = 'credentials';

  /// Opens the Hive box for credentials.
  /// This must be called before any other method.
  static Future<void> openBox() async {
    // We need to register all subtypes of Credentials before opening the box.
    if (!Hive.isAdapterRegistered(M3uCredentialsAdapter().typeId)) {
      Hive.registerAdapter(M3uCredentialsAdapter());
    }
    if (!Hive.isAdapterRegistered(StalkerCredentialsAdapter().typeId)) {
      Hive.registerAdapter(StalkerCredentialsAdapter());
    }
    await Hive.openBox<Credentials>(_boxName);
  }

  /// Returns the Hive box for credentials.
  Box<Credentials> get _credentialsBox => Hive.box<Credentials>(_boxName);

  /// Saves a new set of credentials to the local database.
  Future<void> saveCredentials(Credentials credentials) async {
    developer.log('Saving credentials with id: ${credentials.id}',
        name: 'CredentialsLocalDataSource');
    await _credentialsBox.put(credentials.id, credentials);
  }

  /// Retrieves all saved credentials from the local database.
  List<Credentials> getCredentials() {
    final credentials = _credentialsBox.values.toList();
    developer.log('Retrieved ${credentials.length} credentials from local database.',
        name: 'CredentialsLocalDataSource');
    return credentials;
  }

  /// Deletes a specific set of credentials from the local database using its ID.
  Future<void> deleteCredentials(String id) async {
    developer.log('Deleting credentials with id: $id',
        name: 'CredentialsLocalDataSource');
    await _credentialsBox.delete(id);
  }
}

@riverpod
CredentialsLocalDataSource credentialsLocalDataSource(
        CredentialsLocalDataSourceRef ref) =>
    CredentialsLocalDataSource();
