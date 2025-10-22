import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/channel_override_provider.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/utils/app_logger.dart';

// Define a data structure for a tree node
class TreeNode {
  final String title;
  final String
  type; // e.g., 'portal', 'live', 'film', 'series', 'radio', 'category', 'channel', 'vod_item'
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

  final overrides = await ref.watch(channelOverridesProvider(portalId).future);
  final overrideMap = {
    for (final override in overrides) override.channelId: override,
  };

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
  final radioNode = TreeNode(
    title: 'Radio',
    type: 'radio',
    children: [],
  ); // Placeholder for now

  portalNode.children.addAll([liveNode, filmNode, seriesNode, radioNode]);

  try {
    // --- Populate Live TV with Universal Grouping Logic ---

    // 1. Fetch all necessary data
    final channelsMaps = await dbHelper.getAllChannels(portalId);
    final allChannels = <Channel>[];
    for (final map in channelsMaps) {
      final channel = Channel.fromDbMap(map);
      final override = overrideMap[channel.id];
      if (override?.isHidden ?? false) {
        continue;
      }
      allChannels.add(_applyChannelOverride(channel, override));
    }
    allChannels.sort((a, b) => _channelSortComparator(a, b, overrideMap));

    final genresMaps = await dbHelper.getAllGenres(portalId);
    final genreIdToTitleMap = {
      for (var g in genresMaps)
        g[DatabaseHelper.columnGenreId]: g[DatabaseHelper.columnGenreTitle],
    };

    // 2. Group channels
    final groupedChannels = <String, List<Channel>>{};
    for (var channel in allChannels) {
      String groupKey;
      if (channel.group != null && channel.group!.isNotEmpty) {
        groupKey = channel.group!;
      } else if (channel.genreId != null &&
          genreIdToTitleMap.containsKey(channel.genreId)) {
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
          return TreeNode(title: channel.name, type: 'channel', data: channel);
        }).toList(),
      );
      liveNode.children.add(categoryNode);
    });

    // --- Populate Films (VOD Categories and Content) ---
    final vodCategoriesMaps = await dbHelper.getAllVodCategories(portalId);
    final vodCategories = vodCategoriesMaps
        .map((e) => VodCategory.fromJson(e))
        .toList();
    final vodCategoryTitleMap = {
      for (final category in vodCategories) category.id: category.title,
    };

    for (var category in vodCategories) {
      final categoryNode = TreeNode(
        title: category.title,
        type: 'category',
        data: category,
        children: [],
      );
      filmNode.children.add(
        categoryNode,
      ); // Assuming VOD categories are for Films/Series

      final vodContentMaps = await dbHelper.getVodContentByCategoryId(
        category.id,
        portalId,
      );
      final vodContent = vodContentMaps
          .map((e) => VodContent.fromDbMap(e))
          .toList();

      for (var content in vodContent) {
        final contentNode = TreeNode(
          title: content.name,
          type: 'vod_item',
          data: content,
        );
        categoryNode.children.add(contentNode);
      }
    }

    // --- Populate Series ---
    final seriesMaps = await dbHelper.getAllSeries(portalId);
    if (seriesMaps.isEmpty) {
      seriesNode.children.add(
        TreeNode(title: 'No series available', type: 'info'),
      );
    } else {
      final seriesItems = seriesMaps.map((row) {
        return VodContent(
          id: row[DatabaseHelper.columnSeriesId] as String,
          name: row[DatabaseHelper.columnSeriesName] as String,
          cmd: row[DatabaseHelper.columnSeriesCmd] as String?,
          logo: row[DatabaseHelper.columnSeriesLogo] as String?,
          description: row[DatabaseHelper.columnSeriesDescription] as String?,
          year: row[DatabaseHelper.columnSeriesYear] as String?,
          director: row[DatabaseHelper.columnSeriesDirector] as String?,
          actors: row[DatabaseHelper.columnSeriesActors] as String?,
          duration: row[DatabaseHelper.columnSeriesDuration] as String?,
          categoryId: row[DatabaseHelper.columnSeriesCategoryId] as String?,
        );
      }).toList();

      final groupedSeries = <String, List<VodContent>>{};
      for (final series in seriesItems) {
        final key = series.categoryId ?? '_uncategorized';
        groupedSeries.putIfAbsent(key, () => []).add(series);
      }

      groupedSeries.forEach((categoryId, items) {
        final categoryTitle =
            vodCategoryTitleMap[categoryId] ?? 'Uncategorized Series';
        seriesNode.children.add(
          TreeNode(
            title: categoryId == '_uncategorized'
                ? 'Uncategorized Series'
                : categoryTitle,
            type: 'category',
            children: items
                .map(
                  (item) => TreeNode(
                    title: item.name,
                    type: 'series_item',
                    data: item,
                  ),
                )
                .toList(),
          ),
        );
      });
    }

    // --- Populate Radio ---
    final radioChannels = allChannels.where((channel) {
      final group = channel.group?.toLowerCase() ?? '';
      return group.contains('radio');
    }).toList();

    if (radioChannels.isEmpty) {
      radioNode.children.add(
        TreeNode(title: 'No radio channels available', type: 'info'),
      );
    } else {
      final groupedRadio = <String, List<Channel>>{};
      for (final channel in radioChannels) {
        final key = channel.group?.isNotEmpty == true
            ? channel.group!
            : 'Radio';
        groupedRadio.putIfAbsent(key, () => []).add(channel);
      }

      groupedRadio.forEach((groupName, channelsInGroup) {
        final categoryNode = TreeNode(
          title: groupName,
          type: 'category',
          children: channelsInGroup
              .map(
                (channel) => TreeNode(
                  title: channel.name,
                  type: 'radio_channel',
                  data: channel,
                ),
              )
              .toList(),
        );
        radioNode.children.add(categoryNode);
      });
    }
  } catch (e, stackTrace) {
    appLogger.e(
      'Error building navigation tree',
      error: e,
      stackTrace: stackTrace,
    );
    // Return an empty tree or a tree with an error node if desired
    return [
      TreeNode(
        title: 'Error loading data',
        type: 'error',
        data: '$e\n$stackTrace',
      ),
    ];
  }

  return tree;
});
Channel _applyChannelOverride(Channel channel, ChannelOverride? override) {
  if (override == null) {
    return channel;
  }
  final name = override.customName?.isNotEmpty == true
      ? override.customName!
      : channel.name;
  final group = override.customGroup?.isNotEmpty == true
      ? override.customGroup!
      : channel.group;
  return Channel(
    id: channel.id,
    name: name,
    number: channel.number,
    logo: channel.logo,
    genreId: channel.genreId,
    xmltvId: channel.xmltvId,
    epg: channel.epg,
    genresStr: channel.genresStr,
    curPlaying: channel.curPlaying,
    status: channel.status,
    hd: channel.hd,
    censored: channel.censored,
    fav: channel.fav,
    locked: channel.locked,
    archive: channel.archive,
    pvr: channel.pvr,
    enableTvArchive: channel.enableTvArchive,
    tvArchiveDuration: channel.tvArchiveDuration,
    allowPvr: channel.allowPvr,
    allowLocalPvr: channel.allowLocalPvr,
    allowRemotePvr: channel.allowRemotePvr,
    allowLocalTimeshift: channel.allowLocalTimeshift,
    cmd: channel.cmd,
    cmd1: channel.cmd1,
    cmd2: channel.cmd2,
    cmd3: channel.cmd3,
    cost: channel.cost,
    count: channel.count,
    baseCh: channel.baseCh,
    serviceId: channel.serviceId,
    bonusCh: channel.bonusCh,
    volumeCorrection: channel.volumeCorrection,
    mcCmd: channel.mcCmd,
    wowzaTmpLink: channel.wowzaTmpLink,
    wowzaDvr: channel.wowzaDvr,
    useHttpTmpLink: channel.useHttpTmpLink,
    monitoringStatus: channel.monitoringStatus,
    enableMonitoring: channel.enableMonitoring,
    enableWowzaLoadBalancing: channel.enableWowzaLoadBalancing,
    correctTime: channel.correctTime,
    nimbleDvr: channel.nimbleDvr,
    modified: channel.modified,
    nginxSecureLink: channel.nginxSecureLink,
    open: channel.open,
    useLoadBalancing: channel.useLoadBalancing,
    cmds: channel.cmds,
    streamUrl: channel.streamUrl,
    group: group,
    epgId: channel.epgId,
  );
}

int _channelSortComparator(
  Channel a,
  Channel b,
  Map<String, ChannelOverride> overrides,
) {
  final posA = overrides[a.id]?.position ?? 1 << 20;
  final posB = overrides[b.id]?.position ?? 1 << 20;
  if (posA != posB) {
    return posA.compareTo(posB);
  }
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
