import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/models/m3u_credentials.dart';
import 'package:openiptv/src/data/providers/m3u_api_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/data/providers/stalker_api_provider.dart';
import 'package:openiptv/src/data/xtream_api_service.dart'; // New import
import 'package:openiptv/utils/dio_logger_interceptor.dart'; // Added this import

part 'api_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 30);
  dio.interceptors.add(DioLoggerInterceptor()); // Added this line
  return dio;
}

@riverpod
StalkerApiProvider stalkerApi(Ref ref) {
  return StalkerApiProvider(ref.watch(dioProvider), ref.watch(flutterSecureStorageProvider));
}

@riverpod
XtreamApiService xtreamApi(Ref ref) {
  // Base URL will be provided at the call site (login screen)
  return XtreamApiService(''); // Placeholder base URL
}

@riverpod
M3uApiService m3uApi(Ref ref, M3uCredentials credentials) {
  return M3uApiService(ref.watch(dioProvider), credentials);
}
