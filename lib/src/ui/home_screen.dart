import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/navigation_tree_provider.dart'; // Import the new provider
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';

// import '../application/providers/channel_list_provider.dart'; // No longer needed
// import '../core/models/channel.dart'; // No longer directly needed for display
import 'package:openiptv/src/application/providers/credentials_provider.dart';

/// The main screen of the application, displaying the list of channels.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  TreeNode? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final portalIdAsyncValue = ref.watch(portalIdProvider);

    return portalIdAsyncValue.when(
      data: (portalId) {
        if (portalId == null) {
          return const Center(child: Text('Portal URL not found. Please log in.'));
        }
        // Watch the navigationTreeProvider to get the state of the tree.
        final navigationTreeAsyncValue = ref.watch(navigationTreeProvider);

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                    ),
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  )
                : const Text('OpenIPTV'),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    _searchQuery = '';
                  });
                },
              ),
              // Add a refresh button to the app bar.
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Invalidate the provider to force a refresh of the tree.
                  ref.invalidate(navigationTreeProvider);
                },
              ),
              // Add a logout button to the app bar.
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(stalkerApiProvider).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              // Add a debug button to the app bar.
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: () {
                  context.push('/debug');
                },
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return navigationTreeAsyncValue.when(
                // Data is successfully loaded, display the tree.
                data: (treeNodes) {
                  if (constraints.maxWidth > 600) {
                    return _buildWideLayout(context, treeNodes, portalId, ref);
                  } else {
                    return _buildNarrowLayout(context, treeNodes, portalId, ref);
                  }
                },
                // An error occurred, display the error message.
                error: (err, stack) => Center(
                  child: Text('Error: ${err.toString()}'),
                ),
                // Data is loading, show a progress indicator.
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading portal ID: ${err.toString()}')),
    );
  }

  Widget _buildWideLayout(BuildContext context, List<TreeNode> nodes, String portalId, WidgetRef ref) {
    final filteredNodes = _filterNodes(nodes, _searchQuery);
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: ListView.builder(
            itemCount: filteredNodes.length,
            itemBuilder: (context, index) {
              final node = filteredNodes[index];
              return ExpansionTile(
                title: Text(node.title),
                initiallyExpanded: true,
                children: node.children.map((child) {
                  return ListTile(
                    title: Text(child.title),
                    selected: _selectedCategory == child,
                    onTap: () {
                      setState(() {
                        _selectedCategory = child;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        Expanded(
          child: _selectedCategory != null
              ? ListView.builder(
                  itemCount: _selectedCategory!.children.length,
                  itemBuilder: (context, index) {
                    final node = _selectedCategory!.children[index];
                    return _buildTreeNode(context, node, portalId, ref);
                  },
                )
              : const Center(
                  child: Text('Select a category'),
                ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, List<TreeNode> nodes, String portalId, WidgetRef ref) {
    return _buildTree(context, nodes, portalId, ref);
  }

  /// Builds the tree structure using ExpansionTiles.
  Widget _buildTree(BuildContext context, List<TreeNode> nodes, String portalId, WidgetRef ref) { // Added context
    if (nodes.isEmpty) {
      return const Center(
        child: Text('No data found to build the navigation tree.'),
      );
    }

    final filteredNodes = _filterNodes(nodes, _searchQuery);

    return FocusTraversalGroup(
      child: ListView.builder(
        itemCount: filteredNodes.length,
        itemBuilder: (context, index) {
          final node = filteredNodes[index];
          return _buildTreeNode(context, node, portalId, ref); // Pass context
        },
      ),
    );
  }

  List<TreeNode> _filterNodes(List<TreeNode> nodes, String query) {
    if (query.isEmpty) {
      return nodes;
    }

    final filteredNodes = <TreeNode>[];
    for (final node in nodes) {
      if (node.title.toLowerCase().contains(query.toLowerCase())) {
        filteredNodes.add(node);
      } else if (node.children.isNotEmpty) {
        final filteredChildren = _filterNodes(node.children, query);
        if (filteredChildren.isNotEmpty) {
          filteredNodes.add(TreeNode(
            title: node.title,
            type: node.type,
            data: node.data,
            children: filteredChildren,
          ));
        }
      }
    }
    return filteredNodes;
  }

  Widget _buildTreeNode(BuildContext context, TreeNode node, String portalId, WidgetRef ref) { // Added context
    if (node.children.isEmpty) {
      // Leaf node (e.g., Channel, VOD item)
      return ListTile(
        focusNode: FocusNode(),
        title: Text(node.title),
        trailing: node.type == 'channel'
            ? IconButton(
                icon: Icon(
                  (node.data as Channel).fav == 1 ? Icons.star : Icons.star_border,
                ),
                onPressed: () => _toggleFavorite(node.data as Channel, portalId, ref),
              )
            : null,
        onTap: () {
          if (node.type == 'channel') {
            context.go('/player', extra: node.data);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped on \${node.title} (\${node.type})')),
            );
          }
        },
      );
    } else {
      // Node with children (e.g., Portal, Live TV, Category)
      return ExpansionTile(
        initiallyExpanded: _searchQuery.isNotEmpty,
        title: Text(node.title),
        children: node.children.map((childNode) => _buildTreeNode(context, childNode, portalId, ref)).toList(), // Pass context
      );
    }
  }

  void _toggleFavorite(Channel channel, String portalId, WidgetRef ref) async {
    final newChannel = Channel(
      id: channel.id,
      name: channel.name,
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
      fav: channel.fav == 1 ? 0 : 1,
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
      group: channel.group,
      epgId: channel.epgId,
    );
    await DatabaseHelper.instance.updateChannel(newChannel.toMap(), portalId);
    ref.invalidate(navigationTreeProvider);
  }
}
