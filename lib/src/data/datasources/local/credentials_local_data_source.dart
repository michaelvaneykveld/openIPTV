import 'package:openiptv/src/core/models/credential.dart'; // Import the Credential model
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart'; // Import the SecureStorageInterface

abstract class CredentialsLocalDataSource {
  Future<void> saveCredential(Credential credential);
  Future<List<Credential>> getSavedCredentials();
  Future<void> deleteCredential(Credential credential); // To delete a specific credential
  Future<void> deleteAllCredentials(); // To delete all credentials
}

class CredentialsLocalDataSourceImpl implements CredentialsLocalDataSource {
  final SecureStorageInterface _secureStorage;

  CredentialsLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> saveCredential(Credential credential) async {
    final currentCredentials = await _secureStorage.getCredentialsList();
    // Check if the credential already exists to avoid duplicates
    if (!currentCredentials.any((c) => c.portalUrl == credential.portalUrl && c.macAddress == credential.macAddress)) {
      currentCredentials.add(credential);
      await _secureStorage.saveCredentialsList(currentCredentials);
    }
  }

  @override
  Future<List<Credential>> getSavedCredentials() async {
    return await _secureStorage.getCredentialsList();
  }

  @override
  Future<void> deleteCredential(Credential credential) async {
    final currentCredentials = await _secureStorage.getCredentialsList();
    currentCredentials.removeWhere((c) => c.portalUrl == credential.portalUrl && c.macAddress == credential.macAddress);
    await _secureStorage.saveCredentialsList(currentCredentials);
  }

  @override
  Future<void> deleteAllCredentials() async {
    await _secureStorage.saveCredentialsList([]);
  }
}