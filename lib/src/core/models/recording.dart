enum RecordingStatus {
  scheduled,
  recording,
  completed,
  failed,
  cancelled,
}

class Recording {
  final int? id;
  final String portalId;
  final String channelId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final RecordingStatus status;
  final String? filePath;
  final DateTime createdAt;

  const Recording({
    this.id,
    required this.portalId,
    required this.channelId,
    required this.title,
    required this.startTime,
    this.endTime,
    this.status = RecordingStatus.scheduled,
    this.filePath,
    required this.createdAt,
  });

  Recording copyWith({
    int? id,
    RecordingStatus? status,
    DateTime? endTime,
    String? filePath,
  }) {
    return Recording(
      id: id ?? this.id,
      portalId: portalId,
      channelId: channelId,
      title: title,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'portal_id': portalId,
      'channel_id': channelId,
      'title': title,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'status': status.index,
      'file_path': filePath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'] as int?,
      portalId: map['portal_id'] as String,
      channelId: map['channel_id'] as String,
      title: map['title'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      status: RecordingStatus.values[map['status'] as int? ?? 0],
      filePath: map['file_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
