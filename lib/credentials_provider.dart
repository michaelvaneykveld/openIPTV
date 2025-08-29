import 'storage/secure_storage_interface.dart';
import 'storage/flutter_secure_storage_adapter.dart';

/// Geeft de juiste concrete implementatie van SecureStorageInterface terug.
/// Omdat FlutterSecureStorage cross-platform werkt, is er geen platform-specifieke logica nodig.
SecureStorageInterface getSecureStorage() {
  return FlutterSecureStorageAdapter();
}
