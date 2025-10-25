import 'package:dio/dio.dart';

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
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 10),
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
    final resolved =
        configuration.baseUri.resolve('player_api.php');

    final mergedParams = <String, dynamic>{
      'username': configuration.username,
      'password': configuration.password,
      ...?queryParameters,
    };

    final response = await _dio.getUri(
      resolved,
      queryParameters: mergedParams,
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent': configuration.userAgent,
          'Accept': 'application/json',
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

