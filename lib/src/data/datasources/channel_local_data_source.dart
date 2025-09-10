import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/database/database_helper.dart'; // Import DatabaseHelper
import 'package:openiptv/src/core/models/channel_cmd.dart'; // Import ChannelCmd

part 'channel_local_data_source.g.dart';

class ChannelLocalDataSource {
  final DatabaseHelper _dbHelper;

  ChannelLocalDataSource(this._dbHelper);

  List<Channel> getChannels() {
    // This method will be asynchronous as database operations are async
    // It's better to make this a Future<List<Channel>>
    throw UnimplementedError('getChannels must be asynchronous');
  }

  Future<List<Channel>> getChannelsAsync(String portalId) async {
    final List<Map<String, dynamic>> channelMaps = await _dbHelper.getAllChannels(portalId);
    final List<Channel> channels = [];

    for (var channelMap in channelMaps) {
      final Channel channel = Channel.fromStalkerJson(channelMap);
      final List<Map<String, dynamic>> cmdMaps = await _dbHelper.getChannelCmdsForChannel(channel.id, portalId);
      final List<ChannelCmd> cmds = cmdMaps.map((cmdMap) => ChannelCmd.fromJson(cmdMap, channelId: channel.id)).toList();
      
      // Create a new Channel object with cmds populated
      channels.add(Channel(
        id: channel.id,
        name: channel.name,
        number: channel.number,
        logo: channel.logo,
        genreId: channel.genreId,
        xmltvId: channel.xmltvId,
        epg: channel.epg,
        genresStr: channel.genresStr,
        curPlaying: channel.curPlaying,
        status: channel.status,
        hd: channel.hd,
        censored: channel.censored,
        fav: channel.fav,
        locked: channel.locked,
        archive: channel.archive,
        pvr: channel.pvr,
        enableTvArchive: channel.enableTvArchive,
        tvArchiveDuration: channel.tvArchiveDuration,
        allowPvr: channel.allowPvr,
        allowLocalPvr: channel.allowLocalPvr,
        allowRemotePvr: channel.allowRemotePvr,
        allowLocalTimeshift: channel.allowLocalTimeshift,
        cmd: channel.cmd,
        cmd1: channel.cmd1,
        cmd2: channel.cmd2,
        cmd3: channel.cmd3,
        cost: channel.cost,
        count: channel.count,
        baseCh: channel.baseCh,
        serviceId: channel.serviceId,
        bonusCh: channel.bonusCh,
        volumeCorrection: channel.volumeCorrection,
        mcCmd: channel.mcCmd,
        wowzaTmpLink: channel.wowzaTmpLink,
        wowzaDvr: channel.wowzaDvr,
        useHttpTmpLink: channel.useHttpTmpLink,
        monitoringStatus: channel.monitoringStatus,
        enableMonitoring: channel.enableMonitoring,
        enableWowzaLoadBalancing: channel.enableWowzaLoadBalancing,
        correctTime: channel.correctTime,
        nimbleDvr: channel.nimbleDvr,
        modified: channel.modified,
        nginxSecureLink: channel.nginxSecureLink,
        open: channel.open,
        useLoadBalancing: channel.useLoadBalancing,
        cmds: cmds, // Populate cmds
      ));
    }
    return channels;
  }

  Future<void> saveChannels(List<Channel> channels, String portalId) async {
    // Clear existing data before saving new data
    await _dbHelper.clearAllData(portalId); // This clears all tables, might need to be more specific

    for (var channel in channels) {
      await _dbHelper.insertChannel(channel.toMap(), portalId);
      if (channel.cmds != null) {
        for (var cmd in channel.cmds!) {
          await _dbHelper.insertChannelCmd(cmd.toMap(), portalId);
        }
      }
    }
  }
}

@riverpod
ChannelLocalDataSource channelLocalDataSource(Ref ref) {
  return ChannelLocalDataSource(DatabaseHelper.instance); // Pass DatabaseHelper instance
}