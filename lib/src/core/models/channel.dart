import 'package:meta/meta.dart';

/// Represents a single television channel.
/// This is a core domain model for the application.
@immutable
class Channel {
  final String id;
  final String name;
  final String? logoUrl;
  final String streamUrl;
  final String group;
  final String epgId;

  const Channel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.streamUrl,
    required this.group,
    required this.epgId,
  });
}