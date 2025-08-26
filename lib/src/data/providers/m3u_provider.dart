import 'package:dio/dio.dart';
import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';

/// A simple resolver for M3U that just returns the already known URL.
class _M3uStreamResolver implements StreamUrlResolver {
  final Map<String, String> _streamUrls;

  _M3uStreamResolver(this._streamUrls);

  @override
  Future<String> resolveStreamUrl(String itemId, {Map<String, dynamic>? options}) async {
    final url = _streamUrls[itemId];
    if (url == null) {
      throw Exception('Stream URL for item ID $itemId not found.');
    }
    return url;
  }
}

/// An implementation of [IProvider] for parsing and handling M3U playlists.
class M3uProvider implements IProvider {
  final Dio _dio;
  M3uCredentials? _credentials;
  List<Channel> _channels = [];
  late final Map<String, String> _streamUrls = {};

  M3uProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<void> signIn(Credentials credentials) async {
    if (credentials is! M3uCredentials) {
      throw ArgumentError('Invalid credentials type provided for M3uProvider.');
    }
    _credentials = credentials;
    // Reset state
    _channels = [];
    _streamUrls.clear();
    // Immediately fetch channels to validate the M3U file.
    await fetchLiveChannels();
  }

  @override
  Future<List<Channel>> fetchLiveChannels() async {
    if (_credentials == null) {
      throw StateError('You must sign in before fetching channels.');
    }
    if (_channels.isNotEmpty) {
      return _channels;
    }

    final response = await _dio.get<String>(_credentials!.m3uUrl);
    final m3uContent = response.data;

    if (m3uContent == null || !m3uContent.startsWith('#EXTM3U')) {
      throw Exception('Invalid or empty M3U file.');
    }

    final lines = m3uContent.split('\n');
    final List<Channel> parsedChannels = [];
    
    // Regex to capture attributes from the #EXTINF line
    final extinfRegex = RegExp(r'#EXTINF:-1(?: +(.*?))?,(.*)');
    final attributeRegex = RegExp(r'([a-zA-Z0-9_-]+)="([^"]*)"');

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXTINF')) {
        final match = extinfRegex.firstMatch(lines[i]);
        if (match != null && i + 1 < lines.length) {
          final attributesString = match.group(1) ?? '';
          final channelName = match.group(2)?.trim() ?? 'Unknown Channel';
          final attributes = { for (var m in attributeRegex.allMatches(attributesString)) m.group(1)!: m.group(2)! };
          
          final streamUrl = lines[i + 1].trim();
          final channelId = attributes['tvg-id'] ?? channelName;

          parsedChannels.add(Channel(
            id: channelId,
            name: channelName,
            logoUrl: attributes['tvg-logo'],
            group: attributes['group-title'] ?? 'Uncategorized',
            epgId: attributes['tvg-id'] ?? '',
          ));
          _streamUrls[channelId] = streamUrl;
        }
      }
    }
    _channels = parsedChannels;
    return _channels;
  }

  @override
  StreamUrlResolver get resolver => _M3uStreamResolver(_streamUrls);

  // For the MVP, these are not yet implemented for M3U.
  @override
  Future<List<Category>> fetchCategories() async => throw UnimplementedError('M3U provider does not support VOD/Series categories.');
  @override
  Future<List<VodItem>> fetchVod({Category? category}) async => throw UnimplementedError('M3U provider does not support VOD.');
  @override
  Future<List<Series>> fetchSeries({Category? category}) async => throw UnimplementedError('M3U provider does not support Series.');
  @override
  Future<List<EpgEvent>> fetchEpg(String channelId, DateTime from, DateTime to) async => throw UnimplementedError('EPG fetching is not implemented in this provider. Use a separate EPG parser.');
}

