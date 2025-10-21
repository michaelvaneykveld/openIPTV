import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/utils/app_logger.dart';

class EpgProgramme {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String channelId;
  String? portalId;

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

  factory EpgProgramme.fromDbMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
        final numeric = int.tryParse(value);
        if (numeric != null) {
          return DateTime.fromMillisecondsSinceEpoch(numeric);
        }
      }
      throw ArgumentError('Unsupported timestamp value: $value');
    }

    return EpgProgramme(
      id: map[DatabaseHelper.columnEpgId] as String,
      title: map[DatabaseHelper.columnEpgTitle] as String,
      description: (map[DatabaseHelper.columnEpgDescription] as String?) ?? '',
      start: parseTimestamp(map[DatabaseHelper.columnEpgStart]),
      end: parseTimestamp(map[DatabaseHelper.columnEpgStop]),
      channelId: map[DatabaseHelper.columnEpgChannelId] as String,
      portalId: map[DatabaseHelper.columnPortalId] as String?,
    );
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
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'channel_id': channelId,
      'portal_id': portalId,
    };
  }
}
