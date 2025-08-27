import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../core/models/channel.dart';
import '../../../application/providers/channel_list_provider.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    developer.log('HomeScreen build method called.', name: 'UI-Lifecycle');

    final channelsAsyncValue = ref.watch(channelListProvider);

    developer.log('channelListProvider state: $channelsAsyncValue', name: 'UI-State');

    // Group channels by the 'group' property
    final groupedChannels = channelsAsyncValue.asData?.value.fold<Map<String, List<Channel>>>(
      {},
      (map, channel) {
        map.putIfAbsent(channel.group, () => []).add(channel);
        return map;
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('openIPTV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              developer.log('Refreshing channel list...', name: 'UI-Action');
              ref.invalidate(channelListProvider);
            },
          ),
        ],
      ),
      body: channelsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          developer.log(
            'An error occurred in channelListProvider',
            name: 'UI-Error',
            error: error,
            stackTrace: stackTrace,
          );
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Failed to load channels:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(child: Text('No channels found.'));
          }
          // Render the grouped list
          return ListView.builder(
            itemCount: groupedChannels?.keys.length ?? 0,
            itemBuilder: (context, index) {
              final group = groupedChannels?.keys.elementAt(index);
              final groupChannels = groupedChannels?[group] ?? [];
              return ExpansionTile(
                title: Text(group ?? 'Uncategorized'),
                children: groupChannels.map((channel) => ListTile(
                  leading: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                      ? Image.network(
                          channel.logoUrl!,
                          width: 40, // Set a fixed width for logos
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv),
                        )
                      : const Icon(Icons.tv),
                  title: Text(channel.name),
                  onTap: () {
                    // TODO: Implement channel playback
                    developer.log('Tapped on channel: ${channel.name}', name: 'UI-Action');
                  },
                )).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
