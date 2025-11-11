import 'dart:async';
import 'dart:convert';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/playback/playable.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_authenticator.dart';
import 'package:openiptv/src/protocols/stalker/stalker_http_client.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_session.dart';
import 'package:openiptv/src/utils/header_json_codec.dart';
import 'package:openiptv/src/utils/profile_header_utils.dart';
import 'package:openiptv/src/utils/url_normalization.dart';

class PlayableResolver {
  PlayableResolver(
    this.profile, {
    StalkerAuthenticator? stalkerAuthenticator,
    StalkerHttpClient? stalkerHttpClient,
  }) : _profileHeaders = decodeProfileCustomHeaders(profile),
       _stalkerAuthenticator =
           stalkerAuthenticator ?? DefaultStalkerAuthenticator(),
       _stalkerHttpClient = stalkerHttpClient ?? StalkerHttpClient();

  final ResolvedProviderProfile profile;
  final Map<String, String> _profileHeaders;
  final StalkerAuthenticator _stalkerAuthenticator;
  final StalkerHttpClient _stalkerHttpClient;
  StalkerPortalConfiguration? _stalkerConfig;
  StalkerSession? _stalkerSession;
  Future<StalkerSession>? _stalkerSessionFuture;

  Map<String, String> get _secrets => profile.secrets;
  Map<String, String> get _config => profile.record.configuration;
  Map<String, String> get _hints => profile.record.hints;

  Future<PlayerMediaSource?> channel(
    ChannelRecord channel, {
    bool isRadio = false,
  }) async {
    final headers = decodeHeadersJson(channel.streamHeadersJson);
    final playable = await _buildPlayable(
      kind: isRadio ? ContentBucket.radio : ContentBucket.live,
      streamTemplate: channel.streamUrlTemplate,
      providerKey: channel.providerChannelKey,
      previewUrl: channel.streamUrlTemplate,
      isLive: !isRadio,
      headerHints: headers,
    );
    if (playable == null) {
      return null;
    }
    return PlayerMediaSource(playable: playable, title: channel.name);
  }

  Future<PlayerMediaSource?> movie(MovieRecord movie) async {
    final headers = decodeHeadersJson(movie.streamHeadersJson);
    final playable = await _buildPlayable(
      kind: ContentBucket.films,
      streamTemplate: movie.streamUrlTemplate,
      providerKey: movie.providerVodKey,
      isLive: false,
      headerHints: headers,
    );
    if (playable == null) {
      return null;
    }
    return PlayerMediaSource(playable: playable, title: movie.title);
  }

