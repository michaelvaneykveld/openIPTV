
import 'package:openiptv/src/core/database/database_helper.dart';

class Genre {
  final String id;
  final String title;
  final String? alias;
  final int? censored;
  final String? modified;
  final int? number;

  Genre({
    required this.id,
    required this.title,
    this.alias,
    this.censored,
    this.modified,
    this.number,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as String,
      title: json['title'] as String,
      alias: json['alias'] as String?,
      censored: json['censored'] as int?,
      modified: json['modified'] as String?,
      number: json['number'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnGenreId: id,
      DatabaseHelper.columnGenreTitle: title,
      DatabaseHelper.columnGenreAlias: alias,
      DatabaseHelper.columnGenreCensored: censored,
      DatabaseHelper.columnGenreModified: modified,
      DatabaseHelper.columnGenreNumber: number,
    };
  }
}
