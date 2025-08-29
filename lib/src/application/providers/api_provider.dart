import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/data/providers/stalker_api_provider.dart';

part 'api_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  return Dio();
}

@riverpod
StalkerApiProvider stalkerApi(Ref ref) {
  return StalkerApiProvider(ref.watch(dioProvider), ref.watch(flutterSecureStorageProvider));
}