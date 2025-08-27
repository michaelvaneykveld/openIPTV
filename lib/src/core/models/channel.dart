import 'package:hive/hive.dart';

part 'channel.g.dart';

/// The Channel model, now adapted for Hive storage.
/// Annotations are used by the hive_generator to create a TypeAdapter.
@HiveType(typeId: 0)
class Channel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? logoUrl;

  @HiveField(3)
  final String streamUrl;

  @HiveField(4)
  final String group;

  @HiveField(5)
  final String epgId;

  Channel(
      {required this.id,
      required this.name,
      this.logoUrl,
      required this.streamUrl,
      required this.group,
      required this.epgId});
}
