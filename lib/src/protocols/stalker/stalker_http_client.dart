import 'package:dio/dio.dart';

import 'stalker_portal_configuration.dart';

/// Lightweight wrapper around `Dio` that centralises how we talk to
/// `portal.php` during authentication.
///
/// The goal is to keep request construction consistent and to make it easy
/// to swap `Dio` for another HTTP client in the future. The wrapper exposes
/// strongly typed methods returning a small envelope rather than the full
/// `Response` object so downstream code remains platform agnostic.
class StalkerHttpClient {
  /// Underlying HTTP client.
  final Dio _dio;

  /// Builds the client with sensible defaults for Stalker portals. Timeouts
  /// are intentionally short so we can keep retry logic in higher layers.
  StalkerHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                // Stalker portals are often self-signed; we will handle TLS
                // overrides in a dedicated adapter later if required.
                responseType: ResponseType.json,
              ),
            );

  /// Performs a GET request against `portal.php` with the supplied query
  /// parameters and headers. Returns a lightweight envelope containing the
  /// raw data and any cookies emitted by the server.
  Future<PortalResponseEnvelope> getPortal(
    StalkerPortalConfiguration configuration, {
    required Map<String, dynamic> queryParameters,
    required Map<String, String> headers,
  }) async {
    // Compose the absolute URL once. Using `resolve` ensures we respect any
    // portal that runs under a sub-path.
    final url = configuration.baseUri.resolve('portal.php');

    // Execute the HTTP call. We request a plain response so we can control
    // JSON decoding manually and surface clearer error messages.
    final response = await _dio.getUri(
      url,
      queryParameters: queryParameters,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Capture all `Set-Cookie` values so the session can rebuild the cookie
    // header later without hard-coding attribute stripping logic here.
    final cookies = response.headers.map['set-cookie'] ?? const <String>[];

    return PortalResponseEnvelope(
      body: response.data,
      statusCode: response.statusCode ?? 0,
      headers: response.headers.map,
      cookies: cookies,
    );
  }
}

/// Simple immutable structure returned by the HTTP client so higher layers
/// can see the payload, status code, headers, and cookies without depending
/// on a `dio` import.
class PortalResponseEnvelope {
  /// Raw response body. We keep the type dynamic because some portals return
  /// JSON objects while others return JSON strings wrapped in HTML comments.
  final dynamic body;

  /// HTTP status code. Stalker portals mostly use 200 even on failures, but
  /// we expose the value for completeness and debugging.
  final int statusCode;

  /// Complete response headers keyed by lowercase header name.
  final Map<String, List<String>> headers;

  /// Cookies emitted via `Set-Cookie`.
  final List<String> cookies;

  PortalResponseEnvelope({
    required this.body,
    required this.statusCode,
    required this.headers,
    required this.cookies,
  });
}

