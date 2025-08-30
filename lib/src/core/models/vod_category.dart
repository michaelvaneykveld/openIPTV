import 'package:freezed_annotation/freezed_annotation.dart';

part 'vod_category.freezed.dart';
part 'vod_category.g.dart';

@freezed
abstract class VodCategory with _$VodCategory {
  const factory VodCategory({
    required String id,
    required String title,
  }) = _VodCategory;

  factory VodCategory.fromJson(Map<String, dynamic> json) =>
      _$VodCategoryFromJson(json);
}