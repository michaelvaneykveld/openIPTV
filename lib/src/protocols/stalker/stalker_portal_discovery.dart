import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'stalker_portal_normalizer.dart';

/// Enumerates the possible outcomes of the discovery routine.
class StalkerPortalDiscoveryResult {
  final StalkerPortalCandidate candidate;
  final Response<dynamic>? directoryProbe;
  final Response<dynamic>? portalProbe;
  final Response<dynamic>? backendProbe;

  const StalkerPortalDiscoveryResult({
    required this.candidate,
    this.directoryProbe,
    this.portalProbe,
    this.backendProbe,
  });
}

/// Discovers the most promising portal base by probing an ordered list of
/// candidates generated from the normalised input.
class StalkerPortalDiscovery {
  const StalkerPortalDiscovery();

  Future<StalkerPortalDiscoveryResult?> discover(
    StalkerPortalNormalizationResult normalized, {
    bool allowSelfSignedTls = false,
    Map<String, String>? headers,
  }) async {
    final baseOptions = BaseOptions(
      connectTimeout: const Duration(milliseconds: 1500),
      receiveTimeout: const Duration(milliseconds: 1500),
      followRedirects: true,
      maxRedirects: 5,
      headers: {
        'Accept-Encoding': 'identity',
        'Connection': 'close',
        ...?headers,
      },
      validateStatus: (status) => status != null && status < 600,
    );

    final dio = Dio(baseOptions);
    _applyTlsOverrides(dio, allowSelfSignedTls);

    final candidates = generateStalkerPortalCandidates(normalized);

    for (final candidate in candidates) {
      try {
        final directoryProbe = await dio.getUri<dynamic>(
          candidate.baseUri,
          options: Options(responseType: ResponseType.plain),
        );
        if (_looksLikePortal(directoryProbe)) {
          return StalkerPortalDiscoveryResult(
            candidate: candidate,
            directoryProbe: directoryProbe,
          );
        }

        final portalProbe = await dio.getUri<dynamic>(
          candidate.portalPhpUri,
          options: Options(responseType: ResponseType.plain),
        );
        if (_looksLikePortal(portalProbe)) {
          return StalkerPortalDiscoveryResult(
            candidate: candidate,
            portalProbe: portalProbe,
          );
        }

        final backendUri = candidate.serverLoadUri;
        if (backendUri != null) {
          final backendProbe = await dio.getUri<dynamic>(
            backendUri,
            options: Options(responseType: ResponseType.plain),
          );
          if (_looksLikeBackend(backendProbe)) {
            return StalkerPortalDiscoveryResult(
              candidate: candidate,
              portalProbe: portalProbe,
              backendProbe: backendProbe,
            );
          }
        }
      } on DioException {
        continue;
      }
    }

    return null;
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
