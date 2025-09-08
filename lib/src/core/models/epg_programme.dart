
class EpgProgramme {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String channelId;
  int? portalId;

  EpgProgramme({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.channelId,
    this.portalId,
  });

  factory EpgProgramme.fromJson(Map<String, dynamic> json) {
    return EpgProgramme(
      id: json['id'],
      title: json['name'],
      description: json['descr'],
      start: DateTime.fromMillisecondsSinceEpoch(json['start_timestamp'] * 1000),
      end: DateTime.fromMillisecondsSinceEpoch(json['stop_timestamp'] * 1000),
      channelId: json['channel_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'channel_id': channelId,
      'portal_id': portalId,
    };
  }
}
