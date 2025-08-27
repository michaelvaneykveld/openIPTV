import '../../core/models/credential.dart'; // Import the new Credential model

abstract class SecureStorageInterface {
  Future<String?> read({required String key}); // Keep for token storage
  Future<void> write({required String key, required String? value}); // Keep for token storage
  Future<void> delete({required String key}); // Keep for token storage
  Future<void> deleteAll(); // Keep for token storage

  Future<List<Credential>> getCredentialsList();
  Future<void> saveCredentialsList(List<Credential> credentials);
}