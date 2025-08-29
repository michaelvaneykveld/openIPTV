import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';

import '../application/providers/channel_list_provider.dart';
import '../core/models/channel.dart';

/// The main screen of the application, displaying the list of channels.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the channelListProvider to get the state of the channel list.
    final channelsAsyncValue = ref.watch(channelListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenIPTV'),
        actions: [
          // Add a refresh button to the app bar.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Invalidate the provider to force a refresh of the channel list.
              ref.invalidate(channelListProvider);
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
      body: channelsAsyncValue.when(
        // Data is successfully loaded, display the list.
        data: (channels) => _buildChannelList(channels),
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
  }

  /// Builds the list of channels grouped by their category.
  Widget _buildChannelList(List<Channel> channels) {
    if (channels.isEmpty) {
      return const Center(
        child: Text('No channels found. Please check your provider settings.'),
      );
    }

    // Group channels by their 'group' property.
    final groupedChannels = _groupChannels(channels);
    final groupTitles = groupedChannels.keys.toList();

    // Use a ListView.builder for efficient rendering of long lists.
    return ListView.builder(
      itemCount: groupTitles.length,
      itemBuilder: (context, index) {
        final groupName = groupTitles[index];
        final channelsInGroup = groupedChannels[groupName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                groupName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // List of channels in the group
            ...channelsInGroup.map((channel) => ListTile(
                  leading: channel.logoUrl != null
                      ? Image.network(
                          channel.logoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          // Show a placeholder on error
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.tv),
                        )
                      : const Icon(Icons.tv),
                  title: Text(channel.name),
                  onTap: () {
                    // TODO: Implement channel playback functionality.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing ${channel.name}')),
                    );
                  },
                )),
            const Divider(),
          ],
        );
      },
    );
  }

  /// Helper function to group a flat list of channels by their group name.
  Map<String, List<Channel>> _groupChannels(List<Channel> channels) {
    final Map<String, List<Channel>> grouped = {};
    for (final channel in channels) {
      (grouped[channel.group] ??= []).add(channel);
    }
    return grouped;
  }
}