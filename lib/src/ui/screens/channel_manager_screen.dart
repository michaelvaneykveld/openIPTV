import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/channel_override_provider.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/channel_override.dart';

class ChannelManagerScreen extends ConsumerStatefulWidget {
  const ChannelManagerScreen({super.key});

  @override
  ConsumerState<ChannelManagerScreen> createState() =>
      _ChannelManagerScreenState();
}

class _ChannelManagerScreenState extends ConsumerState<ChannelManagerScreen> {
  List<_ManagedChannel>? _managedChannels;

  @override
  Widget build(BuildContext context) {
    final portalIdAsync = ref.watch(portalIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Channel Manager')),
      body: portalIdAsync.when(
        data: (portalId) {
          if (portalId == null) {
            return const Center(child: Text('No active portal selected.'));
          }

          final overridesAsync = ref.watch(channelOverridesProvider(portalId));
          return overridesAsync.when(
            data: (overrides) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance.getAllChannels(portalId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return const Center(child: Text('No channels available.'));
                  }

                  final overrideMap = {
                    for (final override in overrides)
                      override.channelId: override,
                  };

                  _managedChannels ??=
                      rows.map((row) => Channel.fromDbMap(row)).map((channel) {
                        final override =
                            overrideMap[channel.id] ??
                            ChannelOverride(
                              portalId: portalId,
                              channelId: channel.id,
                            );
                        return _ManagedChannel(
                          channel: channel,
                          override: override,
                        );
                      }).toList()..sort((a, b) {
                        final posA = a.override.position ?? 1 << 20;
                        final posB = b.override.position ?? 1 << 20;
                        return posA.compareTo(posB);
                      });

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _managedChannels!.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      setState(() {
                        final item = _managedChannels!.removeAt(oldIndex);
                        _managedChannels!.insert(newIndex, item);
                      });

                      final reordered = _managedChannels!
                          .asMap()
                          .entries
                          .map(
                            (entry) => entry.value.override.copyWith(
                              position: entry.key,
                            ),
                          )
                          .toList();
                      await ref
                          .read(channelOverrideControllerProvider)
                          .reorder(portalId, reordered);
                    },
                    itemBuilder: (context, index) {
                      final managed = _managedChannels![index];
                      return _buildManagedTile(context, portalId, managed);
                    },
                  );
                },
              );
            },
            error: (error, stackTrace) =>
                Center(child: Text('Error: ${error.toString()}')),
            loading: () => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (error, stackTrace) =>
            Center(child: Text('Error: ${error.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildManagedTile(
    BuildContext context,
    String portalId,
    _ManagedChannel managed,
  ) {
    final controller = ref.read(channelOverrideControllerProvider);
    final override = managed.override;
    final isHidden = override.isHidden;
    final displayName = override.customName?.isNotEmpty == true
        ? override.customName!
        : managed.channel.name;
    final groupLabel =
        override.customGroup ?? managed.channel.group ?? 'Ungrouped';

    return ListTile(
      key: ValueKey(managed.channel.id),
      leading: Icon(isHidden ? Icons.visibility_off : Icons.drag_indicator),
      title: Text(displayName),
      subtitle: Text(groupLabel),
      trailing: Wrap(
        spacing: 8,
        children: [
          Switch(
            value: !isHidden,
            onChanged: (visible) async {
              await controller.setHidden(
                portalId,
                managed.channel.id,
                !visible,
              );
              _invalidateCache();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Rename channel',
            onPressed: () async {
              final name = await _promptForText(
                context,
                'Rename channel',
                displayName,
              );
              if (name != null) {
                await controller.updateName(
                  portalId,
                  managed.channel.id,
                  name.trim().isEmpty ? null : name.trim(),
                );
                _invalidateCache();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Set group',
            onPressed: () async {
              final group = await _promptForText(
                context,
                'Set group',
                override.customGroup ?? managed.channel.group ?? '',
              );
              if (group != null) {
                await controller.updateGroup(
                  portalId,
                  managed.channel.id,
                  group.trim().isEmpty ? null : group.trim(),
                );
                _invalidateCache();
              }
            },
          ),
          if (override.customName != null ||
              override.customGroup != null ||
              override.isHidden)
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Reset overrides',
              onPressed: () async {
                await controller.removeOverride(portalId, managed.channel.id);
                _invalidateCache();
              },
            ),
        ],
      ),
    );
  }

  void _invalidateCache() {
    setState(() {
      _managedChannels = null;
    });
  }

  Future<String?> _promptForText(
    BuildContext context,
    String title,
    String initial,
  ) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ManagedChannel {
  const _ManagedChannel({required this.channel, required this.override});

  final Channel channel;
  final ChannelOverride override;
}
