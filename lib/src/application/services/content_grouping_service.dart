import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/genre.dart';
import 'package:openiptv/src/core/models/vod_category.dart';
import 'package:openiptv/src/core/models/vod_content.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/domain/models/grouped_content.dart';

part 'content_grouping_service.g.dart';

class ContentGroupingService {
  final DatabaseHelper _dbHelper;

  ContentGroupingService(this._dbHelper);

  Future<GroupedContent> getGroupedContent(String portalId) async {
    // 1. Fetch all data from the database in parallel
    final futures = [
      _dbHelper.getAllGenres(portalId),
      _dbHelper.getAllChannels(portalId),
      _dbHelper.getAllVodCategories(portalId),
      _dbHelper.getAllVodContent(portalId),
    ];

    final results = await Future.wait(futures);

    final allGenres = (results[0]).map((e) => Genre.fromJson(e)).toList();
    final allChannels = (results[1]).map((e) => Channel.fromDbMap(e)).toList();
    final allVodCategories = (results[2])
        .map((e) => VodCategory.fromJson(e))
        .toList();
    final allVodContent = (results[3])
        .map((e) => VodContent.fromDbMap(e))
        .toList();

    // 2. Group channels and VOD content by their respective category IDs for efficient lookup
    final channelsByGenre = groupBy(allChannels, (c) => c.genreId);
    final vodContentByCategory = groupBy(allVodContent, (v) => v.categoryId);

    // 3. Initialize main categories
    final liveTvSubCategories = <SubCategory>[];
    final radioSubCategories = <SubCategory>[];
    final moviesSubCategories = <SubCategory>[];
    final seriesSubCategories = <SubCategory>[];

    // 4. Process Live TV and Radio genres
    for (final genre in allGenres) {
      final channelsForGenre = (channelsByGenre[genre.id] ?? [])
          .map((c) => PlayableItem(id: c.id, name: c.name, logoUrl: c.logo))
          .toList();

      if (channelsForGenre.isEmpty) continue;

      final subCategory = SubCategory(
        name: genre.title,
        items: channelsForGenre,
      );

      if (genre.title.toLowerCase().contains('radio')) {
        radioSubCategories.add(subCategory);
      } else {
        liveTvSubCategories.add(subCategory);
      }
    }

    // 5. Process VOD categories into Movies and Series
    for (final vodCategory in allVodCategories) {
      final contentForCategory = (vodContentByCategory[vodCategory.id] ?? [])
          .map((v) => PlayableItem(id: v.id, name: v.name, logoUrl: v.logo))
          .toList();

      if (contentForCategory.isEmpty) continue;

      final subCategory = SubCategory(
        name: vodCategory.title,
        items: contentForCategory,
      );

      final title = vodCategory.title.toLowerCase();
      if (title.contains('series') ||
          title.contains('seasons') ||
          title.contains('shows')) {
        seriesSubCategories.add(subCategory);
      } else {
        moviesSubCategories.add(subCategory);
      }
    }

    // 6. Assemble the final list of main categories, filtering out empty ones
    final mainCategories = <MainCategory>[];
    if (liveTvSubCategories.isNotEmpty) {
      mainCategories.add(
        MainCategory(name: 'Live TV', subCategories: liveTvSubCategories),
      );
    }
    if (moviesSubCategories.isNotEmpty) {
      mainCategories.add(
        MainCategory(name: 'Films', subCategories: moviesSubCategories),
      );
    }
    if (seriesSubCategories.isNotEmpty) {
      mainCategories.add(
        MainCategory(name: 'Series', subCategories: seriesSubCategories),
      );
    }
    if (radioSubCategories.isNotEmpty) {
      mainCategories.add(
        MainCategory(name: 'Radio', subCategories: radioSubCategories),
      );
    }

    return GroupedContent(categories: mainCategories);
  }
}

@riverpod
ContentGroupingService contentGroupingService(Ref ref) {
  return ContentGroupingService(DatabaseHelper.instance);
}
