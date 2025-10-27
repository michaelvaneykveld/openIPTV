import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../discovery/portal_discovery.dart';
import '../../utils/url_normalization.dart';

/// Discovers and validates M3U playlists (remote URLs or local files).
class M3uPortalDiscovery implements PortalDiscovery {
  const M3uPortalDiscovery({Dio? dio}) : _overrideDio = dio;

  final Dio? _overrideDio;
  static const _transientStatuses = <int>{HttpStatus.serviceUnavailable, 512};

  static const _m3uContentTypes = <String>{
    'application/x-mpegurl',
    'application/vnd.apple.mpegurl',
    'audio/x-mpegurl',
    'audio/mpegurl',
    'application/octet-stream',
    'text/plain',
  };

  static const _fallbackUserAgent =
      'VLC/3.0.18 (Live IPTV) Flutter/OpenIPTV M3UProbe';

  static const _sensitiveQueryKeys = {'username', 'password', 'token'};

  @override
  ProviderKind get kind => ProviderKind.m3u;

  @override
  Future<DiscoveryResult> discover(
    String userInput, {
    DiscoveryOptions options = DiscoveryOptions.defaults,
  }) async {
    final normalization = _normalizeInput(userInput);

    if (normalization.xtreamBase != null) {
      // This input is actually an Xtream portal masquerading as a playlist.
      return DiscoveryResult(
        kind: ProviderKind.xtream,
        lockedBase: normalization.xtreamBase!,
        hints: const {'redirect': 'xtream'},
      );
    }

    if (normalization.isLocalFile) {
      return _discoverLocalFile(normalization.filePath!);
    }

    return _discoverRemotePlaylist(
      normalization.playlistUri!,
      options: options,
    );
  }

