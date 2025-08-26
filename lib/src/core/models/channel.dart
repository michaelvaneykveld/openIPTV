import 'package:meta/meta.dart';

/// Represents a single television channel.
///
/// This is a core domain model for the application, used across different
/// layers like the UI and the repository.
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

  // It's good practice to include equality checks and hashCode for model classes.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Channel{id: $id, name: $name, group: $group}';
  }
}

