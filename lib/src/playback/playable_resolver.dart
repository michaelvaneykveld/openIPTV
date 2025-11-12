import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
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
import 'package:openiptv/src/utils/playback_logger.dart';
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
  http.Client? _xtreamProbeClient;

  static const Duration _xtreamProbeTimeout = Duration(seconds: 6);

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
      PlaybackLogger.playableDrop('unsupported-scheme', uri: uri);
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

  _XtreamCandidate? _xtreamLivePattern;

  Future<Playable?> _buildXtreamPlayable({
    required String providerKey,
    required ContentBucket kind,
    required bool isLive,
    String? templateExtension,
    Map<String, String>? headerHints,
  }) async {
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
    final escapedUsername = Uri.encodeComponent(username);
    final escapedPassword = Uri.encodeComponent(password);
    final userAgent = (_config['userAgent'] ?? '').trim();
    final headers = _mergeHeaders(
      headerHints,
      overrides:
          userAgent.isEmpty ? null : <String, String>{'User-Agent': userAgent},
    );
    if (kind == ContentBucket.live || kind == ContentBucket.radio) {
      final livePlayable = await _buildXtreamLivePlayable(
        base: base,
        slugPrefix: 'live/$escapedUsername/$escapedPassword',
        providerKey: providerKey,
        headers: headers,
        templateExtension: templateExtension,
      );
      if (livePlayable != null) {
        return livePlayable;
      }
    }
    final segment = switch (kind) {
      ContentBucket.live || ContentBucket.radio => 'live',
      ContentBucket.films => 'movie',
      ContentBucket.series => 'series',
    };
    final ext =
        templateExtension ??
        _resolveXtreamExtension(kind: kind, isLive: isLive);
    final path = '$segment/$escapedUsername/$escapedPassword/$providerKey.$ext';
    final url = base.resolve(path);
    return Playable(
      url: url,
      isLive: isLive,
      headers: headers,
      containerExtension: ext,
      mimeHint: guessMimeFromUri(url),
    );
  }

  String _resolveXtreamExtension({
    required ContentBucket kind,
    required bool isLive,
  }) {
    final preferred = (_config['outputFormat'] ?? '').trim().toLowerCase();
    if (preferred.isNotEmpty) {
      return preferred;
    }
    switch (kind) {
      case ContentBucket.live:
      case ContentBucket.radio:
        return isLive ? 'ts' : 'mp3';
      case ContentBucket.films:
      case ContentBucket.series:
        return 'mp4';
    }
  }

  Future<Playable?> _buildXtreamLivePlayable({
    required Uri base,
    required String slugPrefix,
    required String providerKey,
    required Map<String, String> headers,
    String? templateExtension,
  }) async {
    final candidates = _xtreamLiveCandidates(
      slugPrefix: slugPrefix,
      providerKey: providerKey,
      templateExtension: templateExtension,
    );
    if (_xtreamLivePattern != null) {
      candidates.sort((a, b) {
        if (identical(a, _xtreamLivePattern)) return -1;
        if (identical(b, _xtreamLivePattern)) return 1;
        if (a.pathTemplate == _xtreamLivePattern!.pathTemplate) return -1;
        if (b.pathTemplate == _xtreamLivePattern!.pathTemplate) return 1;
        return 0;
      });
    }
    for (final candidate in candidates) {
      final uri = candidate.resolve(base, providerKey);
      final probe = await _probeXtreamCandidate(uri, headers);
      if (probe == null) {
        continue;
      }
      final ext = _determineXtreamExtension(probe, candidate);
      final mime = probe.contentType?.isNotEmpty == true
          ? probe.contentType
          : guessMimeFromUri(probe.uri) ?? _mimeFromExtension(ext);
      _xtreamLivePattern ??= candidate;
      return Playable(
        url: probe.uri,
        isLive: true,
        headers: probe.playbackHeaders,
        containerExtension: ext,
        mimeHint: mime,
      );
    }
    return null;
  }

  List<_XtreamCandidate> _xtreamLiveCandidates({
    required String slugPrefix,
    required String providerKey,
    String? templateExtension,
  }) {
    const placeholder = _XtreamCandidate.placeholder;
    final raw = <_XtreamCandidate>[
      _XtreamCandidate(
        pathTemplate: '$slugPrefix/$placeholder.m3u8',
        extension: 'm3u8',
      ),
      _XtreamCandidate(
        pathTemplate: '$slugPrefix/$placeholder/index.m3u8',
        extension: 'm3u8',
      ),
      _XtreamCandidate(
        pathTemplate: '$slugPrefix/$placeholder.ts',
        extension: 'ts',
      ),
      _XtreamCandidate(
        pathTemplate: '$slugPrefix/$placeholder',
        extension: 'ts',
      ),
    ];
    if (templateExtension == null || templateExtension.isEmpty) {
      return raw;
    }
    final normalized = templateExtension.toLowerCase();
    raw.sort((a, b) {
      final aScore = a.extension == normalized ? 0 : 1;
      final bScore = b.extension == normalized ? 0 : 1;
      return aScore.compareTo(bScore);
    });
    return raw;
  }

  Future<_XtreamProbeResult?> _probeXtreamCandidate(
    Uri uri,
    Map<String, String> playbackHeaders,
  ) async {
    try {
      final headResult = await _sendXtreamProbeRequest(
        uri,
        playbackHeaders,
        method: 'HEAD',
      );
      if (headResult != null) {
        return headResult;
      }
    } catch (_) {
      // Swallow and fall back to GET probe.
    }
    try {
      final getHeaders = playbackHeaders.isEmpty
          ? <String, String>{}
          : Map<String, String>.from(playbackHeaders);
      getHeaders.putIfAbsent('Range', () => 'bytes=0-2047');
      return await _sendXtreamProbeRequest(
        uri,
        getHeaders,
        method: 'GET',
        playbackHeaders: playbackHeaders,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_XtreamProbeResult?> _sendXtreamProbeRequest(
    Uri uri,
    Map<String, String> requestHeaders, {
    required String method,
    Map<String, String>? playbackHeaders,
  }) async {
    final client = _xtreamProbeClient ??= _createXtreamProbeClient();
    final request = http.Request(method, uri)
      ..followRedirects = true
      ..maxRedirects = 5
      ..headers.addAll(requestHeaders);
    try {
      final response =
          await client.send(request).timeout(_xtreamProbeTimeout);
      await response.stream.drain();
      if (response.statusCode >= 200 && response.statusCode < 400) {
        final resolvedUri = response.request?.url ?? uri;
        final contentType = response.headers['content-type'];
        return _XtreamProbeResult(
          uri: resolvedUri,
          contentType: contentType,
          playbackHeaders: playbackHeaders ?? Map.unmodifiable(requestHeaders),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _determineXtreamExtension(
    _XtreamProbeResult probe,
    _XtreamCandidate candidate,
  ) {
    if (candidate.extension != null && candidate.extension!.isNotEmpty) {
      return candidate.extension!;
    }
    final fromContentType = _extensionFromContentType(probe.contentType);
    if (fromContentType != null) {
      return fromContentType;
    }
    final guessed = guessExtensionFromUri(probe.uri);
    if (guessed.isNotEmpty && guessed != 'unknown') {
      return guessed;
    }
    return 'ts';
  }

  String? _extensionFromContentType(String? contentType) {
    if (contentType == null) {
      return null;
    }
    final normalized = contentType.toLowerCase();
    if (normalized.contains('mpegurl')) {
      return 'm3u8';
    }
    if (normalized.contains('mp2t')) {
      return 'ts';
    }
    return null;
  }

  http.Client _createXtreamProbeClient() {
    if (profile.record.allowSelfSignedTls) {
      final ioClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      return IOClient(ioClient);
    }
    return http.Client();
  }

  Future<Playable?> _buildStalkerPlayable({
    required String command,
    required ContentBucket kind,
    required bool isLive,
    Map<String, String>? headerHints,
  }) async {
    final module = _stalkerModuleForBucket(kind);
    final config = _stalkerConfig ??= _buildStalkerConfiguration();
    if (config == null) {
      PlaybackLogger.stalker(
        'missing-config',
        portal: profile.lockedBase,
        module: module,
        command: command,
      );
      return null;
    }
    final session = await _loadStalkerSession();
    if (session == null) {
      PlaybackLogger.stalker(
        'session-unavailable',
        portal: config.baseUri,
        module: module,
        command: command,
      );
      return null;
    }
    final queryParameters = <String, dynamic>{
      'type': module,
      'action': 'create_link',
      'token': session.token,
      'mac': config.macAddress.toLowerCase(),
      'cmd': command,
      'JsHttpRequest': '1-xml',
    };
    final sessionHeaders = session.buildAuthenticatedHeaders();
    try {
      final response = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: queryParameters,
        headers: sessionHeaders,
      );
      final resolvedLink = _extractStalkerLink(response.body);
      if (resolvedLink == null || resolvedLink.isEmpty) {
        PlaybackLogger.stalker(
          'link-missing',
          portal: config.baseUri,
          module: module,
          command: command,
        );
        return null;
      }
      final uri = _parseDirectUri(resolvedLink);
      if (uri == null) {
        PlaybackLogger.stalker(
          'link-parse-failed',
          portal: config.baseUri,
          module: module,
          command: command,
        );
        return null;
      }
      final playbackHeaders = _mergeHeaders(
        headerHints,
        overrides: {
          for (final entry in sessionHeaders.entries)
            if (!_headerBlacklist.contains(entry.key)) entry.key: entry.value,
        },
      );
      var playable = _playableFromUri(
        uri,
        isLive: isLive,
        headers: playbackHeaders,
      );
      final inferredExtension = _stalkerExtensionFromUri(uri);
      if (playable != null &&
          inferredExtension != null &&
          inferredExtension.isNotEmpty &&
          inferredExtension != playable.containerExtension) {
        playable = playable.copyWith(
          containerExtension: inferredExtension,
          mimeHint: playable.mimeHint ?? _mimeFromExtension(inferredExtension),
        );
      }
      if (playable == null) {
        PlaybackLogger.playableDrop('stalker-unhandled', uri: uri);
        return null;
      }
      PlaybackLogger.stalker(
        'resolved',
        portal: config.baseUri,
        module: module,
        command: command,
        resolvedUri: uri,
        headers: playbackHeaders,
      );
      return playable;
    } catch (error) {
      PlaybackLogger.stalker(
        'create-link-error',
        portal: config.baseUri,
        module: module,
        command: command,
        error: error,
      );
      rethrow;
    }
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

  static const Set<String> _headerBlacklist = {
    'cookie',
    'Cookie',
    'authorization',
    'Authorization',
  };

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

  String? _stalkerExtensionFromUri(Uri uri) {
    final queryExt = uri.queryParameters['extension'];
    if (queryExt != null && queryExt.trim().isNotEmpty) {
      return queryExt.trim().toLowerCase();
    }
    if (uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      final dot = last.lastIndexOf('.');
      if (dot != -1 && dot < last.length - 1) {
        return last.substring(dot + 1).toLowerCase();
      }
    }
    return null;
  }

  String? _mimeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'm3u8':
        return 'application/vnd.apple.mpegurl';
      case 'mpd':
        return 'application/dash+xml';
      case 'mp4':
        return 'video/mp4';
      case 'ts':
        return 'video/mp2t';
      case 'aac':
        return 'audio/aac';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return null;
    }
  }
}

class _XtreamCandidate {
  const _XtreamCandidate({
    required this.pathTemplate,
    required this.extension,
  });

  static const placeholder = '{stream_id}';

  final String pathTemplate;
  final String? extension;

  Uri resolve(Uri base, String providerKey) {
    final path = pathTemplate.replaceAll(placeholder, providerKey);
    return base.resolve(path);
  }
}

class _XtreamProbeResult {
  _XtreamProbeResult({
    required this.uri,
    required this.contentType,
    required this.playbackHeaders,
  });

  final Uri uri;
  final String? contentType;
  final Map<String, String> playbackHeaders;
}
