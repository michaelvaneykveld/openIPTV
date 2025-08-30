import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'grouped_content.freezed.dart';

@freezed
class GroupedContent with _$GroupedContent {
  const factory GroupedContent({
    required List<MainCategory> categories,
  }) = _GroupedContent;
}

@freezed
class MainCategory with _$MainCategory {
  const factory MainCategory({
    required String name,
    required List<SubCategory> subCategories,
  }) = _MainCategory;
}

@freezed
class SubCategory with _$SubCategory {
  const factory SubCategory({
    required String name,
    required List<PlayableItem> items,
  }) = _SubCategory;
}

@freezed
class PlayableItem with _$PlayableItem {
  const factory PlayableItem({
    required String id,
    required String name,
    String? logoUrl,
  }) = _PlayableItem;
}