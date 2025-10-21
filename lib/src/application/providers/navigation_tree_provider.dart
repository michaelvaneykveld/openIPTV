import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/models.dart';
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
    // --- Populate Live TV with Universal Grouping Logic ---

    // 1. Fetch all necessary data
    final channelsMaps = await dbHelper.getAllChannels(portalId);
    final allChannels = channelsMaps.map((c) => Channel.fromDbMap(c)).toList();

    final genresMaps = await dbHelper.getAllGenres(portalId);
    final genreIdToTitleMap = { for (var g in genresMaps) g[DatabaseHelper.columnGenreId]: g[DatabaseHelper.columnGenreTitle] };

    // 2. Group channels
    final groupedChannels = <String, List<Channel>>{};
    for (var channel in allChannels) {
      String groupKey;
      if (channel.group != null && channel.group!.isNotEmpty) {
        groupKey = channel.group!;
      } else if (channel.genreId != null && genreIdToTitleMap.containsKey(channel.genreId)) {
        groupKey = genreIdToTitleMap[channel.genreId]!;
      } else {
        groupKey = 'Uncategorized';
      }

      if (!groupedChannels.containsKey(groupKey)) {
        groupedChannels[groupKey] = [];
      }
      groupedChannels[groupKey]!.add(channel);
    }

    // 3. Build the TreeNode structure for Live TV
    groupedChannels.forEach((groupName, channelsInGroup) {
      final categoryNode = TreeNode(
        title: groupName,
        type: 'category',
        children: channelsInGroup.map((channel) {
          return TreeNode(
            title: channel.name,
            type: 'channel',
            data: channel,
          );
        }).toList(),
      );
      liveNode.children.add(categoryNode);
    });

    // --- Populate Films (VOD Categories and Content) ---
    final vodCategoriesMaps = await dbHelper.getAllVodCategories(portalId);
    final vodCategories = vodCategoriesMaps.map((e) => VodCategory.fromJson(e)).toList();

    for (var category in vodCategories) {
      final categoryNode = TreeNode(
        title: category.title,
        type: 'category',
        data: category,
        children: [],
      );
      filmNode.children.add(categoryNode); // Assuming VOD categories are for Films/Series

      final vodContentMaps = await dbHelper.getVodContentByCategoryId(category.id, portalId);
      final vodContent = vodContentMaps.map((e) => VodContent.fromDbMap(e)).toList();

      for (var content in vodContent) {
        final contentNode = TreeNode(
          title: content.name,
          type: 'vod_item',
          data: content,
        );
        categoryNode.children.add(contentNode);
      }
    }

    // TODO: Implement Series and Radio population if data sources become available
    // For now, Films will contain all VOD content.

  } catch (e, stackTrace) {
    appLogger.e('Error building navigation tree', error: e, stackTrace: stackTrace);
    // Return an empty tree or a tree with an error node if desired
    return [
      TreeNode(
        title: 'Error loading data',
        type: 'error',
        data: '$e\n$stackTrace',
      )
    ];
  }

  return tree;
});
