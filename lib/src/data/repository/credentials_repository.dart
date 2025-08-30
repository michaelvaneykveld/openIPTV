import 'package:openiptv/src/core/models/credentials.dart'; // Import the Credentials model (plural)
import 'package:openiptv/src/data/datasources/local/credentials_local_data_source.dart';

abstract class CredentialsRepository {
  Future<void> saveCredential(Credentials credential);
  Future<List<Credentials>> getSavedCredentials();
  Future<void> deleteCredential(String credentialId); // Changed to use ID for deletion
  Future<void> deleteAllCredentials();
}

class CredentialsRepositoryImpl implements CredentialsRepository {
  final CredentialsLocalDataSource localDataSource;

  CredentialsRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveCredential(Credentials credential) {
    return localDataSource.saveCredential(credential);
  }

  @override
  Future<List<Credentials>> getSavedCredentials() {
    return localDataSource.getSavedCredentials();
  }

  @override
  Future<void> deleteCredential(String credentialId) {
    return localDataSource.deleteCredential(credentialId);
  }

  @override
  Future<void> deleteAllCredentials() {
    return localDataSource.deleteAllCredentials();
  }
}
