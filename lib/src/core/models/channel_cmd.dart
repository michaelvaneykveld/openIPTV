import 'package:openiptv/src/core/database/database_helper.dart';

class ChannelCmd {
  final String id;
  final String channelId;
  final int? priority;
  final String? url;
  final int? status;
  final int? useHttpTmpLink;
  final int? wowzaTmpLink;
  final String? userAgentFilter;
  final int? useLoadBalancing;
  final String? changed;
  final int? enableMonitoring;
  final int? enableBalancerMonitoring;
  final int? nginxSecureLink;
  final int? flussonicTmpLink;

  ChannelCmd({
    required this.id,
    required this.channelId, // Required to link back to the channel
    this.priority,
    this.url,
    this.status,
    this.useHttpTmpLink,
    this.wowzaTmpLink,
    this.userAgentFilter,
    this.useLoadBalancing,
    this.changed,
    this.enableMonitoring,
    this.enableBalancerMonitoring,
    this.nginxSecureLink,
    this.flussonicTmpLink,
  });

  factory ChannelCmd.fromJson(
    Map<String, dynamic> json, {
    required String channelId,
  }) {
    return ChannelCmd(
      id: _asString(json['id']) ?? channelId,
      channelId: channelId, // Pass the parent channel's ID
      priority: _asInt(json['priority']),
      url: _asString(json['url']),
      status: _asInt(json['status']),
      useHttpTmpLink: _asInt(json['use_http_tmp_link']),
      wowzaTmpLink: _asInt(json['wowza_tmp_link']),
      userAgentFilter: _asString(json['user_agent_filter']),
      useLoadBalancing: _asInt(json['use_load_balancing']),
      changed: _asString(json['changed']),
      enableMonitoring: _asInt(json['enable_monitoring']),
      enableBalancerMonitoring: _asInt(json['enable_balancer_monitoring']),
      nginxSecureLink: _asInt(json['nginx_secure_link']),
      flussonicTmpLink: _asInt(json['flussonic_tmp_link']),
    );
  }

  factory ChannelCmd.fromDbMap(Map<String, dynamic> map) {
    return ChannelCmd(
      id: map[DatabaseHelper.columnCmdId] as String,
      channelId: map[DatabaseHelper.columnCmdChannelId] as String,
      priority: map[DatabaseHelper.columnCmdPriority] as int?,
      url: map[DatabaseHelper.columnCmdUrl] as String?,
      status: map[DatabaseHelper.columnCmdStatus] as int?,
      useHttpTmpLink: map[DatabaseHelper.columnCmdUseHttpTmpLink] as int?,
      wowzaTmpLink: map[DatabaseHelper.columnCmdWowzaTmpLink] as int?,
      userAgentFilter: map[DatabaseHelper.columnCmdUserAgentFilter] as String?,
      useLoadBalancing: map[DatabaseHelper.columnCmdUseLoadBalancing] as int?,
      changed: map[DatabaseHelper.columnCmdChanged] as String?,
      enableMonitoring: map[DatabaseHelper.columnCmdEnableMonitoring] as int?,
      enableBalancerMonitoring:
          map[DatabaseHelper.columnCmdEnableBalancerMonitoring] as int?,
      nginxSecureLink: map[DatabaseHelper.columnCmdNginxSecureLink] as int?,
      flussonicTmpLink: map[DatabaseHelper.columnCmdFlussonicTmpLink] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnCmdId: id,
      DatabaseHelper.columnCmdChannelId: channelId,
      DatabaseHelper.columnCmdPriority: priority,
      DatabaseHelper.columnCmdUrl: url,
      DatabaseHelper.columnCmdStatus: status,
      DatabaseHelper.columnCmdUseHttpTmpLink: useHttpTmpLink,
      DatabaseHelper.columnCmdWowzaTmpLink: wowzaTmpLink,
      DatabaseHelper.columnCmdUserAgentFilter: userAgentFilter,
      DatabaseHelper.columnCmdUseLoadBalancing: useLoadBalancing,
      DatabaseHelper.columnCmdChanged: changed,
      DatabaseHelper.columnCmdEnableMonitoring: enableMonitoring,
      DatabaseHelper.columnCmdEnableBalancerMonitoring:
          enableBalancerMonitoring,
      DatabaseHelper.columnCmdNginxSecureLink: nginxSecureLink,
      DatabaseHelper.columnCmdFlussonicTmpLink: flussonicTmpLink,
    };
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
}
