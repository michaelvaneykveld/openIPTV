import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'xtream_portal_configuration.dart';

/// Encapsulates the low-level HTTP communication with an Xtream Codes portal.
///
/// Xtream exposes multiple endpoints (`player_api.php`, `panel_api.php`,
/// `/xmltv.php`, ...). For the login flow we only need `player_api.php`,
/// so this client keeps the surface minimal while still allowing easy
/// extension later when we implement category/channel fetching.
class XtreamHttpClient {
  final Dio _dio;

  XtreamHttpClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: Duration(seconds: 10),
              receiveTimeout: Duration(seconds: 15),
              sendTimeout: Duration(seconds: 10),
              responseType: ResponseType.json,
            ),
          );

  /// Executes a GET request against `player_api.php`, merging login query
  /// parameters with any custom `action` values. Returns a lightweight
  /// envelope to keep this module independent of the `dio` package.
  Future<XtreamResponseEnvelope> getPlayerApi(
    XtreamPortalConfiguration configuration, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _applyTlsOverrides(configuration.allowSelfSignedTls);

    var uri = configuration.baseUri.resolve('player_api.php');

    final mergedParams = <String, String>{
      ...uri.queryParameters,
      'username': configuration.username,
      'password': configuration.password,
    };

    queryParameters?.forEach((key, value) {
      mergedParams[key] = value?.toString() ?? '';
    });

    uri = uri.replace(queryParameters: mergedParams);

    final response = await _dio.getUri(
      uri,
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent': configuration.userAgent,
          'Accept': '*/*',
          'Connection': 'keep-alive',
          if (configuration.deviceId != null)
            'X-Device-Id': configuration.deviceId,
          ...configuration.extraHeaders,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    return XtreamResponseEnvelope(
      body: response.data,
      statusCode: response.statusCode ?? 0,
      headers: response.headers.map,
    );
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

/// Minimal immutable envelope that carries the data returned from Xtream.
class XtreamResponseEnvelope {
  final dynamic body;
  final int statusCode;
  final Map<String, List<String>> headers;

  XtreamResponseEnvelope({
    required this.body,
    required this.statusCode,
    required this.headers,
  });
}
