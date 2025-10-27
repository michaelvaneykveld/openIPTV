import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../discovery/portal_discovery.dart';
import '../../utils/url_normalization.dart';

/// Discovers a working Xtream Codes base endpoint by probing candidate URLs.
class XtreamPortalDiscovery implements PortalDiscovery {
  /// Creates a discovery instance. An optional [dio] can be supplied for tests.
  const XtreamPortalDiscovery({Dio? dio}) : _overrideDio = dio;

  final Dio? _overrideDio;
  static const _transientStatuses = <int>{HttpStatus.serviceUnavailable, 512};

  @override
  ProviderKind get kind => ProviderKind.xtream;

  @override
  Future<DiscoveryResult> discover(
    String userInput, {
    DiscoveryOptions options = DiscoveryOptions.defaults,
  }) async {
    final normalized = _normalizeInput(userInput);
    return discoverFromUri(normalized, options: options);
  }

  /// Allows callers that already normalised the input to skip the parsing step.
  Future<DiscoveryResult> discoverFromUri(
    Uri baseUri, {
    DiscoveryOptions options = DiscoveryOptions.defaults,
  }) async {
    final telemetryRecords = <DiscoveryProbeRecord>[];
    final dio = _overrideDio ?? _createClient(options);
    _applyTlsOverrides(dio, options.allowSelfSignedTls);

    final candidates = _buildCandidates(baseUri);
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
        final hints = <String, String>{'matchedEndpoint': 'player_api.php'};
        if (needsUaHint) {
          hints['needsUserAgent'] = 'true';
        }
        return DiscoveryResult(
          kind: kind,
          lockedBase: outcome.lockedBase!,
          hints: hints,
          telemetry: DiscoveryTelemetry(probes: telemetryRecords),
        );
      }
    }

    throw DiscoveryException(
      lastException?.message ??
          'Unable to locate an Xtream Codes endpoint at the supplied address.',
      telemetry: DiscoveryTelemetry(probes: telemetryRecords),
    );
  }

  Dio _createClient(DiscoveryOptions options) {
    final headers = <String, String>{
      'Accept': 'application/json',
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
    required _XtreamCandidate candidate,
    required DiscoveryOptions options,
    required List<DiscoveryProbeRecord> telemetry,
  }) async {
    const probeCredentials = {'username': '__probe__', 'password': '__probe__'};

    final query = Map<String, String>.from(candidate.playerApi.queryParameters)
      ..addAll(probeCredentials);
    final probeUri = candidate.playerApi.replace(queryParameters: query);

    var outcome = await _attemptProbe(
      dio: dio,
      uri: probeUri,
      stage: 'player_api.php',
      options: options,
      telemetry: telemetry,
    );

    var hasRetried = false;
    if (!outcome.matched &&
        _shouldRetryStatus(outcome.statusCode) &&
        !hasRetried) {
      outcome = await _attemptProbe(
        dio: dio,
        uri: probeUri,
        stage: 'player_api.php (retry)',
        options: options,
        telemetry: telemetry,
      );
      hasRetried = true;
    }

    if (!outcome.matched &&
        _shouldRetryException(outcome.error) &&
        !hasRetried) {
      outcome = await _attemptProbe(
        dio: dio,
        uri: probeUri,
        stage: 'player_api.php (retry)',
        options: options,
        telemetry: telemetry,
      );
      hasRetried = true;
    }

    if (outcome.matched) {
      final lockedBase = _deriveLockedBase(outcome.sanitizedUri);
      return _ProbeOutcome.matched(lockedBase);
    }

    if (outcome.isForbidden && options.userAgent == null) {
      // Many Xtream deployments require a STB-flavoured User-Agent before they
      // return JSON; retry with a known-good string and surface the hint.
      final retryOptions = DiscoveryOptions(
        allowSelfSignedTls: options.allowSelfSignedTls,
        headers: options.headers,
        userAgent: _fallbackUserAgent,
        macAddress: options.macAddress,
        logSink: options.logSink,
      );
      final retryOutcome = await _attemptProbe(
        dio: dio,
        uri: probeUri,
        stage: 'player_api.php (UA retry)',
        options: retryOptions,
        telemetry: telemetry,
      );

      if (retryOutcome.matched) {
        final lockedBase = _deriveLockedBase(retryOutcome.sanitizedUri);
        return _ProbeOutcome.matched(lockedBase, needsUserAgent: true);
      }
    }

    return _ProbeOutcome.failure(error: outcome.error);
  }

  Future<_AttemptOutcome> _attemptProbe({
    required Dio dio,
    required Uri uri,
    required String stage,
    required DiscoveryOptions options,
    required List<DiscoveryProbeRecord> telemetry,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final requestHeaders = <String, String>{...options.headers};
      final ua = options.userAgent?.trim();
      if (ua != null && ua.isNotEmpty) {
        requestHeaders['User-Agent'] = ua;
      }

      final response = await dio.getUri<dynamic>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          headers: requestHeaders,
        ),
      );
      stopwatch.stop();

      final sanitized = _sanitizeUri(response.realUri);
      final matched = _looksLikeXtream(response);

      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: sanitized,
        statusCode: response.statusCode,
        elapsed: stopwatch.elapsed,
        matchedSignature: matched,
      );
      telemetry.add(record);
      options.logSink?.call(record);

      return _AttemptOutcome(
        matched: matched,
        sanitizedUri: sanitized,
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      final sanitized = _sanitizeUri(error.response?.realUri ?? uri);
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: sanitized,
        statusCode: error.response?.statusCode,
        elapsed: stopwatch.elapsed,
        error: error,
      );
      telemetry.add(record);
      options.logSink?.call(record);

      return _AttemptOutcome(
        matched: false,
        sanitizedUri: sanitized,
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

  Uri _normalizeInput(String rawInput) {
    final canonical = canonicalizeScheme(rawInput);
    final parsed = Uri.parse(canonical);
    if (parsed.host.isEmpty) {
      throw const FormatException('Server address is missing a host name.');
    }

    final lowered = parsed.replace(
      scheme: parsed.scheme.toLowerCase(),
      host: parsed.host.toLowerCase(),
    );

    final stripped = stripKnownFiles(lowered);
    return ensureTrailingSlash(stripped);
  }

  List<_XtreamCandidate> _buildCandidates(Uri baseUri) {
    final seen = <String>{};
    final candidates = <_XtreamCandidate>[];

    void add(Uri uri) {
      final normalized = ensureTrailingSlash(uri);
      if (seen.add(normalized.toString())) {
        candidates.add(_XtreamCandidate(normalized));
      }
    }

    add(baseUri);

    if (baseUri.path != '/') {
      add(baseUri.replace(path: '/'));
    }

    if (baseUri.scheme == 'https' || baseUri.scheme == 'http') {
      final flippedScheme = baseUri.scheme == 'https' ? 'http' : 'https';
      add(baseUri.replace(scheme: flippedScheme));
      if (baseUri.path != '/') {
        add(baseUri.replace(scheme: flippedScheme, path: '/'));
      }
    }

    return candidates;
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

  bool _looksLikeXtream(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) {
      final keys = data.keys.map((key) => key.toString().toLowerCase()).toSet();
      if (keys.contains('user_info') || keys.contains('server_info')) {
        return true;
      }
    }

    final body = data?.toString().toLowerCase() ?? '';
    if (body.isEmpty) {
      return false;
    }

    if (body.contains('user_info') || body.contains('server_info')) {
      return true;
    }

    // Some Control Panel skins (e.g. XUI.one) return an HTML error page with an
    // INVALID_CREDENTIALS banner instead of JSON when fake credentials are
    // supplied. Treat those branded responses as a positive signature so
    // discovery still locks the base URL.
    const htmlSignatures = <String>{
      'invalid_credentials',
      'username or password is invalid',
      'xui.one',
      'xtream ui',
    };
    for (final signature in htmlSignatures) {
      if (body.contains(signature)) {
        return true;
      }
    }

    return false;
  }

  Uri _deriveLockedBase(Uri uri) {
    final stripped = stripKnownFiles(
      uri,
      knownFiles: const {'player_api.php', 'get.php', 'xmltv.php'},
    );
    return ensureTrailingSlash(stripped);
  }

  Uri _sanitizeUri(Uri uri) {
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    );
  }
}

