class EpgProgram {
  final String id;
  final String chId;
  final String name;
  final String? descr;
  final int startTimestamp;
  final int stopTimestamp;
  final String start;
  final String end;
  final int duration;
  final int hasArchive;

  EpgProgram({
    required this.id,
    required this.chId,
    required this.name,
    this.descr,
    required this.startTimestamp,
    required this.stopTimestamp,
    required this.start,
    required this.end,
    required this.duration,
    required this.hasArchive,
  });

  factory EpgProgram.fromJson(Map<String, dynamic> json) {
    return EpgProgram(
      id: json['id'] as String,
      chId: json['ch_id'] as String,
      name: json['name'] as String,
      descr: json['descr'] as String?,
      startTimestamp: json['start_timestamp'] as int,
      stopTimestamp: json['stop_timestamp'] as int,
      start: json['start'] as String,
      end: json['end'] as String,
      duration: json['duration'] as int,
      hasArchive: json['has_archive'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ch_id': chId,
      'name': name,
      'descr': descr,
      'start_timestamp': startTimestamp,
      'stop_timestamp': stopTimestamp,
      'start': start,
      'end': end,
      'duration': duration,
      'has_archive': hasArchive,
    };
  }
}
