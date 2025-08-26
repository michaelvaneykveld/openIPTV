import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer; // Import the developer log
import '../../../application/providers/channel_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LOG #1: This confirms the UI is being built.
    developer.log('HomeScreen build method called.', name: 'UI-Lifecycle');

    // This line triggers the entire data fetching process.
    final channelsAsyncValue = ref.watch(liveChannelsProvider);

    // LOG #2: This shows us the current state of the provider.
    developer.log('liveChannelsProvider state: $channelsAsyncValue', name: 'UI-State');

    return Scaffold(
      appBar: AppBar(
        title: const Text('openIPTV'),
      ),
      body: channelsAsyncValue.when(
        loading: () {
          // This will be shown while the network request is in progress.
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          // This will be shown if the network request fails.
          developer.log('An error occurred in liveChannelsProvider',
              name: 'UI-Error', error: error, stackTrace: stackTrace);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Failed to load channels:\n$error'),
            ),
          );
        },
        data: (channels) {
          // This is shown on success.
          return const Center(
            child: Text(
              'Success! Check the Debug Console for network logs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}
