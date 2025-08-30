
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/data/providers/stalker_api_provider.dart';
import 'credentials_provider.dart'; // Assuming this is where flutterSecureStorageProvider is defined
import 'package:openiptv/utils/dio_logger_interceptor.dart';

final stalkerApiProvider = Provider<StalkerApiProvider>((ref) {
  final dio = Dio();
  dio.interceptors.add(DioLoggerInterceptor());
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  return StalkerApiProvider(dio, secureStorage);
});
