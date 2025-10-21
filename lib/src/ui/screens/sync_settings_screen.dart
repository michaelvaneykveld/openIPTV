import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/sync_scheduler_provider.dart';

class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(syncSchedulerProvider);
    final controller = ref.read(syncSchedulerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Synchronization Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enable automatic synchronization'),
            value: settings.enabled,
            onChanged: (value) =>
                controller.updateSettings(settings.copyWith(enabled: value)),
          ),
          SwitchListTile(
            title: const Text('Wi-Fi only'),
            value: settings.wifiOnly,
            onChanged: settings.enabled
                ? (value) => controller.updateSettings(
                    settings.copyWith(wifiOnly: value),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Refresh interval: ${settings.intervalMinutes} minutes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: settings.intervalMinutes.toDouble(),
            min: 30,
            max: 360,
            divisions: ((360 - 30) ~/ 30),
            label: '${settings.intervalMinutes} min',
            onChanged: settings.enabled
                ? (value) => controller.updateSettings(
                    settings.copyWith(intervalMinutes: value.round()),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