  Future<PlayerMediaSource?> episode(
    EpisodeRecord episode, {
    String? seriesTitle,
  }) async {
    final headers = decodeHeadersJson(episode.streamHeadersJson);
    final playable = await _buildPlayable(
      kind: ContentBucket.series,
      streamTemplate: episode.streamUrlTemplate,
      providerKey: episode.providerEpisodeKey,
      isLive: false,
      headerHints: headers,
    );
    if (playable == null) {
      return null;
    }
    final buffer = StringBuffer();
    if (seriesTitle != null && seriesTitle.isNotEmpty) {
      buffer.write(seriesTitle);
    }
    if (episode.seasonNumber != null && episode.episodeNumber != null) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(
        'S${episode.seasonNumber!.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber!.toString().padLeft(2, '0')}',
      );
    }
    if ((episode.title ?? '').isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' - ');
      buffer.write(episode.title!.trim());
    }
    final resolvedTitle = buffer.isEmpty
        ? (episode.title ?? seriesTitle ?? 'Episode')
        : buffer.toString();
    return PlayerMediaSource(playable: playable, title: resolvedTitle);
  }

  Future<PlayerMediaSource?> preview(
    CategoryPreviewItem item,
    ContentBucket bucket,
  ) async {
    final playable = await _buildPlayable(
      kind: bucket,
      streamTemplate: item.streamUrl,
      providerKey: item.id,
      previewUrl: item.streamUrl,
      isLive: bucket == ContentBucket.live || bucket == ContentBucket.radio,
      headerHints: item.headers,
    );
    if (playable == null) {
      return null;
    }
    return PlayerMediaSource(playable: playable, title: item.title);
  }

  Future<Playable?> _buildPlayable({
    required ContentBucket kind,
    required bool isLive,
    String? streamTemplate,
    String? providerKey,
    String? previewUrl,
    Map<String, String>? headerHints,
  }) async {
    final directUri =
        _parseDirectUri(streamTemplate) ?? _parseDirectUri(previewUrl);
    if (directUri != null) {
      final directPlayable = _playableFromUri(
        directUri,
        isLive: isLive,
        headers: _mergeHeaders(headerHints),
      );
      if (directPlayable != null) {
        return directPlayable;
      }
    }
    switch (profile.record.kind) {
      case ProviderKind.xtream:
        if (providerKey == null || providerKey.isEmpty) {
          return null;
        }
        return _buildXtreamPlayable(
          providerKey: providerKey,
          kind: kind,
          isLive: isLive,
          templateExtension: _inferExtension(streamTemplate),
          headerHints: headerHints,
        );
      case ProviderKind.stalker:
        final cmd = streamTemplate ?? previewUrl;
        if (cmd == null || cmd.isEmpty) {
          return null;
        }
        final uri = _parseStalkerCommand(cmd);
        if (uri != null) {
          final playable = _playableFromUri(
            uri,
            isLive: isLive,
            headers: _mergeHeaders(headerHints),
          );
          if (playable != null) {
            return playable;
          }
        }
        return _buildStalkerPlayable(
          command: cmd,
          kind: kind,
          isLive: isLive,
          headerHints: headerHints,
        );
      case ProviderKind.m3u:
        if (streamTemplate == null && previewUrl == null) {
          return null;
        }
        final uri =
            _parseDirectUri(streamTemplate) ?? _parseDirectUri(previewUrl);
        if (uri == null) {
          return null;
        }
        return _playableFromUri(
          uri,
          isLive: isLive,
          headers: _mergeHeaders(headerHints),
        );
    }
  }

  Playable? _playableFromUri(
    Uri uri, {
    required bool isLive,
    Map<String, String>? headers,
  }) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }
    final normalizedHeaders = headers == null
        ? const <String, String>{}
        : Map<String, String>.unmodifiable(headers);
    return Playable(
      url: uri,
      isLive: isLive,
      headers: normalizedHeaders,
      containerExtension: guessExtensionFromUri(uri),
      mimeHint: guessMimeFromUri(uri),
    );
  }

  Playable? _buildXtreamPlayable({
    required String providerKey,
    required ContentBucket kind,
    required bool isLive,
    String? templateExtension,
    Map<String, String>? headerHints,
  }) {
    final username = _readCredential(const [
      'username',
      'user',
      'login',
      'user_name',
    ]);
    final password = _readCredential(const ['password', 'pass', 'pwd']);
    if (username == null || password == null) {
      return null;
    }

    final base = _xtreamStreamBase();
    final segment = switch (kind) {
      ContentBucket.live || ContentBucket.radio => 'live',
      ContentBucket.films => 'movie',
      ContentBucket.series => 'series',
    };
    final ext =
        templateExtension ??
        (kind == ContentBucket.live || kind == ContentBucket.radio
            ? 'm3u8'
            : 'mp4');
    final escapedUsername = Uri.encodeComponent(username);
    final escapedPassword = Uri.encodeComponent(password);
    final path = '$segment/$escapedUsername/$escapedPassword/$providerKey.$ext';
    final url = base.resolve(path);
    return Playable(
      url: url,
      isLive: isLive,
      headers: _mergeHeaders(headerHints),
      containerExtension: ext,
      mimeHint: guessMimeFromUri(url),
    );
  }

  Future<Playable?> _buildStalkerPlayable({
    required String command,
    required ContentBucket kind,
    required bool isLive,
    Map<String, String>? headerHints,
  }) async {
    final config = _stalkerConfig ??= _buildStalkerConfiguration();
    if (config == null) {
      return null;
    }
    final session = await _loadStalkerSession();
    if (session == null) {
      return null;
    }
    final module = _stalkerModuleForBucket(kind);
    final queryParameters = <String, dynamic>{
      'type': module,
      'action': 'create_link',
      'token': session.token,
      'mac': config.macAddress.toLowerCase(),
      'cmd': command,
      'JsHttpRequest': '1-xml',
    };
    final response = await _stalkerHttpClient.getPortal(
      config,
      queryParameters: queryParameters,
      headers: session.buildAuthenticatedHeaders(),
    );
    final resolvedLink = _extractStalkerLink(response.body);
    if (resolvedLink == null || resolvedLink.isEmpty) {
      return null;
    }
    final uri = _parseDirectUri(resolvedLink);
    if (uri == null) {
      return null;
    }
    final playbackHeaders = _mergeHeaders(
      headerHints,
      overrides: session.buildAuthenticatedHeaders(),
    );
    return _playableFromUri(uri, isLive: isLive, headers: playbackHeaders);
  }

  Uri _xtreamStreamBase() {
    final stripped = stripKnownFiles(
      profile.record.lockedBase,
      knownFiles: const {
        'player_api.php',
        'get.php',
        'xmltv.php',
        'portal.php',
        'index.php',
      },
    );
    return ensureTrailingSlash(stripped);
  }

  StalkerPortalConfiguration? _buildStalkerConfiguration() {
    final mac = _config['macAddress'] ?? '';
    if (mac.isEmpty) {
      return null;
    }
    final userAgent = _config['userAgent'];
    return StalkerPortalConfiguration(
      baseUri: profile.lockedBase,
      macAddress: mac,
      userAgent: userAgent?.isNotEmpty == true ? userAgent : null,
      allowSelfSignedTls: profile.record.allowSelfSignedTls,
      extraHeaders: _profileHeaders,
    );
  }

  Future<StalkerSession?> _loadStalkerSession() async {
    final config = _stalkerConfig ??= _buildStalkerConfiguration();
    if (config == null) {
      return null;
    }
    final cached = _stalkerSession;
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    final pending = _stalkerSessionFuture ??= _stalkerAuthenticator
        .authenticate(config);
    try {
      final session = await pending;
      _stalkerSession = session;
      return session;
    } finally {
      if (identical(_stalkerSessionFuture, pending)) {
        _stalkerSessionFuture = null;
      }
    }
  }

  Map<String, dynamic> _decodePortalPayload(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) {
        return const {};
      }
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Ignore parse errors.
      }
    }
    return const {};
  }

  String? _extractStalkerLink(dynamic body) {
    final payload = _decodePortalPayload(body);
    final js = payload['js'];
    if (js is Map) {
      final cmd = js['cmd'] ?? js['url'] ?? js['stream_url'];
      if (cmd is String && cmd.trim().isNotEmpty) {
        return cmd.trim();
      }
    }
    final directCmd = payload['cmd'] ?? payload['url'];
    if (directCmd is String && directCmd.trim().isNotEmpty) {
      return directCmd.trim();
    }
    return null;
  }

  String _stalkerModuleForBucket(ContentBucket bucket) {
    switch (bucket) {
      case ContentBucket.live:
        return 'itv';
      case ContentBucket.radio:
        return 'radio';
      case ContentBucket.films:
        return 'vod';
      case ContentBucket.series:
        return 'series';
    }
  }

  Map<String, String> _mergeHeaders(
    Map<String, String>? specific, {
    Map<String, String>? overrides,
  }) {
    Map<String, String>? merged;
    void append(Map<String, String>? source) {
      if (source == null || source.isEmpty) return;
      merged ??= <String, String>{};
      merged!.addAll(source);
    }

    append(_profileHeaders);
    append(specific);
    append(overrides);

    if (merged == null || merged!.isEmpty) {
      return const {};
    }
    return Map.unmodifiable(merged!);
  }

  Uri? _parseDirectUri(String? candidate) {
    if (candidate == null) return null;
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return null;
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    final match = _urlPattern.firstMatch(trimmed);
    if (match != null) {
      return Uri.tryParse(match.group(0)!);
    }
    return null;
  }

  Uri? _parseStalkerCommand(String command) {
    final trimmed = command.trim();
    final uri = _parseDirectUri(trimmed);
    if (uri != null) return uri;
    final parts = trimmed.split(' ');
    for (final part in parts) {
      final candidate = _parseDirectUri(part);
      if (candidate != null) {
        return candidate;
      }
    }
    return null;
  }

  String? _readCredential(Iterable<String> keys) {
    for (final key in keys) {
      final lower = key.toLowerCase();
      final value =
          _secrets[lower] ??
          _secrets[key] ??
          _config[lower] ??
          _config[key] ??
          _hints[lower] ??
          _hints[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _inferExtension(String? template) {
    if (template == null) return null;
    final parsed = _parseDirectUri(template);
    if (parsed != null) {
      final ext = guessExtensionFromUri(parsed);
      if (ext.isNotEmpty) return ext;
    }
    final dot = template.lastIndexOf('.');
    if (dot != -1) {
      final candidate = template.substring(dot + 1).split('?').first.trim();
      if (candidate.isNotEmpty) {
        return candidate.toLowerCase();
      }
    }
    return null;
  }

  static final RegExp _urlPattern = RegExp(
    r'((https?|rtmp|udp)://[^\s]+)',
    caseSensitive: false,
  );
}
