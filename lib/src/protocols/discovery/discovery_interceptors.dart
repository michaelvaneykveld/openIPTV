import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:openiptv/src/utils/url_redaction.dart';

typedef UriRedactor = Uri Function(Uri uri);

bool _isDebugBuild() {
  var debug = false;
  assert(() {
    debug = true;
    return true;
  }());
  return debug;
}

/// Logs discovery HTTP traffic with sensitive query parameters redacted.
class DiscoveryLogInterceptor extends Interceptor {
  DiscoveryLogInterceptor({
    required bool enableLogging,
    UriRedactor? redactor,
    String protocolLabel = 'discovery',
  }) : _enabled = enableLogging,
       _redactor =
           redactor ?? ((uri) => redactSensitiveUri(uri, dropAllQuery: true)),
       _protocolLabel = protocolLabel;

  final bool _enabled;
  final UriRedactor _redactor;
  final String _protocolLabel;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      _printMessage('-> ${options.method} ${_formatUri(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_enabled) {
      _printMessage(
        '<- ${response.statusCode} ${_formatUri(response.realUri)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      final uri = err.response?.realUri ?? err.requestOptions.uri;
      _printMessage('!! ${err.type.name} ${_formatUri(uri)}');
    }
    handler.next(err);
  }

  String _formatUri(Uri uri) => _redactor(uri).toString();

  void _printMessage(String message) {
    // ignore: avoid_print
    print('[$_protocolLabel] $message');
  }
}

/// Retries idempotent GET/HEAD requests when transient network failures occur.
class DiscoveryRetryInterceptor extends Interceptor {
  DiscoveryRetryInterceptor({
    required this.dio,
    this.maxRetries = 1,
    Duration Function(int attempt)? delayBuilder,
    bool Function(RequestOptions request, DioException error)? shouldRetry,
  }) : _delayBuilder =
           delayBuilder ??
           ((_) => Duration(milliseconds: 100 + _random.nextInt(200))),
       _shouldRetry =
           shouldRetry ??
           ((RequestOptions request, DioException error) =>
               (request.method == 'GET' || request.method == 'HEAD') &&
               _defaultRetry(error));

  final Dio dio;
  final int maxRetries;
  final Duration Function(int attempt) _delayBuilder;
  final bool Function(RequestOptions request, DioException error) _shouldRetry;

  static final Random _random = Random();

  static bool _defaultRetry(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final attempt = (request.extra['retry_attempt'] as int?) ?? 0;

    if (attempt >= maxRetries || !_shouldRetry(request, err)) {
      handler.next(err);
      return;
    }

    final delay = _delayBuilder(attempt);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final updatedExtra = Map<String, dynamic>.from(request.extra)
      ..['retry_attempt'] = attempt + 1;
    request.extra = updatedExtra;

    try {
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

bool discoveryLoggingEnabled() => _isDebugBuild();
