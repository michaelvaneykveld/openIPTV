/// Dit is de abstracte interface voor secure storage.
/// Houdt de code testbaar en platform-onafhankelijk.
abstract class SecureStorageInterface {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
