import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/data/providers/stalker_api_provider.dart';
import 'package:openiptv/utils/dio_logger_interceptor.dart'; // Added this import

part 'api_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio();
  dio.interceptors.add(DioLoggerInterceptor()); // Added this line
  return dio;
}

@riverpod
StalkerApiProvider stalkerApi(Ref ref) {
  return StalkerApiProvider(ref.watch(dioProvider), ref.watch(flutterSecureStorageProvider));
}