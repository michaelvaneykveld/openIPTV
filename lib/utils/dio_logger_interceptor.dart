import 'package:dio/dio.dart';
import 'package:openiptv/src/core/debug/response_logger.dart';
import 'package:openiptv/utils/app_logger.dart';

class DioLoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    appLogger.d('DIO Request: ${options.method} ${options.uri}');
    appLogger.d('Headers: ${options.headers}');
    if (options.data != null) {
      appLogger.d('Request Body: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLogger.d('DIO Response: ${response.statusCode} ${response.requestOptions.uri}');
    appLogger.d('Response Data: ${response.data}');
    ResponseLogger.addLog(ResponseLog(
      timestamp: DateTime.now(),
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      statusCode: response.statusCode,
      data: response.data,
    ));
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLogger.e(
      'DIO Error on ${err.requestOptions.method} ${err.requestOptions.uri}',
      error: err,
      stackTrace: err.stackTrace,
    );
    ResponseLogger.addLog(ResponseLog(
      timestamp: DateTime.now(),
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      statusCode: err.response?.statusCode,
      data: err.response?.data ?? err.message,
    ));
    super.onError(err, handler);
  }
}
