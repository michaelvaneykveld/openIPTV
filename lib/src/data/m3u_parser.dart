import 'package:openiptv/src/data/models.dart'; // Assuming Channel model is here

class M3uParser {
  static List<Channel> parse(String m3uContent) {
    final List<Channel> channels = [];
    final lines = m3uContent.split('\n');

    Channel? currentChannel;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        // Parse EXTINF line
        final nameMatch = RegExp(r',(.+)$').firstMatch(line);
        final name = nameMatch?.group(1)?.trim() ?? 'Unknown Channel';

        final logoMatch = RegExp(r'tvg-logo="([^"]+)"').firstMatch(line);
        final logo = logoMatch?.group(1);

        final groupMatch = RegExp(r'group-title="([^"]+)"').firstMatch(line);
        final group = groupMatch?.group(1);

        currentChannel = Channel(
          id: name, // Using name as ID for simplicity, might need a better unique ID
          name: name,
          logoUrl: logo ?? '',
          genreId: group ?? 'Unknown', // Using group as genreId
          number: '', // M3U doesn't typically have channel numbers
          epgId: '',
          epg: '',
          genresStr: '',
          curPlaying: '',
          status: 0,
          hd: 0,
          censored: 0,
          fav: 0,
          locked: 0,
          archive: 0,
          pvr: 0,
          enableTvArchive: 0,
          tvArchiveDuration: 0,
          allowPvr: 0,
          allowLocalPvr: 0,
          allowRemotePvr: 0,
          allowLocalTimeshift: 0,
          cmd: '',
          cmd1: '',
          cmd2: '',
          cmd3: '',
          cost: '',
          count: '',
          baseCh: '',
          serviceId: '',
          bonusCh: '',
          volumeCorrection: '',
          mcCmd: '',
          wowzaTmpLink: '',
          wowzaDvr: '',
          useHttpTmpLink: '0', // Changed to String as per Channel model
          monitoringStatus: '',
          enableMonitoring: 0,
          enableWowzaLoadBalancing: 0,
          correctTime: '',
          nimbleDvr: '',
          modified: '',
          nginxSecureLink: '',
          open: 0,
          useLoadBalancing: 0,
        );
      } else if (currentChannel != null && line.isNotEmpty && !line.startsWith('#')) {
        // This is the URL line
        currentChannel = currentChannel.copyWith(cmd: line); // Assuming cmd is the URL
        channels.add(currentChannel);
        currentChannel = null; // Reset for next channel
      }
    }
    return channels;
  }
}