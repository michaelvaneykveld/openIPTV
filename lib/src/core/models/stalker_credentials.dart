import 'package:hive/hive.dart';

import 'credentials.dart';

part 'stalker_credentials.g.dart';

/// Represents the credentials for a Stalker Portal provider.
/// This class is designed to be stored in Hive.
@HiveType(typeId: 2)
class StalkerCredentials extends Credentials {
  /// The base URL of the Stalker Portal.
  /// Example: http://portal.example.com
  @HiveField(2)
  final String baseUrl;

  /// The MAC address used for authentication.
  /// Example: 00:1A:79:XX:XX:XX
  @HiveField(3)
  final String macAddress;

  StalkerCredentials({
    required super.id,
    required super.name,
    required this.baseUrl,
    required this.macAddress,
  });
}