class _XtreamCandidate {
  _XtreamCandidate(Uri base)
    : baseUri = base,
      playerApi = base.resolve('player_api.php'),
      getPhp = base.resolve('get.php'),
      xmltv = base.resolve('xmltv.php');

  final Uri baseUri;
  final Uri playerApi;
  final Uri getPhp;
  final Uri xmltv;
}

class _AttemptOutcome {
  _AttemptOutcome({
    required this.matched,
    required this.sanitizedUri,
    this.statusCode,
    this.error,
  });

  final bool matched;
  final Uri sanitizedUri;
  final int? statusCode;
  final DioException? error;

  bool get isForbidden => statusCode == 403;
}

class _ProbeOutcome {
  _ProbeOutcome._({
    required this.matched,
    this.lockedBase,
    this.needsUserAgent = false,
    this.error,
  });

  factory _ProbeOutcome.matched(
    Uri lockedBase, {
    bool needsUserAgent = false,
  }) => _ProbeOutcome._(
    matched: true,
    lockedBase: lockedBase,
    needsUserAgent: needsUserAgent,
  );

  factory _ProbeOutcome.failure({DioException? error}) =>
      _ProbeOutcome._(matched: false, error: error);

  final bool matched;
  final Uri? lockedBase;
  final bool needsUserAgent;
  final DioException? error;
}

const _fallbackUserAgent =
    'Hypnotix/2.0 (Linux; IPTV) Flutter/OpenIPTV XtreamProbe';
