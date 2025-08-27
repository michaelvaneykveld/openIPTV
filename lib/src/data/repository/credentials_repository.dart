import 'package:openiptv/src/core/models/credential.dart'; // Import the Credential model
import 'package:openiptv/src/data/datasources/local/credentials_local_data_source.dart';

abstract class CredentialsRepository {
  Future<void> saveCredential(Credential credential);
  Future<List<Credential>> getSavedCredentials();
  Future<void> deleteCredential(Credential credential);
  Future<void> deleteAllCredentials();
}

class CredentialsRepositoryImpl implements CredentialsRepository {
  final CredentialsLocalDataSource localDataSource;

  CredentialsRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveCredential(Credential credential) {
    return localDataSource.saveCredential(credential);
  }

  @override
  Future<List<Credential>> getSavedCredentials() {
    return localDataSource.getSavedCredentials();
  }

  @override
  Future<void> deleteCredential(Credential credential) {
    return localDataSource.deleteCredential(credential);
  }

  @override
  Future<void> deleteAllCredentials() {
    return localDataSource.deleteAllCredentials();
  }
}