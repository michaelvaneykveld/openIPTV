import 'package:openiptv/src/core/models/credentials.dart'; // Import the Credentials model (plural)
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart'; // Import the SecureStorageInterface

abstract class CredentialsLocalDataSource {
  Future<void> saveCredential(Credentials credential);
  Future<List<Credentials>> getSavedCredentials();
  Future<void> deleteCredential(
    String credentialId,
  ); // Changed to use ID for deletion
  Future<void> deleteAllCredentials(); // To delete all credentials
}

class CredentialsLocalDataSourceImpl implements CredentialsLocalDataSource {
  final SecureStorageInterface _secureStorage;

  CredentialsLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> saveCredential(Credentials credential) async {
    await _secureStorage.saveCredentials(credential);
  }

  @override
  Future<List<Credentials>> getSavedCredentials() async {
    return await _secureStorage.getCredentialsList();
  }

  @override
  Future<void> deleteCredential(String credentialId) async {
    await _secureStorage.deleteCredentialById(credentialId);
  }

  @override
  Future<void> deleteAllCredentials() async {
    await _secureStorage.clearAllCredentials();
  }
}
