import 'package:openiptv/utils/app_logger.dart';

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

  factory EpgProgramme.fromStalkerJson(Map<String, dynamic> json) {
    final programme = EpgProgramme(
      id: json['id'],
      title: json['name'],
      description: json['descr'],
      start: DateTime.fromMillisecondsSinceEpoch(json['start_timestamp'] * 1000),
      end: DateTime.fromMillisecondsSinceEpoch(json['stop_timestamp'] * 1000),
      channelId: json['channel_id'],
    );
    _logEpgProgrammeDifferences(programme, 'Stalker');
    return programme;
  }

  static void _logEpgProgrammeDifferences(EpgProgramme programme, String type) {
    appLogger.d('[$type] EPG Programme created: ${programme.title}');
    appLogger.d('[$type] ID: ${programme.id}');
    appLogger.d('[$type] Title: ${programme.title}');
    appLogger.d('[$type] Description: ${programme.description}');
    appLogger.d('[$type] Start: ${programme.start}');
    appLogger.d('[$type] End: ${programme.end}');
    appLogger.d('[$type] Channel ID: ${programme.channelId}');
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