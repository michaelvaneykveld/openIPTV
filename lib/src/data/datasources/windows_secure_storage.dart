import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/src/core/models/credential.dart';

/// Windows-implementatie van SecureStorageInterface.
/// Voor nu zijn de methodes nog niet geïmplementeerd en gooien ze een UnimplementedError.
class WindowsSecureStorage implements SecureStorageInterface {
  WindowsSecureStorage(); // <-- geen const meer

  @override
  Future<void> write({required String key, required String? value}) async {
    throw UnimplementedError('Windows secure storage write not implemented');
  }

  @override
  Future<String?> read({required String key}) async {
    throw UnimplementedError('Windows secure storage read not implemented');
  }

  @override
  Future<void> delete({required String key}) async {
    throw UnimplementedError('Windows secure storage delete not implemented');
  }

  @override
  Future<void> deleteAll() async {
    throw UnimplementedError('Windows secure storage deleteAll not implemented');
  }

  @override
  Future<List<Credential>> getCredentialsList() async {
    throw UnimplementedError('Windows secure storage getCredentialsList not implemented');
  }

  @override
  Future<void> saveCredentialsList(List<Credential> credentials) async {
    throw UnimplementedError('Windows secure storage saveCredentialsList not implemented');
  }
}
