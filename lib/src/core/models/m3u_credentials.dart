import 'package:hive/hive.dart';

import 'credentials.dart';

part 'm3u_credentials.g.dart';

/// Vertegenwoordigt de inloggegevens voor een M3U-playlist provider.
/// Deze klasse is ontworpen om opgeslagen te worden in Hive.
@HiveType(typeId: 1)
class M3uCredentials extends Credentials {
  /// De URL van de M3U-afspeellijst.
  @HiveField(2)
  final String m3uUrl;

  M3uCredentials({
    required super.id,
    required super.name,
    required this.m3uUrl,
  });
}
