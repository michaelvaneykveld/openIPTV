import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:openiptv/src/utils/url_redaction.dart';

import '../discovery/portal_discovery.dart';
import '../discovery/discovery_interceptors.dart';
import 'stalker_portal_normalizer.dart';

/// Concrete discovery adapter for Stalker/Ministra portals.
class StalkerPortalDiscovery implements PortalDiscovery {
  const StalkerPortalDiscovery();

  static const _fallbackUserAgent =
      'Mozilla/5.0 (QtEmbedded; Linux; U; en) stbapp';
  static const _transientStatuses = <int>{HttpStatus.serviceUnavailable, 512};
  static const _maxProbeRetries = 1;

  @override
  ProviderKind get kind => ProviderKind.stalker;

  @override
  Future<DiscoveryResult> discover(
    String userInput, {
    DiscoveryOptions options = DiscoveryOptions.defaults,
  }) async {
    final normalized = normalizeStalkerPortalInput(userInput);
    return discoverFromNormalized(normalized, options: options);
  }

  /// Convenience hook used by the login flow which already performs
  /// normalisation so validation errors can surface immediately.
  Future<DiscoveryResult> discoverFromNormalized(
    StalkerPortalNormalizationResult normalized, {
    DiscoveryOptions options = DiscoveryOptions.defaults,
  }) async {
    final telemetryRecords = <DiscoveryProbeRecord>[];
    final dio = _createClient(options);
    _applyTlsOverrides(dio, options.allowSelfSignedTls);

    final candidates = _buildCandidateList(normalized);

    for (final candidate in candidates) {
      final matchedDirectory = await _probe(
        dio: dio,
        uri: candidate.baseUri,
        stage: 'base-directory',
        matcher: _looksLikePortal,
        telemetry: telemetryRecords,
        options: options,
      );
      var needsUserAgentHint = matchedDirectory.needsUserAgent;
      if (matchedDirectory.matched) {
        return _buildResult(
          candidate: candidate,
          matchedStage: matchedDirectory.stageLabel,
          telemetryRecords: telemetryRecords,
          needsUserAgent: needsUserAgentHint,
        );
      }

      final matchedPortalPhp = await _probe(
        dio: dio,
        uri: candidate.portalPhpUri,
        stage: 'portal.php',
        matcher: _looksLikePortal,
        telemetry: telemetryRecords,
        options: options,
      );
      needsUserAgentHint =
          needsUserAgentHint || matchedPortalPhp.needsUserAgent;
      if (matchedPortalPhp.matched) {
        return _buildResult(
          candidate: candidate,
          matchedStage: matchedPortalPhp.stageLabel,
          telemetryRecords: telemetryRecords,
          needsUserAgent: needsUserAgentHint,
        );
      }

      final backendUri = candidate.serverLoadUri;
      if (backendUri != null) {
        final matchedBackend = await _probe(
          dio: dio,
          uri: backendUri,
          stage: 'server/load.php',
          matcher: _looksLikeBackend,
          telemetry: telemetryRecords,
          options: options,
        );
        needsUserAgentHint =
            needsUserAgentHint || matchedBackend.needsUserAgent;
        if (matchedBackend.matched) {
          return _buildResult(
            candidate: candidate,
            matchedStage: matchedBackend.stageLabel,
            telemetryRecords: telemetryRecords,
            needsUserAgent: needsUserAgentHint,
          );
        }
      }
    }

    throw DiscoveryException(
      'Unable to locate a Stalker/Ministra portal at the supplied address.',
      telemetry: DiscoveryTelemetry(probes: telemetryRecords),
    );
  }

  Dio _createClient(DiscoveryOptions options) {
    final headers = <String, String>{
      'Accept-Encoding': 'identity',
      'Connection': 'close',
      ...options.headers,
    };

    final userAgent = options.userAgent?.trim();
    if (userAgent != null && userAgent.isNotEmpty) {
      headers['User-Agent'] = userAgent;
      headers.putIfAbsent('X-User-Agent', () => userAgent);
    }

    final mac = options.macAddress?.trim();
    if (mac != null && mac.isNotEmpty) {
      headers.putIfAbsent('X-MAC-Address', () => mac);
    }

    final baseOptions = BaseOptions(
      connectTimeout: const Duration(milliseconds: 1500),
      receiveTimeout: const Duration(milliseconds: 2000),
      followRedirects: true,
      maxRedirects: 5,
      headers: headers,
      validateStatus: (status) => status != null && status < 600,
    );

    final dio = Dio(baseOptions);
    final logEnabled = discoveryLoggingEnabled();
    if (logEnabled) {
      dio.interceptors.add(
        DiscoveryLogInterceptor(
          enableLogging: logEnabled,
          protocolLabel: 'Stalker',
        ),
      );
    }
    dio.interceptors.add(DiscoveryRetryInterceptor(dio: dio));
    return dio;
  }

