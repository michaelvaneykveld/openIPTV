import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openiptv/src/data/datasources/windows_secure_storage.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/src/data/datasources/flutter_secure_storage_wrapper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/data/datasources/local/credentials_local_data_source.dart';
import 'package:openiptv/src/data/repository/credentials_repository.dart';

part 'credentials_provider.g.dart';

@riverpod
SecureStorageInterface flutterSecureStorage(Ref ref) {
  if (Platform.isWindows) {
    // Gebruik GEEN const → dit veroorzaakte de fout
    return WindowsSecureStorage();
  } else {
    final storage = FlutterSecureStorage();
    // Let op: named argument gebruiken
    return FlutterSecureStorageWrapper(storage: storage);
  }
}

@riverpod
CredentialsLocalDataSource credentialsLocalDataSource(Ref ref) {
  return CredentialsLocalDataSource(ref.watch(flutterSecureStorageProvider));
}

@riverpod
CredentialsRepository credentialsRepository(Ref ref) {
  return CredentialsRepositoryImpl(
    localDataSource: ref.watch(credentialsLocalDataSourceProvider),
  );
}