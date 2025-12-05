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
import 'package:openiptv/src/utils/device_identity.dart';
import 'package:openiptv/src/utils/header_json_codec.dart';
import 'package:openiptv/src/utils/playback_logger.dart';
import 'package:openiptv/src/utils/profile_header_utils.dart';
import 'package:openiptv/src/utils/url_normalization.dart';
import 'package:openiptv/src/playback/stream_probe.dart';
import 'package:openiptv/services/webview_session_extractor.dart';
// DEPRECATED: LocalProxyServer is no longer used (RAW TCP mode disabled)
// import 'package:openiptv/src/playback/local_proxy_server.dart';

import 'package:openiptv/src/utils/xtream_flutter_integration.dart';

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
    var durationHint = movie.durationSec != null
        ? Duration(seconds: movie.durationSec!)
        : null;

    if (durationHint == null && profile.record.kind == ProviderKind.stalker) {
      durationHint = await _fetchStalkerMovieDuration(movie.providerVodKey);
    }

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
    var durationHint = episode.durationSec != null
        ? Duration(seconds: episode.durationSec!)
        : null;

    if (durationHint == null && profile.record.kind == ProviderKind.stalker) {
      durationHint = await _fetchStalkerEpisodeDuration(
        episode.providerEpisodeKey,
      );
    }

    final playable = await _buildPlayable(
      kind: ContentBucket.series,
      streamTemplate: episode.streamUrlTemplate,
      providerKey: episode.providerEpisodeKey,
      isLive: false,
      headerHints: headers,
      durationHint: durationHint,
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
          durationHint: durationHint,
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
          durationHint: durationHint,
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
          durationHint: durationHint,
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
    Duration? durationHint,
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

    // No API warmup - will warm up exact stream URL with Range:0-1 instead
    final serverContext = _XtreamServerContext(
      host: profile.record.lockedBase.host,
      scheme: profile.record.lockedBase.scheme,
      httpPort: profile.record.lockedBase.port,
      httpsPort: profile.record.lockedBase.port,
    );

    final base = _xtreamStreamBase(serverContext);
    // SPLIT STRATEGY:
    // Live TV: Use RAW credentials. The server rejects encoded credentials during probe.
    // VOD: Use ENCODED credentials. Direct playback requires safe URLs for players/FFmpeg.

    // 1. Setup for Live (Raw)
    final rawUsername = username;
    final rawPassword = password;

    final deviceId = await DeviceIdentity.getDeviceId();
    var headers = _mergeHeaders(headerHints);
    headers = _applyXtreamHeaderDefaults(
      headers,
      base,
      username,
      password,
      deviceId: deviceId,
    );

    if (kind == ContentBucket.live || kind == ContentBucket.radio) {
      // Skip probe for Live TV - just like VOD, build URL directly
      // Probing causes 401 errors because servers require full authentication
      final ext = templateExtension ?? (isLive ? 'ts' : 'm3u8');

      var manualUrl = SmartUrlBuilder.build(
        host: base.host,
        port: base.port,
        type: 'live',
        username: rawUsername,
        password: rawPassword,
        id: providerKey,
        ext: ext,
        forceHttps: base.scheme == 'https',
      );

      // ALWAYS use Direct Stream mode - bypass RAW TCP proxy (Cloudflare blocks it)
      // Direct mode passes headers to media_kit/player directly (normal HTTP)
      final useDirectStream =
          _config['useDirectStream'] != 'false'; // Default: true

      if (!useDirectStream) {
        PlaybackLogger.videoInfo(
          'xtream-proxy-mode-deprecated',
          uri: Uri.parse(manualUrl),
          extra: {
            'reason': 'RAW TCP proxy mode is deprecated (Cloudflare blocks it)',
            'recommendation': 'Remove useDirectStream=false from configuration',
          },
        );
      }

      // CRITICAL: FFmpeg cannot replicate Android HTTP fingerprint
      // Use LocalProxyServer with XtreamRawClient for exact header order
      final useRawProxy = _config['useRawProxy'] != 'false';

      if (useRawProxy) {
        PlaybackLogger.videoInfo(
          'xtream-raw-proxy-mode',
          uri: Uri.parse(manualUrl),
          extra: {
            'reason':
                'Use raw socket proxy for Android HTTP fingerprint matching',
            'headers': headers,
          },
        );

        // Return URL with custom scheme that LocalProxyServer recognizes
        // Headers will be sent via XtreamRawClient with correct Android order
        return Playable(
          url: Uri.parse(manualUrl),
          isLive: isLive,
          headers: headers, // LocalProxyServer will use XtreamRawClient
          containerExtension: ext,
          mimeHint: guessMimeFromUri(Uri.parse(manualUrl)),
          rawUrl: manualUrl,
        );
      }

      PlaybackLogger.videoInfo(
        'xtream-direct-stream-mode',
        uri: Uri.parse(manualUrl),
        extra: {
          'reason': 'Direct streaming - normal HTTP with headers',
          'cloudflareCompatible': true,
          'proxyDisabled': true,
        },
      );

      // CLOUDFLARE BYPASS: WebView2 Session Extraction
      // If enabled (or forced for known blocked providers), we spin up a headless WebView to get valid cookies/UA
      // For now, we enable it if the user has set 'useWebView' in config, OR if we are on Windows (implied by platform check elsewhere, but here we rely on config)
      final useWebView = _config['useWebView'] == 'true';

      if (useWebView) {
        try {
          // Use the API URL as the target for Cloudflare clearance.
          // The Root URL returns "Access denied", but API returns 200 OK.
          // This allows us to capture any session cookies (like __cf_bm) set by Cloudflare/Server.
          final sessionUrl =
              '${base.scheme}://${base.host}:${base.port}/player_api.php?username=$username&password=$password';

          PlaybackLogger.videoInfo(
            'xtream-webview-start',
            extra: {'url': sessionUrl},
          );
          final session = await WebViewSessionExtractor.getSession(sessionUrl);

          // Create a mutable copy of headers
          final mutableHeaders = Map<String, String>.from(headers);
          mutableHeaders['User-Agent'] = session['User-Agent']!;
          mutableHeaders['Cookie'] = session['Cookie']!;
          headers = Map.unmodifiable(mutableHeaders);

          PlaybackLogger.videoInfo(
            'xtream-webview-success',
            extra: {'ua': headers['User-Agent'], 'cookie': headers['Cookie']},
          );
        } catch (e) {
          PlaybackLogger.videoError('xtream-webview-failed', error: e);
          // Fallback to normal headers (which will likely fail with 401, but we tried)
        }
      }

      PlaybackLogger.videoInfo(
        'xtream-final-headers',
        extra: {'url': manualUrl, 'headers': headers},
      );

      return Playable(
        url: Uri.parse(manualUrl),
        isLive: isLive,
        headers: headers, // Direct headers to media_kit
        containerExtension: ext,
        mimeHint: guessMimeFromUri(Uri.parse(manualUrl)),
        rawUrl: manualUrl,
      );
    }

    // 2. Setup for VOD (Encoded)
    // Use SmartUrlBuilder to handle encoding correctly
    final segment = switch (kind) {
      ContentBucket.live || ContentBucket.radio => 'live',
      ContentBucket.films => 'movie',
      ContentBucket.series => 'series',
    };
    // For VOD, ignore template extension and use proper container format
    // Some providers mistakenly set .ts in templates, but VOD requires .mp4/.mkv
    var ext = (kind == ContentBucket.films || kind == ContentBucket.series)
        ? _resolveXtreamExtension(kind: kind, isLive: isLive)
        : (templateExtension ??
              _resolveXtreamExtension(kind: kind, isLive: isLive));

    PlaybackLogger.videoInfo(
      'xtream-extension-resolved',
      extra: {
        'bucket': kind.name,
        'templateExtension': templateExtension ?? 'null',
        'resolvedExtension': ext,
        'configOutputFormat': _config['outputFormat'] ?? 'null',
      },
    );

    // VOD requires following redirects to get token-based URLs
    if (kind == ContentBucket.films || kind == ContentBucket.series) {
      final manualUrl = SmartUrlBuilder.build(
        host: base.host,
        port: base.port,
        type: segment,
        username: username,
        password: password,
        id: providerKey,
        ext: ext,
        forceHttps: base.scheme == 'https',
      );

      PlaybackLogger.videoInfo(
        'xtream-vod-direct-skip-probe',
        uri: Uri.parse(manualUrl),
        extra: {
          'reason': 'Server blocks GET probe, use direct URL like live streams',
          'extension': ext,
          'manualUrl': manualUrl,
          'encoding': 'smart-builder',
        },
      );

      // ALWAYS use Direct Stream mode - bypass RAW TCP proxy (Cloudflare blocks it)
      // Direct mode passes headers to media_kit/player directly (normal HTTP)
      final useDirectStream =
          _config['useDirectStream'] != 'false'; // Default: true

      if (!useDirectStream) {
        PlaybackLogger.videoInfo(
          'xtream-vod-proxy-mode-deprecated',
          uri: Uri.parse(manualUrl),
          extra: {
            'reason': 'RAW TCP proxy mode is deprecated (Cloudflare blocks it)',
            'recommendation': 'Remove useDirectStream=false from configuration',
          },
        );
      }

      PlaybackLogger.videoInfo(
        'xtream-vod-direct-stream-mode',
        uri: Uri.parse(manualUrl),
        extra: {
          'reason': 'Direct streaming - normal HTTP with headers',
          'cloudflareCompatible': true,
          'proxyDisabled': true,
        },
      );

      // CLOUDFLARE BYPASS: WebView2 Session Extraction (VOD)
      final useWebView = _config['useWebView'] == 'true';

      if (useWebView) {
        try {
          // Use the API URL as the target for Cloudflare clearance.
          // The Root URL returns "Access denied", but API returns 200 OK.
          final sessionUrl =
              '${base.scheme}://${base.host}:${base.port}/player_api.php?username=$username&password=$password';

          PlaybackLogger.videoInfo(
            'xtream-vod-webview-start',
            extra: {'url': sessionUrl},
          );
          final session = await WebViewSessionExtractor.getSession(sessionUrl);

          final mutableHeaders = Map<String, String>.from(headers);
          mutableHeaders['User-Agent'] = session['User-Agent']!;
          mutableHeaders['Cookie'] = session['Cookie']!;
          headers = Map.unmodifiable(mutableHeaders);

          PlaybackLogger.videoInfo(
            'xtream-vod-webview-success',
            extra: {'ua': headers['User-Agent'], 'cookie': headers['Cookie']},
          );
        } catch (e) {
          PlaybackLogger.videoError('xtream-vod-webview-failed', error: e);
        }
      }

      return Playable(
        url: Uri.parse(manualUrl),
        isLive: isLive,
        headers: headers, // Direct headers to media_kit
        containerExtension: ext,
        mimeHint: guessMimeFromUri(Uri.parse(manualUrl)),
        rawUrl: manualUrl,
        durationHint: durationHint,
      );
    }

    // Fallback for unknown types (shouldn't happen given the if block above)
    final path = '$segment/$rawUsername/$rawPassword/$providerKey.$ext';
    final url = base.resolve(path);

    // Probe and resolve redirects/blocking
    Uri finalUri = url;
    try {
      final resolvedUrl = await StreamProbe.resolve(
        url.toString(),
        headers: headers,
      );
      finalUri = Uri.parse(resolvedUrl);
      PlaybackLogger.videoInfo(
        'xtream-probe-resolved',
        uri: finalUri,
        extra: {'original': url.toString()},
      );
    } catch (e) {
      PlaybackLogger.videoError(
        'xtream-probe-failed',
        error: e,
        description: url.toString(),
      );
      // Proxy fallback removed as per user request
    }

    return Playable(
      url: finalUri,
      isLive: isLive,
      headers: headers,
      containerExtension: ext,
      mimeHint: guessMimeFromUri(url),
      durationHint: durationHint,
    );
  }

  String _resolveXtreamExtension({
    required ContentBucket kind,
    required bool isLive,
  }) {
    // For VOD (films/series), always use mp4 regardless of config
    // The outputFormat config is meant for live streams only
    if (kind == ContentBucket.films || kind == ContentBucket.series) {
      return 'mp4';
    }

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

  Map<String, String> _applyXtreamHeaderDefaults(
    Map<String, String> headers,
    Uri base,
    String username,
    String password, {
    String? deviceId,
  }) {
    final normalized = Map<String, String>.from(headers);

    PlaybackLogger.videoInfo(
      'xtream-headers-incoming',
      extra: Map<String, String>.from(normalized),
    );

    // Use standard OkHttp User-Agent (common in IPTV apps like TiviMate)
    normalized.clear();
    normalized['User-Agent'] = 'okhttp/4.9.0';
    normalized['Connection'] =
        'close'; // Use close to avoid max_connections=1 issues

    // TEST: Try without Accept-Encoding - some servers block compressed responses
    // normalized['Accept-Encoding'] = 'gzip';

    // Add Referer - many Xtream servers require this to prevent hotlinking
    final baseUrl =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    normalized['Referer'] = baseUrl;

    // Add X-Device-Id if provided - many Xtream servers require this
    if (deviceId != null && deviceId.isNotEmpty) {
      normalized['X-Device-Id'] = deviceId;
    }

    PlaybackLogger.videoInfo(
      'xtream-headers-generated',
      extra: {
        'User-Agent': normalized['User-Agent']!,
        'Connection': normalized['Connection']!,
        'X-Device-Id': normalized['X-Device-Id'] ?? 'not-set',
        'Referer': normalized['Referer']!,
      },
    );

    return Map.unmodifiable(normalized);
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

    // For clone Stalker servers with embedded episode in cmd, try series module first
    // Standard Stalker uses VOD module, but clones may use series module
    if (module == 'series' && !command.contains('|episode=')) {
      PlaybackLogger.stalker(
        'series-episode-using-vod-module',
        portal: profile.lockedBase,
        module: module,
        command: command,
      );
      module = 'vod';
    } else if (module == 'series') {
      PlaybackLogger.stalker(
        'series-episode-using-series-module',
        portal: profile.lockedBase,
        module: module,
        command: command,
      );
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

    // For live TV: call create_link to get fresh play_token,
    // but use template URL (with stream ID) instead of server's broken response (stream=&)
    /* DISABLED: This pre-emptive interception forces the stream ID, which breaks signature on strict servers (mag.4k365.xyz).
       We will let the standard flow handle it, which respects the server's returned URL (even if stream=&).
    if (isLive && directUri != null) {
      // Clean the command of any old play_token before sending to create_link
      // This prevents the server from seeing an expired token in the request
      var cleanCommand = command;
      if (command.contains('play_token=')) {
        try {
          final cmdUri = Uri.parse(command.trim());
          final newQp = Map<String, String>.from(cmdUri.queryParameters);
          newQp.remove('play_token');
          cleanCommand = cmdUri.replace(queryParameters: newQp).toString();
          // Decode again because toString() encodes query params, but Stalker expects raw colons in mac
          cleanCommand = Uri.decodeFull(cleanCommand);
        } catch (_) {
          // If parsing fails, fallback to regex or just use original
          cleanCommand = command.replaceAll(
            RegExp(r'[?&]play_token=[^&]*'),
            '',
          );
        }
      }

      final queryParameters = <String, dynamic>{
        'type': module,
        'action': 'create_link',
        'token': session.token,
        'mac': config.macAddress.toLowerCase(),
        'cmd': cleanCommand,
        // 'forced_storage': 'undefined', // Removed
        // 'disable_ad': '0', // Removed
        'JsHttpRequest': '1-xml',
      };

      try {
        final response = await _stalkerHttpClient.getPortal(
          config,
          queryParameters: queryParameters,
          headers: sessionHeaders,
        );

        _logStalkerCreateLinkResponse(
          config: config,
          module: module,
          command: command,
          response: response,
        );

        // Extract just the play_token from server response
        final resolvedLink = _sanitizeStalkerResolvedLink(
          _extractStalkerLink(response.body),
        );
        final resolvedUri = resolvedLink != null
            ? Uri.tryParse(resolvedLink)
            : null;
        final freshPlayToken = resolvedUri?.queryParameters['play_token'];

        if (freshPlayToken != null &&
            freshPlayToken.isNotEmpty &&
            resolvedUri != null) {
          // CRITICAL INSIGHT: The server returns stream=& but expects us to use the stream ID we asked for.
          // We must construct a URL that has BOTH the stream ID AND the fresh play_token.
          // We put play_token in the Cookie (not URL) to avoid signature issues if the token signs the URL.
          // This matches the behavior of other players (iptvnator, etc) for Stalker.

          var headers = _mergePlaybackCookies(
            playbackHeaders,
            response.cookies,
          );

          // Ensure play_token is NOT in the cookie (URL-Only Strategy)
          final existingCookies = _parseCookieHeader(headers['Cookie']);
          existingCookies.remove('play_token');
          headers['Cookie'] = existingCookies.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');

          // Use template URL (with correct stream ID)
          final templateQp = Map<String, String>.from(
            directUri.queryParameters,
          );

          // Add sn2 if server returned it
          if (resolvedUri.queryParameters.containsKey('sn2')) {
            templateQp['sn2'] = resolvedUri.queryParameters['sn2']!;
          }

          // REMOVE play_token from URL (it's in the Cookie now)
          templateQp.remove('play_token');

          // Add fresh play_token to URL as well (Double-Token Strategy)
          // Some servers check URL signature (needs token) AND Cookie (needs token)
          templateQp['play_token'] =
              freshPlayToken; // RESTORED: Double token strategy

          final finalUri = directUri.replace(queryParameters: templateQp);

          PlaybackLogger.stalker(
            'live-template-stream-fresh-url-only-token',
            portal: config.baseUri,
            module: module,
            command: command,
          );

          return _buildDirectStalkerPlayable(
            fallbackUri: finalUri,
            config: config,
            module: module,
            command: command,
            headers: _sanitizeStalkerPlaybackHeaders(headers, config: config),
            isLive: isLive,
            rawUrl: _buildRawUrlFromUri(finalUri),
          );
        }
      } catch (e) {
        PlaybackLogger.stalker(
          'live-create-link-failed',
          portal: config.baseUri,
          module: module,
          command: command,
        );
      }
    }
    */

    // For series episodes on clone servers: use VOD create_link with series parameter
    // Format: base64cmd|episode=1 → cmd=base64&series=1
    final queryParameters = <String, dynamic>{
      'type': (module == 'series' || command.contains('|episode='))
          ? 'vod'
          : module,
      'action': 'create_link',
      'token': session.token,
      'mac': config.macAddress.toLowerCase(),
      // 'forced_storage': 'undefined', // Removed: likely undefined in JS means omitted
      // 'disable_ad': '0', // Removed: likely not needed or default
      'JsHttpRequest': '1-xml',
    };

    if (command.contains('|episode=')) {
      final parts = command.split('|episode=');
      final seasonCmd = parts[0]; // base64 season cmd (unchanged)
      final episodeNum = parts[1]; // episode number

      PlaybackLogger.stalker(
        'clone-series-episode-vod-create-link',
        portal: config.baseUri,
        module: module,
        command: 'cmd=$seasonCmd&series=$episodeNum',
      );

      // Clone servers: pass base64 cmd AS-IS + series parameter for episode
      queryParameters['cmd'] = seasonCmd;
      queryParameters['series'] = episodeNum;
    } else {
      // Standard flow: use command as cmd
      // Clean the command of any old play_token before sending to create_link
      var cleanCmd = command;
      if (command.contains('play_token=')) {
        try {
          final cmdUri = Uri.parse(command.trim());
          final newQp = Map<String, String>.from(cmdUri.queryParameters);
          newQp.remove('play_token');
          cleanCmd = cmdUri.replace(queryParameters: newQp).toString();
          cleanCmd = Uri.decodeFull(cleanCmd);
        } catch (_) {
          cleanCmd = command.replaceAll(RegExp(r'[?&]play_token=[^&]*'), '');
        }
      }
      queryParameters['cmd'] = cleanCmd;
    }
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
    int retryCount = 0,
  }) async {
    try {
      final response = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: queryParameters,
        headers: sessionHeaders,
      );

      // Check for auth failure or empty link to trigger session refresh
      final isAuthFailure =
          response.statusCode == 401 || response.statusCode == 403;
      final rawLink = _extractStalkerLink(response.body);
      final resolvedLink = _sanitizeStalkerResolvedLink(rawLink);
      final isLinkMissing = resolvedLink == null || resolvedLink.isEmpty;

      if ((isAuthFailure || isLinkMissing) && retryCount == 0) {
        PlaybackLogger.stalker(
          'session-refresh-retry-${isAuthFailure ? "auth-failure" : "link-missing"}',
          portal: config.baseUri,
          module: module,
          command: command,
        );

        // Force refresh session
        final newSession = await _loadStalkerSession(forceRefresh: true);
        if (newSession != null) {
          // Update token in query params
          final newQueryParams = Map<String, dynamic>.from(queryParameters);
          newQueryParams['token'] = newSession.token;

          // Update session headers
          final newSessionHeaders = newSession.buildAuthenticatedHeaders();

          // Update playback headers with new session headers (Authorization, etc)
          final newPlaybackHeaders = Map<String, String>.from(playbackHeaders);
          newPlaybackHeaders.addAll(newSessionHeaders);

          return _resolveStalkerLinkViaPortalWithFallback(
            config: config,
            module: module,
            command: command,
            queryParameters: newQueryParams,
            sessionHeaders: newSessionHeaders,
            playbackHeaders: newPlaybackHeaders,
            fallbackUri: fallbackUri,
            isLive: isLive,
            durationHint: durationHint,
            retryCount: 1,
          );
        }
      }

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

        // Fallback: If Radio module fails, try ITV module
        // Many providers put radio channels in the ITV system
        // Simplified condition: if we are in 'radio' module and failed, try 'itv'.
        // The recursive call passes module='itv', so we won't loop.
        if (module == 'radio') {
          PlaybackLogger.stalker(
            'radio-fallback-to-itv',
            portal: config.baseUri,
            module: module,
            command: command,
          );
          return _resolveStalkerLinkViaPortalWithFallback(
            config: config,
            module: 'itv', // Switch to ITV
            command: command,
            queryParameters: {
              ...queryParameters,
              'type': 'itv', // Update type param
            },
            sessionHeaders: sessionHeaders,
            playbackHeaders: playbackHeaders,
            fallbackUri: fallbackUri,
            isLive: isLive,
            durationHint: durationHint,
            retryCount: retryCount + 1, // Increment retry count
          );
        }

        // For series episodes, construct URL manually from command
        if (module == 'series' && command.startsWith('{')) {
          try {
            final cmdData = jsonDecode(command) as Map<String, dynamic>;
            final seriesId = cmdData['series_id'];
            final season = cmdData['season'];
            final episode = cmdData['episode'];

            if (seriesId != null && season != null && episode != null) {
              // Try using VOD module with series command - this often works
              // because series episodes are stored as VOD content
              PlaybackLogger.stalker(
                'series-retrying-with-vod-module',
                portal: config.baseUri,
                module: module,
                command: command,
              );

              final vodResult = await _resolveStalkerLinkViaPortalWithFallback(
                config: config,
                module: 'vod', // Use vod module instead of series
                command: command, // Keep the JSON command
                queryParameters: {
                  'type': 'vod',
                  'action': 'create_link',
                  'token': (await _loadStalkerSession())?.token ?? '',
                  'mac': config.macAddress.toLowerCase(),
                  'cmd': command,
                  'JsHttpRequest': '1-xml',
                },
                sessionHeaders: sessionHeaders,
                playbackHeaders: playbackHeaders,
                fallbackUri: null,
                isLive: false,
                durationHint: durationHint,
              );

              if (vodResult != null) {
                return vodResult;
              }
            }
          } catch (e) {
            PlaybackLogger.stalker(
              'series-url-construction-failed',
              portal: config.baseUri,
              module: module,
              command: command,
            );
          }
        }

        return _buildDirectStalkerPlayable(
          fallbackUri: fallbackUri,
          config: config,
          module: module,
          command: command,
          headers: playbackHeaders,
          isLive: isLive,
        );
      }
      // Use the server's URL verbatim - don't parse/rebuild which loses port :80
      // According to stalkerworksnow.md: "Use the portal's ffmpeg command verbatim"
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
          rawUrl: fallbackUri != null ? _buildRawUrlFromUri(fallbackUri) : null,
        );
      }

      // Check if stream parameter is empty/invalid (stream=., stream=&, or stream=)
      final streamParam = uri.queryParameters['stream'] ?? '';

      // If stream is empty, we MUST use the fallback URI (template) because ffmpeg cannot play an empty stream.
      // We ignore whether a play_token is present or not - an empty stream is useless.
      final hasInvalidStream =
          (streamParam.isEmpty || streamParam == '.' || streamParam == '&');

      if (hasInvalidStream) {
        PlaybackLogger.stalker(
          'invalid-stream-parameter',
          portal: config.baseUri,
          module: module,
          command: command,
        );

        // Attempt to recover using fallbackUri (template) and token from server response
        // If server returns stream=& but provides a token, we can apply that token to our known good template
        final freshPlayToken = uri.queryParameters['play_token'];
        if (fallbackUri != null &&
            freshPlayToken != null &&
            freshPlayToken.isNotEmpty) {
          // DO NOT add play_token to Cookie header. It belongs in URL only.
          var headers = _mergePlaybackCookies(
            playbackHeaders,
            response.cookies,
          );
          // Ensure play_token is NOT in the cookie
          final existingCookies = _parseCookieHeader(headers['Cookie']);
          if (existingCookies.containsKey('play_token')) {
            existingCookies.remove('play_token');
            headers['Cookie'] = existingCookies.entries
                .map((e) => '${e.key}=${e.value}')
                .join('; ');
          }

          // Use template URL (with correct stream ID) but remove old play_token
          final templateQp = Map<String, String>.from(
            fallbackUri.queryParameters,
          );

          // Remove old play_token
          templateQp.remove('play_token');

          // Add sn2 if server returned it
          if (uri.queryParameters.containsKey('sn2')) {
            templateQp['sn2'] = uri.queryParameters['sn2']!;
          }

          // Add fresh play_token to URL (Stalker/MAG requirement)
          templateQp['play_token'] = freshPlayToken;

          final finalUri = fallbackUri.replace(queryParameters: templateQp);

          PlaybackLogger.stalker(
            'live-template-stream-fresh-url-token',
            portal: config.baseUri,
            module: module,
            command: command,
          );

          return _buildDirectStalkerPlayable(
            fallbackUri: finalUri,
            config: config,
            module: module,
            command: command,
            headers: _sanitizeStalkerPlaybackHeaders(headers, config: config),
            isLive: isLive,
            rawUrl: _buildRawUrlFromUri(finalUri),
          );
        }

        // For series episodes with JSON command, server doesn't support this format
        // This server requires a different approach for episodes
        return null;
      }

      // Portal link looks usable, proceed normally
      // DO NOT PATCH stream parameter! The server's token is tied to the exact URL it returns.
      // If we modify stream=& to stream=123, the token becomes invalid and server returns 4XX.
      // The server knows which stream to play from the cmd we sent to create_link.
      final rawUrl = resolvedLink; // Use server response exactly as-is
      final normalizedUri = uri;

      effectiveHeaders = _ensureQueryTokenCookies(
        effectiveHeaders,
        normalizedUri,
      );
      final sanitizedHeaders = _sanitizeStalkerPlaybackHeaders(
        effectiveHeaders,
        config: config,
      );
      var playable = _playableFromUri(
        normalizedUri,
        isLive: isLive,
        headers: sanitizedHeaders,
        durationHint: durationHint,
        rawUrl: rawUrl,
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
          rawUrl: fallbackUri != null ? _buildRawUrlFromUri(fallbackUri) : null,
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
        rawUrl: fallbackUri != null ? _buildRawUrlFromUri(fallbackUri) : null,
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
    String? rawUrl,
  }) {
    if (fallbackUri == null) {
      return null;
    }

    // Handle localhost URLs (common in some Stalker portals for internal streams)
    // e.g. http://localhost/ch/123 -> http://portal.com/ch/123
    Uri effectiveUri = fallbackUri;
    if (effectiveUri.host == 'localhost' || effectiveUri.host == '127.0.0.1') {
      effectiveUri = effectiveUri.replace(
        scheme: config.baseUri.scheme,
        host: config.baseUri.host,
        port: config.baseUri.port,
      );
      PlaybackLogger.stalker(
        'localhost-rewrite',
        portal: config.baseUri,
        module: module,
        command: command,
        resolvedUri: effectiveUri,
      );
    }

    // Ensure play_token from URL is added to Cookie header
    final effectiveHeaders = _ensureQueryTokenCookies(headers, effectiveUri);
    final sanitizedHeaders = _sanitizeStalkerPlaybackHeaders(
      effectiveHeaders,
      config: config,
    );

    // If we have a play_token in the cookie, remove it from the URL
    // This helps with servers that return 4XX when token is in both places
    // Strategy: Cookie Only (Strip from URL)
    // UPDATE: Re-enabling token in URL because some servers require it in the request line
    /*
    if (effectiveUri.queryParameters.containsKey('play_token')) {
      final newQueryParams = Map<String, String>.from(
        effectiveUri.queryParameters,
      );
      newQueryParams.remove('play_token');
      effectiveUri = effectiveUri.replace(queryParameters: newQueryParams);
    }
    */

    final playable = _playableFromUri(
      effectiveUri,
      isLive: isLive,
      headers: sanitizedHeaders,
      // Regenerate rawUrl from effectiveUri to ensure changes (localhost rewrite, token removal) are applied
      rawUrl: _buildRawUrlFromUri(effectiveUri),
    );
    if (playable == null) {
      PlaybackLogger.playableDrop(
        'stalker-direct-unhandled',
        uri: effectiveUri,
      );
      return null;
    }
    PlaybackLogger.stalker(
      'direct-fallback',
      portal: config.baseUri,
      module: module,
      command: command,
      resolvedUri: effectiveUri,
      headers: sanitizedHeaders,
    );
    return playable;
  }

  StalkerPortalConfiguration? _buildStalkerConfiguration() {
    final mac = _config['macAddress'] ?? '';
    if (mac.isEmpty) {
      return null;
    }

    // Prepare MAG headers for API calls (create_link, etc)
    final extra = Map<String, String>.from(_profileHeaders);

    // Force MAG headers
    extra['X-User-Agent'] = 'Model:MAG254; Link:Ethernet';

    // Ensure Referer points to the portal interface
    final base = profile.lockedBase;
    var referer = base.toString();
    if (!referer.contains('stalker_portal/c')) {
      referer = base.resolve('stalker_portal/c/').toString();
    }
    if (!referer.endsWith('/')) {
      referer = '$referer/';
    }
    extra['Referer'] = referer;

    // Force MAG User-Agent
    const magUA =
        'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) InfomirBrowser/3.0 StbApp/0.23';

    return StalkerPortalConfiguration(
      baseUri: profile.lockedBase,
      macAddress: mac,
      userAgent: magUA,
      allowSelfSignedTls: profile.record.allowSelfSignedTls,
      extraHeaders: extra,
    );
  }

  Future<StalkerSession?> _loadStalkerSession({
    bool forceRefresh = false,
  }) async {
    final config = _stalkerConfig ??= _buildStalkerConfiguration();
    if (config == null) {
      return null;
    }
    final cached = _stalkerSession;
    if (!forceRefresh && cached != null && !cached.isExpired) {
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

      // EXCLUDE play_token from Cookie header per Stalker/MAG compatibility rules
      // if (name == 'play_token') return; // RESTORED: Allow play_token in Cookie

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

    // Capture token for Cookie header, but NOT play_token
    // play_token must be in URL only for Stalker/MAG compatibility
    capture('token'); // RESTORED: Session token belongs in Cookie
    // capture('play_token'); // REMOVED: play_token belongs in URL only for standard Stalker

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
    // Always include port, even default ports like 80
    // Stalker servers require explicit :80 in URL
    // uri.hasPort returns false for default ports, but uri.port still has the value
    final port = uri.port;
    if (port > 0) {
      buffer.write(':');
      buffer.write(port);
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

  Future<Duration?> _fetchStalkerMovieDuration(String movieId) async {
    try {
      final session = await _loadStalkerSession();
      if (session == null) return null;
      final config = _stalkerConfig!;

      final response = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: {
          'type': 'vod',
          'action': 'get_info',
          'media_id': movieId,
          'token': session.token,
          'mac': config.macAddress.toLowerCase(),
          'JsHttpRequest': '1-xml',
        },
        headers: session.buildAuthenticatedHeaders(),
      );

      var data = _decodePortalPayload(response.body);
      if (data.containsKey('js') && data['js'] is Map) {
        data = Map<String, dynamic>.from(data['js']);
      } else if (data.containsKey('data') && data['data'] is Map) {
        data = Map<String, dynamic>.from(data['data']);
      }

      return _parseStalkerDuration(data);
    } catch (e) {
      PlaybackLogger.videoError(
        'stalker-movie-duration-fetch-failed',
        error: e,
      );
      return null;
    }
  }

  Future<Duration?> _fetchStalkerEpisodeDuration(String episodeId) async {
    try {
      final session = await _loadStalkerSession();
      if (session == null) return null;
      final config = _stalkerConfig!;

      // Try get_episode first
      var response = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: {
          'type': 'series',
          'action': 'get_episode',
          'episode_id': episodeId,
          'token': session.token,
          'mac': config.macAddress.toLowerCase(),
          'JsHttpRequest': '1-xml',
        },
        headers: session.buildAuthenticatedHeaders(),
      );

      var data = _decodePortalPayload(response.body);
      if (data.containsKey('js') && data['js'] is Map) {
        data = Map<String, dynamic>.from(data['js']);
      }

      var duration = _parseStalkerDuration(data);
      if (duration != null) return duration;

      // Fallback to vod get_info with episode ID (common for clones)
      response = await _stalkerHttpClient.getPortal(
        config,
        queryParameters: {
          'type': 'vod',
          'action': 'get_info',
          'media_id': episodeId,
          'token': session.token,
          'mac': config.macAddress.toLowerCase(),
          'JsHttpRequest': '1-xml',
        },
        headers: session.buildAuthenticatedHeaders(),
      );
      data = _decodePortalPayload(response.body);
      if (data.containsKey('js') && data['js'] is Map) {
        data = Map<String, dynamic>.from(data['js']);
      }
      return _parseStalkerDuration(data);
    } catch (e) {
      PlaybackLogger.videoError(
        'stalker-episode-duration-fetch-failed',
        error: e,
      );
      return null;
    }
  }

  Duration? _parseStalkerDuration(Map<String, dynamic> data) {
    // 1. duration_in_seconds (int)
    if (data['duration_in_seconds'] != null) {
      final val = int.tryParse(data['duration_in_seconds'].toString());
      if (val != null && val > 0) return Duration(seconds: val);
    }

    // 2. duration (HH:MM:SS)
    if (data['duration'] != null) {
      final val = data['duration'].toString();
      if (val.contains(':')) {
        final parts = val.split(':').reversed.toList();
        var seconds = 0;
        for (var i = 0; i < parts.length; i++) {
          seconds += (int.tryParse(parts[i]) ?? 0) * [1, 60, 3600][i];
        }
        if (seconds > 0) return Duration(seconds: seconds);
      }
    }

    // 3. time (seconds or string)
    if (data['time'] != null) {
      final val = int.tryParse(data['time'].toString());
      if (val != null && val > 0) return Duration(seconds: val);
    }

    // 4. length (minutes)
    if (data['length'] != null) {
      final val = int.tryParse(data['length'].toString());
      if (val != null && val > 0) return Duration(minutes: val);
    }

    // 5. movie_length (minutes)
    if (data['movie_length'] != null) {
      final val = int.tryParse(data['movie_length'].toString());
      if (val != null && val > 0) return Duration(minutes: val);
    }

    return null;
  }
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

Map<String, String> _sanitizeStalkerPlaybackHeaders(
  Map<String, String> headers, {
  StalkerPortalConfiguration? config,
}) {
  // Per stalkerworksnow.md: Never strip Cookie, Authorization, or X-User-Agent
  // All portal session headers must reach ffmpeg/media_kit for Windows playback
  final sanitized = Map<String, String>.from(headers);

  // FORCE MAG headers required for playback
  // We overwrite existing values because they might be incorrect (e.g. X-User-Agent matching User-Agent)
  sanitized['User-Agent'] =
      'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) InfomirBrowser/3.0 StbApp/0.23';

  sanitized['X-User-Agent'] = 'Model:MAG254; Link:Ethernet';

  // Force Accept to */* for media streams (ffmpeg default)
  sanitized['Accept'] = '*/*';

  // Remove Authorization header for playback requests
  // The media server (play/live.php) authenticates via Cookie/URL params (mac, token)
  // Sending 'Authorization: Bearer ...' can cause 400/403 errors on strict servers
  sanitized.remove('Authorization');

  // Remove Referer and Origin headers
  // Stalker servers often reject playback requests with a Referer header (hotlinking protection)
  // The stream URL is signed with a token, so Referer is not needed for security
  // sanitized.remove('Referer'); // RESTORED: Some servers might need it
  sanitized.remove('Origin');

  // Remove Cookie header entirely for playback
  // The 'play_token' and 'mac' are in the URL, which is sufficient for authentication.
  // Sending Cookies (especially 'mac' or 'token') can cause 4XX errors (e.g. 406/412)
  // on some servers due to conflict or anti-bot protection.
  // sanitized.remove('Cookie'); // RESTORED: We are now putting play_token in Cookie

  // Remove 'token' (session token) from Cookie if present
  // Some servers (e.g. mag.4k365.xyz) reject playback if session token is in cookie
  // The 'play_token' in the Cookie is sufficient and correct for playback
  /* RESTORED: We are keeping the session token because "YOU ARE BANNED" might mean "missing session token".
  if (sanitized.containsKey('Cookie')) {
    final cookies = _parseCookieHeader(sanitized['Cookie']);
    if (cookies.containsKey('token')) {
      cookies.remove('token');
      if (cookies.isEmpty) {
        sanitized.remove('Cookie');
      } else {
        sanitized['Cookie'] = cookies.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');
      }
    }
  }
  */
  if (config != null) {
    // Ensure Referer points to the portal interface
    // Usually http://host/stalker_portal/c/
    // RESTORED: Standard Stalker behavior requires Referer
    final base = config.baseUri;
    var referer = base.toString();

    // Ensure it points to /c/ directory
    if (!referer.contains('stalker_portal/c')) {
      referer = base.resolve('stalker_portal/c/').toString();
    }

    // STRICTLY ensure trailing slash for Referer
    if (!referer.endsWith('/')) {
      referer = '$referer/';
    }
    sanitized['Referer'] = referer;
  }

  return sanitized;
}
