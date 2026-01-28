import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/player/categories_fetchers.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_normalizer.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_discovery.dart';
import 'package:openiptv/src/providers/provider_import_service.dart';
import 'package:openiptv/src/providers/provider_sync_service.dart';
import 'package:openiptv/src/ui/settings/transient_portal_info.dart';
import 'package:openiptv/src/utils/credential_parser.dart';
import 'package:openiptv/src/utils/url_normalization.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';

class ParsedCredentialsPage extends ConsumerStatefulWidget {
  final List<StalkerCredential> stalkerCredentials;
  final List<XtreamCredential> xtreamCredentials;

  const ParsedCredentialsPage({
    super.key,
    required this.stalkerCredentials,
    required this.xtreamCredentials,
  });

  @override
  ConsumerState<ParsedCredentialsPage> createState() =>
      _ParsedCredentialsPageState();
}

class _ParsedCredentialsPageState extends ConsumerState<ParsedCredentialsPage> {
  static const int _maxConcurrentGroupProbes = 3;
  static const int _maxConcurrentCredentialProbes = 4;
  static const int _maxCategoryPreviewChips = 8;

  static const String _xtreamFallbackUserAgent =
      'Hypnotix/2.0 (Linux; IPTV) Flutter/OpenIPTV XtreamProbe';
  static const String _stalkerFallbackUserAgent =
      'Mozilla/5.0 (QtEmbedded; Linux; U; en) stbapp';

  late final List<PortalGroup> _groups;
  final Map<String, GroupProbeState> _groupStates = {};
  final Map<String, CredentialProbeState> _credentialStates = {};
  final Map<String, bool> _selectedCredentials = {};

  bool _isProbingAll = false;
  bool _showOnlySuccess = false;

  @override
  void initState() {
    super.initState();
    _groups = _buildGroups();
  }

  List<PortalGroup> _buildGroups() {
    final allItems = <TransientCredential>[
      ...widget.stalkerCredentials.map((c) => TransientCredential(stalker: c)),
      ...widget.xtreamCredentials.map((c) => TransientCredential(xtream: c)),
    ];

    final grouped = <String, PortalGroup>{};

    for (final credential in allItems) {
      final rawUrl = credential.url;
      final kind = credential.kind;
      StalkerPortalNormalizationResult? stalkerNormalization;
      Uri? normalizedUri;
      String normalizedKey = rawUrl;
      String displayUrl = rawUrl;

      try {
        if (kind == ProviderKind.stalker) {
          stalkerNormalization = normalizeStalkerPortalInput(rawUrl);
          normalizedUri = normalizePort(stalkerNormalization.canonicalUri);
        } else {
          final parsed = Uri.parse(
            canonicalizeScheme(rawUrl, defaultScheme: 'http'),
          );
          final stripped = ensureTrailingSlash(stripKnownFiles(parsed));
          normalizedUri = normalizePort(stripped);
        }
      } catch (_) {
        normalizedUri = null;
      }

      if (normalizedUri != null) {
        normalizedKey = normalizedUri.toString();
        displayUrl = normalizedKey;
      }

      final groupKey = '${kind.name}::$normalizedKey';
      final existing = grouped[groupKey];
      if (existing == null) {
        grouped[groupKey] = PortalGroup(
          kind: kind,
          normalizedKey: normalizedKey,
          displayUrl: displayUrl,
          normalizedUri: normalizedUri,
          stalkerNormalization: stalkerNormalization,
          credentials: [credential],
        );
      } else {
        existing.credentials.add(credential);
      }
    }

    final groups = grouped.values.toList()
      ..sort((a, b) => a.displayUrl.compareTo(b.displayUrl));
    return groups;
  }

  String _groupKey(PortalGroup group) =>
      '${group.kind.name}::${group.normalizedKey}';

  String _credentialKey(TransientCredential credential) {
    if (credential.stalker != null) {
      final stalker = credential.stalker!;
      return 'stalker::${stalker.url}::${stalker.mac}';
    }
    final xtream = credential.xtream!;
    return 'xtream::${xtream.url}::${xtream.username}::${xtream.password}';
  }

