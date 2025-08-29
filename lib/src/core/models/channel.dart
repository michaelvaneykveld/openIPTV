/// The Channel model, now adapted for Hive storage.
/// Annotations are used by the hive_generator to create a TypeAdapter.
class Channel {
  final String id;
  final String name;
  final String? logoUrl;
  final String streamUrl;
  final String group;
  final String epgId;

  Channel(
      {required this.id,
      required this.name,
      this.logoUrl,
      required this.streamUrl,
      required this.group,
      required this.epgId});
}