  _NormalizedInput _normalizeInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException(
        'Provide a playlist URL or local file path to continue.',
      );
    }

    if (_looksLikeLocalPath(trimmed)) {
      return _NormalizedInput.file(trimmed);
    }

    final canonical = canonicalizeScheme(trimmed);
    late Uri parsed;
    try {
      parsed = Uri.parse(canonical);
    } on FormatException {
      throw const FormatException('Playlist URL is not a valid URI.');
    }

    if (parsed.host.isEmpty) {
      throw const FormatException('Playlist URL is missing a host name.');
    }

    final lowered = parsed.replace(
      scheme: parsed.scheme.toLowerCase(),
      host: parsed.host.toLowerCase(),
    );

    if (_looksLikeXtream(lowered)) {
      return _NormalizedInput.remote(
        lowered,
        xtreamBase: _deriveXtreamBase(lowered),
      );
    }

    return _NormalizedInput.remote(lowered);
  }

  bool _looksLikeLocalPath(String value) {
    final windowsPath = RegExp(r'^[a-zA-Z]:[\\/]');
    final uncPath = value.startsWith('\\\\');
    final unixPath = value.startsWith('/') || value.startsWith('~/');
    return windowsPath.hasMatch(value) || uncPath || unixPath;
  }

  bool _looksLikeXtream(Uri uri) {
    final path = uri.path.toLowerCase();
    final query = uri.queryParameters;
    final hasCredentials =
        query.containsKey('username') && query.containsKey('password');
    final hasMarkers =
        path.contains('player_api.php') ||
        path.contains('get.php') ||
        path.contains('xmltv.php');
    return hasCredentials || hasMarkers;
  }

  Uri _deriveXtreamBase(Uri uri) {
    final stripped = stripKnownFiles(
      uri,
      knownFiles: const {'player_api.php', 'get.php', 'xmltv.php'},
    );
    return ensureTrailingSlash(stripped);
  }

  Future<DiscoveryResult> _discoverLocalFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw DiscoveryException(
        'Playlist file could not be found. Confirm the path and try again.',
      );
    }

    final stat = await file.stat();
    if (stat.size <= 0) {
      throw DiscoveryException(
        'Playlist file appears to be empty. Verify the download completed.',
      );
    }

    final preview = await file
        .openRead(0, 4096)
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .take(5)
        .join('\n');

    if (!preview.toUpperCase().contains('#EXTM3U')) {
      throw DiscoveryException(
        'Playlist file does not look like an M3U playlist (#EXTM3U missing).',
      );
    }

    final hints = <String, String>{
      'fileBytes': stat.size.toString(),
      'modifiedAt': stat.modified.toUtc().toIso8601String(),
    };

    return DiscoveryResult(
      kind: ProviderKind.m3u,
      lockedBase: Uri.file(path),
      hints: hints,
    );
  }

  Future<DiscoveryResult> _discoverRemotePlaylist(
    Uri playlistUri, {
    required DiscoveryOptions options,
  }) async {
    final telemetryRecords = <DiscoveryProbeRecord>[];
    final dio = _overrideDio ?? _createClient(options);
    _applyTlsOverrides(dio, options.allowSelfSignedTls);

    final candidates = _buildCandidates(playlistUri);
    DioException? lastException;
    bool needsUaHint = false;

    for (final candidate in candidates) {
      final outcome = await _probeCandidate(
        dio: dio,
        candidate: candidate,
        options: options,
        telemetry: telemetryRecords,
      );

      lastException = outcome.error ?? lastException;
      needsUaHint = needsUaHint || outcome.needsUserAgent;

      if (outcome.matched) {
        final hints = <String, String>{
          'matchedStage': outcome.matchedStage ?? 'unknown',
          'sanitizedPlaylist': _redactSecrets(outcome.lockedUri!).toString(),
        };
        if (needsUaHint || outcome.needsUserAgent) {
          hints['needsMediaUserAgent'] = 'true';
        }

        return DiscoveryResult(
          kind: ProviderKind.m3u,
          lockedBase: outcome.lockedUri!,
          hints: hints,
          telemetry: DiscoveryTelemetry(probes: telemetryRecords),
        );
      }
    }

    throw DiscoveryException(
      lastException?.message ??
          'Unable to fetch a valid playlist from the supplied URL.',
      telemetry: DiscoveryTelemetry(probes: telemetryRecords),
    );
  }

  Dio _createClient(DiscoveryOptions options) {
    final headers = <String, String>{
      'Accept':
          'application/x-mpegurl, audio/x-mpegurl, application/vnd.apple.mpegurl, */*;q=0.2',
      'Accept-Encoding': 'identity',
      'Connection': 'close',
      ...options.headers,
    };

    final userAgent = options.userAgent?.trim();
    if (userAgent != null && userAgent.isNotEmpty) {
      headers['User-Agent'] = userAgent;
    }

    final baseOptions = BaseOptions(
      connectTimeout: const Duration(milliseconds: 1500),
      receiveTimeout: const Duration(milliseconds: 2000),
      followRedirects: true,
      maxRedirects: 5,
      headers: headers,
      validateStatus: (status) => status != null && status < 600,
    );

    return Dio(baseOptions);
  }

  Future<_ProbeOutcome> _probeCandidate({
    required Dio dio,
    required _M3uCandidate candidate,
    required DiscoveryOptions options,
    required List<DiscoveryProbeRecord> telemetry,
  }) async {
    var headOutcome = await _attemptHead(
      dio: dio,
      uri: candidate.uri,
      options: options,
      telemetry: telemetry,
      stage: 'HEAD',
    );

    var hasRetriedHead = false;
    if (!headOutcome.matched &&
        _shouldRetryStatus(headOutcome.statusCode) &&
        !hasRetriedHead) {
      headOutcome = await _attemptHead(
        dio: dio,
        uri: candidate.uri,
        options: options,
        telemetry: telemetry,
        stage: 'HEAD (retry)',
      );
      hasRetriedHead = true;
    }

    if (!headOutcome.matched &&
        _shouldRetryException(headOutcome.error) &&
        !hasRetriedHead) {
      headOutcome = await _attemptHead(
        dio: dio,
        uri: candidate.uri,
        options: options,
        telemetry: telemetry,
        stage: 'HEAD (retry)',
      );
      hasRetriedHead = true;
    }

    if (headOutcome.matched) {
      return _ProbeOutcome.matched(
        headOutcome.resolvedUri,
        matchedStage: headOutcome.stageLabel,
      );
    }

    final shouldTryGet =
        headOutcome.statusCode == null ||
        headOutcome.statusCode! >= HttpStatus.multipleChoices;

    _AttemptOutcome? rangeOutcome;
    if (shouldTryGet) {
      rangeOutcome = await _attemptRangeGet(
        dio: dio,
        uri: candidate.uri,
        options: options,
        telemetry: telemetry,
        stage: 'RANGE',
      );
      var hasRetriedRange = false;
      if (!rangeOutcome.matched &&
          _shouldRetryStatus(rangeOutcome.statusCode) &&
          !hasRetriedRange) {
        rangeOutcome = await _attemptRangeGet(
          dio: dio,
          uri: candidate.uri,
          options: options,
          telemetry: telemetry,
          stage: 'RANGE (retry)',
        );
        hasRetriedRange = true;
      }

      if (!rangeOutcome.matched &&
          _shouldRetryException(rangeOutcome.error) &&
          !hasRetriedRange) {
        rangeOutcome = await _attemptRangeGet(
          dio: dio,
          uri: candidate.uri,
          options: options,
          telemetry: telemetry,
          stage: 'RANGE (retry)',
        );
        hasRetriedRange = true;
      }

      if (rangeOutcome.matched) {
        return _ProbeOutcome.matched(
          rangeOutcome.resolvedUri,
          matchedStage: rangeOutcome.stageLabel,
        );
      }
    }

    final needsUaRetry =
        (headOutcome.shouldRetryWithUa ||
            (rangeOutcome?.shouldRetryWithUa ?? false)) &&
        options.userAgent == null;

    if (needsUaRetry) {
      final retryOptions = DiscoveryOptions(
        allowSelfSignedTls: options.allowSelfSignedTls,
        headers: options.headers,
        userAgent: _fallbackUserAgent,
        macAddress: options.macAddress,
        logSink: options.logSink,
      );

      final retryOutcome = await _attemptRangeGet(
        dio: dio,
        uri: candidate.uri,
        options: retryOptions,
        telemetry: telemetry,
        stage: 'RANGE (UA retry)',
      );

      if (retryOutcome.matched) {
        return _ProbeOutcome.matched(
          retryOutcome.resolvedUri,
          matchedStage: 'RANGE (UA retry)',
          needsUserAgent: true,
        );
      }

      return _ProbeOutcome.failure(
        error: retryOutcome.error ?? rangeOutcome?.error ?? headOutcome.error,
        needsUserAgent: true,
      );
    }

    return _ProbeOutcome.failure(
      error: rangeOutcome?.error ?? headOutcome.error,
    );
  }

  Future<_AttemptOutcome> _attemptHead({
    required Dio dio,
    required Uri uri,
    required DiscoveryOptions options,
    required List<DiscoveryProbeRecord> telemetry,
    required String stage,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await dio.headUri(
        uri,
        options: Options(headers: {...options.headers}),
      );
      stopwatch.stop();

      final resolved = response.realUri;
      final matched = _looksLikeM3uContent(response);

      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: _redactSecrets(resolved),
        statusCode: response.statusCode,
        elapsed: stopwatch.elapsed,
        matchedSignature: matched,
      );
      telemetry.add(record);
      options.logSink?.call(record);

      return _AttemptOutcome(
        matched: matched,
        sanitizedUri: record.uri,
        resolvedUri: resolved,
        stageLabel: stage,
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: _redactSecrets(error.response?.realUri ?? uri),
        statusCode: error.response?.statusCode,
        elapsed: stopwatch.elapsed,
        error: error,
      );
      telemetry.add(record);
      options.logSink?.call(record);

      return _AttemptOutcome(
        matched: false,
        sanitizedUri: record.uri,
        resolvedUri: error.response?.realUri ?? uri,
        stageLabel: stage,
        statusCode: error.response?.statusCode,
        error: error,
      );
    }
  }

  Future<_AttemptOutcome> _attemptRangeGet({
    required Dio dio,
    required Uri uri,
    required DiscoveryOptions options,
    required List<DiscoveryProbeRecord> telemetry,
    required String stage,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final headers = <String, String>{
        ...options.headers,
        'Range': 'bytes=0-4095',
      };
      final ua = options.userAgent?.trim();
      if (ua != null && ua.isNotEmpty) {
        headers['User-Agent'] = ua;
      }

      final response = await dio.getUri(
        uri,
        options: Options(responseType: ResponseType.plain, headers: headers),
      );
      stopwatch.stop();

      final body = response.data?.toString() ?? '';
      final matched = _looksLikeM3uBody(body);
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: _redactSecrets(response.realUri),
        statusCode: response.statusCode,
        elapsed: stopwatch.elapsed,
        matchedSignature: matched,
      );
      telemetry.add(record);
      options.logSink?.call(record);

      return _AttemptOutcome(
        matched: matched,
        sanitizedUri: record.uri,
        resolvedUri: response.realUri,
        stageLabel: stage,
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: _redactSecrets(error.response?.realUri ?? uri),
        statusCode: error.response?.statusCode,
        elapsed: stopwatch.elapsed,
        error: error,
      );
      telemetry.add(record);
      options.logSink?.call(record);

      return _AttemptOutcome(
        matched: false,
        sanitizedUri: record.uri,
        resolvedUri: error.response?.realUri ?? uri,
        stageLabel: stage,
        statusCode: error.response?.statusCode,
        error: error,
      );
    }
  }

  void _applyTlsOverrides(Dio dio, bool allowSelfSigned) {
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      if (allowSelfSigned) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };
      } else {
        adapter.createHttpClient = null;
      }
    }
  }

  List<_M3uCandidate> _buildCandidates(Uri uri) {
    final seen = <String>{};
    final candidates = <_M3uCandidate>[];

    void add(Uri candidate) {
      final key = candidate.toString();
      if (seen.add(key)) {
        candidates.add(_M3uCandidate(candidate));
      }
    }

    add(uri);
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final flipped = uri.scheme == 'https'
          ? uri.replace(scheme: 'http')
          : uri.replace(scheme: 'https');
      add(flipped);
    }

    return candidates;
  }

  bool _looksLikeM3uContent(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= HttpStatus.badRequest) {
      return false;
    }
    final type = response.headers.value('content-type');
    if (type == null || type.isEmpty) {
      return false;
    }
    final lower = type.toLowerCase();
    return _m3uContentTypes.any(lower.contains);
  }

  bool _shouldRetryStatus(int? status) {
    if (status == null) return false;
    return _transientStatuses.contains(status);
  }

  bool _shouldRetryException(DioException? error) {
    if (error == null) return false;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      final message = error.message ?? error.error?.toString() ?? '';
      return message.contains('Connection closed before full header') ||
          message.contains('Connection reset by peer');
    }
    return false;
  }

  bool _looksLikeM3uBody(String body) {
    return body.toUpperCase().contains('#EXTM3U');
  }

  Uri _redactSecrets(Uri uri) {
    Map<String, String> sanitized = const {};
    if (uri.hasQuery) {
      try {
        sanitized = Uri.splitQueryString(uri.query, encoding: utf8);
      } catch (_) {
        sanitized = {};
      }
      sanitized = Map.of(sanitized);
      sanitized.removeWhere(
        (key, value) => _sensitiveQueryKeys.contains(key.toLowerCase()),
      );
    }

    final queryString = sanitized.isEmpty
        ? ''
        : Uri(queryParameters: sanitized).query;

    final cleaned = uri.replace(userInfo: '', query: queryString);
    if (sanitized.isEmpty) {
      final value = cleaned.toString();
      final separatorIndex = value.indexOf('?');
      if (separatorIndex != -1) {
        return Uri.parse(value.substring(0, separatorIndex));
      }
    }
    return cleaned;
  }
}

