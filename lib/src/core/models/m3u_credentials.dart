import 'credentials.dart';

/// Represents the credentials for an M3U playlist provider.
class M3uCredentials extends Credentials {
  /// The URL of the M3U playlist.
  final String m3uUrl;

  M3uCredentials({
    required super.id,
    required super.name,
    required this.m3uUrl,
  }) : super(type: 'm3u'); // Add type for serialization

  factory M3uCredentials.fromJson(Map<String, dynamic> json) {
    return M3uCredentials(
      id: json['id'] as String,
      name: json['name'] as String,
      m3uUrl: json['m3uUrl'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'm3uUrl': m3uUrl,
      'type': type, // Include type for deserialization
    };
  }
}