import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/utils/credential_parser.dart';

// A union type for the provider family
class TransientCredential {
  final StalkerCredential? stalker;
  final XtreamCredential? xtream;

  const TransientCredential({this.stalker, this.xtream});

  String get url => stalker?.url ?? xtream?.url ?? 'Unknown';
  ProviderKind get kind =>
      stalker != null ? ProviderKind.stalker : ProviderKind.xtream;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransientCredential &&
        other.stalker == stalker &&
        other.xtream == xtream;
  }

  @override
  int get hashCode => stalker.hashCode ^ xtream.hashCode;
}

class TransientPortalInfoDialog extends ConsumerWidget {
  final TransientCredential credential;

  const TransientPortalInfoDialog({super.key, required this.credential});

  ResolvedProviderProfile _createProfile() {
    final now = DateTime.now();
    if (credential.xtream != null) {
      final xtream = credential.xtream!;
      return ResolvedProviderProfile(
        record: ProviderProfileRecord(
          id: 'transient_${xtream.url}', // Transient ID
          displayName: xtream.url,
          kind: ProviderKind.xtream,
          configuration: const {},
          createdAt: now,
          updatedAt: now,
          followRedirects: true,
          allowSelfSignedTls: true, // Allow for flexibility
          lockedBase: Uri.parse(xtream.url),
          needsUserAgent: false,
          hints: const {},
          hasSecrets: true,
        ),
        secrets: {'username': xtream.username, 'password': xtream.password},
      );
    } else {
      final stalker = credential.stalker!;
      return ResolvedProviderProfile(
        record: ProviderProfileRecord(
          id: 'transient_${stalker.url}', // Transient ID
          displayName: stalker.url,
          kind: ProviderKind.stalker,
          configuration: {'macAddress': stalker.mac},
          createdAt: now,
          updatedAt: now,
          followRedirects: true,
          allowSelfSignedTls: true, // Allow for flexibility
          lockedBase: Uri.parse(stalker.url),
          needsUserAgent: false,
          hints: const {},
          hasSecrets: true,
        ),
        secrets: {'mac': stalker.mac},
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a transient profile from the credential
    final profile = _createProfile();

    // Use the existing legacySummaryProvider to fetch the data
    final summaryAsync = ref.watch(legacySummaryProvider(profile));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: summaryAsync.when(
          data: (summary) {
            return SingleChildScrollView(
              child: _buildTransientCard(context, profile, summary),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching Portal Info...'),
                ],
              ),
            ),
          ),
          error: (err, stack) {
            if (err is PingException ||
                err is DioException ||
                err is FormatException) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.signal_wifi_off_outlined,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Portal May Be Offline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Fetching Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransientCard(
    BuildContext context,
    ResolvedProviderProfile profile,
    SummaryData data,
  ) {
    final theme = Theme.of(context);
    final counts = {
      'Live': data.counts['Live'] ?? data.counts['live'] ?? 0,
      'Movies': data.counts['Movies'] ?? data.counts['vod'] ?? 0,
      'Series': data.counts['Series'] ?? data.counts['series'] ?? 0,
      'Radio': data.counts['Radio'] ?? data.counts['radio'] ?? 0,
    };
    final expiry = _getExpiryDate(profile, data);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme, profile, latency: data.pingLatency),
          const Divider(height: 16),
          if (data.fields.containsKey('Error'))
            _buildInfoRow(theme, 'Error', data.fields['Error']!)
          else ...[
            ...counts.entries.map(
              (e) => _buildInfoRow(theme, e.key, e.value.toString()),
            ),
            if (expiry != null) _buildInfoRow(theme, 'Expires', expiry),
          ],
        ],
      ),
    );
  }

  String? _getExpiryDate(ResolvedProviderProfile profile, SummaryData data) {
    if (profile.kind == ProviderKind.stalker) {
      final phone = data.fields['Phone'];
      if (phone != null && phone.isNotEmpty) {
        return phone;
      }
      final expireField = data.fields.entries.firstWhere(
        (entry) => entry.key.toLowerCase().contains('expir'),
        orElse: () => const MapEntry('', ''),
      );
      if (expireField.value.isNotEmpty) {
        return expireField.value;
      }
    } else if (profile.kind == ProviderKind.xtream) {
      return data.fields['exp_date'];
    }
    return null;
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ResolvedProviderProfile profile, {
    Duration? latency,
  }) {
    final colorScheme = theme.colorScheme;
    String typeLabel = '';
    switch (profile.kind) {
      case ProviderKind.stalker:
        typeLabel = 'Stalker Portal';
        break;
      case ProviderKind.xtream:
        typeLabel = 'Xtream Codes';
        break;
      case ProviderKind.m3u:
        typeLabel = 'M3U Playlist';
        break;
    }

    String? detailText;
    if (profile.kind == ProviderKind.stalker) {
      final mac = profile.secrets['mac'] ?? profile.record.configuration['mac'];
      if (mac != null) {
        detailText = 'MAC: $mac';
      }
    } else if (profile.kind == ProviderKind.xtream) {
      final username = profile.secrets['username'];
      if (username != null) {
        detailText = 'User: $username';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PORTAL INFO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            if (latency != null)
              Text(
                'Latency: ${latency.inMilliseconds}ms',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(153),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          profile.record.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          profile.lockedBase.host,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withAlpha(180),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (detailText != null) ...[
          const SizedBox(height: 6),
          Text(
            detailText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(180),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
