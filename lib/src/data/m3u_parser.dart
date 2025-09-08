import 'package:openiptv/src/core/models/models.dart'; // Assuming Channel model is here

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
          logo: logo ?? '',
          genreId: group ?? 'Unknown', // Using group as genreId
        );
      } else if (currentChannel != null && line.isNotEmpty && !line.startsWith('#')) {
        // This is the URL line
        channels.add(Channel(
          id: currentChannel.id,
          name: currentChannel.name,
          logo: currentChannel.logo,
          streamUrl: line,
          genreId: currentChannel.genreId,
        ));
        currentChannel = null; // Reset for next channel
      }
    }
    return channels;
  }
}