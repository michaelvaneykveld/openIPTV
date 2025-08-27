import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openiptv/src/data/datasources/windows_secure_storage.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart'; // Import the new interface
import 'package:openiptv/src/data/datasources/flutter_secure_storage_wrapper.dart'; // Import the wrapper
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/data/datasources/local/credentials_local_data_source.dart';
import 'package:openiptv/src/data/repository/credentials_repository.dart';

part 'credentials_provider.g.dart';

@riverpod
SecureStorageInterface flutterSecureStorage(FlutterSecureStorageRef ref) { // Change return type
  if (Platform.isWindows) {
    return const WindowsSecureStorage();
  } else {
    return FlutterSecureStorageWrapper(const FlutterSecureStorage()); // Use the wrapper
  }
}

@riverpod
CredentialsLocalDataSource credentialsLocalDataSource(CredentialsLocalDataSourceRef ref) {
  return CredentialsLocalDataSourceImpl(ref.watch(flutterSecureStorageProvider));
}

@riverpod
CredentialsRepository credentialsRepository(CredentialsRepositoryRef ref) {
  return CredentialsRepositoryImpl(localDataSource: ref.watch(credentialsLocalDataSourceProvider));
}
