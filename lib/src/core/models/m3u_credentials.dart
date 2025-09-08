import 'credentials.dart';

/// Represents the credentials for an M3U playlist provider.
class M3uCredentials extends Credentials {
  /// The URL of the M3U playlist.
  final String m3uUrl;
  final String? username;
  final String? password;

  M3uCredentials({
    required this.m3uUrl,
    this.username,
    this.password,
  }) : super(id: '$m3uUrl-${username ?? ''}', name: 'M3U: ${username ?? m3uUrl}', type: 'm3u');

  factory M3uCredentials.fromJson(Map<String, dynamic> json) {
    return M3uCredentials(
      m3uUrl: json['m3uUrl'] as String,
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'm3uUrl': m3uUrl,
      'type': type, // Include type for deserialization
      'username': username,
      'password': password,
    };
  }
}