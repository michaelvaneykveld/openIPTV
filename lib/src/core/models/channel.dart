import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel_cmd.dart';

/// The Channel model, now adapted for Hive storage.
/// Annotations are used by the hive_generator to create a TypeAdapter.
class Channel {
  final String id;
  final String name;
  final String? number;
  final String? logo;
  final String? genreId;
  final String? xmltvId;
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
  final List<ChannelCmd>? cmds; // List of ChannelCmd objects
  final String? streamUrl; // Added streamUrl
  final String? group; // Added group
  final String? epgId; // Added epgId

  Channel({
    required this.id,
    required this.name,
    this.number,
    this.logo,
    this.genreId,
    this.xmltvId,
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
    this.cmds,
    this.streamUrl,
    this.group,
    this.epgId,
  });

  factory Channel.fromStalkerJson(Map<String, dynamic> json) {
    final List<dynamic>? cmdsJson = json['cmds'] as List<dynamic>?;
    final List<ChannelCmd>? cmds = cmdsJson
        ?.whereType<Map<String, dynamic>>()
        .map(
          (cmdJson) => ChannelCmd.fromJson(
            cmdJson,
            channelId: _asString(json['id']) ?? '',
          ),
        )
        .toList();

    final channel = Channel(
      id: _asString(json['id']) ?? '',
      name: _asString(json['name']) ?? 'Unknown Channel',
      number: _asString(json['number']),
      logo: _asString(json['logo']),
      genreId: _asString(json['tv_genre_id']),
      xmltvId: _asString(json['xmltv_id']),
      epg: _asString(_preferString(json['epg'])),
      genresStr: _asString(json['genres_str']),
      curPlaying: _asString(json['cur_playing']),
      status: _asInt(json['status']),
      hd: _asInt(json['hd']),
      censored: _asInt(json['censored']),
      fav: _asInt(json['fav']),
      locked: _asInt(json['locked']),
      archive: _asInt(json['archive']),
      pvr: _asInt(json['pvr']),
      enableTvArchive: _asInt(json['enable_tv_archive']),
      tvArchiveDuration: _asInt(json['tv_archive_duration']),
      allowPvr: _asInt(json['allow_pvr']),
      allowLocalPvr: _asInt(json['allow_local_pvr']),
      allowRemotePvr: _asInt(json['allow_remote_pvr']),
      allowLocalTimeshift: _asInt(json['allow_local_timeshift']),
      cmd: _asString(json['cmd']),
      cmd1: _asString(json['cmd_1']),
      cmd2: _asString(json['cmd_2']),
      cmd3: _asString(json['cmd_3']),
      cost: _asString(json['cost']),
      count: _asString(json['count']),
      baseCh: _asString(json['base_ch']),
      serviceId: _asString(json['service_id']),
      bonusCh: _asString(json['bonus_ch']),
      volumeCorrection: _asString(json['volume_correction']),
      mcCmd: _asString(json['mc_cmd']),
      wowzaTmpLink: _asString(json['wowza_tmp_link']),
      wowzaDvr: _asString(json['wowza_dvr']),
      useHttpTmpLink: _asString(json['use_http_tmp_link']),
      monitoringStatus: _asString(json['monitoring_status']),
      enableMonitoring: _asInt(json['enable_monitoring']),
      enableWowzaLoadBalancing: _asInt(json['enable_wowza_load_balancing']),
      correctTime: _asString(json['correct_time']),
      nimbleDvr: _asString(json['nimble_dvr']),
      modified: _asString(json['modified']),
      nginxSecureLink: _asString(json['nginx_secure_link']),
      open: _asInt(json['open']),
      useLoadBalancing: _asInt(json['use_load_balancing']),
      cmds: cmds,
      streamUrl: _asString(json['url']),
      group: _asString(json['group_title']),
      epgId: _asString(json['epg_id']),
    );
    return channel;
  }

