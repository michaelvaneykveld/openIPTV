import 'package:openiptv/src/core/models/channel.dart';

class M3uParser {
  static List<Channel> parse(String m3uContent) {
    final List<Channel> channels = [];
    final lines = m3uContent.split('\n');

    Map<String, String> currentAttributes = {};

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        continue;
      }

      if (trimmedLine.startsWith('#EXTINF:')) {
        currentAttributes = _parseExtinf(trimmedLine);
      } else if (!trimmedLine.startsWith('#') && currentAttributes.isNotEmpty) {
        final streamUrl = trimmedLine;
        channels.add(Channel.fromM3UEntry(currentAttributes, streamUrl));
        currentAttributes = {}; // Reset for the next entry
      }
    }
    return channels;
  }

  static Map<String, String> _parseExtinf(String line) {
    final attributes = <String, String>{};
    final parts = line.split(',');
    if (parts.length > 1) {
      attributes['title'] = parts.sublist(1).join(',').trim();
    }

    final regex = RegExp(r'([a-zA-Z0-9\-]+)=\"([^\"]*)\"|([a-zA-Z0-9\-]+)=([^\s,]+)');
    final matches = regex.allMatches(line);

    for (final match in matches) {
      final key = (match.group(1) ?? match.group(3))?.trim();
      final value = (match.group(2) ?? match.group(4))?.trim();
      if (key != null && value != null) {
        attributes[key] = value;
      }
    }
    return attributes;
  }
}
