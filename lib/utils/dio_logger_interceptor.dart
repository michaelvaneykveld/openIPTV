import 'package:dio/dio.dart';
import 'package:openiptv/src/core/debug/response_logger.dart';
import 'package:openiptv/utils/app_logger.dart';

class DioLoggerInterceptor extends Interceptor {
  static const int _maxStringLength = 2000;
  static const int _collectionPreviewCount = 5;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    appLogger.d('DIO Request: ${options.method} ${options.uri}');
    appLogger.d('Headers: ${options.headers}');
    if (options.data != null) {
      appLogger.d('Request Body: ${_summarizeData(options.data)}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLogger.d(
      'DIO Response: ${response.statusCode} ${response.requestOptions.uri}',
    );
    final responseSummary = _summarizeData(response.data);
    appLogger.d('Response Data: $responseSummary');
    ResponseLogger.addLog(
      ResponseLog(
        timestamp: DateTime.now(),
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        statusCode: response.statusCode,
        data: responseSummary,
      ),
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errorData = err.response?.data ?? err.message;
    final errorSummary = _summarizeData(errorData);
    appLogger.e(
      'DIO Error on ${err.requestOptions.method} ${err.requestOptions.uri}',
      error: err,
      stackTrace: err.stackTrace,
    );
    ResponseLogger.addLog(
      ResponseLog(
        timestamp: DateTime.now(),
        method: err.requestOptions.method,
        url: err.requestOptions.uri.toString(),
        statusCode: err.response?.statusCode,
        data: errorSummary,
      ),
    );
    super.onError(err, handler);
  }

  String _summarizeData(dynamic data) {
    if (data == null) {
      return 'null';
    }

    if (data is List) {
      final length = data.length;
      if (length == 0) {
        return 'List(length: 0)';
      }
      final previewCount = length > _collectionPreviewCount
          ? _collectionPreviewCount
          : length;
      final preview = data.take(previewCount).toList();
      final hasMore = length > previewCount ? '...' : '';
      return 'List(length: $length, preview: $preview$hasMore)';
    }

    if (data is Map) {
      final map = data.cast<Object?, Object?>();
      final length = map.length;
      if (length == 0) {
        return 'Map(length: 0)';
      }
      final entries = map.entries
          .take(_collectionPreviewCount)
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
      final hasMore = length > _collectionPreviewCount ? ', ...' : '';
      return 'Map(length: $length, preview: {$entries$hasMore})';
    }

    final dataStr = data.toString();
    if (dataStr.length <= _maxStringLength) {
      return dataStr;
    }
    return '${dataStr.substring(0, _maxStringLength)}... (truncated ${dataStr.length - _maxStringLength} chars)';
  }
}
