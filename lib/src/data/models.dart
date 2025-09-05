class Genre {
  final String id;
  final String title;
  final String? alias;
  final int? censored;
  final String? modified;
  final int? number;

  Genre({
    required this.id,
    required this.title,
    this.alias,
    this.censored,
    this.modified,
    this.number,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as String,
      title: json['title'] as String,
      alias: json['alias'] as String?,
      censored: json['censored'] as int?,
      modified: json['modified'] as String?,
      number: json['number'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'alias': alias,
      'censored': censored,
      'modified': modified,
      'number': number,
    };
  }
}

class Channel {
  final String id;
  final String name;
  final String? number;
  final String? logoUrl;
  final String? streamUrl;
  final String? group;
  final String? genreId;
  final String? epgId;
  final String? epg;
  final String? genresStr;
  final String? curPlaying;
  final int? status;
  final int? hd;
  final int? censored;
  final int? fav;
  final int? locked;
  final int? archive;
  final int? pvr;
  final int? enableTvArchive;
  final int? tvArchiveDuration;
  final int? allowPvr;
  final int? allowLocalPvr;
  final int? allowRemotePvr;
  final int? allowLocalTimeshift;
  final String? cmd;
  final String? cmd1;
  final String? cmd2;
  final String? cmd3;
  final String? cost;
  final String? count;
  final String? baseCh;
  final String? serviceId;
  final String? bonusCh;
  final String? volumeCorrection;
  final String? mcCmd;
  final String? wowzaTmpLink;
  final String? wowzaDvr;
  final String? useHttpTmpLink;
  final String? monitoringStatus;
  final int? enableMonitoring;
  final int? enableWowzaLoadBalancing;
  final String? correctTime;
  final String? nimbleDvr;
  final String? modified;
  final String? nginxSecureLink;
  final int? open;
  final int? useLoadBalancing;

  Channel({
    required this.id,
    required this.name,
    this.number,
    this.logoUrl,
    this.streamUrl,
    this.group,
    this.genreId,
    this.epgId,
    this.epg,
    this.genresStr,
    this.curPlaying,
    this.status,
    this.hd,
    this.censored,
    this.fav,
    this.locked,
    this.archive,
    this.pvr,
    this.enableTvArchive,
    this.tvArchiveDuration,
    this.allowPvr,
    this.allowLocalPvr,
    this.allowRemotePvr,
    this.allowLocalTimeshift,
    this.cmd,
    this.cmd1,
    this.cmd2,
    this.cmd3,
    this.cost,
    this.count,
    this.baseCh,
    this.serviceId,
    this.bonusCh,
    this.volumeCorrection,
    this.mcCmd,
    this.wowzaTmpLink,
    this.wowzaDvr,
    this.useHttpTmpLink,
    this.monitoringStatus,
    this.enableMonitoring,
    this.enableWowzaLoadBalancing,
    this.correctTime,
    this.nimbleDvr,
    this.modified,
    this.nginxSecureLink,
    this.open,
    this.useLoadBalancing,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as String?,
      logoUrl: json['logo'] as String?,
      streamUrl: json['stream_url'] as String?,
      group: json['group'] as String?,
      genreId: json['genre_id'] as String?,
      epgId: json['xmltv_id'] as String?,
      epg: json['epg'] as String?,
      genresStr: json['genres_str'] as String?,
      curPlaying: json['cur_playing'] as String?,
      status: json['status'] as int?,
      hd: json['hd'] as int?,
      censored: json['censored'] as int?,
      fav: json['fav'] as int?,
      locked: json['locked'] as int?,
      archive: json['archive'] as int?,
      pvr: json['pvr'] as int?,
      enableTvArchive: json['enable_tv_archive'] as int?,
      tvArchiveDuration: json['tv_archive_duration'] as int?,
      allowPvr: json['allow_pvr'] as int?,
      allowLocalPvr: json['allow_local_pvr'] as int?,
      allowRemotePvr: json['allow_remote_pvr'] as int?,
      allowLocalTimeshift: json['allow_local_timeshift'] as int?,
      cmd: json['cmd'] as String?,
      cmd1: json['cmd_1'] as String?,
      cmd2: json['cmd_2'] as String?,
      cmd3: json['cmd_3'] as String?,
      cost: json['cost'] as String?,
      count: json['count'] as String?,
      baseCh: json['base_ch'] as String?,
      serviceId: json['service_id'] as String?,
      bonusCh: json['bonus_ch'] as String?,
      volumeCorrection: json['volume_correction'] as String?,
      mcCmd: json['mc_cmd'] as String?,
      wowzaTmpLink: json['wowza_tmp_link'] as String?,
      wowzaDvr: json['wowza_dvr'] as String?,
      useHttpTmpLink: json['use_http_tmp_link'] as String?,
      monitoringStatus: json['monitoring_status'] as String?,
      enableMonitoring: json['enable_monitoring'] as int?,
      enableWowzaLoadBalancing: json['enable_wowza_load_balancing'] as int?,
      correctTime: json['correct_time'] as String?,
      nimbleDvr: json['nimble_dvr'] as String?,
      modified: json['modified'] as String?,
      nginxSecureLink: json['nginx_secure_link'] as String?,
      open: json['open'] as int?,
      useLoadBalancing: json['use_load_balancing'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'logo': logoUrl,
      'stream_url': streamUrl,
      'group': group,
      'genre_id': genreId,
      'xmltv_id': epgId,
      'epg': epg,
      'genres_str': genresStr,
      'cur_playing': curPlaying,
      'status': status,
      'hd': hd,
      'censored': censored,
      'fav': fav,
      'locked': locked,
      'archive': archive,
      'pvr': pvr,
      'enable_tv_archive': enableTvArchive,
      'tv_archive_duration': tvArchiveDuration,
      'allow_pvr': allowPvr,
      'allow_local_pvr': allowLocalPvr,
      'allow_remote_pvr': allowRemotePvr,
      'allow_local_timeshift': allowLocalTimeshift,
      'cmd': cmd,
      'cmd_1': cmd1,
      'cmd_2': cmd2,
      'cmd_3': cmd3,
      'cost': cost,
      'count': count,
      'base_ch': baseCh,
      'service_id': serviceId,
      'bonus_ch': bonusCh,
      'volume_correction': volumeCorrection,
      'mc_cmd': mcCmd,
      'wowza_tmp_link': wowzaTmpLink,
      'wowza_dvr': wowzaDvr,
      'use_http_tmp_link': useHttpTmpLink,
      'monitoring_status': monitoringStatus,
      'enable_monitoring': enableMonitoring,
      'enable_wowza_load_balancing': enableWowzaLoadBalancing,
      'correct_time': correctTime,
      'nimble_dvr': nimbleDvr,
      'modified': modified,
      'nginx_secure_link': nginxSecureLink,
      'open': open,
      'use_load_balancing': useLoadBalancing,
    };
  }

  Channel copyWith({
    String? id,
    String? name,
    String? number,
    String? logoUrl,
    String? streamUrl,
    String? group,
    String? genreId,
    String? epgId,
    String? epg,
    String? genresStr,
    String? curPlaying,
    int? status,
    int? hd,
    int? censored,
    int? fav,
    int? locked,
    int? archive,
    int? pvr,
    int? enableTvArchive,
    int? tvArchiveDuration,
    int? allowPvr,
    int? allowLocalPvr,
    int? allowRemotePvr,
    int? allowLocalTimeshift,
    String? cmd,
    String? cmd1,
    String? cmd2,
    String? cmd3,
    String? cost,
    String? count,
    String? baseCh,
    String? serviceId,
    String? bonusCh,
    String? volumeCorrection,
    String? mcCmd,
    String? wowzaTmpLink,
    String? wowzaDvr,
    String? useHttpTmpLink,
    String? monitoringStatus,
    int? enableMonitoring,
    int? enableWowzaLoadBalancing,
    String? correctTime,
    String? nimbleDvr,
    String? modified,
    String? nginxSecureLink,
    int? open,
    int? useLoadBalancing,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      group: group ?? this.group,
      genreId: genreId ?? this.genreId,
      epgId: epgId ?? this.epgId,
      epg: epg ?? this.epg,
      genresStr: genresStr ?? this.genresStr,
      curPlaying: curPlaying ?? this.curPlaying,
      status: status ?? this.status,
      hd: hd ?? this.hd,
      censored: censored ?? this.censored,
      fav: fav ?? this.fav,
      locked: locked ?? this.locked,
      archive: archive ?? this.archive,
      pvr: pvr ?? this.pvr,
      enableTvArchive: enableTvArchive ?? this.enableTvArchive,
      tvArchiveDuration: tvArchiveDuration ?? this.tvArchiveDuration,
      allowPvr: allowPvr ?? this.allowPvr,
      allowLocalPvr: allowLocalPvr ?? this.allowLocalPvr,
      allowRemotePvr: allowRemotePvr ?? this.allowRemotePvr,
      allowLocalTimeshift: allowLocalTimeshift ?? this.allowLocalTimeshift,
      cmd: cmd ?? this.cmd,
      cmd1: cmd1 ?? this.cmd1,
      cmd2: cmd2 ?? this.cmd2,
      cmd3: cmd3 ?? this.cmd3,
      cost: cost ?? this.cost,
      count: count ?? this.count,
      baseCh: baseCh ?? this.baseCh,
      serviceId: serviceId ?? this.serviceId,
      bonusCh: bonusCh ?? this.bonusCh,
      volumeCorrection: volumeCorrection ?? this.volumeCorrection,
      mcCmd: mcCmd ?? this.mcCmd,
      wowzaTmpLink: wowzaTmpLink ?? this.wowzaTmpLink,
      wowzaDvr: wowzaDvr ?? this.wowzaDvr,
      useHttpTmpLink: useHttpTmpLink ?? this.useHttpTmpLink,
      monitoringStatus: monitoringStatus ?? this.monitoringStatus,
      enableMonitoring: enableMonitoring ?? this.enableMonitoring,
      enableWowzaLoadBalancing: enableWowzaLoadBalancing ?? this.enableWowzaLoadBalancing,
      correctTime: correctTime ?? this.correctTime,
      nimbleDvr: nimbleDvr ?? this.nimbleDvr,
      modified: modified ?? this.modified,
      nginxSecureLink: nginxSecureLink ?? this.nginxSecureLink,
      open: open ?? this.open,
      useLoadBalancing: useLoadBalancing ?? this.useLoadBalancing,
    );
  }
}

class VodCategory {
  final String id;
  final String title;
  final String? alias;
  final int? censored;

  VodCategory({
    required this.id,
    required this.title,
    this.alias,
    this.censored,
  });

  factory VodCategory.fromJson(Map<String, dynamic> json) {
    return VodCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      alias: json['alias'] as String?,
      censored: json['censored'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'alias': alias,
      'censored': censored,
    };
  }
}

class VodContent {
  final String id;
  final String name;
  final String? cmd;
  final String? logo;
  final String? description;
  final String? year;
  final String? director;
  final String? actors;
  final String? duration;
  final String? categoryId;

  VodContent({
    required this.id,
    required this.name,
    this.cmd,
    this.logo,
    this.description,
    this.year,
    this.director,
    this.actors,
    this.duration,
    this.categoryId,
  });

  factory VodContent.fromJson(Map<String, dynamic> json) {
    return VodContent(
      id: json['id'] as String,
      name: json['name'] as String,
      cmd: json['cmd'] as String?,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      year: json['year'] as String?,
      director: json['director'] as String?,
      actors: json['actors'] as String?,
      duration: json['duration'] as String?,
      categoryId: json['category_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cmd': cmd,
      'logo': logo,
      'description': description,
      'year': year,
      'director': director,
      'actors': actors,
      'duration': duration,
      'category_id': categoryId,
    };
  }
}
