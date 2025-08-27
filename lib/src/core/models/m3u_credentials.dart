import 'package:meta/meta.dart';

import 'credentials.dart';

/// Represents the credentials needed to connect to an M3U source.
@immutable
class M3uCredentials extends Credentials {
  final String m3uUrl;

  const M3uCredentials({required this.m3uUrl});
}