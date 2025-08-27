import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer; // Import the developer log

import '../../../application/providers/repository_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    developer.log('HomeScreen build method called.', name: 'UI-Lifecycle');

    // This line triggers the entire data fetching process.
    final channelsAsyncValue = ref.watch(liveChannelsProvider);

    developer.log('liveChannelsProvider state: $channelsAsyncValue',
        name: 'UI-State');

    return Scaffold(
      appBar: AppBar(
        title: const Text('openIPTV'),
      ),
      body: channelsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          developer.log('An error occurred in liveChannelsProvider',
              name: 'UI-Error', error: error, stackTrace: stackTrace);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Failed to load channels:\n$error',
                  textAlign: TextAlign.center),
            ),
          );
        },
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(child: Text('No channels found.'));
          }
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ListTile(
                leading: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                    ? Image.network(channel.logoUrl!)
                    : const Icon(Icons.tv),
                title: Text(channel.name),
                subtitle: Text(channel.group),
              );
            },
          );
        },
      ),
    );
  }
}
