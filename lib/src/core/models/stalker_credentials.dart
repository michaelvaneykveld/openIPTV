import 'package:meta/meta.dart';

import 'credentials.dart';

/// Represents the credentials needed to connect to a Stalker portal.
@immutable
class StalkerCredentials extends Credentials {
  final String baseUrl;
  final String macAddress;

  const StalkerCredentials({
    required this.baseUrl,
    required this.macAddress,
  });
}