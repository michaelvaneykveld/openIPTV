import 'package:meta/meta.dart';

/// Represents a single channel item from the Stalker API response.
///
/// This is an intermediate model used for parsing the raw JSON data from the
/// Stalker portal before converting it to the application's domain [Channel] model.
@immutable
class StalkerApiChannel {
  final String id;
  final String name;
  final String cmd; // This contains the stream URL, sometimes with a prefix like "ffmpeg "
  final String? logoUrl;
  final String number;

  const StalkerApiChannel({
    required this.id,
    required this.name,
    required this.cmd,
    this.logoUrl,
    required this.number,
  });

  /// Creates a [StalkerApiChannel] from a JSON map.
  factory StalkerApiChannel.fromJson(Map<String, dynamic> json) {
    return StalkerApiChannel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Channel',
      cmd: json['cmd']?.toString() ?? '',
      logoUrl: json['logo']?.toString(),
      number: json['number']?.toString() ?? '0',
    );
  }
}