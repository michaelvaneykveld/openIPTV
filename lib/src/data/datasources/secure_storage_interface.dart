import '../../core/models/credentials.dart'; // Import the Credentials model (plural)

abstract class SecureStorageInterface {
  Future<String?> read({required String key}); // Keep for token storage
  Future<void> write({
    required String key,
    required String? value,
  }); // Keep for token storage
  Future<void> delete({required String key}); // Keep for token storage

  Future<List<Credentials>> getCredentialsList();
  Future<void> saveCredentials(Credentials credentials); // Changed to singular
  Future<void> deleteCredentialById(String credentialId);
  Future<void> clearAllCredentials(); // Added this method
}
