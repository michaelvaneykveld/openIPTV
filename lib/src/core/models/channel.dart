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

  factory Channel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? cmdsJson = json['cmds'];
    final List<ChannelCmd>? cmds = cmdsJson?.map((cmdJson) => ChannelCmd.fromJson(cmdJson, channelId: json['id'] as String)).toList();

    return Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as String?,
      logo: json['logo'] as String?,
      genreId: json['tv_genre_id'] as String?,
      xmltvId: json['xmltv_id'] as String?,
      epg: json['epg'] as String?, // This might need more specific parsing if it's an array/object
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
      cmds: cmds,
      streamUrl: json['url'] as String?, // Assuming 'url' from JSON is the stream URL
      group: json['group_title'] as String?, // Assuming 'group_title' from JSON is the group
      epgId: json['epg_id'] as String?, // Assuming 'epg_id' from JSON is the epgId
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
      'monitoringStatus': monitoringStatus,
      'enableMonitoring': enableMonitoring,
      'enableWowzaLoadBalancing': enableWowzaLoadBalancing,
      'correctTime': correctTime,
      'nimbleDvr': nimbleDvr,
      'modified': modified,
      'nginxSecureLink': nginxSecureLink,
      'open': open,
      'useLoadBalancing': useLoadBalancing,
      // cmds are handled separately as they are a list of objects
      // Add new fields to toMap if they need to be persisted
    };
  }
}