  Future<_StalkerProbeResult> _probe({
    required Dio dio,
    required Uri uri,
    required String stage,
    required bool Function(Response<dynamic>) matcher,
    required List<DiscoveryProbeRecord> telemetry,
    required DiscoveryOptions options,
  }) {
    return _probeInternal(
      dio: dio,
      uri: uri,
      stage: stage,
      matcher: matcher,
      telemetry: telemetry,
      options: options,
    );
  }

  Future<_StalkerProbeResult> _probeInternal({
    required Dio dio,
    required Uri uri,
    required String stage,
    required bool Function(Response<dynamic>) matcher,
    required List<DiscoveryProbeRecord> telemetry,
    required DiscoveryOptions options,
    String? overrideUserAgent,
    bool userAgentRetry = false,
    int attempt = 0,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestHeaders = <String, String>{};
    dio.options.headers.forEach((key, value) {
      if (value != null) {
        requestHeaders[key] = value.toString();
      }
    });

    if (overrideUserAgent != null && overrideUserAgent.isNotEmpty) {
      requestHeaders['User-Agent'] = overrideUserAgent;
      requestHeaders['X-User-Agent'] = overrideUserAgent;
    }

    try {
      final response = await dio.getUri<dynamic>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          headers: requestHeaders,
        ),
      );
      stopwatch.stop();
      final status = response.statusCode ?? 0;
      final matched = matcher(response);
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: redactSensitiveUri(response.realUri, dropAllQuery: true),
        statusCode: response.statusCode,
        elapsed: stopwatch.elapsed,
        matchedSignature: matched,
      );
      telemetry.add(record);
      options.logSink?.call(record);
      if (!matched &&
          attempt < _maxProbeRetries &&
          _shouldRetryStatus(status)) {
        return _probeInternal(
          dio: dio,
          uri: uri,
          stage: '$stage (retry)',
          matcher: matcher,
          telemetry: telemetry,
          options: options,
          overrideUserAgent: overrideUserAgent,
          userAgentRetry: userAgentRetry,
          attempt: attempt + 1,
        );
      }

      if (status == HttpStatus.forbidden &&
          !userAgentRetry &&
          _shouldAttemptUserAgentRetry(options)) {
        final fallback = await _probeInternal(
          dio: dio,
          uri: uri,
          stage: '$stage (UA retry)',
          matcher: matcher,
          telemetry: telemetry,
          options: options,
          overrideUserAgent: _fallbackUserAgent,
          userAgentRetry: true,
          attempt: attempt,
        );
        if (fallback.matched) {
          return fallback.copyWith(needsUserAgent: true);
        }
        return fallback;
      }

      return _StalkerProbeResult(
        matched: matched,
        needsUserAgent: userAgentRetry && matched,
        stageLabel: stage,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: redactSensitiveUri(
          error.response?.realUri ?? uri,
          dropAllQuery: true,
        ),
        statusCode: error.response?.statusCode,
        elapsed: stopwatch.elapsed,
        error: error,
      );
      telemetry.add(record);
      options.logSink?.call(record);
      if (attempt < _maxProbeRetries &&
          _shouldRetryStatus(error.response?.statusCode)) {
        return _probeInternal(
          dio: dio,
          uri: uri,
          stage: '$stage (retry)',
          matcher: matcher,
          telemetry: telemetry,
          options: options,
          overrideUserAgent: overrideUserAgent,
          userAgentRetry: userAgentRetry,
          attempt: attempt + 1,
        );
      }

      if (attempt < _maxProbeRetries && _shouldRetryException(error)) {
        return _probeInternal(
          dio: dio,
          uri: uri,
          stage: '$stage (retry)',
          matcher: matcher,
          telemetry: telemetry,
          options: options,
          overrideUserAgent: overrideUserAgent,
          userAgentRetry: userAgentRetry,
          attempt: attempt + 1,
        );
      }

