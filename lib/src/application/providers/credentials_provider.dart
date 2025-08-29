import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/src/data/datasources/flutter_secure_storage_adapter.dart'; // Import the new adapter
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/data/datasources/local/credentials_local_data_source.dart';
import 'package:openiptv/src/data/repository/credentials_repository.dart';

part 'credentials_provider.g.dart';

@riverpod
SecureStorageInterface flutterSecureStorage(Ref ref) {
  return FlutterSecureStorageAdapter();
}

@riverpod
CredentialsLocalDataSource credentialsLocalDataSource(Ref ref) {
  return CredentialsLocalDataSourceImpl(ref.watch(flutterSecureStorageProvider));
}

@riverpod
CredentialsRepository credentialsRepository(Ref ref) {
  return CredentialsRepositoryImpl(
    localDataSource: ref.watch(credentialsLocalDataSourceProvider),
  );
}
