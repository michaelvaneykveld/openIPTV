class Reminder {
  final int? id;
  final String portalId;
  final String channelId;
  final String programTitle;
  final DateTime startTime;
  final int? notificationId;
  final DateTime createdAt;

  const Reminder({
    this.id,
    required this.portalId,
    required this.channelId,
    required this.programTitle,
    required this.startTime,
    this.notificationId,
    required this.createdAt,
  });

  Reminder copyWith({
    int? id,
    int? notificationId,
  }) {
    return Reminder(
      id: id ?? this.id,
      portalId: portalId,
      channelId: channelId,
      programTitle: programTitle,
      startTime: startTime,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'portal_id': portalId,
      'channel_id': channelId,
      'program_title': programTitle,
      'start_time': startTime.millisecondsSinceEpoch,
      'notification_id': notificationId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      portalId: map['portal_id'] as String,
      channelId: map['channel_id'] as String,
      programTitle: map['program_title'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      notificationId: map['notification_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