class _NormalizedInput {
  final bool isLocalFile;
  final String? filePath;
  final Uri? playlistUri;
  final Uri? xtreamBase;

  const _NormalizedInput._({
    required this.isLocalFile,
    this.filePath,
    this.playlistUri,
    this.xtreamBase,
  });

  factory _NormalizedInput.file(String path) =>
      _NormalizedInput._(isLocalFile: true, filePath: path);

  factory _NormalizedInput.remote(Uri uri, {Uri? xtreamBase}) =>
      _NormalizedInput._(
        isLocalFile: false,
        playlistUri: uri,
        xtreamBase: xtreamBase,
      );
}

class _M3uCandidate {
  const _M3uCandidate(this.uri);

  final Uri uri;
}

class _AttemptOutcome {
  _AttemptOutcome({
    required this.matched,
    required this.sanitizedUri,
    required this.resolvedUri,
    required this.stageLabel,
    this.statusCode,
    this.error,
  });

  final bool matched;
  final Uri sanitizedUri;
  final Uri resolvedUri;
  final String stageLabel;
  final int? statusCode;
  final DioException? error;

  bool get shouldRetryWithUa =>
      statusCode == HttpStatus.forbidden ||
      statusCode == HttpStatus.notAcceptable;
}

class _ProbeOutcome {
  _ProbeOutcome._({
    required this.matched,
    this.lockedUri,
    this.matchedStage,
    this.needsUserAgent = false,
    this.error,
  });

  factory _ProbeOutcome.matched(
    Uri lockedUri, {
    String? matchedStage,
    bool needsUserAgent = false,
  }) => _ProbeOutcome._(
    matched: true,
    lockedUri: lockedUri,
    matchedStage: matchedStage,
    needsUserAgent: needsUserAgent,
  );

  factory _ProbeOutcome.failure({
    DioException? error,
    bool needsUserAgent = false,
  }) => _ProbeOutcome._(
    matched: false,
    error: error,
    needsUserAgent: needsUserAgent,
  );

  final bool matched;
  final Uri? lockedUri;
  final String? matchedStage;
  final bool needsUserAgent;
  final DioException? error;
}
