import 'credentials.dart';

/// Represents the credentials for a Stalker Portal provider.
class StalkerCredentials extends Credentials {
  /// The base URL of the Stalker Portal.
  /// Example: http://portal.example.com
  final String baseUrl;

  /// The MAC address used for authentication.
  /// Example: 00:1A:79:XX:XX:XX
  final String macAddress;

  StalkerCredentials({
    required super.id,
    required super.name,
    required this.baseUrl,
    required this.macAddress,
  }) : super(type: 'stalker'); // Add type for serialization

  factory StalkerCredentials.fromJson(Map<String, dynamic> json) {
    return StalkerCredentials(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      macAddress: json['macAddress'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'macAddress': macAddress,
      'type': type, // Include type for deserialization
    };
  }
}