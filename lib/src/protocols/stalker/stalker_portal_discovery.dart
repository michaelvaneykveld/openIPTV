import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../discovery/portal_discovery.dart';
import 'stalker_portal_normalizer.dart';

/// Concrete discovery adapter for Stalker/Ministra portals.
class StalkerPortalDiscovery implements PortalDiscovery {
  const StalkerPortalDiscovery();

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

    final candidates = generateStalkerPortalCandidates(normalized);

    for (final candidate in candidates) {
      final matchedDirectory = await _probe(
        dio: dio,
        uri: candidate.baseUri,
        stage: 'base-directory',
        matcher: _looksLikePortal,
        telemetry: telemetryRecords,
        options: options,
      );
      if (matchedDirectory) {
        return _buildResult(
          candidate: candidate,
          matchedStage: 'base-directory',
          telemetryRecords: telemetryRecords,
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
      if (matchedPortalPhp) {
        return _buildResult(
          candidate: candidate,
          matchedStage: 'portal.php',
          telemetryRecords: telemetryRecords,
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
        if (matchedBackend) {
          return _buildResult(
            candidate: candidate,
            matchedStage: 'server/load.php',
            telemetryRecords: telemetryRecords,
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
      receiveTimeout: const Duration(milliseconds: 1500),
      followRedirects: true,
      maxRedirects: 5,
      headers: headers,
      validateStatus: (status) => status != null && status < 600,
    );

    return Dio(baseOptions);
  }

  Future<bool> _probe({
    required Dio dio,
    required Uri uri,
    required String stage,
    required bool Function(Response<dynamic>) matcher,
    required List<DiscoveryProbeRecord> telemetry,
    required DiscoveryOptions options,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await dio.getUri<dynamic>(
        uri,
        options: Options(responseType: ResponseType.plain),
      );
      stopwatch.stop();
      final matched = matcher(response);
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: _sanitizeUri(response.realUri),
        statusCode: response.statusCode,
        elapsed: stopwatch.elapsed,
        matchedSignature: matched,
      );
      telemetry.add(record);
      options.logSink?.call(record);
      return matched;
    } on DioException catch (error) {
      stopwatch.stop();
      final record = DiscoveryProbeRecord(
        kind: kind,
        stage: stage,
        uri: _sanitizeUri(error.response?.realUri ?? uri),
        statusCode: error.response?.statusCode,
        elapsed: stopwatch.elapsed,
        error: error,
      );
      telemetry.add(record);
      options.logSink?.call(record);
      return false;
    }
  }

  DiscoveryResult _buildResult({
    required StalkerPortalCandidate candidate,
    required String matchedStage,
    required List<DiscoveryProbeRecord> telemetryRecords,
  }) {
    final hints = <String, String>{
      'matchedStage': matchedStage,
      'portalPath': candidate.portalPhpUri.path,
    };
    final telemetry = DiscoveryTelemetry(probes: telemetryRecords);

    return DiscoveryResult(
      kind: kind,
      lockedBase: candidate.baseUri,
      hints: hints,
      telemetry: telemetry,
    );
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

  Uri _sanitizeUri(Uri uri) {
    return uri.replace(userInfo: '', query: null, fragment: null);
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
}