  Future<void> _probeAllGroups() async {
    if (_isProbingAll) return;
    setState(() => _isProbingAll = true);
    await _runWithConcurrency<PortalGroup>(
      _groups,
      _maxConcurrentGroupProbes,
      (group) => _probeGroup(group, probeAllCredentials: true),
    );
    if (!mounted) return;
    setState(() => _isProbingAll = false);
  }

  Future<void> _probeGroup(
    PortalGroup group, {
    bool probeAllCredentials = false,
  }) async {
    final key = _groupKey(group);
    _updateGroupState(
      key,
      const GroupProbeState(
        status: GroupProbeStatus.discovering,
        message: 'Discovering portal…',
      ),
    );

    if (group.normalizedUri == null) {
      _updateGroupState(
        key,
        const GroupProbeState(
          status: GroupProbeStatus.error,
          message: 'Invalid portal URL.',
        ),
      );
      return;
    }

    DiscoveryResult discovery;
    try {
      if (group.kind == ProviderKind.stalker) {
        final normalised =
            group.stalkerNormalization ??
            normalizeStalkerPortalInput(group.displayUrl);
        discovery = await const StalkerPortalDiscovery().discoverFromNormalized(
          normalised,
          options: DiscoveryOptions(allowSelfSignedTls: true),
        );
      } else {
        discovery = await const XtreamPortalDiscovery().discoverFromUri(
          group.normalizedUri!,
          options: DiscoveryOptions(allowSelfSignedTls: true),
        );
      }
    } catch (error) {
      _updateGroupState(
        key,
        GroupProbeState(
          status: GroupProbeStatus.offline,
          message: error.toString(),
        ),
      );
      return;
    }

    final needsUa = discovery.hints['needsUserAgent'] == 'true';
    _updateGroupState(
      key,
      GroupProbeState(
        status: GroupProbeStatus.ready,
        lockedBase: discovery.lockedBase,
        needsUserAgent: needsUa,
        hints: discovery.hints,
        message: 'Portal discovered',
      ),
    );

    if (!probeAllCredentials) return;

    await _runWithConcurrency<TransientCredential>(
      group.credentials,
      _maxConcurrentCredentialProbes,
      (credential) => _probeCredential(group, credential, discovery, needsUa),
    );
  }

