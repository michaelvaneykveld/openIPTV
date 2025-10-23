import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/core/models/channel.dart';

/// Temporary placeholder for the video player screen.
///
/// Until the real player is implemented this screen simply displays the
/// resolved stream source (if any) so we can verify that channel selection
/// and navigation work end-to-end.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final streamUrl = _resolveStreamUrl(channel);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(channel.name),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.tv,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Player coming soon',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  streamUrl != null
                      ? 'When the player is implemented, this channel will try to play from the stream source below.'
                      : 'We could not resolve a stream source for this channel yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (streamUrl != null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Resolved stream source',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            streamUrl,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No stream URL or command was found for this channel.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveStreamUrl(Channel channel) {
    if (channel.streamUrl != null && channel.streamUrl!.isNotEmpty) {
      return channel.streamUrl;
    }
    if (channel.cmd != null && channel.cmd!.isNotEmpty) {
      return channel.cmd;
    }
    final cmds = channel.cmds ?? [];
    for (final cmd in cmds) {
      if (cmd.url != null && cmd.url!.isNotEmpty) {
        return cmd.url;
      }
    }
    return null;
  }
}