      if (!userAgentRetry &&
          _isForbidden(error.response?.statusCode) &&
          _shouldAttemptUserAgentRetry(options)) {
        final fallback = await _probeInternal(
          dio: dio,
          uri: uri,
          stage: '$stage (UA retry)',
          matcher: matcher,
          telemetry: telemetry,
          options: options,
          overrideUserAgent: _fallbackUserAgent,
          userAgentRetry: true,
          attempt: attempt,
        );
        if (fallback.matched) {
          return fallback.copyWith(needsUserAgent: true);
        }
        return fallback;
      }

      return _StalkerProbeResult(
        matched: false,
        needsUserAgent: false,
        stageLabel: stage,
      );
    }
  }

  DiscoveryResult _buildResult({
    required StalkerPortalCandidate candidate,
    required String matchedStage,
    required List<DiscoveryProbeRecord> telemetryRecords,
    bool needsUserAgent = false,
  }) {
    final hints = <String, String>{
      'matchedStage': matchedStage,
      'portalPath': candidate.portalPhpUri.path,
    };
    if (needsUserAgent) {
      hints['needsUserAgent'] = 'true';
    }
    final telemetry = DiscoveryTelemetry(probes: telemetryRecords);

    return DiscoveryResult(
      kind: kind,
      lockedBase: candidate.baseUri,
      hints: hints,
      telemetry: telemetry,
    );
  }

  List<StalkerPortalCandidate> _buildCandidateList(
    StalkerPortalNormalizationResult normalized,
  ) {
    final candidates = <StalkerPortalCandidate>[];
    final visitedBases = <String>{};

    // Always probe the supplied scheme then retry with the opposite scheme so
    // clipboard links that default to HTTPS (or HTTP) still recover.
    void addForBase(Uri baseUri) {
      final key = baseUri.toString();
      if (!visitedBases.add(key)) return;
      final normalised = StalkerPortalNormalizationResult(
        canonicalUri: baseUri,
        hadExplicitScheme: true,
        hadExplicitPort: baseUri.hasPort,
      );
      candidates.addAll(generateStalkerPortalCandidates(normalised));
    }

    addForBase(normalized.canonicalUri);

    final flipped = _flipScheme(normalized.canonicalUri);
    if (flipped != null) {
      addForBase(flipped);
    }

    return candidates;
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

  Uri? _flipScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }
    final flipped = scheme == 'https' ? 'http' : 'https';
    return uri.replace(scheme: flipped, port: null);
  }

  bool _looksLikePortal(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) return false;
    final body = response.data?.toString().toLowerCase() ?? '';
    return body.contains('stalker_portal') ||
        body.contains('ministra') ||
        response.realUri.path.toLowerCase().contains('/stalker_portal/');
  }

  bool _looksLikeBackend(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) return false;
    if (response.data is Map || response.data is List) {
      return true;
    }
    final body = response.data?.toString().toLowerCase() ?? '';
    return body.contains('js') &&
        body.contains('token') &&
        body.contains('mac');
  }

  bool _shouldRetryStatus(int? status) {
    if (status == null) return false;
    return _transientStatuses.contains(status);
  }

  bool _shouldRetryException(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      final message = error.message ?? error.error?.toString() ?? '';
      return message.contains('Connection closed before full header') ||
          message.contains('Connection reset by peer');
    }
    return false;
  }

  bool _shouldAttemptUserAgentRetry(DiscoveryOptions options) {
    final userAgent = options.userAgent?.trim();
    return userAgent == null || userAgent.isEmpty;
  }

  bool _isForbidden(int? status) => status == HttpStatus.forbidden;
}

class _StalkerProbeResult {
  const _StalkerProbeResult({
    required this.matched,
    required this.stageLabel,
    this.needsUserAgent = false,
  });

  final bool matched;
  final String stageLabel;
  final bool needsUserAgent;

  _StalkerProbeResult copyWith({bool? needsUserAgent}) => _StalkerProbeResult(
    matched: matched,
    stageLabel: stageLabel,
    needsUserAgent: needsUserAgent ?? this.needsUserAgent,
  );
}