  Future<void> _probeCredential(
    PortalGroup group,
    TransientCredential credential,
    DiscoveryResult discovery,
    bool needsUserAgent,
  ) async {
    final credentialKey = _credentialKey(credential);
    _updateCredentialState(
      credentialKey,
      const CredentialProbeState(
        status: CredentialProbeStatus.probing,
        message: 'Checking login…',
      ),
    );

    final profile = _buildTransientProfile(
      credential: credential,
      lockedBase: discovery.lockedBase,
      needsUserAgent: needsUserAgent,
      hints: discovery.hints,
    );

    try {
      final coordinator = ref.read(summaryCoordinatorProvider);
      final summary = await coordinator
          .fetch(profile)
          .timeout(const Duration(seconds: 8));

      final summaryError = summary.fields['Error'];
      if (summaryError != null && summaryError.isNotEmpty) {
        _updateCredentialState(
          credentialKey,
          CredentialProbeState(
            status: CredentialProbeStatus.failure,
            message: summaryError,
            summary: summary,
          ),
        );
        return;
      }

      final categoriesCoordinator = ref.read(categoriesCoordinatorProvider);
      final categoryMap = await categoriesCoordinator
          .fetch(profile)
          .timeout(const Duration(seconds: 10));
      final liveCategories =
          categoryMap[ContentBucket.live] ?? const <CategoryEntry>[];
      final preview = liveCategories.take(_maxCategoryPreviewChips).toList();

      _updateCredentialState(
        credentialKey,
        CredentialProbeState(
          status: CredentialProbeStatus.success,
          message: 'Login OK',
          summary: summary,
          liveCategories: preview,
          liveCategoryTotal: liveCategories.length,
        ),
      );
    } catch (error) {
      _updateCredentialState(
        credentialKey,
        CredentialProbeState(
          status: CredentialProbeStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _addSelectedCredentials() async {
    final selected = _selectedCredentials.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    if (selected.isEmpty) {
      _showSnack('Select credentials to add.');
      return;
    }

    var addedCount = 0;
    for (final group in _groups) {
      final groupState = _groupStates[_groupKey(group)];
      final discovery = groupState?.lockedBase;
      for (final credential in group.credentials) {
        final credentialKey = _credentialKey(credential);
        if (!selected.contains(credentialKey)) {
          continue;
        }

        final lockedBase = discovery ?? group.normalizedUri;
        if (lockedBase == null) {
          continue;
        }

        final needsUserAgent = groupState?.needsUserAgent ?? false;
        final hints = groupState?.hints ?? const <String, String>{};
        final profileRecord = await _persistProfile(
          credential: credential,
          lockedBase: lockedBase,
          needsUserAgent: needsUserAgent,
          hints: hints,
        );

        final providerDbId = await ref
            .read(providerSyncServiceProvider)
            .ensureProviderForProfile(profileRecord, createIfMissing: true);
        if (providerDbId != null) {
          final secrets = _buildSecrets(
            credential,
            needsUserAgent: needsUserAgent,
          );
          final resolved = ResolvedProviderProfile(
            record: profileRecord,
            secrets: secrets,
            providerDbId: providerDbId,
          );
          unawaited(
            ref.read(providerImportServiceProvider).runInitialImport(resolved),
          );
          addedCount += 1;
        }
      }
    }

    if (!mounted) return;
    _showSnack('Added $addedCount provider(s).');
    setState(() {
      _selectedCredentials.removeWhere((_, value) => value);
    });
  }

  Future<ProviderProfileRecord> _persistProfile({
    required TransientCredential credential,
    required Uri lockedBase,
    required bool needsUserAgent,
    required Map<String, String> hints,
  }) {
    final repository = ref.read(providerProfileRepositoryProvider);
    final now = DateTime.now().toUtc();

    final configuration = <String, String>{
      if (credential.stalker != null) 'macAddress': credential.stalker!.mac,
      if (needsUserAgent)
        'userAgent': credential.kind == ProviderKind.stalker
            ? _stalkerFallbackUserAgent
            : _xtreamFallbackUserAgent,
    };
    final secrets = _buildSecrets(credential, needsUserAgent: needsUserAgent);

    return repository.saveProfile(
      profileId: ProviderProfileRepository.allocateProfileId(),
      kind: credential.kind,
      lockedBase: lockedBase,
      displayName: _buildDisplayName(credential, lockedBase),
      configuration: configuration,
      hints: hints,
      secrets: secrets,
      needsUserAgent: needsUserAgent,
      allowSelfSignedTls: true,
      followRedirects: true,
      successAt: now,
    );
  }

  Map<String, String> _buildSecrets(
    TransientCredential credential, {
    required bool needsUserAgent,
  }) {
    if (credential.xtream != null) {
      final secrets = <String, String>{
        'username': credential.xtream!.username,
        'password': credential.xtream!.password,
      };
      if (needsUserAgent) {
        secrets['customHeaders'] = jsonEncode({
          'User-Agent': _xtreamFallbackUserAgent,
        });
      }
      return secrets;
    }
    return <String, String>{'mac': credential.stalker!.mac};
  }

  ResolvedProviderProfile _buildTransientProfile({
    required TransientCredential credential,
    required Uri lockedBase,
    required bool needsUserAgent,
    required Map<String, String> hints,
  }) {
    final now = DateTime.now();
    final configuration = <String, String>{
      if (credential.stalker != null) 'macAddress': credential.stalker!.mac,
      if (needsUserAgent)
        'userAgent': credential.kind == ProviderKind.stalker
            ? _stalkerFallbackUserAgent
            : _xtreamFallbackUserAgent,
    };

    final record = ProviderProfileRecord(
      id: 'transient_${_credentialKey(credential)}',
      displayName: _buildDisplayName(credential, lockedBase),
      kind: credential.kind,
      configuration: configuration,
      createdAt: now,
      updatedAt: now,
      followRedirects: true,
      allowSelfSignedTls: true,
      lockedBase: lockedBase,
      needsUserAgent: needsUserAgent,
      hints: hints,
      hasSecrets: true,
    );

    final secrets = _buildSecrets(credential, needsUserAgent: needsUserAgent);

    return ResolvedProviderProfile(record: record, secrets: secrets);
  }

  String _buildDisplayName(TransientCredential credential, Uri lockedBase) {
    final host = lockedBase.host.isNotEmpty
        ? lockedBase.host
        : lockedBase.toString();
    if (credential.kind == ProviderKind.xtream) {
      return 'XTREAM @ $host (${credential.xtream!.username})';
    }
    return 'STALKER @ $host (${credential.stalker!.mac})';
  }

  void _updateGroupState(String key, GroupProbeState state) {
    if (!mounted) return;
    setState(() {
      _groupStates[key] = state;
    });
  }

  void _updateCredentialState(String key, CredentialProbeState state) {
    if (!mounted) return;
    setState(() {
      _credentialStates[key] = state;
    });
  }

  void _toggleSelection(String credentialKey, bool selected) {
    setState(() {
      _selectedCredentials[credentialKey] = selected;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runWithConcurrency<T>(
    List<T> items,
    int concurrency,
    Future<void> Function(T) task,
  ) async {
    if (items.isEmpty) return;
    final queue = List<T>.from(items);
    final workerCount = min(concurrency, queue.length);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final item = queue.removeAt(0);
        await task(item);
      }
    }

    await Future.wait(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCredentials =
        widget.stalkerCredentials.length + widget.xtreamCredentials.length;

    return ProviderScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Found Credentials ($totalCredentials)'),
          actions: [
            IconButton(
              tooltip: 'Probe all portals',
              onPressed: _isProbingAll ? null : _probeAllGroups,
              icon: _isProbingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
            ),
            IconButton(
              tooltip: 'Add selected providers',
              onPressed: _addSelectedCredentials,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        body: totalCredentials == 0
            ? const Center(child: Text('No credentials found in messages.'))
            : Column(
                children: [
                  _buildToolbar(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return _buildGroupTile(group);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToolbar() {
    final totalGroups = _groups.length;
    final selectedCount = _selectedCredentials.values
        .where((value) => value)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$totalGroups portals • $selectedCount selected',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() => _showOnlySuccess = !_showOnlySuccess);
            },
            icon: Icon(
              _showOnlySuccess ? Icons.check_circle : Icons.filter_alt,
              size: 18,
            ),
            label: Text(_showOnlySuccess ? 'Showing OK' : 'Show OK only'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(PortalGroup group) {
    final groupState =
        _groupStates[_groupKey(group)] ??
        const GroupProbeState(status: GroupProbeStatus.idle);

    final subtitle = _groupStatusLabel(groupState);
    final statusIcon = _groupStatusIcon(groupState.status);
    final statusColor = _groupStatusColor(groupState.status);

    final credentialWidgets = group.credentials
        .map((credential) => _buildCredentialCard(group, credential))
        .whereType<Widget>()
        .toList();

    if (credentialWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(
          group.displayUrl,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        leading: Icon(statusIcon, color: statusColor),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            _buildKindChip(group.kind),
            Text('${group.credentials.length}'),
            IconButton(
              tooltip: 'Probe this portal',
              onPressed: groupState.isBusy
                  ? null
                  : () => _probeGroup(group, probeAllCredentials: true),
              icon: groupState.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_outline),
            ),
          ],
        ),
        children: credentialWidgets,
      ),
    );
  }

  Widget? _buildCredentialCard(
    PortalGroup group,
    TransientCredential credential,
  ) {
    final credentialKey = _credentialKey(credential);
    final state =
        _credentialStates[credentialKey] ??
        const CredentialProbeState(status: CredentialProbeStatus.idle);
    if (_showOnlySuccess && state.status != CredentialProbeStatus.success) {
      return null;
    }
    final isSelected = _selectedCredentials[credentialKey] ?? false;
    final kindLabel = credential.kind == ProviderKind.xtream
        ? 'User: ${credential.xtream!.username}\nPass: ${credential.xtream!.password}'
        : 'MAC: ${credential.stalker!.mac}';

    final statusColor = _credentialStatusColor(state.status, context);
    final statusText = _credentialStatusLabel(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        elevation: 0,
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(40),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) =>
                        _toggleSelection(credentialKey, value ?? false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.url,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kindLabel,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildStatusChip(statusText, statusColor),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Probe this login',
                            onPressed:
                                state.status == CredentialProbeStatus.probing
                                ? null
                                : () {
                                    final groupState =
                                        _groupStates[_groupKey(group)];
                                    if (groupState == null ||
                                        groupState.lockedBase == null) {
                                      unawaited(
                                        _probeGroup(
                                          group,
                                          probeAllCredentials: false,
                                        ).then((_) {
                                          final refreshed =
                                              _groupStates[_groupKey(group)];
                                          if (refreshed?.lockedBase != null) {
                                            unawaited(
                                              _probeCredential(
                                                group,
                                                credential,
                                                DiscoveryResult(
                                                  kind: group.kind,
                                                  lockedBase:
                                                      refreshed!.lockedBase!,
                                                  hints:
                                                      refreshed.hints ??
                                                      const <String, String>{},
                                                ),
                                                refreshed.needsUserAgent ??
                                                    false,
                                              ),
                                            );
                                          }
                                        }),
                                      );
                                      return;
                                    }
                                    unawaited(
                                      _probeCredential(
                                        group,
                                        credential,
                                        DiscoveryResult(
                                          kind: group.kind,
                                          lockedBase: groupState.lockedBase!,
                                          hints:
                                              groupState.hints ??
                                              const <String, String>{},
                                        ),
                                        groupState.needsUserAgent ?? false,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow),
                          ),
                          IconButton(
                            tooltip: 'Portal info',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return TransientPortalInfoDialog(
                                    credential: credential,
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.info_outline),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          await _addSingleCredential(group, credential);
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
              if (state.summary != null) ...[
                const SizedBox(height: 8),
                _buildSummaryChips(state.summary!),
              ],
              if (state.liveCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Live categories (${state.liveCategoryTotal ?? state.liveCategories.length})',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                _buildCategoryChips(state),
              ],
              if (state.status == CredentialProbeStatus.failure &&
                  state.message?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  state.message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChips(SummaryData summary) {
    final chips = <Widget>[];
    if (summary.pingLatency != null) {
      chips.add(_buildChip('Ping ${summary.pingLatency!.inMilliseconds}ms'));
    }
    summary.counts.forEach((key, value) {
      chips.add(_buildChip('$key $value'));
    });

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _buildCategoryChips(CredentialProbeState state) {
    final chips = <Widget>[];
    for (final category in state.liveCategories) {
      final label = category.count != null
          ? '${category.name} (${category.count})'
          : category.name;
      chips.add(_buildChip(label));
    }
    if (state.liveCategoryTotal != null &&
        state.liveCategoryTotal! > state.liveCategories.length) {
      chips.add(
        _buildChip(
          '+${state.liveCategoryTotal! - state.liveCategories.length} more',
        ),
      );
    }
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildKindChip(ProviderKind kind) {
    final label = switch (kind) {
      ProviderKind.stalker => 'STALKER',
      ProviderKind.xtream => 'XTREAM',
      ProviderKind.m3u => 'M3U',
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(String text, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color ?? Colors.grey),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Future<void> _addSingleCredential(
    PortalGroup group,
    TransientCredential credential,
  ) async {
    final groupState = _groupStates[_groupKey(group)];
    final lockedBase = groupState?.lockedBase ?? group.normalizedUri;
    if (lockedBase == null) {
      _showSnack('Portal URL is invalid.');
      return;
    }
    final needsUserAgent = groupState?.needsUserAgent ?? false;
    final hints = groupState?.hints ?? const <String, String>{};

    final profileRecord = await _persistProfile(
      credential: credential,
      lockedBase: lockedBase,
      needsUserAgent: needsUserAgent,
      hints: hints,
    );
    final providerDbId = await ref
        .read(providerSyncServiceProvider)
        .ensureProviderForProfile(profileRecord, createIfMissing: true);
    if (providerDbId != null) {
      final secrets = _buildSecrets(credential, needsUserAgent: needsUserAgent);
      final resolved = ResolvedProviderProfile(
        record: profileRecord,
        secrets: secrets,
        providerDbId: providerDbId,
      );
      unawaited(
        ref.read(providerImportServiceProvider).runInitialImport(resolved),
      );
      if (!mounted) return;
      _showSnack('Provider added. Import started.');
    }
  }

  String _groupStatusLabel(GroupProbeState state) {
    switch (state.status) {
      case GroupProbeStatus.idle:
        return 'Not checked';
      case GroupProbeStatus.discovering:
        return 'Checking portal…';
      case GroupProbeStatus.ready:
        return 'Portal OK';
      case GroupProbeStatus.offline:
        return 'Offline';
      case GroupProbeStatus.error:
        return state.message ?? 'Error';
    }
  }

  IconData _groupStatusIcon(GroupProbeStatus status) {
    switch (status) {
      case GroupProbeStatus.ready:
        return Icons.check_circle;
      case GroupProbeStatus.offline:
      case GroupProbeStatus.error:
        return Icons.error_outline;
      case GroupProbeStatus.discovering:
        return Icons.wifi_tethering;
      case GroupProbeStatus.idle:
        return Icons.pause_circle_outline;
    }
  }

  Color? _groupStatusColor(GroupProbeStatus status) {
    switch (status) {
      case GroupProbeStatus.ready:
        return Colors.green;
      case GroupProbeStatus.offline:
      case GroupProbeStatus.error:
        return Colors.red;
      case GroupProbeStatus.discovering:
        return Colors.orange;
      case GroupProbeStatus.idle:
        return Colors.grey;
    }
  }

  String _credentialStatusLabel(CredentialProbeState state) {
    switch (state.status) {
      case CredentialProbeStatus.idle:
        return 'Not checked';
      case CredentialProbeStatus.probing:
        return 'Checking';
      case CredentialProbeStatus.success:
        return 'OK';
      case CredentialProbeStatus.failure:
        return 'Failed';
    }
  }

  Color? _credentialStatusColor(
    CredentialProbeStatus status,
    BuildContext context,
  ) {
    switch (status) {
      case CredentialProbeStatus.success:
        return Colors.green;
      case CredentialProbeStatus.failure:
        return Theme.of(context).colorScheme.error;
      case CredentialProbeStatus.probing:
        return Colors.orange;
      case CredentialProbeStatus.idle:
        return Colors.grey;
    }
  }
}

class PortalGroup {
  PortalGroup({
    required this.kind,
    required this.normalizedKey,
    required this.displayUrl,
    required this.normalizedUri,
    required this.credentials,
    this.stalkerNormalization,
  });

  final ProviderKind kind;
  final String normalizedKey;
  final String displayUrl;
  final Uri? normalizedUri;
  final StalkerPortalNormalizationResult? stalkerNormalization;
  final List<TransientCredential> credentials;
}

enum GroupProbeStatus { idle, discovering, ready, offline, error }

class GroupProbeState {
  const GroupProbeState({
    required this.status,
    this.message,
    this.lockedBase,
    this.needsUserAgent,
    this.hints,
  });

  final GroupProbeStatus status;
  final String? message;
  final Uri? lockedBase;
  final bool? needsUserAgent;
  final Map<String, String>? hints;

  bool get isBusy => status == GroupProbeStatus.discovering;
}

enum CredentialProbeStatus { idle, probing, success, failure }

class CredentialProbeState {
  const CredentialProbeState({
    required this.status,
    this.message,
    this.summary,
    this.liveCategories = const [],
    this.liveCategoryTotal,
  });

  final CredentialProbeStatus status;
  final String? message;
  final SummaryData? summary;
  final List<CategoryEntry> liveCategories;
  final int? liveCategoryTotal;
}
