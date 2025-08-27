import 'package:hive/hive.dart';

/// Dit is de abstracte basisklasse voor alle soorten inloggegevens.
/// Het definieert de gemeenschappelijke velden die elke credential-type zal hebben.
/// De subklassen (M3uCredentials, StalkerCredentials) zullen de specifieke
/// HiveType-annotaties krijgen.
abstract class Credentials {
  /// Een unieke identificatie voor de credential, kan de URL of een eigen naam zijn.
  @HiveField(0)
  final String id;

  /// Een gebruiksvriendelijke naam voor deze IPTV-dienst.
  @HiveField(1)
  final String name;

  Credentials({required this.id, required this.name});
}
