import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

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
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: Duration(seconds: 10),
              receiveTimeout: Duration(seconds: 10),
              sendTimeout: Duration(seconds: 10),
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
    _applyTlsOverrides(configuration.allowSelfSignedTls);
    final normalizedHeaders = _mergeStbHeaders(
      configuration: configuration,
      headers: headers,
      token: _extractToken(queryParameters['token']),
    );
    // Compose the absolute URL once. Using `resolve` ensures we respect any
    // portal that runs under a sub-path.
    var uri = configuration.baseUri.resolve('portal.php');
    if (queryParameters.isNotEmpty) {
      final merged = <String, String>{...uri.queryParameters};
      queryParameters.forEach((key, value) {
        merged[key] = value?.toString() ?? '';
      });
      uri = uri.replace(queryParameters: merged);
    }

    // Execute the HTTP call. We request a plain response so we can control
    // JSON decoding manually and surface clearer error messages.
    final response = await _dio.getUri(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        headers: normalizedHeaders,
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

  Map<String, String> _mergeStbHeaders({
    required StalkerPortalConfiguration configuration,
    required Map<String, String> headers,
    String? token,
  }) {
    final merged = <String, String>{};
    merged.addAll(headers);

    void ensureHeader(String key, String value) {
      if (value.isEmpty) return;
      final existing = merged[key];
      if (existing == null || existing.trim().isEmpty) {
        merged[key] = value;
      }
    }

    ensureHeader('User-Agent', configuration.userAgent);
    ensureHeader('X-User-Agent', configuration.userAgent);
    ensureHeader('Referer', configuration.refererUri.toString());
    if (token != null && token.isNotEmpty) {
      ensureHeader('Authorization', 'Bearer $token');
    }

    configuration.extraHeaders.forEach((key, value) {
      ensureHeader(key, value);
    });

    final mergedCookie = _mergeCookieHeader(
      configuration: configuration,
      existing: merged['Cookie'],
      token: token,
    );
    if (mergedCookie.isNotEmpty) {
      merged['Cookie'] = mergedCookie;
    }

    return merged;
  }

  String _mergeCookieHeader({
    required StalkerPortalConfiguration configuration,
    required String? existing,
    String? token,
  }) {
    final entries = <String>[];
    if (existing != null && existing.trim().isNotEmpty) {
      entries.addAll(
        existing
            .split(';')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty),
      );
    }

    String lowerKey(String entry) => entry.toLowerCase();

    void ensureCookie(String key, String value) {
      if (value.isEmpty) return;
      final prefix = '${key.toLowerCase()}=';
      if (!entries.any((entry) => lowerKey(entry).startsWith(prefix))) {
        entries.add('$key=$value');
      }
    }

    ensureCookie('mac', configuration.macAddress.toLowerCase());
    ensureCookie('stb_lang', configuration.languageCode);
    ensureCookie('timezone', configuration.timezone);
    if (token != null && token.isNotEmpty) {
      ensureCookie('token', token);
    }

    return entries.join('; ');
  }

  String? _extractToken(dynamic value) {
    if (value == null) return null;
    final token = value.toString().trim();
    if (token.isEmpty) {
      return null;
    }
    return token;
  }

  void _applyTlsOverrides(bool allowSelfSigned) {
    final adapter = _dio.httpClientAdapter;
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
