import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/providers/openiptv_content_providers.dart';
import 'package:openiptv/src/ui/player/mini_player.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  final ResolvedProviderProfile profile;
  final CategoryKind categoryKind;

  const LiveTvScreen({
    super.key,
    required this.profile,
    this.categoryKind = CategoryKind.live,
  });

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  int? _selectedCategoryId;
  int? _selectedStreamId;
  PlayerMediaSource? _currentMediaSource;
  bool _isLoadingMedia = false;

  Future<void> _resolveChannel(ChannelRecord channel) async {
    setState(() {
      _isLoadingMedia = true;
      _selectedStreamId = channel.id;
    });

    try {
      final resolver = ref.read(playableResolverProvider(widget.profile));
      final source = await resolver.channel(channel);

      if (mounted) {
        setState(() {
          _currentMediaSource = source;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play channel: $e')));
      }
    }
  }

  ContentBucket _getBucket() {
    switch (widget.categoryKind) {
      case CategoryKind.live:
        return ContentBucket.live;
      case CategoryKind.radio:
        return ContentBucket.radio;
      case CategoryKind.vod:
        return ContentBucket.films;
      case CategoryKind.series:
        return ContentBucket.series;
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerId = widget.profile.providerDbId;
    if (providerId == null) {
      return const Center(child: Text('Provider not initialized in new DB'));
    }

    final groupsAsync = ref.watch(dbCategoriesProvider(providerId));

    return Row(
      children: [
        // Column 1: Groups
        Expanded(
          flex: 2,
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: groupsAsync.when(
              data: (categoryMap) {
                final groups = categoryMap[_getBucket()] ?? [];
                return ListView.builder(
                  itemCount: groups.length + 1, // +1 for "All"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: const Text('All Channels'),
                        selected: _selectedCategoryId == null,
                        onTap: () => setState(() => _selectedCategoryId = null),
                      );
                    }
                    final group = groups[index - 1];
                    final groupId = int.tryParse(group.id);
                    if (groupId == null) return const SizedBox.shrink();

                    return ListTile(
                      title: Text(group.name),
                      selected: _selectedCategoryId == groupId,
                      onTap: () =>
                          setState(() => _selectedCategoryId = groupId),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Column 2: Channels
        Expanded(
          flex: 3,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: _buildChannelList(providerId),
          ),
        ),
        const VerticalDivider(width: 1),
        // Column 3: Preview & EPG
        Expanded(
          flex: 5,
          child: Column(
            children: [
              // Player Area
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.black,
                  child: Center(child: _buildPlayerArea()),
                ),
              ),
              // EPG Area
              Expanded(
                flex: 1,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: _selectedStreamId == null
                      ? const Center(child: Text('No EPG available'))
                      : _buildEpgList(_selectedStreamId!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerArea() {
    if (_isLoadingMedia) {
      return const CircularProgressIndicator();
    }
    if (_currentMediaSource == null) {
      return const Text(
        'Select a channel',
        style: TextStyle(color: Colors.white),
      );
    }
    return MiniPlayer(
      key: ValueKey(_currentMediaSource!.uri),
      source: _currentMediaSource!,
    );
  }

  Widget _buildChannelList(int providerId) {
    final channelsAsync = ref.watch(
      channelsProvider((
        providerId: providerId,
        categoryId: _selectedCategoryId,
        kind: widget.categoryKind,
      )),
    );

    return channelsAsync.when(
      data: (channels) => ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return ListTile(
            leading: channel.logoUrl != null
                ? Image.network(
                    channel.logoUrl!,
                    width: 40,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.tv),
                  )
                : const Icon(Icons.tv),
            title: Text(channel.name),
            selected: _selectedStreamId == channel.id,
            onTap: () => _resolveChannel(channel),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildEpgList(int channelId) {
    final epgAsync = ref.watch(epgProvider((channelId: channelId)));

    return epgAsync.when(
      data: (events) {
        if (events.isEmpty) return const Center(child: Text('No program info'));
        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final now = DateTime.now().toUtc();
            final isCurrent =
                event.startUtc.isBefore(now) && event.endUtc.isAfter(now);

            return ListTile(
              title: Text(
                event.title ?? 'No Title',
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                '${_formatTime(event.startUtc)} - ${_formatTime(event.endUtc)}',
              ),
              leading: isCurrent
                  ? const Icon(Icons.play_arrow, size: 16)
                  : null,
              selected: isCurrent,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
