import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/ui/settings/transient_portal_info.dart';
import 'package:openiptv/src/utils/credential_parser.dart';

class ParsedCredentialsPage extends StatelessWidget {
  final List<StalkerCredential> stalkerCredentials;
  final List<XtreamCredential> xtreamCredentials;

  const ParsedCredentialsPage({
    super.key,
    required this.stalkerCredentials,
    required this.xtreamCredentials,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [
      ...stalkerCredentials.map((c) => TransientCredential(stalker: c)),
      ...xtreamCredentials.map((c) => TransientCredential(xtream: c)),
    ];

    // Wrap with ProviderScope to provide Riverpod context for the dialog
    return ProviderScope(
      child: Scaffold(
        appBar: AppBar(title: Text('Found Credentials (${allItems.length})')),
        body: allItems.isEmpty
            ? const Center(child: Text('No credentials found in messages.'))
            : ListView.separated(
                itemCount: allItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  Widget subtitle;
                  if (item.stalker != null) {
                    subtitle = Text(
                      'MAC: ${item.stalker!.mac}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    );
                  } else if (item.xtream != null) {
                    subtitle = Text(
                      'User: ${item.xtream!.username}\nPass: ${item.xtream!.password}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    );
                  } else {
                    subtitle = const SizedBox.shrink();
                  }

                  return ListTile(
                    title: Text(
                      item.url,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: subtitle,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Fetch Portal Info',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            // The ProviderScope from the Scaffold's body provides the context
                            return TransientPortalInfoDialog(credential: item);
                          },
                        );
                      },
                    ),
                    isThreeLine: item.xtream != null,
                  );
                },
              ),
      ),
    );
  }
}
