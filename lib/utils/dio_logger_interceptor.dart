import 'package:dio/dio.dart';
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
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLogger.e('DIO Error: ${err.requestOptions.method} ${err.requestOptions.uri}');
    appLogger.e('Error Type: ${err.type}');
    appLogger.e('Error Message: ${err.message}');
    if (err.response != null) {
      appLogger.e('Error Response Status: ${err.response?.statusCode}');
      appLogger.e('Error Response Data: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}
