class EpgProgramme {
  final String id;
  final String chId;
  final String name;
  final String? descr;
  final int startTimestamp;
  final int stopTimestamp;
  final int duration;
  final int? hasArchive;
  int portalId;

  EpgProgramme({
    required this.id,
    required this.chId,
    required this.name,
    this.descr,
    required this.startTimestamp,
    required this.stopTimestamp,
    required this.duration,
    this.hasArchive,
    required this.portalId,
  });

  factory EpgProgramme.fromJson(Map<String, dynamic> json) {
    return EpgProgramme(
      id: json['id'] as String,
      chId: json['ch_id'] as String,
      name: json['name'] as String,
      descr: json['descr'] as String?,
      startTimestamp: json['start_timestamp'] as int,
      stopTimestamp: json['stop_timestamp'] as int,
      duration: json['duration'] as int,
      hasArchive: json['has_archive'] as int?,
      portalId: 0, // Will be set later
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
      'duration': duration,
      'has_archive': hasArchive,
      'portalId': portalId,
    };
  }
}