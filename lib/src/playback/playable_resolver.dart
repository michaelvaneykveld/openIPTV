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
  _XtreamCandidate? _xtreamLivePattern;
  Future<_XtreamCandidate?>? _xtreamLivePatternFuture;
  _XtreamServerContext? _xtreamServerContext;
  Future<_XtreamServerContext?>? _xtreamServerContextFuture;

  static const Duration _xtreamProbeTimeout = Duration(seconds: 10);

  Map<String, String> get _secrets => profile.secrets;
  Map<String, String> get _config => profile.record.configuration;
  Map<String, String> get _hints => profile.record.hints;

  /// Public accessor for Stalker session (for series/VOD hierarchy)
  StalkerSession? get stalkerSession => _stalkerSession;

  /// Public accessor for Stalker configuration (for series/VOD hierarchy)
  StalkerPortalConfiguration? get stalkerConfiguration => _stalkerConfig;

  /// Ensures a Stalker session is available, initializing if needed
  Future<void> ensureStalkerSession() async {
    await _loadStalkerSession();
  }

  Future<PlayerMediaSource?> channel(
    ChannelRecord channel, {
    bool isRadio = false,
  }) async {
    PlaybackLogger.resolverActivity(
      'channel-start',
      bucket: isRadio ? 'radio' : 'live',
      providerKind: profile.record.kind.name,
      extra: {
        'channelName': channel.name,
        'template': _truncate(channel.streamUrlTemplate ?? 'null'),
      },
    );

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
      PlaybackLogger.resolverActivity(
        'channel-failed',
        bucket: isRadio ? 'radio' : 'live',
        extra: {'channelName': channel.name},
      );
      return null;
    }
    PlaybackLogger.resolverActivity(
      'channel-resolved',
      bucket: isRadio ? 'radio' : 'live',
      extra: {
        'channelName': channel.name,
        'url': _summarizeUrl(playable.url.toString()),
      },
    );
    return PlayerMediaSource(playable: playable, title: channel.name);
  }

  String _truncate(String value, {int max = 100}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 3)}...';
  }

  String _summarizeUrl(String url) {
    if (url.length <= 100) return url;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return '${uri.scheme}://${uri.host}${uri.path.length > 30 ? '${uri.path.substring(0, 30)}...' : uri.path}';
    }
    return _truncate(url);
  }

  Future<PlayerMediaSource?> movie(MovieRecord movie) async {
    PlaybackLogger.resolverActivity(
      'movie-start',
      bucket: 'films',
      providerKind: profile.record.kind.name,
      extra: {
        'title': movie.title,
        'template': _truncate(movie.streamUrlTemplate ?? 'null'),
      },
    );

    final headers = decodeHeadersJson(movie.streamHeadersJson);
    final durationHint = movie.durationSec != null
        ? Duration(seconds: movie.durationSec!)
        : null;
    final playable = await _buildPlayable(
      kind: ContentBucket.films,
      streamTemplate: movie.streamUrlTemplate,
      providerKey: movie.providerVodKey,
      isLive: false,
      headerHints: headers,
      durationHint: durationHint,
    );
    if (playable == null) {
      PlaybackLogger.resolverActivity(
        'movie-failed',
        bucket: 'films',
        extra: {'title': movie.title},
      );
      return null;
    }
    PlaybackLogger.resolverActivity(
      'movie-resolved',
      bucket: 'films',
      extra: {
        'title': movie.title,
        'url': _summarizeUrl(playable.url.toString()),
      },
    );
    return PlayerMediaSource(playable: playable, title: movie.title);
  }

  Future<PlayerMediaSource?> episode(
    EpisodeRecord episode, {
    String? seriesTitle,
  }) async {
    PlaybackLogger.resolverActivity(
      'episode-start',
      bucket: 'series',
      providerKind: profile.record.kind.name,
      extra: {
        'series': seriesTitle ?? 'unknown',
        'episode': episode.title ?? 'unknown',
        'template': _truncate(episode.streamUrlTemplate ?? 'null'),
      },
    );

    final headers = decodeHeadersJson(episode.streamHeadersJson);
    final playable = await _buildPlayable(
      kind: ContentBucket.series,
      streamTemplate: episode.streamUrlTemplate,
      providerKey: episode.providerEpisodeKey,
      isLive: false,
      headerHints: headers,
    );
    if (playable == null) {
      PlaybackLogger.resolverActivity(
        'episode-failed',
        bucket: 'series',
        extra: {
          'series': seriesTitle ?? 'unknown',
          'episode': episode.title ?? 'unknown',
        },
      );
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

    PlaybackLogger.resolverActivity(
      'episode-resolved',
      bucket: 'series',
      extra: {
        'title': resolvedTitle,
        'url': _summarizeUrl(playable.url.toString()),
      },
    );
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
    Duration? durationHint,
  }) async {
    PlaybackLogger.videoInfo(
      'build-playable',
      extra: {
        'provider': profile.record.kind.name,
        'bucket': kind.name,
        'isLive': isLive,
        'hasTemplate': streamTemplate != null,
        'hasProviderKey': providerKey != null,
      },
    );

    final isStalkerProvider = profile.record.kind == ProviderKind.stalker;
    if (!isStalkerProvider) {
      final directUri =
          _parseDirectUri(streamTemplate) ?? _parseDirectUri(previewUrl);
      if (directUri != null) {
        PlaybackLogger.videoInfo(
          'direct-uri-found',
          uri: directUri,
          extra: {'provider': profile.record.kind.name},
        );
        final directPlayable = _playableFromUri(
          directUri,
          isLive: isLive,
          headers: _mergeHeaders(headerHints),
        );
        if (directPlayable != null) {
          return directPlayable;
        }
      }
    }
    switch (profile.record.kind) {
      case ProviderKind.xtream:
        if (providerKey == null || providerKey.isEmpty) {
          PlaybackLogger.videoError(
            'xtream-no-provider-key',
            description: 'Missing provider key for Xtream',
          );
          return null;
        }
        PlaybackLogger.videoInfo(
          'xtream-build-start',
          extra: {'bucket': kind.name, 'providerKey': providerKey},
        );
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
          PlaybackLogger.videoError(
            'stalker-no-command',
            description: 'Missing command for Stalker',
          );
          return null;
        }
        PlaybackLogger.videoInfo(
          'stalker-build-start',
          extra: {'bucket': kind.name, 'cmd': _truncate(cmd, max: 150)},
        );
        return _buildStalkerPlayable(
          command: cmd,
          kind: kind,
          isLive: isLive,
          headerHints: headerHints,
          durationHint: durationHint,
        );
      case ProviderKind.m3u:
        if (streamTemplate == null && previewUrl == null) {
          PlaybackLogger.videoError(
            'm3u-no-url',
            description: 'Missing URL for M3U',
          );
          return null;
        }
        final uri =
            _parseDirectUri(streamTemplate) ?? _parseDirectUri(previewUrl);
        if (uri == null) {
          PlaybackLogger.videoError(
            'm3u-parse-failed',
            description: 'Failed to parse M3U URL',
          );
          return null;
        }
        PlaybackLogger.videoInfo('m3u-build-start', uri: uri);
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
    String? ffmpegCommand,
    Duration? durationHint,
    String? rawUrl,
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
      ffmpegCommand: ffmpegCommand,
      durationHint: durationHint,
      rawUrl: rawUrl,
    );
  }

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

    final serverContext = await _ensureXtreamServerContext(
      username: username,
      password: password,
    );
    if (serverContext == null) {
      PlaybackLogger.videoError(
        'xtream-server-info-missing',
        description: 'Xtream server_info unavailable',
      );
      return null;
    }
    final base = _xtreamStreamBase(serverContext);
    final escapedUsername = Uri.encodeComponent(username);
    final escapedPassword = Uri.encodeComponent(password);
    final slugPrefix = 'live/$escapedUsername/$escapedPassword';
    var headers = _mergeHeaders(headerHints);
    headers = _applyXtreamHeaderDefaults(headers, base, username, password);
    if (kind == ContentBucket.live || kind == ContentBucket.radio) {
      final livePlayable = await _buildXtreamLivePlayable(
        base: base,
        slugPrefix: slugPrefix,
        providerKey: providerKey,
        headers: headers,
        templateExtension: templateExtension,
      );
      if (livePlayable != null) {
        return livePlayable;
      }
      return null;
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
    final normalizedTemplate = templateExtension?.toLowerCase();
    final cachedPattern = _xtreamLivePattern;
    if (cachedPattern != null &&
        (normalizedTemplate == null ||
            cachedPattern.extension == normalizedTemplate)) {
      return _playableFromPattern(
        base: base,
        candidate: cachedPattern,
        providerKey: providerKey,
        headers: headers,
      );
    }
    final candidate = await _ensureXtreamLivePattern(
      base: base,
      slugPrefix: slugPrefix,
      providerKey: providerKey,
      headers: headers,
      templateExtension: normalizedTemplate,
    );
    if (candidate == null) {
      return null;
    }
    return _playableFromPattern(
      base: base,
      candidate: candidate,
      providerKey: providerKey,
      headers: headers,
    );
  }

  Future<_XtreamServerContext?> _ensureXtreamServerContext({
    required String username,
    required String password,
  }) async {
    final cached = _xtreamServerContext;
    if (cached != null) {
      return cached;
    }
    final pending = _xtreamServerContextFuture;
    if (pending != null) {
      return pending;
    }
    final future = _fetchXtreamServerContext(
      username: username,
      password: password,
    );
    _xtreamServerContextFuture = future;
    try {
      final context = await future;
      if (context != null && _xtreamServerContext == null) {
        _xtreamServerContext = context;
      }
      return context;
    } finally {
      if (identical(_xtreamServerContextFuture, future)) {
        _xtreamServerContextFuture = null;
      }
    }
  }

  Future<_XtreamServerContext?> _fetchXtreamServerContext({
    required String username,
    required String password,
  }) async {
    final client = _xtreamProbeClient ??= _createXtreamProbeClient();
    final discoveryBase = ensureTrailingSlash(
      stripKnownFiles(
        profile.lockedBase,
        knownFiles: const {
          'player_api.php',
          'get.php',
          'xmltv.php',
          'portal.php',
          'index.php',
        },
      ),
    );
    final playerUri = discoveryBase
        .resolve('player_api.php')
        .replace(queryParameters: {'username': username, 'password': password});
    final request = http.Request('GET', playerUri)
      ..followRedirects = true
      ..maxRedirects = 5;
    final apiHeaders = Map<String, String>.from(
      _applyXtreamHeaderDefaults(
        _profileHeaders,
        discoveryBase,
        username,
        password,
      ),
    );
    apiHeaders['Accept'] = 'application/json';
    request.headers.addAll(apiHeaders);
    try {
      final response = await client.send(request).timeout(_xtreamProbeTimeout);
      final body = await response.stream.bytesToString();
      if (response.statusCode >= 400) {
        PlaybackLogger.videoInfo(
          'xtream-server-info-http',
          uri: playerUri,
          extra: {'code': response.statusCode},
        );
        return null;
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final serverInfo = decoded['server_info'];
      if (serverInfo is! Map) {
        return null;
      }
      final rawScheme = serverInfo['server_protocol']?.toString();
      final scheme = _normalizeXtreamScheme(rawScheme) ?? discoveryBase.scheme;
      final host = _normalizeServerHost(
        serverInfo['url']?.toString(),
        discoveryBase.host,
      );
      final httpPort = _parsePortValue(serverInfo['port']);
      final httpsPort = _parsePortValue(
        serverInfo['https_port'] ?? serverInfo['httpsPort'],
      );
      return _XtreamServerContext(
        scheme: scheme,
        host: host,
        httpPort: httpPort,
        httpsPort: httpsPort,
      );
    } catch (error) {
      PlaybackLogger.videoError(
        'xtream-server-info-error',
        description: 'Failed to load server_info',
        error: error,
      );
      return null;
    }
  }

  Future<_XtreamCandidate?> _ensureXtreamLivePattern({
    required Uri base,
    required String slugPrefix,
    required String providerKey,
    required Map<String, String> headers,
    String? templateExtension,
  }) async {
    final cached = _xtreamLivePattern;
    if (cached != null &&
        (templateExtension == null || cached.extension == templateExtension)) {
      return cached;
    }
    final pending = _xtreamLivePatternFuture;
    if (pending != null) {
      final candidate = await pending;
      if (candidate != null &&
          (templateExtension == null ||
              candidate.extension == templateExtension)) {
        return candidate;
      }
    }
    final future = _probeXtreamLivePattern(
      base: base,
      slugPrefix: slugPrefix,
      providerKey: providerKey,
      headers: headers,
      templateExtension: templateExtension,
    );
    _xtreamLivePatternFuture = future;
    try {
      final candidate = await future;
      if (candidate != null && _xtreamLivePattern == null) {
        _xtreamLivePattern = candidate;
      }
      return candidate;
    } finally {
      if (identical(_xtreamLivePatternFuture, future)) {
        _xtreamLivePatternFuture = null;
      }
    }
  }

  Future<_XtreamCandidate?> _probeXtreamLivePattern({
    required Uri base,
    required String slugPrefix,
    required String providerKey,
    required Map<String, String> headers,
    String? templateExtension,
  }) async {
    final candidates = _xtreamLiveCandidates(
      slugPrefix: slugPrefix,
      templateExtension: templateExtension,
    );
    for (final candidate in candidates) {
      final uri = candidate.resolve(base, providerKey);
      PlaybackLogger.videoInfo(
        'xtream-live-probe-start',
        uri: uri,
        extra: {'template': candidate.pathTemplate},
      );
      final probe = await _probeXtreamCandidate(uri, headers);
      if (probe == null) {
        continue;
      }
      final ext = _determineXtreamExtension(probe, candidate);
      PlaybackLogger.videoInfo(
        'xtream-live-probe-success',
        uri: probe.uri,
        extra: {'ext': ext, 'template': candidate.pathTemplate},
      );
      return _candidateFromProbe(
        original: candidate,
        probe: probe,
        providerKey: providerKey,
        extension: ext,
      );
    }
    PlaybackLogger.videoError(
      'xtream-live-probe-failed',
      description: 'Unable to resolve live stream variants',
    );
    return null;
  }

  Playable _playableFromPattern({
    required Uri base,
    required _XtreamCandidate candidate,
    required String providerKey,
    required Map<String, String> headers,
  }) {
    final uri = candidate.resolve(base, providerKey);
    final ext = (candidate.extension?.isNotEmpty ?? false)
        ? candidate.extension!
        : guessExtensionFromUri(uri);
    final mime = guessMimeFromUri(uri) ?? _mimeFromExtension(ext) ?? '';
    return Playable(
      url: uri,
      isLive: true,
      headers: headers,
      containerExtension: ext,
      mimeHint: mime.isEmpty ? null : mime,
    );
  }

  List<_XtreamCandidate> _xtreamLiveCandidates({
    required String slugPrefix,
    String? templateExtension,
  }) {
    final slug = '$slugPrefix/${_XtreamCandidate.placeholder}';
    final barePrefix = slugPrefix.startsWith('live/')
        ? slugPrefix.substring(5)
        : slugPrefix;
    final bareSlug = '$barePrefix/${_XtreamCandidate.placeholder}';
    final raw = <_XtreamCandidate>[
      _XtreamCandidate(pathTemplate: '$slug.m3u8', extension: 'm3u8'),
      _XtreamCandidate(pathTemplate: '$slug.ts', extension: 'ts'),
      if (barePrefix.isNotEmpty && barePrefix != slugPrefix) ...[
        _XtreamCandidate(pathTemplate: '$bareSlug.m3u8', extension: 'm3u8'),
        _XtreamCandidate(pathTemplate: '$bareSlug.ts', extension: 'ts'),
      ],
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
    final headers = playbackHeaders.isEmpty
        ? <String, String>{}
        : Map<String, String>.from(playbackHeaders);
    headers['Range'] = 'bytes=0-2047';
    return _sendXtreamProbeRequest(
      uri,
      headers,
      method: 'GET',
      playbackHeaders: playbackHeaders,
    );
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
      final response = await client.send(request).timeout(_xtreamProbeTimeout);
      await response.stream.drain();
      final resolvedUri = response.request?.url ?? uri;
      if (response.statusCode >= 200 && response.statusCode < 400) {
        final contentType = response.headers['content-type'];
        if (!_isLikelyPlayableContentType(contentType)) {
          return null;
        }
        return _XtreamProbeResult(
          uri: resolvedUri,
          contentType: contentType,
          playbackHeaders: playbackHeaders ?? Map.unmodifiable(requestHeaders),
        );
      }
      PlaybackLogger.videoInfo(
        'xtream-live-probe-http',
        uri: resolvedUri,
        extra: {'code': response.statusCode, 'method': method},
      );
    } catch (error) {
      PlaybackLogger.videoError(
        'xtream-live-probe-error',
        description: '$method ${uri.toString()}',
        error: error,
      );
      return null;
    }
    return null;
  }

  _XtreamCandidate _candidateFromProbe({
    required _XtreamCandidate original,
    required _XtreamProbeResult probe,
    required String providerKey,
    required String extension,
  }) {
    final template =
        _buildTemplateFromProbe(probe.uri, providerKey) ??
        original.pathTemplate;
    final baseOverride =
        _deriveBaseOverride(probe.uri, providerKey, template) ??
        original.baseOverride;
    return _XtreamCandidate(
      pathTemplate: template,
      extension: extension,
      baseOverride: baseOverride,
    );
  }

  String? _buildTemplateFromProbe(Uri uri, String providerKey) {
    final normalizedPath = uri.path.startsWith('/')
        ? uri.path.substring(1)
        : uri.path;
    final buffer = StringBuffer(normalizedPath);
    if (uri.hasQuery) {
      buffer
        ..write('?')
        ..write(uri.query);
    }
    final replaced = buffer.toString().replaceAll(
      providerKey,
      _XtreamCandidate.placeholder,
    );
    if (!replaced.contains(_XtreamCandidate.placeholder)) {
      return null;
    }
    return replaced;
  }

  Uri? _deriveBaseOverride(Uri uri, String providerKey, String template) {
    final normalizedPath = uri.path.startsWith('/')
        ? uri.path.substring(1)
        : uri.path;
    final realized = template.replaceAll(
      _XtreamCandidate.placeholder,
      providerKey,
    );
    final realizedPath = realized.split('?').first;
    if (!normalizedPath.endsWith(realizedPath)) {
      return null;
    }
    final baseLength = normalizedPath.length - realizedPath.length;
    final baseSegment = baseLength <= 0
        ? ''
        : normalizedPath.substring(0, baseLength);
    final prefixed = baseSegment.isEmpty
        ? '/'
        : baseSegment.startsWith('/')
        ? baseSegment
        : '/$baseSegment';
    final normalizedBase = prefixed.endsWith('/') ? prefixed : '$prefixed/';
    return uri.replace(path: normalizedBase, query: '', fragment: '');
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

  bool _isLikelyPlayableContentType(String? contentType) {
    if (contentType == null || contentType.isEmpty) {
      return true;
    }
    final lowered = contentType.toLowerCase();
    if (lowered.contains('json')) {
      return false;
    }
    if (lowered.contains('html')) {
      return false;
    }
    return true;
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

  Map<String, String> _applyXtreamHeaderDefaults(
    Map<String, String> headers,
    Uri base,
    String username,
    String password,
  ) {
    final normalized = Map<String, String>.from(headers);
    normalized['User-Agent'] = 'VLC/3.0.20';
    normalized['Referer'] = '${base.scheme}://${base.host}/';
    normalized['Host'] = base.host;
    normalized.putIfAbsent('Accept', () => '*/*');
    final creds = base64Encode(utf8.encode('$username:$password'));
    normalized['Authorization'] = 'Basic $creds';
    return Map.unmodifiable(normalized);
  }

  String? _normalizeXtreamScheme(String? value) {
    if (value == null) {
      return null;
    }
    final lower = value.toLowerCase();
    if (lower == 'http' || lower == 'https') {
      return lower;
    }
    return null;
  }

  int? _parsePortValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value > 0 ? value : null;
    }
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  String _normalizeServerHost(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    final trimmed = value.trim();
    if (trimmed.contains('://')) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed != null && parsed.host.isNotEmpty) {
        return parsed.host;
      }
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  String _summarizeResponseBody(dynamic body, {int maxLength = 200}) {
    if (body == null) {
      return '';
    }
    final text = body is String ? body : jsonEncode(body);
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}…';
  }

  Future<Playable?> _buildStalkerPlayable({
    required String command,
    required ContentBucket kind,
    required bool isLive,
    Map<String, String>? headerHints,
    Duration? durationHint,
  }) async {
    var module = _stalkerModuleForBucket(kind);

    // For series episodes with ID format like "8412:3:2" (series:season:episode),
    // use 'vod' module instead of 'series' since create_link doesn't support series
    if (module == 'series' && command.contains(':')) {
      final parts = command.split(':');
      if (parts.length >= 3) {
        PlaybackLogger.stalker(
          'series-episode-detected-using-vod-module',
          portal: profile.lockedBase,
          module: module,
          command: command,
        );
        module = 'vod';
      }
    }

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
    final sessionHeaders = session.buildAuthenticatedHeaders();
    final playbackHeaders = Map<String, String>.from(
      _mergeHeaders(headerHints, overrides: sessionHeaders),
    );
    final directUri = _parseDirectUri(command);
    final queryParameters = <String, dynamic>{
      'type': module,
      'action': 'create_link',
      'token': session.token,
      'mac': config.macAddress.toLowerCase(),
      'cmd': command,
      'JsHttpRequest': '1-xml',
    };

    final result = await _resolveStalkerLinkViaPortalWithFallback(
      config: config,
      module: module,
      command: command,
      queryParameters: queryParameters,
      sessionHeaders: sessionHeaders,
      playbackHeaders: playbackHeaders,
      fallbackUri: directUri,
      isLive: isLive,
      durationHint: durationHint,
    );

    return result;
  }

  Future<Playable?> _resolveStalkerLinkViaPortalWithFallback({
    required StalkerPortalConfiguration config,
    required String module,
    required String command,
    required Map<String, dynamic> queryParameters,
    required Map<String, String> sessionHeaders,
    required Map<String, String> playbackHeaders,
    Uri? fallbackUri,
    required bool isLive,
    Duration? durationHint,
  }) async {
    try {
      final response = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: queryParameters,
        headers: sessionHeaders,
      );
      var effectiveHeaders = _mergePlaybackCookies(
        playbackHeaders,
        response.cookies,
      );
      _logStalkerCreateLinkResponse(
        config: config,
        module: module,
        command: command,
        response: response,
      );
      final resolvedLink = _sanitizeStalkerResolvedLink(
        _extractStalkerLink(response.body),
      );
      PlaybackLogger.videoInfo(
        'stalker-resolved-link',
        extra: {
          'module': module,
          'resolvedLink': resolvedLink ?? 'null',
          'resolvedLinkLength': resolvedLink?.length ?? 0,
        },
      );
      if (resolvedLink == null || resolvedLink.isEmpty) {
        PlaybackLogger.stalker(
          'link-missing',
          portal: config.baseUri,
          module: module,
          command: command,
        );
        return _buildDirectStalkerPlayable(
          fallbackUri: fallbackUri,
          config: config,
          module: module,
          command: command,
          headers: playbackHeaders,
          isLive: isLive,
        );
      }
      final uri = _parseDirectUri(resolvedLink);
      PlaybackLogger.videoInfo(
        'stalker-parse-uri-result',
        extra: {
          'module': module,
          'uriIsNull': uri == null,
          'resolvedLinkPrefix': resolvedLink.length > 50
              ? resolvedLink.substring(0, 50)
              : resolvedLink,
        },
      );
      if (uri == null) {
        PlaybackLogger.stalker(
          'link-parse-failed',
          portal: config.baseUri,
          module: module,
          command: command,
        );
        return _buildDirectStalkerPlayable(
          fallbackUri: fallbackUri,
          config: config,
          module: module,
          command: command,
          headers: playbackHeaders,
          isLive: isLive,
        );
      }

      // Portal link looks usable, proceed normally
      final normalizedUri = _normalizeStalkerResolvedUri(
        uri,
        module: module,
        portal: config.baseUri,
        fallbackUri: fallbackUri,
        fallbackCommand: command,
      );
      effectiveHeaders = _ensureQueryTokenCookies(
        effectiveHeaders,
        normalizedUri,
      );
      final sanitizedHeaders = _sanitizeStalkerPlaybackHeaders(
        effectiveHeaders,
      );
      // Build rawUrl from normalized URI to preserve unencoded MAC addresses
      final patchedRawUrl = _buildRawUrlFromUri(normalizedUri);
      var playable = _playableFromUri(
        normalizedUri,
        isLive: isLive,
        headers: sanitizedHeaders,
        durationHint: durationHint,
        rawUrl: patchedRawUrl,
      );
      PlaybackLogger.videoInfo(
        'stalker-rawurl-set',
        extra: {
          'hasRawUrl': playable?.rawUrl != null,
          'rawUrlPrefix':
              playable?.rawUrl != null && playable!.rawUrl!.length > 80
              ? '${playable.rawUrl!.substring(0, 80)}...'
              : playable?.rawUrl ?? 'null',
          'urlString': playable?.url.toString().substring(0, 80) ?? 'null',
        },
      );
      final inferredExtension = _stalkerExtensionFromUri(normalizedUri);
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
        PlaybackLogger.playableDrop('stalker-unhandled', uri: normalizedUri);
        return _buildDirectStalkerPlayable(
          fallbackUri: fallbackUri,
          config: config,
          module: module,
          command: command,
          headers: playbackHeaders,
          isLive: isLive,
        );
      }
      PlaybackLogger.stalker(
        'resolved',
        portal: config.baseUri,
        module: module,
        command: command,
        resolvedUri: normalizedUri,
        headers: sanitizedHeaders,
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
      return _buildDirectStalkerPlayable(
        fallbackUri: fallbackUri,
        config: config,
        module: module,
        command: command,
        headers: playbackHeaders,
        isLive: isLive,
      );
    }
  }

  Uri _xtreamStreamBase(_XtreamServerContext context) {
    final base = Uri(
      scheme: context.scheme,
      host: context.host,
      port: context.portForScheme(),
      path: '/',
    );
    return ensureTrailingSlash(base);
  }

  void _logStalkerCreateLinkResponse({
    required StalkerPortalConfiguration config,
    required String module,
    required String command,
    required PortalResponseEnvelope response,
  }) {
    final bodyPreview = _summarizeResponseBody(response.body);
    PlaybackLogger.videoInfo(
      'stalker-create-link',
      extra: {
        'portal': config.baseUri.host,
        'module': module,
        'status': response.statusCode,
        'body': bodyPreview,
        'cmd': command,
      },
    );
  }

  Playable? _buildDirectStalkerPlayable({
    required Uri? fallbackUri,
    required StalkerPortalConfiguration config,
    required String module,
    required String command,
    required Map<String, String> headers,
    required bool isLive,
  }) {
    if (fallbackUri == null) {
      return null;
    }
    final sanitizedHeaders = _sanitizeStalkerPlaybackHeaders(headers);
    final playable = _playableFromUri(
      fallbackUri,
      isLive: isLive,
      headers: sanitizedHeaders,
    );
    if (playable == null) {
      PlaybackLogger.playableDrop('stalker-direct-unhandled', uri: fallbackUri);
      return null;
    }
    PlaybackLogger.stalker(
      'direct-fallback',
      portal: config.baseUri,
      module: module,
      command: command,
      resolvedUri: fallbackUri,
      headers: sanitizedHeaders,
    );
    return playable;
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
      final id = js['id'];
      final cmdValue = cmd is String && cmd.trim().isNotEmpty
          ? cmd.trim()
          : null;
      final idValue = id is String && id.trim().isNotEmpty ? id : null;
      // Prioritize cmd over id for proper stream URL
      if (cmdValue != null) {
        return cmdValue;
      }
      if (idValue != null) {
        return idValue;
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
      return <String, String>{};
    }
    return Map<String, String>.from(merged!);
  }

  Map<String, String> _mergePlaybackCookies(
    Map<String, String> playbackHeaders,
    List<String> cookies,
  ) {
    if (cookies.isEmpty) return playbackHeaders;
    final parsed = _parseCookieHeader(playbackHeaders['Cookie']);
    var updated = false;

    void apply(String rawCookie) {
      final trimmed = rawCookie.trim();
      if (trimmed.isEmpty) return;
      final eq = trimmed.indexOf('=');
      if (eq == -1) return;
      final name = trimmed.substring(0, eq).trim();
      final value = trimmed.substring(eq + 1).trim();
      if (name.isEmpty) return;
      // Skip play_token - it should only be in URL query params
      if (name == 'play_token') return;
      final existing = parsed[name];
      if (existing == value) {
        return;
      }
      parsed[name] = value;
      updated = true;
    }

    for (final cookie in cookies) {
      final pair = cookie.split(';').first;
      apply(pair);
    }

    if (!updated) {
      return playbackHeaders;
    }
    final merged = Map<String, String>.from(playbackHeaders);
    merged['Cookie'] = parsed.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
    return merged;
  }

  Map<String, String> _parseCookieHeader(String? header) {
    final map = <String, String>{};
    if (header == null || header.trim().isEmpty) {
      return map;
    }
    final pieces = header.split(';');
    for (final piece in pieces) {
      final trimmed = piece.trim();
      if (trimmed.isEmpty) continue;
      final eq = trimmed.indexOf('=');
      if (eq == -1) continue;
      final name = trimmed.substring(0, eq).trim();
      final value = trimmed.substring(eq + 1).trim();
      if (name.isEmpty) continue;
      map[name] = value;
    }
    return map;
  }

  Map<String, String> _ensureQueryTokenCookies(
    Map<String, String> playbackHeaders,
    Uri uri,
  ) {
    final entries = <String, String>{};
    void capture(String key) {
      final value = uri.queryParameters[key];
      if (value != null && value.isNotEmpty) {
        entries[key] = value;
      }
    }

    // Only capture main token, NOT play_token
    // play_token should only be in URL query params, not in Cookie header
    // This prevents token duplication which may cause 4XX errors
    capture('token');

    if (entries.isEmpty) {
      return playbackHeaders;
    }

    final existing = _parseCookieHeader(playbackHeaders['Cookie']);
    var updated = false;
    entries.forEach((key, value) {
      if (existing[key] == value) {
        return;
      }
      existing[key] = value;
      updated = true;
    });
    if (!updated) {
      return playbackHeaders;
    }
    final merged = Map<String, String>.from(playbackHeaders);
    merged['Cookie'] = existing.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
    return merged;
  }

  Uri _normalizeStalkerResolvedUri(
    Uri uri, {
    required Uri portal,
    required String module,
    required String fallbackCommand,
    Uri? fallbackUri,
  }) {
    final streamParam = uri.queryParameters['stream'];
    if (streamParam != null && streamParam.trim().isNotEmpty) {
      return uri;
    }
    final fallbackStream =
        _extractStreamIdFromUri(fallbackUri) ??
        _extractStreamId(fallbackCommand);
    if (fallbackStream == null || fallbackStream.isEmpty) {
      return uri;
    }
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['stream'] = fallbackStream;
    var patched = uri.replace(queryParameters: qp);
    final patchedQp = Map<String, String>.from(patched.queryParameters);
    final playToken =
        _extractPlayToken(fallbackUri) ??
        _extractPlayTokenUriString(fallbackCommand);
    if (playToken != null && playToken.isNotEmpty) {
      patchedQp.putIfAbsent('play_token', () => playToken);
    }
    final sn2 = patchedQp['sn2'];
    if (sn2 != null && sn2.trim().isEmpty) {
      patchedQp.remove('sn2');
    }
    patched = patched.replace(queryParameters: patchedQp);
    PlaybackLogger.stalker(
      'patched-stream-id',
      portal: portal,
      module: module,
      resolvedUri: patched,
    );
    return patched;
  }

  String? _extractStreamIdFromUri(Uri? uri) {
    if (uri == null) return null;
    final value = uri.queryParameters['stream'];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _extractStreamId(String? source) {
    if (source == null || source.isEmpty) return null;
    final match = RegExp(
      r'stream=([0-9]+)',
      caseSensitive: false,
    ).firstMatch(source);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  String? _extractPlayToken(Uri? uri) {
    if (uri == null) return null;
    final value = uri.queryParameters['play_token'];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  String? _extractPlayTokenUriString(String? source) {
    if (source == null || source.isEmpty) return null;
    final match = RegExp(
      r'play_token=([A-Za-z0-9]+)',
      caseSensitive: false,
    ).firstMatch(source);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  String? _sanitizeStalkerResolvedLink(String? link) {
    if (link == null) return null;
    var trimmed = link.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('ffmpeg ')) {
      final urlMatch = _urlPattern.firstMatch(trimmed);
      if (urlMatch != null) {
        return urlMatch.group(0);
      }
      final space = trimmed.indexOf(' ');
      if (space != -1 && space + 1 < trimmed.length) {
        trimmed = trimmed.substring(space + 1).trim();
      }
    }
    return trimmed.isEmpty ? null : trimmed;
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

    // Check if template is just an extension (e.g., ".mkv" or "mkv")
    // This happens with Xtream episodes where we store container_extension
    final trimmed = template.trim();
    if (trimmed.startsWith('.')) {
      final ext = trimmed.substring(1).toLowerCase();
      if (ext.isNotEmpty && ext.length <= 5) return ext;
    }
    if (!trimmed.contains('/') &&
        !trimmed.contains('://') &&
        trimmed.length <= 5) {
      // Likely just an extension without the dot
      final ext = trimmed.toLowerCase();
      if (RegExp(r'^[a-z0-9]+$').hasMatch(ext)) {
        return ext;
      }
    }

    // Try parsing as URI to extract extension
    final parsed = _parseDirectUri(template);
    if (parsed != null) {
      final ext = guessExtensionFromUri(parsed);
      if (ext.isNotEmpty) return ext;
    }

    // Fall back to simple dot extraction
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

  /// Build URL string from Uri without encoding query parameters.
  /// This preserves literal colons in MAC addresses which Stalker requires.
  String _buildRawUrlFromUri(Uri uri) {
    final buffer = StringBuffer();
    buffer.write(uri.scheme);
    buffer.write('://');
    buffer.write(uri.host);
    if (uri.hasPort &&
        !((uri.scheme == 'http' && uri.port == 80) ||
            (uri.scheme == 'https' && uri.port == 443))) {
      buffer.write(':');
      buffer.write(uri.port);
    }
    buffer.write(uri.path);
    if (uri.hasQuery) {
      buffer.write('?');
      var first = true;
      uri.queryParameters.forEach((key, value) {
        if (!first) buffer.write('&');
        first = false;
        buffer.write(key);
        buffer.write('=');
        buffer.write(value); // Write value without encoding
      });
    }
    if (uri.hasFragment) {
      buffer.write('#');
      buffer.write(uri.fragment);
    }
    return buffer.toString();
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
    this.baseOverride,
  });

  static const placeholder = '{stream_id}';

  final String pathTemplate;
  final String? extension;
  final Uri? baseOverride;

  Uri resolve(Uri base, String providerKey) {
    final resolvedBase = baseOverride ?? base;
    final path = pathTemplate.replaceAll(placeholder, providerKey);
    return resolvedBase.resolve(path);
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

class _XtreamServerContext {
  const _XtreamServerContext({
    required this.scheme,
    required this.host,
    this.httpPort,
    this.httpsPort,
  });

  final String scheme;
  final String host;
  final int? httpPort;
  final int? httpsPort;

  int portForScheme() {
    if (scheme == 'https') {
      return httpsPort ?? httpPort ?? 443;
    }
    return httpPort ?? httpsPort ?? 80;
  }
}

Map<String, String> _sanitizeStalkerPlaybackHeaders(
  Map<String, String> headers,
) {
  // Per stalkerworksnow.md: Never strip Cookie, Authorization, or X-User-Agent
  // All portal session headers must reach ffmpeg/media_kit for Windows playback
  return Map<String, String>.from(headers);
}
