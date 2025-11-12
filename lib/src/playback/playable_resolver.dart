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
    headers = _applyXtreamHeaderDefaults(
      headers,
      base,
      username,
      password,
    );
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
    final playerUri = discoveryBase.resolve('player_api.php').replace(
      queryParameters: {
        'username': username,
        'password': password,
      },
    );
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
      final response =
          await client.send(request).timeout(_xtreamProbeTimeout);
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
      final scheme =
          _normalizeXtreamScheme(rawScheme) ?? discoveryBase.scheme;
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
        (templateExtension == null ||
            cached.extension == templateExtension)) {
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
    final barePrefix =
        slugPrefix.startsWith('live/') ? slugPrefix.substring(5) : slugPrefix;
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
      final response =
          await client.send(request).timeout(_xtreamProbeTimeout);
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
        _buildTemplateFromProbe(probe.uri, providerKey) ?? original.pathTemplate;
    final baseOverride =
        _deriveBaseOverride(probe.uri, providerKey, template) ?? original.baseOverride;
    return _XtreamCandidate(
      pathTemplate: template,
      extension: extension,
      baseOverride: baseOverride,
    );
  }

  String? _buildTemplateFromProbe(Uri uri, String providerKey) {
    final normalizedPath =
        uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    final buffer = StringBuffer(normalizedPath);
    if (uri.hasQuery) {
      buffer
        ..write('?')
        ..write(uri.query);
    }
    final replaced =
        buffer.toString().replaceAll(providerKey, _XtreamCandidate.placeholder);
    if (!replaced.contains(_XtreamCandidate.placeholder)) {
      return null;
    }
    return replaced;
  }

  Uri? _deriveBaseOverride(
    Uri uri,
    String providerKey,
    String template,
  ) {
    final normalizedPath =
        uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    final realized = template.replaceAll(
      _XtreamCandidate.placeholder,
      providerKey,
    );
    final realizedPath = realized.split('?').first;
    if (!normalizedPath.endsWith(realizedPath)) {
      return null;
    }
    final baseLength = normalizedPath.length - realizedPath.length;
    final baseSegment =
        baseLength <= 0 ? '' : normalizedPath.substring(0, baseLength);
    final prefixed =
        baseSegment.isEmpty ? '/' : baseSegment.startsWith('/') ? baseSegment : '/$baseSegment';
    final normalizedBase =
        prefixed.endsWith('/') ? prefixed : '$prefixed/';
    return uri.replace(
      path: normalizedBase,
      query: '',
      fragment: '',
    );
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
        overrides: sessionHeaders,
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

  Uri _xtreamStreamBase(_XtreamServerContext context) {
    final base = Uri(
      scheme: context.scheme,
      host: context.host,
      port: context.portForScheme(),
      path: '/',
    );
    return ensureTrailingSlash(base);
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
