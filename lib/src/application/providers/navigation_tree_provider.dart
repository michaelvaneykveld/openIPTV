import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/data/models.dart';
import 'package:openiptv/utils/app_logger.dart';

// Define a data structure for a tree node
class TreeNode {
  final String title;
  final String type; // e.g., 'portal', 'live', 'film', 'series', 'radio', 'category', 'channel', 'vod_item'
  final dynamic data; // The actual object (e.g., Channel, VodContent, Genre)
  final List<TreeNode> children;

  TreeNode({
    required this.title,
    required this.type,
    this.data,
    this.children = const [],
  });
}

final navigationTreeProvider = FutureProvider<List<TreeNode>>((ref) async {
  final portalId = await ref.watch(portalIdProvider.future);
  if (portalId == null) {
    return [];
  }

  final dbHelper = DatabaseHelper.instance;
  final List<TreeNode> tree = [];

  // 1. The Portal
  final portalNode = TreeNode(
    title: 'Portal: $portalId',
    type: 'portal',
    children: [],
  );
  tree.add(portalNode);

  // 2. Live / Film / Series / Radio
  final liveNode = TreeNode(title: 'Live TV', type: 'live', children: []);
  final filmNode = TreeNode(title: 'Films', type: 'film', children: []);
  final seriesNode = TreeNode(title: 'Series', type: 'series', children: []);
  final radioNode = TreeNode(title: 'Radio', type: 'radio', children: []); // Placeholder for now

  portalNode.children.addAll([liveNode, filmNode, seriesNode, radioNode]);

  try {
    // Populate Live TV (Genres and Channels)
    final genresMaps = await dbHelper.getAllGenres(portalId);
    final genres = genresMaps.map((e) => Genre.fromJson(e)).toList();

    for (var genre in genres) {
      final genreNode = TreeNode(
        title: genre.title, // Removed ?? 'Unknown Genre'
        type: 'category',
        data: genre,
        children: [],
      );
      liveNode.children.add(genreNode);

      final channelsMaps = await dbHelper.getAllChannels(portalId);
      final channels = channelsMaps.map((e) => Channel.fromJson(e)).toList();
      final channelsInGenre = channels.where((c) => c.genreId == genre.id).toList();

      for (var channel in channelsInGenre) {
        final channelNode = TreeNode(
          title: channel.name, // Removed ?? 'Unknown Channel'
          type: 'channel',
          data: channel,
        );
        genreNode.children.add(channelNode);
      }
    }

    // Populate Films (VOD Categories and Content)
    final vodCategoriesMaps = await dbHelper.getAllVodCategories(portalId);
    final vodCategories = vodCategoriesMaps.map((e) => VodCategory.fromJson(e)).toList();

    for (var category in vodCategories) {
      final categoryNode = TreeNode(
        title: category.title, // Removed ?? 'Unknown Category'
        type: 'category',
        data: category,
        children: [],
      );
      filmNode.children.add(categoryNode); // Assuming VOD categories are for Films/Series

      final vodContentMaps = await dbHelper.getVodContentByCategoryId(category.id, portalId); // Removed !
      final vodContent = vodContentMaps.map((e) => VodContent.fromJson(e)).toList();

      for (var content in vodContent) {
        final contentNode = TreeNode(
          title: content.name, // Removed ?? 'Unknown Content'
          type: 'vod_item',
          data: content,
        );
        categoryNode.children.add(contentNode);
      }
    }

    // TODO: Implement Series and Radio population if data sources become available
    // For now, Films will contain all VOD content.

  } catch (e) {
    appLogger.e('Error building navigation tree: $e');
    // Return an empty tree or a tree with an error node if desired
    return [
      TreeNode(
        title: 'Error loading data',
        type: 'error',
        data: e.toString(),
      )
    ];
  }

  return tree;
});