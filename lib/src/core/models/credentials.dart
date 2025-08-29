/// This is the abstract base class for all types of credentials.
/// It defines the common fields that every credential type will have.
abstract class Credentials {
  /// A unique identification for the credential, can be the URL or a custom name.
  final String id;

  /// A user-friendly name for this IPTV service.
  final String name;

  /// The type of credential (e.g., 'm3u', 'stalker').
  final String type;

  Credentials({required this.id, required this.name, required this.type});

  Map<String, dynamic> toJson();
}