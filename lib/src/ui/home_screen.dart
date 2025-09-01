import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/navigation_tree_provider.dart'; // Import the new provider

// import '../application/providers/channel_list_provider.dart'; // No longer needed
// import '../core/models/channel.dart'; // No longer directly needed for display
import 'package:openiptv/src/application/providers/credentials_provider.dart';

/// The main screen of the application, displaying the list of channels.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: const Text('OpenIPTV'),
            actions: [
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
            ],
          ),
          body: navigationTreeAsyncValue.when(
            // Data is successfully loaded, display the tree.
            data: (treeNodes) => _buildTree(context, treeNodes), // Pass context
            // An error occurred, display the error message.
            error: (err, stack) => Center(
              child: Text('Error: ${err.toString()}'),
            ),
            // Data is loading, show a progress indicator.
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

  /// Builds the tree structure using ExpansionTiles.
  Widget _buildTree(BuildContext context, List<TreeNode> nodes) { // Added context
    if (nodes.isEmpty) {
      return const Center(
        child: Text('No data found to build the navigation tree.'),
      );
    }

    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return _buildTreeNode(context, node); // Pass context
      },
    );
  }

  Widget _buildTreeNode(BuildContext context, TreeNode node) { // Added context
    if (node.children.isEmpty) {
      // Leaf node (e.g., Channel, VOD item)
      return ListTile(
        title: Text(node.title),
        onTap: () {
          // TODO: Implement playback or detail view based on node.type and node.data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on \${node.title} (\${node.type})')),
          );
        },
      );
    } else {
      // Node with children (e.g., Portal, Live TV, Category)
      return ExpansionTile(
        title: Text(node.title),
        children: node.children.map((childNode) => _buildTreeNode(context, childNode)).toList(), // Pass context
      );
    }
  }
}