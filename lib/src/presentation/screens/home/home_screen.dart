import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/channel_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the liveChannelsProvider to get the async result.
    final channelsAsyncValue = ref.watch(liveChannelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Channels'),
      ),
      // Use .when to handle loading, error, and data states gracefully.
      body: channelsAsyncValue.when(
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(child: Text('No channels found.'));
          }
          // If we have data, display it in a ListView.
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ListTile(
                leading: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                    ? Image.network(channel.logoUrl!, width: 40, errorBuilder: (c, o, s) => const Icon(Icons.tv))
                    : const Icon(Icons.tv),
                title: Text(channel.name),
                subtitle: Text(channel.group),
                onTap: () {
                  // TODO: Implement player navigation
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load channels:\n$error', textAlign: TextAlign.center)),
      ),
    );
  }
}