  static String? _preferString(dynamic value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  factory Channel.fromM3UEntry(
    Map<String, String> attributes,
    String streamUrl,
  ) {
    final name = attributes['title'] ?? 'Unnamed Channel';
    final tvgId = attributes['tvg-id'];
    final channel = Channel(
      id: (tvgId != null && tvgId.isNotEmpty) ? tvgId : streamUrl,
      name: name,
      logo: attributes['tvg-logo'] ?? '',
      streamUrl: streamUrl,
      group: attributes['group-title'] ?? 'Uncategorized',
      epgId: tvgId ?? name,
    );
    return channel;
  }

  factory Channel.fromXtreamJson(Map<String, dynamic> json) {
    final channel = Channel(
      id: json['stream_id'].toString(),
      name: json['name'] as String,
      logo: json['stream_icon'] as String?,
      streamUrl: json['stream_url'] as String?,
      group: json['category_name'] as String?,
      epgId: json['epg_channel_id'] as String?,
      number: json['num'].toString(),
    );
    return channel;
  }

  factory Channel.fromDbMap(Map<String, dynamic> map) {
    return Channel(
      id: map[DatabaseHelper.columnChannelId] as String,
      name: map[DatabaseHelper.columnChannelName] as String,
      number: map[DatabaseHelper.columnChannelNumber] as String?,
      logo: map[DatabaseHelper.columnChannelLogo] as String?,
      genreId: map[DatabaseHelper.columnChannelGenreId] as String?,
      xmltvId: map[DatabaseHelper.columnChannelXmltvId] as String?,
      epg: map[DatabaseHelper.columnChannelEpg] as String?,
      genresStr: map[DatabaseHelper.columnChannelGenresStr] as String?,
      curPlaying: map[DatabaseHelper.columnChannelCurPlaying] as String?,
      status: map[DatabaseHelper.columnChannelStatus] as int?,
      hd: map[DatabaseHelper.columnChannelHd] as int?,
      censored: map[DatabaseHelper.columnChannelCensored] as int?,
      fav: map[DatabaseHelper.columnChannelFav] as int?,
      locked: map[DatabaseHelper.columnChannelLocked] as int?,
      archive: map[DatabaseHelper.columnChannelArchive] as int?,
      pvr: map[DatabaseHelper.columnChannelPvr] as int?,
      enableTvArchive: map[DatabaseHelper.columnChannelEnableTvArchive] as int?,
      tvArchiveDuration:
          map[DatabaseHelper.columnChannelTvArchiveDuration] as int?,
      allowPvr: map[DatabaseHelper.columnChannelAllowPvr] as int?,
      allowLocalPvr: map[DatabaseHelper.columnChannelAllowLocalPvr] as int?,
      allowRemotePvr: map[DatabaseHelper.columnChannelAllowRemotePvr] as int?,
      allowLocalTimeshift:
          map[DatabaseHelper.columnChannelAllowLocalTimeshift] as int?,
      cmd: map[DatabaseHelper.columnChannelCmd] as String?,
      cmd1: map[DatabaseHelper.columnChannelCmd1] as String?,
      cmd2: map[DatabaseHelper.columnChannelCmd2] as String?,
      cmd3: map[DatabaseHelper.columnChannelCmd3] as String?,
      cost: map[DatabaseHelper.columnChannelCost] as String?,
      count: map[DatabaseHelper.columnChannelCount] as String?,
      baseCh: map[DatabaseHelper.columnChannelBaseCh] as String?,
      serviceId: map[DatabaseHelper.columnChannelServiceId] as String?,
      bonusCh: map[DatabaseHelper.columnChannelBonusCh] as String?,
      volumeCorrection:
          map[DatabaseHelper.columnChannelVolumeCorrection] as String?,
      mcCmd: map[DatabaseHelper.columnChannelMcCmd] as String?,
      wowzaTmpLink: map[DatabaseHelper.columnChannelWowzaTmpLink] as String?,
      wowzaDvr: map[DatabaseHelper.columnChannelWowzaDvr] as String?,
      useHttpTmpLink:
          map[DatabaseHelper.columnChannelUseHttpTmpLink] as String?,
      monitoringStatus:
          map[DatabaseHelper.columnChannelMonitoringStatus] as String?,
      enableMonitoring:
          map[DatabaseHelper.columnChannelEnableMonitoring] as int?,
      enableWowzaLoadBalancing:
          map[DatabaseHelper.columnChannelEnableWowzaLoadBalancing] as int?,
      correctTime: map[DatabaseHelper.columnChannelCorrectTime] as String?,
      nimbleDvr: map[DatabaseHelper.columnChannelNimbleDvr] as String?,
      modified: map[DatabaseHelper.columnChannelModified] as String?,
      nginxSecureLink:
          map[DatabaseHelper.columnChannelNginxSecureLink] as String?,
      open: map[DatabaseHelper.columnChannelOpen] as int?,
      useLoadBalancing:
          map[DatabaseHelper.columnChannelUseLoadBalancing] as int?,
      group: map[DatabaseHelper.columnChannelGroupTitle] as String?,
      // Note: cmds, streamUrl, epgId are not stored in the main channels table
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnChannelId: id,
      DatabaseHelper.columnChannelName: name,
      DatabaseHelper.columnChannelNumber: number,
      DatabaseHelper.columnChannelLogo: logo,
      DatabaseHelper.columnChannelGenreId: genreId,
      DatabaseHelper.columnChannelXmltvId: xmltvId,
      DatabaseHelper.columnChannelEpg: epg,
      DatabaseHelper.columnChannelGenresStr: genresStr,
      DatabaseHelper.columnChannelCurPlaying: curPlaying,
      DatabaseHelper.columnChannelStatus: status,
      DatabaseHelper.columnChannelHd: hd,
      DatabaseHelper.columnChannelCensored: censored,
      DatabaseHelper.columnChannelFav: fav,
      DatabaseHelper.columnChannelLocked: locked,
      DatabaseHelper.columnChannelArchive: archive,
      DatabaseHelper.columnChannelPvr: pvr,
      DatabaseHelper.columnChannelEnableTvArchive: enableTvArchive,
      DatabaseHelper.columnChannelTvArchiveDuration: tvArchiveDuration,
      DatabaseHelper.columnChannelAllowPvr: allowPvr,
      DatabaseHelper.columnChannelAllowLocalPvr: allowLocalPvr,
      DatabaseHelper.columnChannelAllowRemotePvr: allowRemotePvr,
      DatabaseHelper.columnChannelAllowLocalTimeshift: allowLocalTimeshift,
      DatabaseHelper.columnChannelCmd: cmd,
      DatabaseHelper.columnChannelCmd1: cmd1,
      DatabaseHelper.columnChannelCmd2: cmd2,
      DatabaseHelper.columnChannelCmd3: cmd3,
      DatabaseHelper.columnChannelCost: cost,
      DatabaseHelper.columnChannelCount: count,
      DatabaseHelper.columnChannelBaseCh: baseCh,
      DatabaseHelper.columnChannelServiceId: serviceId,
      DatabaseHelper.columnChannelBonusCh: bonusCh,
      DatabaseHelper.columnChannelVolumeCorrection: volumeCorrection,
      DatabaseHelper.columnChannelMcCmd: mcCmd,
      DatabaseHelper.columnChannelWowzaTmpLink: wowzaTmpLink,
      DatabaseHelper.columnChannelWowzaDvr: wowzaDvr,
      DatabaseHelper.columnChannelUseHttpTmpLink: useHttpTmpLink,
      DatabaseHelper.columnChannelMonitoringStatus: monitoringStatus,
      DatabaseHelper.columnChannelEnableMonitoring: enableMonitoring,
      DatabaseHelper.columnChannelEnableWowzaLoadBalancing:
          enableWowzaLoadBalancing,
      DatabaseHelper.columnChannelCorrectTime: correctTime,
      DatabaseHelper.columnChannelNimbleDvr: nimbleDvr,
      DatabaseHelper.columnChannelModified: modified,
      DatabaseHelper.columnChannelNginxSecureLink: nginxSecureLink,
      DatabaseHelper.columnChannelOpen: open,
      DatabaseHelper.columnChannelGroupTitle: group,
      DatabaseHelper.columnChannelUseLoadBalancing: useLoadBalancing,
    };
  }
}
