import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/src/providers/provider_profiles_provider.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

/// Entry screen for managing saved provider logins alongside new additions.
class ProviderManagementScreen extends ConsumerStatefulWidget {
  const ProviderManagementScreen({super.key});

  @override
  ConsumerState<ProviderManagementScreen> createState() =>
      _ProviderManagementScreenState();
}

class _ProviderManagementScreenState
    extends ConsumerState<ProviderManagementScreen> {
  final _stalkerUrlController = TextEditingController();
  final _stalkerMacController = TextEditingController();
  final _xtreamUrlController = TextEditingController();
  final _xtreamUsernameController = TextEditingController();
  final _xtreamPasswordController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _m3uFileController = TextEditingController();

  @override
  void dispose() {
    _stalkerUrlController.dispose();
    _stalkerMacController.dispose();
    _xtreamUrlController.dispose();
    _xtreamUsernameController.dispose();
    _xtreamPasswordController.dispose();
    _m3uUrlController.dispose();
    _m3uFileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provider Management'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            final addProviderSection = FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: _AddProviderCard(
                stalkerUrlController: _stalkerUrlController,
                stalkerMacController: _stalkerMacController,
                xtreamUrlController: _xtreamUrlController,
                xtreamUsernameController: _xtreamUsernameController,
                xtreamPasswordController: _xtreamPasswordController,
                m3uUrlController: _m3uUrlController,
                m3uFileController: _m3uFileController,
              ),
            );

            final savedLoginsSection = FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: _SavedLoginsPanel(
                onRequestDelete: _handleDeleteProfile,
                onConnect: (record) =>
                    _showSnack('Connecting to ${record.displayName}'),
                onEdit: (record) =>
                    _showSnack('Edit flow for ${record.displayName}'),
              ),
            );

            final content = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: addProviderSection),
                      const SizedBox(width: 16),
                      Expanded(child: savedLoginsSection),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      addProviderSection,
                      const SizedBox(height: 16),
                      savedLoginsSection,
                    ],
                  );

            return FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleDeleteProfile(ProviderProfileRecord record) async {
    final repository = ref.read(providerProfileRepositoryProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${record.displayName}?'),
          content: const Text(
            'Delete this saved login? This removes credentials.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirm != true) {
      return;
    }

    final secretsSnapshot =
        await repository.loadSecrets(record.id);

    await repository.deleteProfile(record.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${record.displayName}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            repository.saveProfile(
              profileId: record.id,
              kind: record.kind,
              lockedBase: record.lockedBase,
              displayName: record.displayName,
              configuration: Map<String, String>.from(record.configuration),
              hints: Map<String, String>.from(record.hints),
              secrets: secretsSnapshot?.secrets ?? const <String, String>{},
              needsUserAgent: record.needsUserAgent,
              allowSelfSignedTls: record.allowSelfSignedTls,
              followRedirects: record.followRedirects,
              successAt: record.lastOkAt,
            );
          },
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AddProviderCard extends StatelessWidget {
  const _AddProviderCard({
    required this.stalkerUrlController,
    required this.stalkerMacController,
    required this.xtreamUrlController,
    required this.xtreamUsernameController,
    required this.xtreamPasswordController,
    required this.m3uUrlController,
    required this.m3uFileController,
  });

  final TextEditingController stalkerUrlController;
  final TextEditingController stalkerMacController;
  final TextEditingController xtreamUrlController;
  final TextEditingController xtreamUsernameController;
  final TextEditingController xtreamPasswordController;
  final TextEditingController m3uUrlController;
  final TextEditingController m3uFileController;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const TabBar(
              tabs: [
                Tab(text: 'Stalker'),
                Tab(text: 'Xtream'),
                Tab(text: 'M3U'),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: TabBarView(
              children: [
                _buildStalkerForm(context),
                _buildXtreamForm(context),
                _buildM3uForm(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStalkerForm(BuildContext context) {
    return _FormSection(
      children: [
        TextFormField(
          controller: stalkerUrlController,
          decoration: const InputDecoration(
            labelText: 'Portal URL',
            hintText: 'http://portal.example.com/c/',
          ),
        ),
        TextFormField(
          controller: stalkerMacController,
          decoration: const InputDecoration(
            labelText: 'MAC Address',
            hintText: '00:1A:79:12:34:56',
          ),
        ),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Custom headers',
            hintText: 'X-Device: Flutter',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Stalker login'),
          ),
        ),
      ],
    );
  }

  Widget _buildXtreamForm(BuildContext context) {
    return _FormSection(
      children: [
        TextFormField(
          controller: xtreamUrlController,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://host:8080',
          ),
        ),
        TextFormField(
          controller: xtreamUsernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
          ),
        ),
        TextFormField(
          controller: xtreamPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Xtream login'),
          ),
        ),
      ],
    );
  }

  Widget _buildM3uForm(BuildContext context) {
    return _FormSection(
      children: [
        TextFormField(
          controller: m3uUrlController,
          decoration: const InputDecoration(
            labelText: 'Playlist URL',
            hintText: 'https://example.com/playlist.m3u8',
          ),
        ),
        TextFormField(
          controller: m3uFileController,
          decoration: const InputDecoration(
            labelText: 'Local file path',
            hintText: '/storage/emulated/0/Download/list.m3u',
          ),
        ),
        SwitchListTile(
          value: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (_) {},
          title: const Text('Follow redirects automatically'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add M3U login'),
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._intersperse(const SizedBox(height: 12), children),
        ],
      ),
    );
  }

  static List<Widget> _intersperse(Widget separator, List<Widget> input) {
    if (input.isEmpty) {
      return const [];
    }
    final result = <Widget>[];
    for (var i = 0; i < input.length; i++) {
      result.add(input[i]);
      if (i < input.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}

class _SavedLoginsPanel extends ConsumerWidget {
  const _SavedLoginsPanel({
    required this.onRequestDelete,
    required this.onConnect,
    required this.onEdit,
  });

  final Future<void> Function(ProviderProfileRecord) onRequestDelete;
  final void Function(ProviderProfileRecord) onConnect;
  final void Function(ProviderProfileRecord) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLoginsAsync = ref.watch(savedProfilesStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: savedLoginsAsync.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return _EmptySavedLogins();
            }
            return ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final record = profiles[index];
                return _SavedLoginTile(
                  record: record,
                  onConnect: () => onConnect(record),
                  onEdit: () => onEdit(record),
                  onDelete: () => onRequestDelete(record),
                );
              },
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemCount: profiles.length,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _SavedLoginsError(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      ),
    );
  }
}

class _SavedLoginsError extends StatelessWidget {
  const _SavedLoginsError({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(
          'Failed to load saved logins',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmptySavedLogins extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'No saved logins',
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 64,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No saved logins yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SavedLoginTile extends StatelessWidget {
  const _SavedLoginTile({
    required this.record,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  final ProviderProfileRecord record;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final host = record.lockedBase.host.isEmpty
        ? record.lockedBase.toString()
        : record.lockedBase.host;
    final subtitle = _buildSubtitle(context, host, record.lastOkAt);
    final iconData = _iconFor(record.kind);
    final semanticLabel = _semanticLabelFor(record.kind);

    return Semantics(
      button: true,
      label: 'Connect ${record.displayName}',
      child: ListTile(
        onTap: onConnect,
        leading: Semantics(
          label: semanticLabel,
          child: Icon(iconData),
        ),
        title: Text(record.displayName),
        subtitle: Text(subtitle),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete ${record.displayName}',
              onPressed: onDelete,
            ),
            PopupMenuButton<_SavedLoginMenuAction>(
              tooltip: 'Actions for ${record.displayName}',
              onSelected: (action) {
                switch (action) {
                  case _SavedLoginMenuAction.connect:
                    onConnect();
                    break;
                  case _SavedLoginMenuAction.edit:
                    onEdit();
                    break;
                  case _SavedLoginMenuAction.delete:
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _SavedLoginMenuAction.connect,
                  child: const Text('Connect'),
                ),
                PopupMenuItem(
                  value: _SavedLoginMenuAction.edit,
                  child: const Text('Edit'),
                ),
                PopupMenuItem(
                  value: _SavedLoginMenuAction.delete,
                  child: const Text('Delete'),
                ),
              ],
              child: Semantics(
                label: 'More actions for ${record.displayName}',
                child: const Icon(Icons.more_vert),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(BuildContext context, String host, DateTime? lastOk) {
    final localization = MaterialLocalizations.of(context);
    final formattedDate = lastOk != null
        ? '${localization.formatShortDate(lastOk.toLocal())} '
            '${localization.formatTimeOfDay(TimeOfDay.fromDateTime(lastOk.toLocal()))}'
        : 'Never';

    return '$host • Last sync: $formattedDate';
  }

  IconData _iconFor(ProviderKind kind) => switch (kind) {
        ProviderKind.stalker => Icons.router,
        ProviderKind.xtream => Icons.tv,
        ProviderKind.m3u => Icons.playlist_play,
      };

  String _semanticLabelFor(ProviderKind kind) => switch (kind) {
        ProviderKind.stalker => 'Stalker provider',
        ProviderKind.xtream => 'Xtream provider',
        ProviderKind.m3u => 'M3U provider',
      };
}

enum _SavedLoginMenuAction { connect, edit, delete }
