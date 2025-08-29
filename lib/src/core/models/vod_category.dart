
import 'package:openiptv/src/core/database/database_helper.dart';

class VodCategory {
  final String id;
  final String title;
  final String? alias;
  final int? censored;

  VodCategory({
    required this.id,
    required this.title,
    this.alias,
    this.censored,
  });

  factory VodCategory.fromJson(Map<String, dynamic> json) {
    return VodCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      alias: json['alias'] as String?,
      censored: json['censored'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnVodCategoryId: id,
      DatabaseHelper.columnVodCategoryTitle: title,
      DatabaseHelper.columnVodCategoryAlias: alias,
      DatabaseHelper.columnVodCategoryCensored: censored,
    };
  }
}
