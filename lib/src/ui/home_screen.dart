import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/navigation_tree_provider.dart'; // Import the new provider
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/ui/responsive/responsive_layout.dart';

/// The main screen of the application, displaying the list of channels.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String? _activeSectionTitle;
  String? _activeCategoryTitle;

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
          body: navigationTreeAsyncValue.when(
            data: (treeNodes) => ResponsiveLayoutBuilder(
              builder: (context, sizeClass) {
                final filteredNodes = _filterNodes(treeNodes, _searchQuery);
                return _buildResponsiveLayout(
                  context,
                  sizeClass,
                  filteredNodes,
                  portalId,
                  ref,
                );
              },
            ),
            error: (err, stack) => Center(
              child: Text('Error: ${err.toString()}'),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading portal ID: ${err.toString()}')),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    ScreenSizeClass sizeClass,
    List<TreeNode> nodes,
    String portalId,
    WidgetRef ref,
  ) {
    if (_searchQuery.isNotEmpty) {
      // For search results, always show the compact list regardless of size.
      return _buildNarrowLayout(context, nodes, portalId, ref);
    }

    switch (sizeClass) {
      case ScreenSizeClass.compact:
        return _buildNarrowLayout(context, nodes, portalId, ref);
      case ScreenSizeClass.medium:
        return _buildWideLayout(context, nodes, portalId, ref);
      case ScreenSizeClass.expanded:
        return _buildDesktopLayout(context, nodes, portalId, ref);
    }
  }

  Widget _buildWideLayout(BuildContext context, List<TreeNode> nodes, String portalId, WidgetRef ref) {
    if (nodes.isEmpty) {
      return const Center(
        child: Text('No data found to build the navigation tree.'),
      );
    }
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

  Widget _buildDesktopLayout(BuildContext context, List<TreeNode> nodes, String portalId, WidgetRef ref) {
    if (nodes.isEmpty) {
      return const Center(
        child: Text('No content available.'),
      );
    }

    final portalNode = nodes.firstWhere(
      (node) => node.type == 'portal',
      orElse: () => nodes.first,
    );
    final sections = portalNode.children.isNotEmpty ? portalNode.children : nodes;

    if (sections.isEmpty) {
      return _buildWideLayout(context, nodes, portalId, ref);
    }

    final selectedSection = _selectNode(sections, _activeSectionTitle);
    if (_activeSectionTitle != selectedSection?.title) {
      _activeSectionTitle = selectedSection?.title;
      _activeCategoryTitle = null; // Reset category when section changes.
    }

    final categoryCandidates = selectedSection?.children ?? [];
    final selectedCategory = _selectNode(categoryCandidates, _activeCategoryTitle);
    if (_activeCategoryTitle != selectedCategory?.title) {
      _activeCategoryTitle = selectedCategory?.title;
    }

    final leafNodes = selectedCategory?.children.isNotEmpty == true
        ? selectedCategory!.children
        : selectedSection?.children ?? [];

    return Row(
      children: [
        NavigationRail(
          selectedIndex: sections.indexWhere((node) => node.title == _activeSectionTitle),
          onDestinationSelected: (index) {
            setState(() {
              _activeSectionTitle = sections[index].title;
              _activeCategoryTitle = null;
            });
          },
          destinations: sections
              .map(
                (section) => NavigationRailDestination(
                  icon: Icon(_iconForNodeType(section.type)),
                  label: Text(section.title),
                ),
              )
              .toList(),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: categoryCandidates.isEmpty
              ? const Center(child: Text('No categories available.'))
              : ListView.builder(
                  itemCount: categoryCandidates.length,
                  itemBuilder: (context, index) {
                    final category = categoryCandidates[index];
                    final isSelected = category.title == _activeCategoryTitle;
                    return ListTile(
                      title: Text(category.title),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _activeCategoryTitle = category.title;
                        });
                      },
                    );
                  },
                ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: leafNodes.isEmpty
              ? const Center(child: Text('Select a category to see items.'))
              : ListView.builder(
                  itemCount: leafNodes.length,
                  itemBuilder: (context, index) {
                    final node = leafNodes[index];
                    if (node.children.isNotEmpty) {
                      return ExpansionTile(
                        title: Text(node.title),
                        children: node.children
                            .map((child) => _buildTreeNode(context, child, portalId, ref))
                            .toList(),
                      );
                    }
                    return _buildTreeNode(context, node, portalId, ref);
                  },
                ),
        ),
      ],
    );
  }

  TreeNode? _selectNode(List<TreeNode> nodes, String? preferredTitle) {
    if (nodes.isEmpty) return null;
    if (preferredTitle != null) {
      for (final node in nodes) {
        if (node.title == preferredTitle) {
          return node;
        }
      }
    }
    return nodes.first;
  }

  IconData _iconForNodeType(String type) {
    switch (type) {
      case 'live':
        return Icons.live_tv;
      case 'film':
        return Icons.movie;
      case 'series':
        return Icons.video_library;
      case 'radio':
        return Icons.radio;
      case 'category':
        return Icons.folder;
      default:
        return Icons.list_alt;
    }
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
