import 'package:openiptv/src/core/models/credentials.dart';

class XtreamCredentials extends Credentials {
  final String url;
  final String username;
  final String password;

  XtreamCredentials({
    required super.id,
    required super.name,
    required this.url,
    required this.username,
    required this.password,
  }) : super(type: 'xtream');

  factory XtreamCredentials.fromJson(Map<String, dynamic> json) {
    return XtreamCredentials(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'username': username,
      'password': password,
    };
  }
}
