import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/src/data/datasources/flutter_secure_storage_adapter.dart'; // Import the new adapter
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/data/datasources/local/credentials_local_data_source.dart';
import 'package:openiptv/src/data/repository/credentials_repository.dart';

import 'package:openiptv/src/core/models/credentials.dart';

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

final credentialsProvider = FutureProvider<List<Credentials>>((ref) async {
  final repository = ref.watch(credentialsRepositoryProvider);
  return await repository.getSavedCredentials();
});

@riverpod
Future<String?> portalId(Ref ref) async {
  final credentialsRepository = ref.watch(credentialsRepositoryProvider);
  final savedCredentials = await credentialsRepository.getSavedCredentials();

  if (savedCredentials.isNotEmpty) {
    final activeCredential = savedCredentials.first;
    return activeCredential.id;
  }
  return null; // No portalId found
}
