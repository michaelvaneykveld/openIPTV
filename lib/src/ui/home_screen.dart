import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/navigation_tree_provider.dart'; // Import the new provider
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/application/providers/account_provider.dart';
import 'package:openiptv/src/application/providers/channel_override_provider.dart';
import 'package:openiptv/src/application/providers/sync_scheduler_provider.dart';
import 'package:openiptv/src/application/services/recording_service.dart';
import 'package:openiptv/src/application/services/reminder_service.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/ui/responsive/responsive_layout.dart';

/// The main screen of the application, displaying the list of channels.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeMenuAction {
  manageChannels,
  recordings,
  reminders,
  syncSettings,
  debug,
}

enum _ChannelAction { recordNow, scheduleRecording, setReminder }

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String? _activeSectionTitle;
  String? _activeCategoryTitle;

  @override
  Widget build(BuildContext context) {
    final portalIdAsyncValue = ref.watch(portalIdProvider);
    ref.watch(syncSchedulerProvider);

    return portalIdAsyncValue.when(
      data: (portalId) {
        if (portalId == null) {
          return const Center(
            child: Text('Portal URL not found. Please log in.'),
          );
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
                tooltip: _isSearching ? 'Close search' : 'Search',
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    _searchQuery = '';
                    _activeSectionTitle = null;
                    _activeCategoryTitle = null;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.switch_account),
                tooltip: 'Switch account',
                onPressed: () => _showAccountSwitcher(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh content',
                onPressed: () {
                  ref.invalidate(navigationTreeProvider);
                },
              ),
              PopupMenuButton<_HomeMenuAction>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More actions',
                onSelected: (action) => _handleMenuAction(context, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _HomeMenuAction.manageChannels,
                    child: Text('Manage channels'),
                  ),
                  PopupMenuItem(
                    value: _HomeMenuAction.recordings,
                    child: Text('Recordings'),
                  ),
                  PopupMenuItem(
                    value: _HomeMenuAction.reminders,
                    child: Text('Reminders'),
                  ),
                  PopupMenuItem(
                    value: _HomeMenuAction.syncSettings,
                    child: Text('Sync settings'),
                  ),
                  PopupMenuItem(
                    value: _HomeMenuAction.debug,
                    child: Text('Debug tools'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await ref.read(stalkerApiProvider).logout();
                  if (!context.mounted) return;
                  context.go('/login');
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
            error: (err, stack) =>
                Center(child: Text('Error: ${err.toString()}')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Error loading portal ID: ${err.toString()}')),
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

  void _handleMenuAction(BuildContext context, _HomeMenuAction action) {
    switch (action) {
      case _HomeMenuAction.manageChannels:
        _openChannelManager(context);
        break;
      case _HomeMenuAction.recordings:
        _openRecordingCenter(context);
        break;
      case _HomeMenuAction.reminders:
        _openReminderCenter(context);
        break;
      case _HomeMenuAction.syncSettings:
        _openSyncSettings(context);
        break;
      case _HomeMenuAction.debug:
        context.push('/debug');
        break;
    }
  }

  void _openChannelManager(BuildContext context) {
    context.push('/channels/manage');
  }

  void _openRecordingCenter(BuildContext context) {
    context.push('/recordings');
  }

  void _openReminderCenter(BuildContext context) {
    context.push('/reminders');
  }

  void _openSyncSettings(BuildContext context) {
    context.push('/settings/sync');
  }

  Future<void> _showAccountSwitcher(BuildContext context) async {
    final credentialsRepository = ref.read(credentialsRepositoryProvider);
    final credentials = await credentialsRepository.getSavedCredentials();
    if (!context.mounted) return;

    final activePortal = ref.read(activePortalProvider);

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: activePortal,
          onChanged: (value) {
            if (value == null) return;
            unawaited(_handleAccountSelection(sheetContext, value));
          },
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Select account')),
              for (final credential in credentials)
                RadioListTile<String>(
                  value: credential.id,
                  title: Text(credential.name),
                  subtitle: Text(credential.type),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccountSelection(
    BuildContext sheetContext,
    String portalId,
  ) async {
    await ref.read(activePortalProvider.notifier).setActivePortal(portalId);
    ref.invalidate(portalIdProvider);
    ref.invalidate(navigationTreeProvider);
    ref.invalidate(channelOverridesProvider(portalId));
    if (!mounted) return;
    setState(() {
      _activeSectionTitle = null;
      _activeCategoryTitle = null;
    });
    if (!sheetContext.mounted) return;
    Navigator.of(sheetContext).pop();
  }

  Widget _buildWideLayout(
    BuildContext context,
    List<TreeNode> nodes,
    String portalId,
    WidgetRef ref,
  ) {
    if (nodes.isEmpty) {
      return const Center(
        child: Text('No data found to build the navigation tree.'),
      );
    }
    final filteredNodes = _filterNodes(nodes, _searchQuery);

    if (filteredNodes.isEmpty) {
      return const Center(
        child: Text('No data found to build the navigation tree.'),
      );
    }

    final portalNode = filteredNodes.firstWhere(
      (node) => node.type == 'portal',
      orElse: () => filteredNodes.first,
    );
    final sections = portalNode.children.isNotEmpty
        ? portalNode.children
        : filteredNodes;

    if (sections.isEmpty) {
      return const Center(child: Text('No sections available.'));
    }

    final selectedSection = _selectNode(sections, _activeSectionTitle);
    if (_activeSectionTitle != selectedSection?.title) {
      _activeSectionTitle = selectedSection?.title;
      _activeCategoryTitle = null;
    }

    final categoryCandidates = selectedSection?.children ?? [];
    final selectedCategory = categoryCandidates.isNotEmpty
        ? _selectNode(categoryCandidates, _activeCategoryTitle)
        : selectedSection;
    if (categoryCandidates.isNotEmpty &&
        _activeCategoryTitle != selectedCategory?.title) {
      _activeCategoryTitle = selectedCategory?.title;
    }

    final leafNodes = selectedCategory?.children ?? [];

    return Row(
      children: [
        SizedBox(
          width: 300,
          child: ListView(
            children: sections.map((section) {
              final isExpanded =
                  section.title == _activeSectionTitle ||
                  section.children.any(
                    (category) => category.title == _activeCategoryTitle,
                  );
              final children = section.children;

              if (children.isEmpty) {
                return ListTile(
                  leading: Icon(_iconForNodeType(section.type)),
                  title: Text(section.title),
                  selected: section.title == _activeSectionTitle,
                  onTap: () {
                    setState(() {
                      _activeSectionTitle = section.title;
                      _activeCategoryTitle = null;
                    });
                  },
                );
              }

              return ExpansionTile(
                key: PageStorageKey(section.title),
                leading: Icon(_iconForNodeType(section.type)),
                title: Text(section.title),
                initiallyExpanded: isExpanded,
                children: children.map((category) {
                  final isSelected = category.title == _activeCategoryTitle;
                  return ListTile(
                    title: Text(category.title),
                    selected: isSelected,
                    trailing: category.children.isNotEmpty
                        ? Text(
                            '${category.children.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _activeSectionTitle = section.title;
                        _activeCategoryTitle = category.title;
                      });
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: leafNodes.isEmpty
              ? const Center(child: Text('Select a category to see items.'))
              : ListView.builder(
                  itemCount: leafNodes.length,
                  itemBuilder: (context, index) {
                    final node = leafNodes[index];
                    return _buildTreeNode(context, node, portalId, ref);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    List<TreeNode> nodes,
    String portalId,
    WidgetRef ref,
  ) {
    return _buildTree(context, nodes, portalId, ref);
  }

  /// Builds the tree structure using ExpansionTiles.
  Widget _buildTree(
    BuildContext context,
    List<TreeNode> nodes,
    String portalId,
    WidgetRef ref,
  ) {
    // Added context
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
          filteredNodes.add(
            TreeNode(
              title: node.title,
              type: node.type,
              data: node.data,
              children: filteredChildren,
            ),
          );
        }
      }
    }
    return filteredNodes;
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    List<TreeNode> nodes,
    String portalId,
    WidgetRef ref,
  ) {
    if (nodes.isEmpty) {
      return const Center(child: Text('No content available.'));
    }

    final portalNode = nodes.firstWhere(
      (node) => node.type == 'portal',
      orElse: () => nodes.first,
    );
    final sections = portalNode.children.isNotEmpty
        ? portalNode.children
        : nodes;

    if (sections.isEmpty) {
      return _buildWideLayout(context, nodes, portalId, ref);
    }

    final selectedSection = _selectNode(sections, _activeSectionTitle);
    if (_activeSectionTitle != selectedSection?.title) {
      _activeSectionTitle = selectedSection?.title;
      _activeCategoryTitle = null; // Reset category when section changes.
    }

    final categoryCandidates = selectedSection?.children ?? [];
    final selectedCategory = _selectNode(
      categoryCandidates,
      _activeCategoryTitle,
    );
    if (_activeCategoryTitle != selectedCategory?.title) {
      _activeCategoryTitle = selectedCategory?.title;
    }

    final leafNodes = selectedCategory?.children.isNotEmpty == true
        ? selectedCategory!.children
        : selectedSection?.children ?? [];

    return Row(
      children: [
        NavigationRail(
          selectedIndex: sections.indexWhere(
            (node) => node.title == _activeSectionTitle,
          ),
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
                            .map(
                              (child) =>
                                  _buildTreeNode(context, child, portalId, ref),
                            )
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

  Widget _buildTreeNode(
    BuildContext context,
    TreeNode node,
    String portalId,
    WidgetRef ref,
  ) {
    // Added context
    if (node.children.isEmpty) {
      // Leaf node (e.g., Channel, VOD item)
      return ListTile(
        focusNode: FocusNode(),
        title: Text(node.title),
        trailing: node.type == 'channel'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      (node.data as Channel).fav == 1
                          ? Icons.star
                          : Icons.star_border,
                    ),
                    onPressed: () =>
                        _toggleFavorite(node.data as Channel, portalId, ref),
                  ),
                  PopupMenuButton<_ChannelAction>(
                    tooltip: 'Channel actions',
                    onSelected: (action) => _handleChannelAction(
                      context,
                      node.data as Channel,
                      action,
                      portalId,
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ChannelAction.recordNow,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.fiber_manual_record,
                            color: Colors.redAccent,
                          ),
                          title: Text('Record now'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _ChannelAction.scheduleRecording,
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.schedule),
                          title: Text('Schedule recording'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _ChannelAction.setReminder,
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.alarm),
                          title: Text('Set reminder'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : null,
        onTap: () {
          if (node.type == 'channel') {
            context.go('/player', extra: node.data);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped on ${node.title} (${node.type})')),
            );
          }
        },
      );
    } else {
      // Node with children (e.g., Portal, Live TV, Category)
      return ExpansionTile(
        initiallyExpanded: _searchQuery.isNotEmpty,
        title: Text(node.title),
        children: node.children
            .map(
              (childNode) => _buildTreeNode(context, childNode, portalId, ref),
            )
            .toList(), // Pass context
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

  Future<void> _handleChannelAction(
    BuildContext context,
    Channel channel,
    _ChannelAction action,
    String portalId,
  ) async {
    switch (action) {
      case _ChannelAction.recordNow:
        await _startRecordingNowForChannel(context, channel, portalId);
        break;
      case _ChannelAction.scheduleRecording:
        await _scheduleRecordingForChannel(context, channel, portalId);
        break;
      case _ChannelAction.setReminder:
        await _createReminderForChannel(context, channel, portalId);
        break;
    }
  }

  Future<void> _startRecordingNowForChannel(
    BuildContext context,
    Channel channel,
    String portalId,
  ) async {
    final durationMinutes = await _promptForNumber(
      context,
      'Recording duration (minutes)',
      '60',
    );
    final duration = durationMinutes != null
        ? Duration(minutes: durationMinutes)
        : null;
    await ref
        .read(recordingManagerProvider)
        .startRecordingNow(
          channel: channel,
          portalId: portalId,
          duration: duration,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recording started for ${channel.name}.')),
    );
  }

  Future<void> _scheduleRecordingForChannel(
    BuildContext context,
    Channel channel,
    String portalId,
  ) async {
    final start = await _pickDateTime(context, 'Recording start time');
    if (!context.mounted) return;
    if (start == null) return;
    final end = await _pickDateTime(context, 'Recording end time');
    if (!context.mounted) return;
    if (end == null || end.isBefore(start)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    await ref
        .read(recordingManagerProvider)
        .scheduleRecording(
          channel: channel,
          portalId: portalId,
          startTime: start,
          endTime: end,
        );
    if (!context.mounted) return;
    final startLabel = _formatDateTime(start);
    final endLabel = _formatDateTime(end);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recording scheduled for ${channel.name} ($startLabel - $endLabel).',
        ),
      ),
    );
  }

  Future<void> _createReminderForChannel(
    BuildContext context,
    Channel channel,
    String portalId,
  ) async {
    final startTime = await _pickDateTime(context, 'Program start time');
    if (!context.mounted) return;
    if (startTime == null) return;
    final title = await _promptForText(context, 'Program title', channel.name);
    if (!context.mounted) return;
    if (title == null || title.trim().isEmpty) return;
    await ref
        .read(reminderManagerProvider)
        .scheduleReminder(
          channel: channel,
          portalId: portalId,
          programTitle: title.trim(),
          startTime: startTime,
        );
    if (!context.mounted) return;
    final startLabel = _formatDateTime(startTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${channel.name} at $startLabel.'),
      ),
    );
  }

  Future<int?> _promptForNumber(
    BuildContext context,
    String title,
    String initial,
  ) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<DateTime?> _pickDateTime(BuildContext context, String title) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: title,
    );
    if (!context.mounted) return null;
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
