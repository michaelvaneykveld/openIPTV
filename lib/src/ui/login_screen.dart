import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/providers/login_flow_controller.dart';
import 'package:openiptv/src/providers/protocol_auth_providers.dart';
import 'package:openiptv/src/providers/login_draft_repository.dart';
import 'package:openiptv/src/providers/provider_profiles_provider.dart';
import 'package:openiptv/src/providers/provider_sync_service.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_portal_discovery.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_authenticator.dart';
import 'package:openiptv/src/protocols/stalker/stalker_http_client.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_authenticator.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_discovery.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_discovery.dart';
import 'package:openiptv/src/utils/input_classifier.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_normalizer.dart';
import 'package:openiptv/src/utils/url_normalization.dart';
import 'package:openiptv/src/utils/url_redaction.dart';
import 'package:openiptv/src/protocols/xtream/xtream_http_client.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';
import 'package:openiptv/src/protocols/xtream/xtream_authenticator.dart';
import 'package:openiptv/src/utils/header_parser.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_client.dart';
import 'package:openiptv/src/player/summary_fetchers.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';
import 'package:openiptv/src/ui/discovery_cache_manager.dart';
import 'package:openiptv/src/ui/player/player_shell.dart' as player;

enum _PasteTarget { stalkerPortal, xtreamBaseUrl, m3uUrl }

enum _ClassificationSource { paste, validation }

/// A [TextInputFormatter] that coerces user input into an uppercase MAC
/// address with colon separators (e.g. 0:1A:79:12:34:56).
class MacAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^0-9A-F]'),
      '',
    );
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length && i < 12; i++) {
      if (i > 0 && i.isEven) {
        buffer.write(':');
      }
      buffer.write(raw[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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
    final providerRecordsAsync = ref.watch(providerRecordsStreamProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: savedLoginsAsync.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return const _EmptySavedLogins();
            }
            final providerRecords = providerRecordsAsync.maybeWhen(
              data: (records) => records,
              orElse: () => const <ProviderRecord>[],
            );
            final providerError = providerRecordsAsync.maybeWhen(
              error: (error, _) => error.toString(),
              orElse: () => null,
            );

            final extraRow = providerError == null ? 0 : 1;
            return ListView.separated(
              itemCount: profiles.length + extraRow,
              itemBuilder: (context, index) {
                if (providerError != null && index == 0) {
                  return _ProviderStatusBanner(message: providerError);
                }
                final profileIndex =
                    providerError != null ? index - 1 : index;
                final record = profiles[profileIndex];
                ProviderRecord? dbRecord;
                for (final candidate in providerRecords) {
                  if (candidate.legacyProfileId == record.id) {
                    dbRecord = candidate;
                    break;
                  }
                }
                return _SavedLoginTile(
                  record: record,
                  dbRecord: dbRecord,
                  onConnect: () => onConnect(record),
                  onEdit: () => onEdit(record),
                  onDelete: () => onRequestDelete(record),
                );
              },
              separatorBuilder: (context, index) {
                final isAfterBanner =
                    providerError != null && index == 0;
                return isAfterBanner
                    ? const SizedBox(height: 8)
                    : const Divider(height: 1);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              _SavedLoginsError(error: error, stackTrace: stackTrace),
        ),
      ),
    );
  }
}

class _SavedLoginsError extends StatelessWidget {
  const _SavedLoginsError({required this.error, required this.stackTrace});

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
        Text(error.toString(), textAlign: TextAlign.center),
      ],
    );
  }
}

class _ProviderStatusBanner extends StatelessWidget {
  const _ProviderStatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.errorContainer;
    final fg = theme.colorScheme.onErrorContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Provider sync unavailable: $message',
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedLogins extends StatelessWidget {
  const _EmptySavedLogins();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'No saved logins',
            child: const Icon(Icons.inventory_2_outlined, size: 64),
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

class _SavedLoginTile extends ConsumerWidget {
  const _SavedLoginTile({
    required this.record,
    required this.dbRecord,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  final ProviderProfileRecord record;
  final ProviderRecord? dbRecord;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = record.lockedBase.host.isEmpty
        ? record.lockedBase.toString()
        : record.lockedBase.host;
    final subtitle = _buildSubtitle(
      context,
      host,
      dbRecord?.lastSyncAt ?? record.lastOkAt,
    );
    final iconData = _iconFor(record.kind);
    final semanticLabel = _semanticLabelFor(record.kind);

    SummaryData? summaryData;
    var summaryLoading = false;
    if (dbRecord != null) {
      final summaryAsync = ref.watch(
        dbSummaryProvider(
          DbSummaryArgs(dbRecord!.id, record.kind),
        ),
      );
      summaryLoading = summaryAsync.isLoading;
      summaryData = summaryAsync.when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );
    }

    final summaryWidget = _buildSummaryWidget(
      context: context,
      summaryData: summaryData,
      isLoading: summaryLoading,
    );

    return Semantics(
      button: true,
      label: 'Connect ${record.displayName}',
      child: ListTile(
        onTap: onConnect,
        leading: Semantics(label: semanticLabel, child: Icon(iconData)),
        title: Text(record.displayName),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (summaryWidget != null) ...[
              const SizedBox(height: 4),
              summaryWidget,
            ],
          ],
        ),
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _SavedLoginMenuAction.connect,
                  child: Text('Connect'),
                ),
                PopupMenuItem(
                  value: _SavedLoginMenuAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: _SavedLoginMenuAction.delete,
                  child: Text('Delete'),
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

    String _buildSubtitle(
    BuildContext context,
    String host,
    DateTime? lastSync,
  ) {
    final localization = MaterialLocalizations.of(context);
    final formattedDate = lastSync != null
        ? '${localization.formatShortDate(lastSync.toLocal())} '
              '${localization.formatTimeOfDay(TimeOfDay.fromDateTime(lastSync.toLocal()))}'
        : 'Never';

    return '$host | Last sync: $formattedDate';
  }

  Widget? _buildSummaryWidget({
    required BuildContext context,
    required SummaryData? summaryData,
    required bool isLoading,
  }) {
    if (dbRecord == null) {
      return null;
    }
    final theme = Theme.of(context);
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading cached counts…',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }
    final counts = summaryData?.counts ?? const {};
    if (counts.isEmpty) {
      return Text(
        'Cache not ready yet',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final summaryText = counts.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' | ');
    return Text(
      summaryText,
      style: theme.textTheme.bodySmall,
    );
  }IconData _iconFor(ProviderKind kind) => switch (kind) {
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

/// Login experience entry point that wires UI state to Riverpod controllers
/// while presenting provider-specific forms according to the design brief.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final InputClassifier _inputClassifier = const InputClassifier();
  static const _m3uSensitiveQueryKeys = {'username', 'password', 'token'};

  /// Form keys are retained for future validation extensions even though
  /// validation currently lives inside the Riverpod controller.
  final GlobalKey<FormState> _stalkerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _xtreamFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _m3uFormKey = GlobalKey<FormState>();

  /// Text controllers mirror the editable fields; updates are synchronised
  /// with the Riverpod state via [_syncControllerText].
  final TextEditingController _portalUrlController = TextEditingController();
  final TextEditingController _macAddressController = TextEditingController(
    text: '00:1A:79:',
  );
  final TextEditingController _xtreamUrlController = TextEditingController();
  final TextEditingController _xtreamUsernameController =
      TextEditingController();
  final TextEditingController _xtreamPasswordController =
      TextEditingController();
  final TextEditingController _m3uInputController = TextEditingController();
  final TextEditingController _m3uUsernameController = TextEditingController();
  final TextEditingController _m3uPasswordController = TextEditingController();
  final TextEditingController _stalkerUserAgentController =
      TextEditingController();
  final TextEditingController _stalkerHeadersController =
      TextEditingController();
  final TextEditingController _xtreamUserAgentController =
      TextEditingController();
  final TextEditingController _xtreamHeadersController =
      TextEditingController();
  final TextEditingController _m3uUserAgentController = TextEditingController();
  final TextEditingController _m3uHeadersController = TextEditingController();

  // Lightweight protocol clients used for follow-up probes during testing.
  late final XtreamHttpClient _xtreamHttpClient = XtreamHttpClient();
  late final StalkerHttpClient _stalkerHttpClient = StalkerHttpClient();
  final StalkerPortalDiscovery _stalkerDiscovery =
      const StalkerPortalDiscovery();
  final XtreamPortalDiscovery _xtreamDiscovery = const XtreamPortalDiscovery();
  final M3uPortalDiscovery _m3uDiscovery = const M3uPortalDiscovery();
  final M3uXmlClient _m3uClient = M3uXmlClient();
  ProviderSubscription<LoginFlowState>? _flowSubscription;
  late final DiscoveryCacheManager _discoveryCacheManager;
  static const String _discoveryCacheStorageKey = 'discovery_cache_v1';
  static const Duration _discoveryCacheTtl = Duration(hours: 24);
  static const Duration _discoveryCacheRefreshLeeway = Duration(hours: 2);

  void _debugPrintSafe(String message) {
    debugPrint(redactSensitiveText(message));
  }

  void _logError(String prefix, Object error, [StackTrace? stackTrace]) {
    final base = redactSensitiveText(prefix);
    final details = redactSensitiveText(error.toString());
    if (stackTrace != null) {
      debugPrint('$base: $details\n$stackTrace');
    } else {
      debugPrint('$base: $details');
    }
  }

  void _logDiscoveryCacheError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    _logError(message, error, stackTrace);
  }

  void _scheduleDiscoveryRefresh({
    required String label,
    required String cacheKey,
    required Future<DiscoveryResult> Function() operation,
  }) {
    unawaited(() async {
      try {
        final refreshed = await operation();
        await _discoveryCacheManager.store(
          cacheKey: cacheKey,
          result: refreshed,
        );
      } catch (error, stackTrace) {
        _logError(label, error, stackTrace);
      }
    }());
  }

  void _logDioError(String prefix, DioException error) {
    final base = redactSensitiveText(prefix);
    debugPrint('$base: ${describeDioError(error)}');
  }

  @override
  void initState() {
    super.initState();
    _discoveryCacheManager = DiscoveryCacheManager(
      storageKey: _discoveryCacheStorageKey,
      ttl: _discoveryCacheTtl,
      errorLogger: _logDiscoveryCacheError,
    );
    unawaited(_discoveryCacheManager.ensureLoaded());

    // Hydrate the controllers with the persisted Riverpod state so that the
    // UI reflects previously stored credentials immediately after launch.
    final flow = ref.read(loginFlowControllerProvider);
    _portalUrlController.text = flow.stalker.portalUrl.value;
    _macAddressController.text = flow.stalker.macAddress.value;
    _xtreamUrlController.text = flow.xtream.serverUrl.value;
    _xtreamUsernameController.text = flow.xtream.username.value;
    _xtreamPasswordController.text = flow.xtream.password.value;
    _m3uInputController.text = flow.m3u.inputMode == M3uInputMode.url
        ? flow.m3u.playlistUrl.value
        : flow.m3u.playlistFilePath.value;
    _m3uUsernameController.text = flow.m3u.username.value;
    _m3uPasswordController.text = flow.m3u.password.value;
    _stalkerUserAgentController.text = flow.stalker.userAgent.value;
    _stalkerHeadersController.text = flow.stalker.customHeaders.value;
    _xtreamUserAgentController.text = flow.xtream.userAgent.value;
    _xtreamHeadersController.text = flow.xtream.customHeaders.value;
    _m3uUserAgentController.text = flow.m3u.userAgent.value;
    _m3uHeadersController.text = flow.m3u.customHeaders.value;

    _flowSubscription = ref.listenManual<LoginFlowState>(
      loginFlowControllerProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        _syncControllerText(
          previous?.stalker.portalUrl.value,
          next.stalker.portalUrl.value,
          _portalUrlController,
        );
        _syncControllerText(
          previous?.stalker.macAddress.value,
          next.stalker.macAddress.value,
          _macAddressController,
        );
        _syncControllerText(
          previous?.stalker.userAgent.value,
          next.stalker.userAgent.value,
          _stalkerUserAgentController,
        );
        _syncControllerText(
          previous?.stalker.customHeaders.value,
          next.stalker.customHeaders.value,
          _stalkerHeadersController,
        );
        _syncControllerText(
          previous?.xtream.serverUrl.value,
          next.xtream.serverUrl.value,
          _xtreamUrlController,
        );
        _syncControllerText(
          previous?.xtream.username.value,
          next.xtream.username.value,
          _xtreamUsernameController,
        );
        _syncControllerText(
          previous?.xtream.password.value,
          next.xtream.password.value,
          _xtreamPasswordController,
        );
        _syncControllerText(
          previous?.xtream.userAgent.value,
          next.xtream.userAgent.value,
          _xtreamUserAgentController,
        );
        _syncControllerText(
          previous?.xtream.customHeaders.value,
          next.xtream.customHeaders.value,
          _xtreamHeadersController,
        );
        final previousM3uInput = previous == null
            ? null
            : previous.m3u.inputMode == M3uInputMode.url
            ? previous.m3u.playlistUrl.value
            : previous.m3u.playlistFilePath.value;
        final currentM3uInput = next.m3u.inputMode == M3uInputMode.url
            ? next.m3u.playlistUrl.value
            : next.m3u.playlistFilePath.value;
        _syncControllerText(
          previousM3uInput,
          currentM3uInput,
          _m3uInputController,
        );
        _syncControllerText(
          previous?.m3u.username.value,
          next.m3u.username.value,
          _m3uUsernameController,
        );
        _syncControllerText(
          previous?.m3u.password.value,
          next.m3u.password.value,
          _m3uPasswordController,
        );
        _syncControllerText(
          previous?.m3u.userAgent.value,
          next.m3u.userAgent.value,
          _m3uUserAgentController,
        );
        _syncControllerText(
          previous?.m3u.customHeaders.value,
          next.m3u.customHeaders.value,
          _m3uHeadersController,
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _flowSubscription?.close();
    // Dispose controllers to prevent memory leaks.
    _portalUrlController.dispose();
    _macAddressController.dispose();
    _xtreamUrlController.dispose();
    _xtreamUsernameController.dispose();
    _xtreamPasswordController.dispose();
    _m3uInputController.dispose();
    _m3uUsernameController.dispose();
    _m3uPasswordController.dispose();
    _stalkerUserAgentController.dispose();
    _stalkerHeadersController.dispose();
    _xtreamUserAgentController.dispose();
    _xtreamHeadersController.dispose();
    _m3uUserAgentController.dispose();
    _m3uHeadersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observe the latest flow state so the UI stays declarative.
    final flowState = ref.watch(loginFlowControllerProvider);
    final isBusy = flowState.testProgress.inProgress;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            final addProviderColumn = Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProviderSelectors(flowState, isBusy),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: SingleChildScrollView(
                        key: ValueKey(flowState.providerType),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: _buildActiveContent(context, flowState, isBusy),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final savedLoginsPanel = SizedBox(
              width: isWide ? constraints.maxWidth * 0.32 : double.infinity,
              child: _SavedLoginsPanel(
                onRequestDelete: _handleDeleteProfile,
                onConnect: (record) {
                  _connectSavedProfile(record);
                },
                onEdit: (record) =>
                    _showSnack('Edit flow for ${record.displayName}'),
              ),
            );

            final header = _buildHeader(context, flowState);
            final banner = flowState.bannerMessage != null
                ? _buildBanner(context, flowState.bannerMessage!)
                : null;

            if (isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  if (banner != null) banner,
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        addProviderColumn,
                        const VerticalDivider(width: 1),
                        savedLoginsPanel,
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                if (banner != null) banner,
                _buildProviderSelectors(flowState, isBusy),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: SingleChildScrollView(
                      key: ValueKey(flowState.providerType),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: _buildActiveContent(context, flowState, isBusy),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: savedLoginsPanel,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Constructs the page header with title and contextual action buttons.
  Widget _buildHeader(BuildContext context, LoginFlowState flowState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Add IPTV provider',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Help',
            onPressed: () => _showHelpSheet(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
    );
  }

  /// Draws the primary provider segmented control and, when required, the
  /// secondary M3U input-mode toggle.
  Widget _buildProviderSelectors(LoginFlowState flowState, bool isBusy) {
    final controller = ref.read(loginFlowControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<LoginProviderType>(
            segments: const [
              ButtonSegment(
                value: LoginProviderType.stalker,
                icon: Icon(Icons.router),
                label: Text('Stalker'),
              ),
              ButtonSegment(
                value: LoginProviderType.xtream,
                icon: Icon(Icons.stream),
                label: Text('Xtream'),
              ),
              ButtonSegment(
                value: LoginProviderType.m3u,
                icon: Icon(Icons.playlist_add),
                label: Text('M3U'),
              ),
            ],
            selected: {flowState.providerType},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty && !isBusy) {
                controller.selectProvider(selection.first);
              }
            },
          ),
          if (flowState.providerType == LoginProviderType.m3u) ...[
            const SizedBox(height: 12),
            SegmentedButton<M3uInputMode>(
              segments: const [
                ButtonSegment(
                  value: M3uInputMode.url,
                  icon: Icon(Icons.link),
                  label: Text('URL'),
                ),
                ButtonSegment(
                  value: M3uInputMode.file,
                  icon: Icon(Icons.insert_drive_file),
                  label: Text('File'),
                ),
              ],
              selected: {flowState.m3u.inputMode},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty && !isBusy) {
                  controller.selectM3uInputMode(selection.first);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Combines the protocol form with progress and summary panels.
  Widget _buildActiveContent(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    final sections = <Widget>[_buildActiveForm(context, flowState, isBusy)];
    final feedback = _buildTestFeedback(context, flowState);
    if (feedback != null) {
      sections.add(const SizedBox(height: 24));
      sections.add(feedback);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  /// Returns the currently active provider form, keeping layouts consistent.
  Widget _buildActiveForm(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    switch (flowState.providerType) {
      case LoginProviderType.stalker:
        return _buildStalkerForm(context, flowState, isBusy);
      case LoginProviderType.xtream:
        return _buildXtreamForm(context, flowState, isBusy);
      case LoginProviderType.m3u:
        return _buildM3uForm(context, flowState, isBusy);
    }
  }

  /// Builds the Stalker/Ministra form body.
  Widget _buildStalkerForm(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    final controller = ref.read(loginFlowControllerProvider.notifier);
    return Form(
      key: _stalkerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Provide the portal URL and MAC address registered with '
            'your provider.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _portalUrlController,
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: 'Portal URL',
              hintText: 'http://portal.example.com',
              errorText: flowState.stalker.portalUrl.error,
              suffixIcon: IconButton(
                tooltip: 'Paste from clipboard',
                icon: const Icon(Icons.paste),
                onPressed: isBusy
                    ? null
                    : () => _handlePaste(
                        context,
                        target: _PasteTarget.stalkerPortal,
                      ),
              ),
            ),
            onChanged: controller.updateStalkerPortalUrl,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _macAddressController,
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: 'MAC Address',
              hintText: '00:1A:79:12:34:56',
              errorText: flowState.stalker.macAddress.error,
            ),
            inputFormatters: [MacAddressInputFormatter()],
            onChanged: controller.updateStalkerMacAddress,
          ),
          const SizedBox(height: 16),
          _buildStalkerAdvancedSection(flowState, isBusy),
          const SizedBox(height: 24),
          _buildFormActions(
            isBusy: isBusy,
            saveForLater: flowState.saveForLater,
            onSaveToggle: controller.setSaveForLater,
            onPrimary: _handleStalkerLogin,
            saveToggleKey: const ValueKey('stalkerSaveToggle'),
          ),
        ],
      ),
    );
  }

  /// Builds the Xtream Codes form body.
  Widget _buildXtreamForm(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    final controller = ref.read(loginFlowControllerProvider.notifier);
    return Form(
      key: _xtreamFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter the Xtream base URL, username, and password.'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _xtreamUrlController,
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: 'Base URL',
              hintText: 'http://example.com:8080',
              errorText: flowState.xtream.serverUrl.error,
              suffixIcon: IconButton(
                tooltip: 'Paste from clipboard',
                icon: const Icon(Icons.paste),
                onPressed: isBusy
                    ? null
                    : () => _handlePaste(
                        context,
                        target: _PasteTarget.xtreamBaseUrl,
                      ),
              ),
            ),
            onChanged: controller.updateXtreamServerUrl,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _xtreamUsernameController,
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: flowState.xtream.username.error,
            ),
            onChanged: controller.updateXtreamUsername,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _xtreamPasswordController,
            enabled: !isBusy,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: flowState.xtream.password.error,
            ),
            obscureText: true,
            onChanged: controller.updateXtreamPassword,
          ),
          const SizedBox(height: 16),
          _buildXtreamAdvancedSection(flowState, isBusy),
          const SizedBox(height: 24),
          _buildFormActions(
            isBusy: isBusy,
            saveForLater: flowState.saveForLater,
            onSaveToggle: controller.setSaveForLater,
            onPrimary: _handleXtreamLogin,
            saveToggleKey: const ValueKey('xtreamSaveToggle'),
          ),
        ],
      ),
    );
  }

  /// Builds the M3U/XMLTV form body, including optional credentials.
  Widget _buildM3uForm(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    final controller = ref.read(loginFlowControllerProvider.notifier);
    final isUrlMode = flowState.m3u.inputMode == M3uInputMode.url;
    return Form(
      key: _m3uFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add an M3U playlist from a URL or a local file path.'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _m3uInputController,
            enabled: isUrlMode ? !isBusy : true,
            readOnly: !isUrlMode,
            decoration: InputDecoration(
              labelText: isUrlMode ? 'M3U URL' : 'M3U file path',
              hintText: isUrlMode
                  ? 'https://provider.example.com/playlist.m3u'
                  : 'Select a local playlist file',
              errorText: isUrlMode
                  ? flowState.m3u.playlistUrl.error
                  : flowState.m3u.playlistFilePath.error,
              suffixIcon: isUrlMode
                  ? IconButton(
                      tooltip: 'Paste from clipboard',
                      icon: const Icon(Icons.paste),
                      onPressed: isBusy
                          ? null
                          : () => _handlePaste(
                              context,
                              target: _PasteTarget.m3uUrl,
                            ),
                    )
                  : IconButton(
                      tooltip: 'Browse files',
                      icon: const Icon(Icons.folder_open),
                      onPressed: isBusy ? null : _pickM3uPlaylistFile,
                    ),
            ),
            onTap: !isUrlMode && !isBusy ? _pickM3uPlaylistFile : null,
            onChanged: isUrlMode ? controller.updateM3uPlaylistUrl : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _m3uUsernameController,
            enabled: !isBusy,
            decoration: const InputDecoration(labelText: 'Username (optional)'),
            onChanged: controller.updateM3uUsername,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _m3uPasswordController,
            enabled: !isBusy,
            decoration: const InputDecoration(labelText: 'Password (optional)'),
            obscureText: true,
            onChanged: controller.updateM3uPassword,
          ),
          const SizedBox(height: 16),
          _buildM3uAdvancedSection(flowState, isBusy, isUrlMode),
          const SizedBox(height: 24),
          _buildFormActions(
            isBusy: isBusy,
            saveForLater: flowState.saveForLater,
            onSaveToggle: controller.setSaveForLater,
            onPrimary: _handleM3uLogin,
            saveToggleKey: const ValueKey('m3uSaveToggle'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdvancedCommonFields({
    required TextEditingController userAgentController,
    required ValueChanged<String> onUserAgentChanged,
    required String userAgentHelperText,
    required TextEditingController headersController,
    required ValueChanged<String> onHeadersChanged,
    required String headersHelperText,
    String? headersErrorText,
    required bool allowSelfSigned,
    required ValueChanged<bool> onToggleSelfSigned,
    required bool isBusy,
    required Key tlsSwitchKey,
    Widget? additionalToggle,
    bool tlsToggleEnabled = true,
  }) {
    final widgets = <Widget>[
      TextFormField(
        controller: userAgentController,
        enabled: !isBusy,
        decoration: InputDecoration(
          labelText: 'User-Agent override',
          helperText: userAgentHelperText,
        ),
        onChanged: onUserAgentChanged,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: headersController,
        enabled: !isBusy,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Custom headers',
          helperText: headersHelperText,
          errorText: headersErrorText,
        ),
        onChanged: onHeadersChanged,
      ),
    ];

    if (additionalToggle != null) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(additionalToggle);
    }

    widgets.add(const SizedBox(height: 12));
    widgets.add(
      SwitchListTile(
        key: tlsSwitchKey,
        contentPadding: EdgeInsets.zero,
        title: const Text('Allow self-signed TLS'),
        subtitle: const Text(
          'Accept certificates that are not trusted by the system CA store.',
        ),
        value: allowSelfSigned,
        onChanged: !isBusy && tlsToggleEnabled ? onToggleSelfSigned : null,
      ),
    );

    return widgets;
  }

  /// Builds the advanced settings panel for Stalker portals.
  Widget _buildStalkerAdvancedSection(LoginFlowState flowState, bool isBusy) {
    final controller = ref.read(loginFlowControllerProvider.notifier);
    final children = _buildAdvancedCommonFields(
      userAgentController: _stalkerUserAgentController,
      onUserAgentChanged: controller.updateStalkerUserAgent,
      userAgentHelperText: 'Leave blank to use the default Infomir agent.',
      headersController: _stalkerHeadersController,
      onHeadersChanged: controller.updateStalkerCustomHeaders,
      headersHelperText: 'One header per line, e.g. X-Api-Key: secret',
      headersErrorText: flowState.stalker.customHeaders.error,
      allowSelfSigned: flowState.stalker.allowSelfSignedTls,
      onToggleSelfSigned: controller.toggleStalkerTlsOverride,
      isBusy: isBusy,
      tlsSwitchKey: const ValueKey('stalkerSelfSignedSwitch'),
    );
    return ExpansionTile(
      key: const ValueKey('stalkerAdvancedTile'),
      title: const Text('Advanced options'),
      initiallyExpanded: flowState.stalker.advancedExpanded,
      onExpansionChanged: controller.toggleStalkerAdvanced,
      childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      children: children,
    );
  }

  /// Builds the advanced settings panel for Xtream portals.
  Widget _buildXtreamAdvancedSection(LoginFlowState flowState, bool isBusy) {
    final controller = ref.read(loginFlowControllerProvider.notifier);
    final children = _buildAdvancedCommonFields(
      userAgentController: _xtreamUserAgentController,
      onUserAgentChanged: controller.updateXtreamUserAgent,
      userAgentHelperText: 'Leave blank to use the default Xtream agent.',
      headersController: _xtreamHeadersController,
      onHeadersChanged: controller.updateXtreamCustomHeaders,
      headersHelperText: 'One header per line, e.g. X-Device: Flutter',
      headersErrorText: flowState.xtream.customHeaders.error,
      allowSelfSigned: flowState.xtream.allowSelfSignedTls,
      onToggleSelfSigned: controller.toggleXtreamTlsOverride,
      isBusy: isBusy,
      tlsSwitchKey: const ValueKey('xtreamSelfSignedSwitch'),
    );
    return ExpansionTile(
      key: const ValueKey('xtreamAdvancedTile'),
      title: const Text('Advanced options'),
      initiallyExpanded: flowState.xtream.advancedExpanded,
      onExpansionChanged: controller.toggleXtreamAdvanced,
      childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      children: children,
    );
  }

  /// Builds the advanced settings panel for M3U/XMLTV providers.
  Widget _buildM3uAdvancedSection(
    LoginFlowState flowState,
    bool isBusy,
    bool isUrlMode,
  ) {
    final controller = ref.read(loginFlowControllerProvider.notifier);
    final followRedirectToggle = SwitchListTile(
      key: const ValueKey('m3uFollowRedirectSwitch'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Follow redirects automatically'),
      subtitle: const Text('Disable when your provider expects strict URLs.'),
      value: flowState.m3u.followRedirects,
      onChanged: !isBusy && isUrlMode
          ? controller.toggleM3uFollowRedirects
          : null,
    );

    final children = _buildAdvancedCommonFields(
      userAgentController: _m3uUserAgentController,
      onUserAgentChanged: controller.updateM3uUserAgent,
      userAgentHelperText: 'Leave blank to use the default playlist agent.',
      headersController: _m3uHeadersController,
      onHeadersChanged: controller.updateM3uCustomHeaders,
      headersHelperText:
          'One header per line, e.g. Authorization: Bearer token',
      headersErrorText: flowState.m3u.customHeaders.error,
      allowSelfSigned: flowState.m3u.allowSelfSignedTls,
      onToggleSelfSigned: controller.toggleM3uTlsOverride,
      isBusy: isBusy,
      tlsSwitchKey: const ValueKey('m3uSelfSignedSwitch'),
      additionalToggle: followRedirectToggle,
      tlsToggleEnabled: isUrlMode,
    );

    return ExpansionTile(
      key: const ValueKey('m3uAdvancedTile'),
      title: const Text('Advanced options'),
      initiallyExpanded: flowState.m3u.advancedExpanded,
      onExpansionChanged: controller.toggleM3uAdvanced,
      childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      children: children,
    );
  }

  /// Assembles the progress tracker and success summary when tests run.
  Widget? _buildTestFeedback(BuildContext context, LoginFlowState flowState) {
    final steps = flowState.testProgress.steps;
    final summary = flowState.testSummary;
    if (steps.isEmpty && summary == null) {
      return null;
    }

    final children = <Widget>[];
    if (steps.isNotEmpty) {
      children.add(_buildProgressCard(context, flowState));
    }
    if (summary != null) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(_buildSuccessSummary(context, summary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildProgressCard(BuildContext context, LoginFlowState flowState) {
    final steps = flowState.testProgress.steps;
    final completed = steps
        .where((step) => step.status == StepStatus.success)
        .length;
    final total = steps.length;
    final progress = total == 0 ? 0.0 : _calculateProgressValue(steps);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Test progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('$completed / $total'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            const SizedBox(height: 16),
            for (final step in steps) _buildTestStepRow(context, step),
          ],
        ),
      ),
    );
  }

  Widget _buildTestStepRow(BuildContext context, LoginTestStepState step) {
    final color = _statusColor(context, step.status);
    final icon = _statusIcon(step.status);
    final label = _labelForStep(step.step);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (step.message != null && step.message!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSummary(BuildContext context, LoginTestSummary summary) {
    final providerLabel = _providerLabel(summary.providerType);
    final channelText = summary.channelCount != null
        ? '${summary.channelCount} channels'
        : 'Channel count unavailable';
    final epgText = summary.epgDaySpan != null
        ? '${summary.epgDaySpan}-day EPG'
        : 'EPG data unavailable';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected to $providerLabel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(channelText),
            Text(epgText),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => _handleContinue(summary),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgressValue(List<LoginTestStepState> steps) {
    if (steps.isEmpty) {
      return 0;
    }
    final successes = steps
        .where((element) => element.status == StepStatus.success)
        .length;
    final inProgress = steps.any(
      (element) => element.status == StepStatus.inProgress,
    );
    final progress = successes + (inProgress ? 0.5 : 0.0);
    return (progress / steps.length).clamp(0.0, 1.0);
  }

  Color _statusColor(BuildContext context, StepStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case StepStatus.success:
        return scheme.primary;
      case StepStatus.failure:
        return scheme.error;
      case StepStatus.inProgress:
        return scheme.secondary;
      case StepStatus.pending:
        return scheme.onSurfaceVariant;
    }
  }

  IconData _statusIcon(StepStatus status) {
    switch (status) {
      case StepStatus.success:
        return Icons.check_circle;
      case StepStatus.failure:
        return Icons.error;
      case StepStatus.inProgress:
        return Icons.autorenew;
      case StepStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  String _labelForStep(LoginTestStep step) {
    switch (step) {
      case LoginTestStep.reachServer:
        return 'Reach server';
      case LoginTestStep.authenticate:
        return 'Authenticate';
      case LoginTestStep.fetchChannels:
        return 'Fetch channels';
      case LoginTestStep.fetchEpg:
        return 'Fetch EPG';
      case LoginTestStep.saveProfile:
        return 'Save profile';
    }
  }

  String _providerLabel(LoginProviderType type) {
    switch (type) {
      case LoginProviderType.m3u:
        return 'M3U/XMLTV';
      case LoginProviderType.xtream:
        return 'Xtream Codes';
      case LoginProviderType.stalker:
        return 'Stalker/Ministra';
    }
  }

  /// Shared action row combining the save-for-later affordance with the
  /// primary test button.
  /// Shared action row combining the save-for-later affordance with the
  /// primary test button.
  Widget _buildFormActions({
    required bool isBusy,
    required bool saveForLater,
    required ValueChanged<bool> onSaveToggle,
    required Future<void> Function() onPrimary,
    Key? saveToggleKey,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Connect',
            isBusy: isBusy,
            onPressed: isBusy ? null : () => unawaited(onPrimary()),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: CheckboxListTile(
            key: saveToggleKey,
            value: saveForLater,
            onChanged: isBusy
                ? null
                : (value) {
                    if (value != null) {
                      onSaveToggle(value);
                    }
                  },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Save this portal for later'),
          ),
        ),
      ],
    );
  }

  /// Reusable primary button with built-in busy indicator.
  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    bool isBusy = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: isBusy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }

  /// Displays a prominent banner for top-level error messages.
  Widget _buildBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }

  /// Validates inputs and performs the Stalker authentication handshake.
  Future<void> _handleStalkerLogin() async {
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    if (!flowController.validateActiveForm()) {
      flowController.setBannerMessage('Please review the highlighted fields.');
      return;
    }

    var current = ref.read(loginFlowControllerProvider);
    late StalkerPortalNormalizationResult normalization;
    try {
      normalization = normalizeStalkerPortalInput(
        current.stalker.portalUrl.value,
      );
    } on FormatException catch (error) {
      final message = error.message.isNotEmpty
          ? error.message
          : 'Enter a valid portal URL.';
      flowController.setStalkerFieldErrors(portalMessage: message);
      flowController.setBannerMessage(message);
      return;
    }

    final canonicalUri = normalization.canonicalUri;
    final normalizedPortalText = normalization.hadExplicitPort
        ? canonicalUri.toString()
        : canonicalUri.replace(port: null).toString();
    if (_portalUrlController.text != normalizedPortalText) {
      _portalUrlController
        ..text = normalizedPortalText
        ..selection = TextSelection.collapsed(
          offset: normalizedPortalText.length,
        );
    }
    flowController.updateStalkerPortalUrl(normalizedPortalText);
    current = ref.read(loginFlowControllerProvider);

    if (_applyInputClassification(
      normalizedPortalText,
      source: _ClassificationSource.validation,
    )) {
      return;
    }

    final headerResult = parseHeaderInput(current.stalker.customHeaders.value);
    if (headerResult.error != null) {
      flowController.setStalkerFieldErrors(
        customHeaderMessage: headerResult.error,
      );
      flowController.setBannerMessage(headerResult.error);
      return;
    }

    flowController.beginTestSequence(includeEpgStep: false);
    flowController.setStalkerFieldErrors();

    String? cacheKey;
    var usedCachedEntry = false;
    var needsCacheRefresh = false;
    late final DiscoveryOptions discoveryOptions;

    try {
      flowController.markStepActive(LoginTestStep.reachServer);

      final lockedBase = current.stalker.lockedBaseUri;
      DiscoveryResult? discoveryResult;
      Uri handshakeBase;

      discoveryOptions = _buildStalkerDiscoveryOptions(
        normalization,
        current,
        headerResult.headers,
      );

      if (lockedBase == null || lockedBase != normalizedPortalText) {
        flowController.clearStalkerLockedBase();
        current = ref.read(loginFlowControllerProvider);

        cacheKey = DiscoveryCacheManager.buildKey(
          kind: ProviderKind.stalker,
          identifier: normalization.canonicalUri.toString(),
          headers: discoveryOptions.headers,
          allowSelfSignedTls: discoveryOptions.allowSelfSignedTls,
          userAgent: discoveryOptions.userAgent,
          macAddress: discoveryOptions.macAddress,
        );

        try {
          final cacheHit = await _discoveryCacheManager.get(
            cacheKey: cacheKey,
            refreshLeeway: _discoveryCacheRefreshLeeway,
          );
          if (cacheHit != null) {
            discoveryResult = cacheHit.result;
            usedCachedEntry = true;
            needsCacheRefresh = cacheHit.shouldRefresh;
          }
        } catch (error, stackTrace) {
          _logError('Stalker cache read error', error, stackTrace);
        }

        if (discoveryResult == null) {
          // Fall back to live discovery when no cached endpoint is available.
          final discovery = await _stalkerDiscovery.discoverFromNormalized(
            normalization,
            options: discoveryOptions,
          );
          discoveryResult = discovery;
          try {
            await _discoveryCacheManager.store(
              cacheKey: cacheKey,
              result: discovery,
            );
          } catch (error, stackTrace) {
            _logError('Stalker cache write error', error, stackTrace);
          }
          needsCacheRefresh = false;
          usedCachedEntry = false;
        }

        handshakeBase = discoveryResult.lockedBase;
        final lockedBaseString = handshakeBase.toString();
        flowController.setStalkerLockedBase(lockedBaseString);
        if (_portalUrlController.text != lockedBaseString) {
          _portalUrlController
            ..text = lockedBaseString
            ..selection = TextSelection.collapsed(
              offset: lockedBaseString.length,
            );
        }
        current = ref.read(loginFlowControllerProvider);
      } else {
        handshakeBase = Uri.parse(lockedBase);
      }

      final userAgentOverride = current.stalker.userAgent.value.trim();
      if (discoveryResult?.hints['needsUserAgent'] == 'true' &&
          userAgentOverride.isEmpty) {
        flowController.setBannerMessage(
          'Portal expects a set-top box User-Agent. Add one under Advanced settings for reliable access.',
        );
      }
      final configuration = StalkerPortalConfiguration(
        baseUri: handshakeBase,
        macAddress: current.stalker.macAddress.value.trim(),
        userAgent: userAgentOverride.isEmpty ? null : userAgentOverride,
        allowSelfSignedTls: current.stalker.allowSelfSignedTls,
        extraHeaders: headerResult.headers,
      );

      final session = await ref.read(
        stalkerSessionProvider(configuration).future,
      );

      flowController.markStepSuccess(
        LoginTestStep.reachServer,
        message: 'Portal reachable',
      );
      flowController.markStepActive(LoginTestStep.authenticate);
      flowController.markStepSuccess(
        LoginTestStep.authenticate,
        message: 'Token acquired',
      );

      flowController.markStepActive(LoginTestStep.fetchChannels);
      int? channelCount;
      try {
        final channelResponse = await _stalkerHttpClient.getPortal(
          configuration,
          queryParameters: {
            'type': 'itv',
            'action': 'get_all_channels',
            'token': session.token,
            'mac': configuration.macAddress.toLowerCase(),
            'JsHttpRequest': '1-xml',
          },
          headers: session.buildAuthenticatedHeaders(),
        );
        channelCount = _extractStalkerChannelCount(channelResponse.body);
      } catch (error, stackTrace) {
        _logError('Stalker channel fetch error', error, stackTrace);
      }

      flowController.markStepSuccess(
        LoginTestStep.fetchChannels,
        message: channelCount != null
            ? '$channelCount channels available'
            : 'Channel probe skipped',
      );

      flowController.markStepActive(LoginTestStep.saveProfile);
      try {
        final persistedState = ref.read(loginFlowControllerProvider);
        final displayName = _deriveDisplayName(
          providerType: LoginProviderType.stalker,
          portalUrl: handshakeBase.toString(),
        );
        final config = <String, String>{
          'macAddress': configuration.macAddress,
          'deviceProfile': persistedState.stalker.deviceProfile,
        };
        final secrets = <String, String>{};
        final userAgentValue = userAgentOverride;
        if (userAgentValue.isNotEmpty) {
          config['userAgent'] = userAgentValue;
        }
        final encodedHeaders = _encodeHeaders(headerResult.headers);
        if (encodedHeaders != null) {
          secrets['customHeaders'] = encodedHeaders;
          config['hasCustomHeaders'] = 'true';
        }
        final hints = <String, String>{};
        if (discoveryResult != null) {
          hints.addAll(discoveryResult.hints);
        }
        final result = await _finalizeProfile(
          kind: ProviderKind.stalker,
          lockedBase: handshakeBase,
          displayName: displayName,
          configuration: config,
          hints: hints,
          secrets: secrets,
          allowSelfSignedTls: configuration.allowSelfSignedTls,
          followRedirects: true,
          needsUserAgent:
              hints['needsUserAgent'] == 'true' || userAgentValue.isNotEmpty,
        );
        flowController.markStepSuccess(
          LoginTestStep.saveProfile,
          message: result.persisted ? 'Profile saved' : 'Connected (not saved)',
        );

        if (needsCacheRefresh && cacheKey != null) {
          _scheduleDiscoveryRefresh(
            label: 'Stalker cache refresh',
            cacheKey: cacheKey,
            operation: () => _stalkerDiscovery.discoverFromNormalized(
              normalization,
              options: discoveryOptions,
            ),
          );
        }

        flowController.setStalkerFieldErrors();
        flowController.setTestSummary(
          LoginTestSummary(
            providerType: LoginProviderType.stalker,
            profileId: result.profile.record.id,
            profile: result.profile,
            channelCount: channelCount,
          ),
        );
        if (!mounted) return;
        _showSuccessSnackBar(
          'Connected successfully. Review the summary and continue when ready.',
        );
        return;
      } catch (error, stackTrace) {
        _logError('Stalker profile save error', error, stackTrace);
        final friendly = _profileSaveFriendlyMessage(error);
        flowController.markStepFailure(
          LoginTestStep.saveProfile,
          message: friendly,
        );
        flowController.setBannerMessage(friendly);
        return;
      }
    } on DiscoveryException catch (error) {
      flowController.clearStalkerLockedBase();
      final message = error.message.isNotEmpty
          ? error.message
          : 'Unable to locate a Stalker/Ministra portal at that address.';
      flowController.setStalkerFieldErrors(portalMessage: message);
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: message,
      );
      flowController.setBannerMessage(message);
      if (kDebugMode && error.telemetry.hasProbes) {
        for (final probe in error.telemetry.probes) {
          _debugPrintSafe(
            'Stalker discovery ${probe.stage} ${probe.uri} '
            'status=${probe.statusCode ?? 'n/a'} '
            'matched=${probe.matchedSignature} '
            'error=${probe.error == null ? 'none' : probe.error.runtimeType}',
          );
        }
      }
      return;
    } on StalkerAuthenticationException catch (error) {
      flowController.clearStalkerLockedBase();
      final message = _stalkerAuthFailureMessage(error.message);
      flowController.setStalkerFieldErrors(
        portalMessage:
            'Portal rejected the handshake. Confirm the URL, MAC address, and account status.',
      );
      flowController.markStepFailure(
        LoginTestStep.authenticate,
        message: message,
      );
    } on DioException catch (dioError) {
      flowController.clearStalkerLockedBase();
      _logDioError('Stalker login network error', dioError);
      if (usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'Stalker cache refresh after failure',
          cacheKey: cacheKey,
          operation: () => _stalkerDiscovery.discoverFromNormalized(
            normalization,
            options: discoveryOptions,
          ),
        );
      }
      final friendly = _describeNetworkError(dioError);
      flowController.setStalkerFieldErrors(
        portalMessage:
            'Unable to reach the portal. Check the address and your network connection.',
      );
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: friendly,
      );
    } catch (error, stackTrace) {
      flowController.clearStalkerLockedBase();
      _logError('Stalker login error', error, stackTrace);
      if (usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'Stalker cache refresh after error',
          cacheKey: cacheKey,
          operation: () => _stalkerDiscovery.discoverFromNormalized(
            normalization,
            options: discoveryOptions,
          ),
        );
      }
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: _unexpectedErrorMessage(error),
      );
    }
  }

  /// Validates inputs and performs the Xtream Codes authentication flow.
  Future<void> _handleXtreamLogin() async {
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    if (!flowController.validateActiveForm()) {
      flowController.setBannerMessage('Please review the highlighted fields.');
      return;
    }

    final current = ref.read(loginFlowControllerProvider);
    final headerResult = parseHeaderInput(current.xtream.customHeaders.value);
    if (headerResult.error != null) {
      flowController.setXtreamFieldErrors(
        customHeaderMessage: headerResult.error,
      );
      flowController.setBannerMessage(headerResult.error);
      return;
    }

    flowController.beginTestSequence(includeEpgStep: true);
    flowController.setM3uFieldErrors();
    flowController.setXtreamFieldErrors();

    String? cacheKey;
    var usedCachedEntry = false;
    var needsCacheRefresh = false;
    late final String baseInput;
    late final DiscoveryOptions discoveryOptions;

    try {
      flowController.markStepActive(LoginTestStep.reachServer);
      baseInput = current.xtream.serverUrl.value.trim();
      final userAgentOverride = current.xtream.userAgent.value.trim();
      final lockedBase = current.xtream.lockedBaseUri;
      Uri handshakeBase;
      DiscoveryResult? discoveryResult;

      discoveryOptions = DiscoveryOptions(
        allowSelfSignedTls: current.xtream.allowSelfSignedTls,
        headers: headerResult.headers,
        userAgent: userAgentOverride.isEmpty ? null : userAgentOverride,
        logSink: kDebugMode ? _onXtreamDiscoveryLog : null,
      );

      if (lockedBase == null) {
        cacheKey = DiscoveryCacheManager.buildKey(
          kind: ProviderKind.xtream,
          identifier: baseInput,
          headers: discoveryOptions.headers,
          allowSelfSignedTls: discoveryOptions.allowSelfSignedTls,
          userAgent: discoveryOptions.userAgent,
        );

        try {
          final cacheHit = await _discoveryCacheManager.get(
            cacheKey: cacheKey,
            refreshLeeway: _discoveryCacheRefreshLeeway,
          );
          if (cacheHit != null) {
            discoveryResult = cacheHit.result;
            usedCachedEntry = true;
            needsCacheRefresh = cacheHit.shouldRefresh;
          }
        } catch (error, stackTrace) {
          _logError('Xtream cache read error', error, stackTrace);
        }

        if (discoveryResult == null) {
          // Probe the server when cache does not have a fresh entry.
          final discovery = await _xtreamDiscovery.discover(
            baseInput,
            options: discoveryOptions,
          );
          discoveryResult = discovery;
          try {
            await _discoveryCacheManager.store(
              cacheKey: cacheKey,
              result: discovery,
            );
          } catch (error, stackTrace) {
            _logError('Xtream cache write error', error, stackTrace);
          }
          needsCacheRefresh = false;
          usedCachedEntry = false;
        }

        handshakeBase = discoveryResult.lockedBase;
        final lockedBaseString = handshakeBase.toString();
        flowController.setXtreamLockedBase(lockedBaseString);
        if (_xtreamUrlController.text != lockedBaseString) {
          _xtreamUrlController
            ..text = lockedBaseString
            ..selection = TextSelection.collapsed(
              offset: lockedBaseString.length,
            );
        }

        if (discoveryResult.hints['needsUserAgent'] == 'true' &&
            userAgentOverride.isEmpty) {
          flowController.setBannerMessage(
            'Server requires a specific User-Agent. Consider saving one in Advanced settings.',
          );
        }
      } else {
        handshakeBase = Uri.parse(lockedBase);
      }

      final refreshedState = ref.read(loginFlowControllerProvider);
      final configuration = XtreamPortalConfiguration(
        baseUri: handshakeBase,
        username: refreshedState.xtream.username.value.trim(),
        password: refreshedState.xtream.password.value.trim(),
        userAgent: userAgentOverride.isEmpty ? null : userAgentOverride,
        allowSelfSignedTls: refreshedState.xtream.allowSelfSignedTls,
        extraHeaders: headerResult.headers,
      );

      await ref.read(xtreamSessionProvider(configuration).future);

      flowController.markStepSuccess(
        LoginTestStep.reachServer,
        message: 'Portal reachable',
      );
      flowController.markStepActive(LoginTestStep.authenticate);
      flowController.markStepSuccess(
        LoginTestStep.authenticate,
        message: 'Authenticated as ${configuration.username}',
      );

      flowController.markStepActive(LoginTestStep.fetchChannels);
      int? channelCount;
      List<dynamic>? streams;
      try {
        final channelResponse = await _xtreamHttpClient.getPlayerApi(
          configuration,
          queryParameters: {'action': 'get_live_streams'},
        );
        streams =
            _asList(channelResponse.body) ??
            _asList(_asMap(channelResponse.body)?['streams']) ??
            _asList(_asMap(channelResponse.body)?['data']);
        channelCount = streams?.length;
      } catch (error, stackTrace) {
        _logError('Xtream channel fetch error', error, stackTrace);
      }

      flowController.markStepSuccess(
        LoginTestStep.fetchChannels,
        message: channelCount != null
            ? '$channelCount live streams available'
            : 'Channel probe skipped',
      );

      flowController.markStepActive(LoginTestStep.fetchEpg);
      int? epgDaySpan;
      final streamId = _extractXtreamStreamId(streams);
      if (streamId != null) {
        try {
          final epgResponse = await _xtreamHttpClient.getPlayerApi(
            configuration,
            queryParameters: {
              'action': 'get_simple_data_table',
              'stream_id': streamId,
            },
          );
          epgDaySpan = _calculateXtreamEpgSpan(epgResponse.body);
        } catch (error, stackTrace) {
          _logError('Xtream EPG fetch error', error, stackTrace);
        }
      }

      flowController.markStepSuccess(
        LoginTestStep.fetchEpg,
        message: epgDaySpan != null
            ? '$epgDaySpan-day guide'
            : 'EPG probe skipped',
      );

      flowController.markStepActive(LoginTestStep.saveProfile);
      try {
        final latestState = ref.read(loginFlowControllerProvider);
        final displayName = _deriveDisplayName(
          providerType: LoginProviderType.xtream,
          baseUrl: handshakeBase.toString(),
        );
        final config = <String, String>{
          'outputFormat': latestState.xtream.outputFormat,
        };
        if (userAgentOverride.isNotEmpty) {
          config['userAgent'] = userAgentOverride;
        }
        final hints = <String, String>{};
        if (discoveryResult != null) {
          hints.addAll(discoveryResult.hints);
        }
        final secrets = <String, String>{};
        final encodedHeaders = _encodeHeaders(headerResult.headers);
        if (encodedHeaders != null) {
          secrets['customHeaders'] = encodedHeaders;
          config['hasCustomHeaders'] = 'true';
        }
        if (configuration.username.trim().isNotEmpty) {
          secrets['username'] = configuration.username.trim();
        }
        if (configuration.password.trim().isNotEmpty) {
          secrets['password'] = configuration.password.trim();
        }
        final result = await _finalizeProfile(
          kind: ProviderKind.xtream,
          lockedBase: handshakeBase,
          displayName: displayName,
          configuration: config,
          hints: hints,
          secrets: secrets,
          allowSelfSignedTls: configuration.allowSelfSignedTls,
          followRedirects: true,
          needsUserAgent:
              hints['needsUserAgent'] == 'true' || userAgentOverride.isNotEmpty,
        );
        flowController.markStepSuccess(
          LoginTestStep.saveProfile,
          message: result.persisted ? 'Profile saved' : 'Connected (not saved)',
        );

        if (needsCacheRefresh && cacheKey != null) {
          _scheduleDiscoveryRefresh(
            label: 'Xtream cache refresh',
            cacheKey: cacheKey,
            operation: () =>
                _xtreamDiscovery.discover(baseInput, options: discoveryOptions),
          );
        }

        flowController.setXtreamFieldErrors();
        flowController.setTestSummary(
          LoginTestSummary(
            providerType: LoginProviderType.xtream,
            profileId: result.profile.record.id,
            profile: result.profile,
            channelCount: channelCount,
            epgDaySpan: epgDaySpan,
          ),
        );
        if (!mounted) return;
        _showSuccessSnackBar(
          'Connected successfully. Review the summary and continue when ready.',
        );
        return;
      } catch (error, stackTrace) {
        _logError('Xtream profile save error', error, stackTrace);
        final friendly = _profileSaveFriendlyMessage(error);
        flowController.markStepFailure(
          LoginTestStep.saveProfile,
          message: friendly,
        );
        flowController.setBannerMessage(friendly);
        return;
      }
    } on DiscoveryException catch (error) {
      flowController.clearXtreamLockedBase();
      if (usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'Xtream cache refresh after discovery failure',
          cacheKey: cacheKey,
          operation: () =>
              _xtreamDiscovery.discover(baseInput, options: discoveryOptions),
        );
      }
      final message = error.message.isNotEmpty
          ? error.message
          : 'Unable to locate an Xtream Codes server at that address.';
      flowController.setXtreamFieldErrors(baseUrlMessage: message);
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: message,
      );
      flowController.setBannerMessage(message);
      if (kDebugMode && error.telemetry.hasProbes) {
        for (final probe in error.telemetry.probes) {
          _debugPrintSafe(
            'Xtream discovery ${probe.stage} ${probe.uri} '
            'status=${probe.statusCode ?? 'n/a'} '
            'matched=${probe.matchedSignature} '
            'error=${probe.error == null ? 'none' : probe.error.runtimeType}',
          );
        }
      }
    } on XtreamAuthenticationException catch (error) {
      flowController.clearXtreamLockedBase();
      final message = _xtreamAuthFailureMessage(error.message);
      flowController.setXtreamFieldErrors(
        usernameMessage: 'Credentials were rejected. Confirm your username.',
        passwordMessage: 'Credentials were rejected. Confirm your password.',
      );
      flowController.markStepFailure(
        LoginTestStep.authenticate,
        message: message,
      );
    } on DioException catch (dioError) {
      flowController.clearXtreamLockedBase();
      _logDioError('Xtream login network error', dioError);
      if (usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'Xtream cache refresh after failure',
          cacheKey: cacheKey,
          operation: () =>
              _xtreamDiscovery.discover(baseInput, options: discoveryOptions),
        );
      }
      final friendly = _describeNetworkError(dioError);
      flowController.setXtreamFieldErrors(
        baseUrlMessage:
            'Unable to reach the server. Confirm the URL and your connection.',
      );
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: friendly,
      );
    } catch (error, stackTrace) {
      flowController.clearXtreamLockedBase();
      _logError('Xtream login error', error, stackTrace);
      if (usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'Xtream cache refresh after error',
          cacheKey: cacheKey,
          operation: () =>
              _xtreamDiscovery.discover(baseInput, options: discoveryOptions),
        );
      }
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: _unexpectedErrorMessage(error),
      );
    }
  }

  DiscoveryOptions _buildStalkerDiscoveryOptions(
    StalkerPortalNormalizationResult normalization,
    LoginFlowState state,
    Map<String, String> customHeaders,
  ) {
    final headers = <String, String>{...customHeaders};
    final mac = state.stalker.macAddress.value.trim();
    final userAgentOverride = state.stalker.userAgent.value.trim();

    final headerConfig = StalkerPortalConfiguration(
      baseUri: normalization.canonicalUri,
      macAddress: mac.isEmpty ? '00:00:00:00:00:00' : mac,
      userAgent: userAgentOverride.isEmpty ? null : userAgentOverride,
    );

    headers.putIfAbsent('Referer', () => headerConfig.refererUri.toString());
    headers.putIfAbsent('X-User-Agent', () => headerConfig.userAgent);

    if (mac.isNotEmpty) {
      headers.putIfAbsent(
        'Cookie',
        () =>
            'mac=${mac.toLowerCase()}; stb_lang=${headerConfig.languageCode}; timezone=${headerConfig.timezone}',
      );
    }

    return DiscoveryOptions(
      allowSelfSignedTls: state.stalker.allowSelfSignedTls,
      headers: headers,
      userAgent: headerConfig.userAgent,
      macAddress: mac.isEmpty ? null : mac.toLowerCase(),
      logSink: kDebugMode ? _onStalkerDiscoveryLog : null,
    );
  }

  void _onStalkerDiscoveryLog(DiscoveryProbeRecord record) {
    _debugPrintSafe(
      'Stalker discovery ${record.stage} ${record.uri} '
      'status=${record.statusCode ?? 'n/a'} '
      'matched=${record.matchedSignature} '
      'error=${record.error == null ? 'none' : record.error.runtimeType} '
      'elapsed=${record.elapsed.inMilliseconds}ms',
    );
  }

  void _onXtreamDiscoveryLog(DiscoveryProbeRecord record) {
    _debugPrintSafe(
      'Xtream discovery ${record.stage} ${record.uri} '
      'status=${record.statusCode ?? 'n/a'} '
      'matched=${record.matchedSignature} '
      'error=${record.error == null ? 'none' : record.error.runtimeType} '
      'elapsed=${record.elapsed.inMilliseconds}ms',
    );
  }

  void _onM3uDiscoveryLog(DiscoveryProbeRecord record) {
    _debugPrintSafe(
      'M3U discovery ${record.stage} ${record.uri} '
      'status=${record.statusCode ?? 'n/a'} '
      'matched=${record.matchedSignature} '
      'error=${record.error == null ? 'none' : record.error.runtimeType} '
      'elapsed=${record.elapsed.inMilliseconds}ms',
    );
  }

  Uri _redactM3uSecrets(Uri uri) {
    Map<String, String> sanitized = const {};
    if (uri.hasQuery) {
      try {
        sanitized = Uri.splitQueryString(uri.query);
      } catch (_) {
        sanitized = {};
      }
      sanitized = Map.of(sanitized);
      sanitized.removeWhere(
        (key, value) => _m3uSensitiveQueryKeys.contains(key.toLowerCase()),
      );
    }

    return uri.replace(
      userInfo: '',
      queryParameters: sanitized.isEmpty ? null : sanitized,
    );
  }

  Future<void> _pickM3uPlaylistFile() async {
    final flowState = ref.read(loginFlowControllerProvider);
    if (flowState.testProgress.inProgress) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['m3u', 'm3u8', 'txt'],
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final path = file.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access the selected file path on this platform.',
            ),
          ),
        );
        return;
      }

      final flowController = ref.read(loginFlowControllerProvider.notifier);
      flowController.setM3uFileSelection(
        path: path,
        fileName: file.name,
        fileSizeBytes: file.size > 0 ? file.size : null,
      );

      if (!mounted) return;
      _m3uInputController.text = path;
      _m3uInputController.selection = TextSelection.collapsed(
        offset: path.length,
      );
    } on PlatformException catch (error) {
      _logError('M3U file picker error', error);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File picker failed: ${error.message ?? error.code}'),
        ),
      );
    } catch (error, stackTrace) {
      _logError('M3U file picker unexpected error', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick a playlist file.')),
      );
    }
  }

  /// Validates inputs and runs the M3U/XMLTV validation flow.
  Future<void> _handleM3uLogin() async {
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    if (!flowController.validateActiveForm()) {
      flowController.setBannerMessage('Please review the highlighted fields.');
      return;
    }

    final initialState = ref.read(loginFlowControllerProvider);
    final headerResult = parseHeaderInput(initialState.m3u.customHeaders.value);
    if (headerResult.error != null) {
      flowController.setM3uFieldErrors(customHeaderMessage: headerResult.error);
      flowController.setBannerMessage(headerResult.error);
      return;
    }

    flowController.beginTestSequence(includeEpgStep: true);
    flowController.setM3uFieldErrors();

    String? cacheKey;
    var usedCachedEntry = false;
    var hadCacheResult = false;
    var needsCacheRefresh = false;
    late final bool isUrlMode;
    late final String playlistInput;
    late final DiscoveryOptions discoveryOptions;

    try {
      flowController.markStepActive(LoginTestStep.reachServer);
      isUrlMode = initialState.m3u.inputMode == M3uInputMode.url;
      playlistInput = isUrlMode
          ? initialState.m3u.playlistUrl.value.trim()
          : initialState.m3u.playlistFilePath.value.trim();
      final userAgentOverride = initialState.m3u.userAgent.value.trim();

      discoveryOptions = DiscoveryOptions(
        allowSelfSignedTls: initialState.m3u.allowSelfSignedTls,
        headers: headerResult.headers,
        userAgent: userAgentOverride.isEmpty ? null : userAgentOverride,
        logSink: kDebugMode && isUrlMode ? _onM3uDiscoveryLog : null,
      );
      DiscoveryResult? discovery;
      if (isUrlMode) {
        cacheKey = DiscoveryCacheManager.buildKey(
          kind: ProviderKind.m3u,
          identifier: playlistInput,
          headers: discoveryOptions.headers,
          allowSelfSignedTls: discoveryOptions.allowSelfSignedTls,
          userAgent: discoveryOptions.userAgent,
          followRedirects: initialState.m3u.followRedirects,
        );
        try {
          final cacheHit = await _discoveryCacheManager.get(
            cacheKey: cacheKey,
            refreshLeeway: _discoveryCacheRefreshLeeway,
          );
          if (cacheHit != null) {
            discovery = cacheHit.result;
            usedCachedEntry = true;
            hadCacheResult = true;
            needsCacheRefresh = cacheHit.shouldRefresh;
          }
        } catch (error, stackTrace) {
          _logError('M3U cache read error', error, stackTrace);
        }
      }

      // Execute remote probes if the cache did not yield a hit.
      discovery ??= await _m3uDiscovery.discover(
        playlistInput,
        options: discoveryOptions,
      );

      if (isUrlMode && cacheKey != null) {
        try {
          await _discoveryCacheManager.store(
            cacheKey: cacheKey,
            result: discovery,
          );
          needsCacheRefresh = false;
          usedCachedEntry = false;
        } catch (error, stackTrace) {
          if (!hadCacheResult) {
            _logError('M3U cache write error', error, stackTrace);
          } else {
            _logError('M3U cache refresh error', error, stackTrace);
          }
        }
      }

      if (discovery.kind == ProviderKind.xtream) {
        flowController.markStepFailure(
          LoginTestStep.reachServer,
          message: 'Detected an Xtream link; switching to Xtream login.',
        );
        flowController.setBannerMessage(
          'Detected an Xtream playlist link. Switched to the Xtream form so you can continue there.',
        );
        if (!mounted) {
          return;
        }
        _applyInputClassification(
          discovery.lockedBase.toString(),
          source: _ClassificationSource.validation,
          messenger: ScaffoldMessenger.of(context),
        );
        return;
      }

      var resolvedPlaylist = discovery.lockedBase.toString();
      if (isUrlMode) {
        if (_m3uInputController.text != resolvedPlaylist) {
          _m3uInputController
            ..text = resolvedPlaylist
            ..selection = TextSelection.collapsed(
              offset: resolvedPlaylist.length,
            );
        }
        flowController.updateM3uPlaylistUrl(resolvedPlaylist);
        flowController.setM3uLockedPlaylist(
          raw: resolvedPlaylist,
          redacted: discovery.hints['sanitizedPlaylist'] ?? resolvedPlaylist,
        );
        if (discovery.hints['needsMediaUserAgent'] == 'true' &&
            userAgentOverride.isEmpty) {
          flowController.setBannerMessage(
            'Playlist server expects a media-player User-Agent. Add one under Advanced settings for reliable access.',
          );
        }
      } else {
        flowController.setM3uLockedPlaylist(
          raw: resolvedPlaylist,
          redacted: discovery.hints['sanitizedPlaylist'] ?? resolvedPlaylist,
        );
        final updatedSize = int.tryParse(discovery.hints['fileBytes'] ?? '');
        final updatedModified = DateTime.tryParse(
          discovery.hints['modifiedAt'] ?? '',
        );
        flowController.updateM3uFileMetadata(
          fileSizeBytes: updatedSize,
          lastModified: updatedModified,
        );
      }

      XmltvHeadMetadata? xmltvHead;
      String? xmltvConfigInput;
      final resolvedState = ref.read(loginFlowControllerProvider);
      final epgInput = resolvedState.m3u.epgUrl.value.trim();
      if (epgInput.isNotEmpty) {
        final isRemoteXmltv = epgInput.contains('://');
        if (isRemoteXmltv) {
          try {
            final canonicalEpg = canonicalizeScheme(epgInput);
            final epgUri = Uri.parse(canonicalEpg);
            if (epgUri.host.isEmpty) {
              throw const FormatException(
                'XMLTV URL must include a host name.',
              );
            }
            final headMetadata = await _probeXmltvHead(
              uri: epgUri,
              headers: headerResult.headers,
              allowSelfSigned: initialState.m3u.allowSelfSignedTls,
              followRedirects: initialState.m3u.followRedirects,
              userAgent: userAgentOverride.isEmpty ? null : userAgentOverride,
            );
            xmltvHead = headMetadata;
            if (headMetadata.isSuccessful || headMetadata.allowsFallback) {
              final resolvedUri = headMetadata.resolvedUri;
              flowController.setM3uLockedEpg(
                _redactM3uSecrets(resolvedUri).toString(),
              );
              xmltvConfigInput = resolvedUri.toString();
              if (!headMetadata.isSuccessful && headMetadata.allowsFallback) {
                flowController.setBannerMessage(
                  'XMLTV server refused HEAD requests; continuing with full download.',
                );
              }
            } else {
              final message =
                  'XMLTV probe failed (HTTP ${headMetadata.statusCode}).';
              flowController.setM3uFieldErrors(epgMessage: message);
              flowController.markStepFailure(
                LoginTestStep.reachServer,
                message: message,
              );
              return;
            }
          } on FormatException catch (error) {
            flowController.setM3uFieldErrors(epgMessage: error.message);
            flowController.setM3uLockedEpg(null);
            flowController.markStepFailure(
              LoginTestStep.reachServer,
              message: error.message,
            );
            return;
          } on DioException catch (dioError) {
            final friendly = _describeNetworkError(dioError);
            flowController.setM3uFieldErrors(
              epgMessage: 'Unable to reach the XMLTV feed. $friendly',
            );
            flowController.setM3uLockedEpg(null);
            flowController.markStepFailure(
              LoginTestStep.reachServer,
              message: friendly,
            );
            return;
          } catch (error, stackTrace) {
            _logError('XMLTV head probe error', error, stackTrace);
            final message = _unexpectedErrorMessage(error);
            flowController.setM3uFieldErrors(epgMessage: message);
            flowController.setM3uLockedEpg(null);
            flowController.markStepFailure(
              LoginTestStep.reachServer,
              message: message,
            );
            return;
          }
        } else {
          xmltvConfigInput = epgInput;
          flowController.setM3uLockedEpg(null);
        }
      } else {
        flowController.setM3uLockedEpg(null);
      }

      final effectiveState = ref.read(loginFlowControllerProvider);
      resolvedPlaylist = effectiveState.m3u.inputMode == M3uInputMode.url
          ? effectiveState.m3u.playlistUrl.value.trim()
          : effectiveState.m3u.playlistFilePath.value.trim();

      final configuration = buildM3uConfiguration(
        portalId: 'm3u-',
        playlistInput: resolvedPlaylist,
        displayName: effectiveState.m3u.inputMode == M3uInputMode.url
            ? resolvedPlaylist
            : effectiveState.m3u.fileName ?? 'Local playlist',
        username: effectiveState.m3u.username.value.trim().isEmpty
            ? null
            : effectiveState.m3u.username.value.trim(),
        password: effectiveState.m3u.password.value.trim().isEmpty
            ? null
            : effectiveState.m3u.password.value.trim(),
        userAgent: userAgentOverride.isEmpty ? null : userAgentOverride,
        customHeaders: headerResult.headers,
        allowSelfSignedTls: effectiveState.m3u.allowSelfSignedTls,
        followRedirects: effectiveState.m3u.followRedirects,
        xmltvInput: xmltvConfigInput,
        xmltvHeaders: headerResult.headers,
      );

      final session = await ref.read(
        m3uXmlSessionProvider(configuration).future,
      );

      flowController.markStepSuccess(
        LoginTestStep.reachServer,
        message: 'Playlist reachable',
      );
      flowController.markStepActive(LoginTestStep.authenticate);
      flowController.markStepSuccess(
        LoginTestStep.authenticate,
        message: 'Playlist validated',
      );

      flowController.markStepActive(LoginTestStep.fetchChannels);
      final playlistText = session.readPlaylist();
      final channelCount = _estimateM3uChannelCount(playlistText);
      flowController.markStepSuccess(
        LoginTestStep.fetchChannels,
        message: channelCount != null
            ? '$channelCount entries found'
            : 'Playlist parsed',
      );

      flowController.markStepActive(LoginTestStep.fetchEpg);
      int? epgDaySpan;
      if (session.xmltv != null) {
        final xml = session.readXmltv();
        if (xml != null) {
          epgDaySpan = _estimateXmltvDaySpan(xml);
        }
        flowController.markStepSuccess(
          LoginTestStep.fetchEpg,
          message: epgDaySpan != null
              ? '$epgDaySpan-day guide'
              : 'EPG validated',
        );
      } else {
        flowController.markStepSuccess(
          LoginTestStep.fetchEpg,
          message: 'No XMLTV supplied',
        );
      }

      flowController.markStepActive(LoginTestStep.saveProfile);
      try {
        final latestState = ref.read(loginFlowControllerProvider);
        final displayName = _deriveDisplayName(
          providerType: LoginProviderType.m3u,
          playlistInput: resolvedPlaylist,
          fileName: latestState.m3u.fileName,
        );
        final config = <String, String>{
          'inputMode': latestState.m3u.inputMode.name,
          'autoUpdate': latestState.m3u.autoUpdate ? 'true' : 'false',
        };
        if (latestState.m3u.fileName?.trim().isNotEmpty == true) {
          config['fileName'] = latestState.m3u.fileName!.trim();
        }
        if (latestState.m3u.fileSizeBytes != null) {
          config['fileSizeBytes'] = latestState.m3u.fileSizeBytes!.toString();
        }
        final userAgentOverride = latestState.m3u.userAgent.value.trim();
        if (userAgentOverride.isNotEmpty) {
          config['userAgent'] = userAgentOverride;
        }
        final redactedPlaylist = latestState.m3u.redactedPlaylistUri;
        if (redactedPlaylist != null && redactedPlaylist.isNotEmpty) {
          config['redactedPlaylist'] = redactedPlaylist;
        }
        final lockedEpg = latestState.m3u.lockedEpgUri;
        if (lockedEpg != null && lockedEpg.isNotEmpty) {
          config['lockedEpg'] = lockedEpg;
        }
        final hints = Map<String, String>.from(discovery.hints);
        final secrets = <String, String>{};
        final encodedHeaders = _encodeHeaders(headerResult.headers);
        if (encodedHeaders != null) {
          secrets['customHeaders'] = encodedHeaders;
          config['hasCustomHeaders'] = 'true';
        }
        if (latestState.m3u.inputMode == M3uInputMode.url) {
          secrets['playlistUrl'] = resolvedPlaylist;
        } else {
          config['playlistFilePath'] = resolvedPlaylist;
        }
        final username = latestState.m3u.username.value.trim();
        if (username.isNotEmpty) {
          secrets['username'] = username;
        }
        final password = latestState.m3u.password.value.trim();
        if (password.isNotEmpty) {
          secrets['password'] = password;
        }
        if (epgInput.isNotEmpty) {
          secrets['epgUrl'] = epgInput;
        }
        if (xmltvHead != null) {
          final head = xmltvHead;
          hints['xmltvHeadStatus'] = head.statusCode.toString();
          final contentType = head.contentType;
          if (contentType != null && contentType.isNotEmpty) {
            hints['xmltvContentType'] = contentType;
          }
          final lastModified = head.lastModified;
          if (lastModified != null) {
            hints['xmltvLastModified'] = lastModified.toIso8601String();
          }
          hints['xmltvResolvedUri'] = _redactM3uSecrets(
            head.resolvedUri,
          ).toString();
        }
        final result = await _finalizeProfile(
          kind: ProviderKind.m3u,
          lockedBase: discovery.lockedBase,
          displayName: displayName,
          configuration: config,
          hints: hints,
          secrets: secrets,
          allowSelfSignedTls: latestState.m3u.allowSelfSignedTls,
          followRedirects: latestState.m3u.followRedirects,
          needsUserAgent:
              hints['needsMediaUserAgent'] == 'true' ||
              userAgentOverride.isNotEmpty,
        );
        flowController.markStepSuccess(
          LoginTestStep.saveProfile,
          message: result.persisted ? 'Profile saved' : 'Connected (not saved)',
        );

        if (isUrlMode && needsCacheRefresh && cacheKey != null) {
          _scheduleDiscoveryRefresh(
            label: 'M3U cache refresh',
            cacheKey: cacheKey,
            operation: () => _m3uDiscovery.discover(
              playlistInput,
              options: discoveryOptions,
            ),
          );
        }

        flowController.setM3uFieldErrors();
        flowController.setTestSummary(
          LoginTestSummary(
            providerType: LoginProviderType.m3u,
            profileId: result.profile.record.id,
            profile: result.profile,
            channelCount: channelCount,
            epgDaySpan: epgDaySpan,
          ),
        );
        if (!mounted) return;
        _showSuccessSnackBar(
          'Connected successfully. Review the summary and continue when ready.',
        );
        return;
      } catch (error, stackTrace) {
        _logError('M3U profile save error', error, stackTrace);
        final friendly = _profileSaveFriendlyMessage(error);
        flowController.markStepFailure(
          LoginTestStep.saveProfile,
          message: friendly,
        );
        flowController.setBannerMessage(friendly);
        return;
      }
    } on FormatException catch (error) {
      flowController.clearM3uLockedPlaylist();
      flowController.setM3uFieldErrors(playlistMessage: error.message);
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: error.message,
      );
      flowController.setBannerMessage(error.message);
    } on DiscoveryException catch (error) {
      flowController.clearM3uLockedPlaylist();
      if (isUrlMode && usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'M3U cache refresh after failure',
          cacheKey: cacheKey,
          operation: () =>
              _m3uDiscovery.discover(playlistInput, options: discoveryOptions),
        );
      }
      flowController.setM3uFieldErrors(playlistMessage: error.message);
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: error.message,
      );
      if (kDebugMode && error.telemetry.hasProbes) {
        for (final record in error.telemetry.probes) {
          _onM3uDiscoveryLog(record);
        }
      }
    } on M3uXmlAuthenticationException catch (error) {
      final lower = error.message.toLowerCase();
      final targetsXmltv = lower.contains('xmltv');
      final playlistMessage = targetsXmltv
          ? null
          : 'Playlist couldn\'t be validated. Confirm the URL or file path and credentials.';
      final epgMessage = targetsXmltv
          ? 'EPG feed couldn\'t be validated. Confirm the XMLTV URL or remove it for now.'
          : null;
      flowController.setM3uFieldErrors(
        playlistMessage: playlistMessage,
        epgMessage: epgMessage,
      );
      final failureStep = targetsXmltv
          ? LoginTestStep.fetchEpg
          : LoginTestStep.fetchChannels;
      flowController.markStepFailure(
        failureStep,
        message: _m3uFailureMessage(error.message),
      );
    } on DioException catch (dioError) {
      _logDioError('M3U validation network error', dioError);
      if (isUrlMode && usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'M3U cache refresh after failure',
          cacheKey: cacheKey,
          operation: () =>
              _m3uDiscovery.discover(playlistInput, options: discoveryOptions),
        );
      }
      final friendly = _describeNetworkError(dioError);
      flowController.setM3uFieldErrors(
        playlistMessage:
            'Unable to reach the playlist. Confirm the address and your connection.',
      );
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: friendly,
      );
    } catch (error, stackTrace) {
      _logError('M3U validation error', error, stackTrace);
      if (isUrlMode && usedCachedEntry && cacheKey != null) {
        _scheduleDiscoveryRefresh(
          label: 'M3U cache refresh after error',
          cacheKey: cacheKey,
          operation: () =>
              _m3uDiscovery.discover(playlistInput, options: discoveryOptions),
        );
      }
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: _unexpectedErrorMessage(error),
      );
    }
  }

  /// Shows a bottom sheet with quick guidance on locating provider details.
  Future<void> _showHelpSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Where to find your details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                '- Stalker/Ministra: usually available in your set-top box portal settings or provider onboarding email.\n'
                '- Xtream: ask your provider for base URL, username, and password (often identical to app credentials).\n'
                '- M3U: copy the playlist link from your provider dashboard or export the file from their portal.',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<ProviderProfileRecord> _persistProviderProfile({
    required ProviderKind kind,
    required String displayName,
    required Uri lockedBase,
    Map<String, String> configuration = const <String, String>{},
    Map<String, String> hints = const <String, String>{},
    Map<String, String> secrets = const <String, String>{},
    bool needsUserAgent = false,
    bool allowSelfSignedTls = false,
    bool followRedirects = true,
  }) {
    final repository = ref.read(providerProfileRepositoryProvider);
    return repository.saveProfile(
      kind: kind,
      lockedBase: lockedBase,
      displayName: displayName,
      configuration: configuration,
      hints: hints,
      secrets: secrets,
      needsUserAgent: needsUserAgent,
      allowSelfSignedTls: allowSelfSignedTls,
      followRedirects: followRedirects,
      successAt: DateTime.now().toUtc(),
    );
  }

  Future<ResolvedProviderProfile?> _loadResolvedProfile({
    required String profileId,
    ProviderProfileRecord? record,
  }) async {
    try {
      final repository = ref.read(providerProfileRepositoryProvider);
      final profileRecord = record ?? await repository.getProfile(profileId);
      if (profileRecord == null) {
        return null;
      }
      Map<String, String> secrets = const {};
      if (profileRecord.hasSecrets) {
        final snapshot = await repository.loadSecrets(profileRecord.id);
        secrets = snapshot?.secrets ?? const {};
      }
      final providerDbId = await _ensureDbProviderIdForProfile(
        profileRecord,
        createIfMissing: true,
      );
      return ResolvedProviderProfile(
        record: profileRecord,
        secrets: secrets,
        providerDbId: providerDbId,
      );
    } catch (error, stackTrace) {
      _logError('Provider profile load error', error, stackTrace);
      return null;
    }
  }

  Future<({ResolvedProviderProfile profile, bool persisted})> _finalizeProfile({
    required ProviderKind kind,
    required Uri lockedBase,
    required String displayName,
    required Map<String, String> configuration,
    required Map<String, String> hints,
    required Map<String, String> secrets,
    required bool allowSelfSignedTls,
    required bool followRedirects,
    required bool needsUserAgent,
  }) async {
    final shouldSave = ref.read(loginFlowControllerProvider).saveForLater;
    if (shouldSave) {
      final record = await _persistProviderProfile(
        kind: kind,
        displayName: displayName,
        lockedBase: lockedBase,
        configuration: configuration,
        hints: hints,
        secrets: secrets,
        needsUserAgent: needsUserAgent,
        allowSelfSignedTls: allowSelfSignedTls,
        followRedirects: followRedirects,
      );
      final resolved = await _loadResolvedProfile(
        profileId: record.id,
        record: record,
      );
      if (resolved == null) {
        throw StateError('Unable to load saved profile for navigation.');
      }
      return (profile: resolved, persisted: true);
    }

    final now = DateTime.now().toUtc();
    final record = ProviderProfileRecord(
      id: ProviderProfileRepository.allocateProfileId(),
      kind: kind,
      displayName: displayName,
      lockedBase: lockedBase,
      needsUserAgent: needsUserAgent,
      allowSelfSignedTls: allowSelfSignedTls,
      followRedirects: followRedirects,
      configuration: Map.unmodifiable(Map<String, String>.from(configuration)),
      hints: Map.unmodifiable(Map<String, String>.from(hints)),
      createdAt: now,
      updatedAt: now,
      lastOkAt: now,
      hasSecrets: secrets.isNotEmpty,
    );
    final resolved = ResolvedProviderProfile(
      record: record,
      secrets: Map.unmodifiable(Map<String, String>.from(secrets)),
      providerDbId: await _ensureDbProviderIdForProfile(
        record,
        createIfMissing: false,
      ),
    );
    return (profile: resolved, persisted: false);
  }

  Future<void> _navigateToPlayer(ResolvedProviderProfile profile) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => player.PlayerShell(profile: profile),
      ),
    );
  }

  Future<int?> _ensureDbProviderIdForProfile(
    ProviderProfileRecord profile, {
    required bool createIfMissing,
  }) {
    final syncService = ref.read(providerSyncServiceProvider);
    return syncService.ensureProviderForProfile(
      profile,
      createIfMissing: createIfMissing,
    );
  }

  String _profileSaveFriendlyMessage(Object error) {
    final description = error.toString();
    if (description.isEmpty || description == 'Exception') {
      return 'Unable to save the profile. Please try again.';
    }
    return 'Unable to save the profile: $description';
  }

  String? _encodeHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return null;
    return jsonEncode(headers);
  }

  Future<XmltvHeadMetadata> _probeXmltvHead({
    required Uri uri,
    required Map<String, String> headers,
    required bool allowSelfSigned,
    required bool followRedirects,
    String? userAgent,
  }) {
    return _m3uClient.headXmltv(
      uri: uri,
      headers: headers,
      userAgent: userAgent,
      allowSelfSignedTls: allowSelfSigned,
      followRedirects: followRedirects,
    );
  }

  bool _applyInputClassification(
    String rawInput, {
    _ClassificationSource source = _ClassificationSource.validation,
    ScaffoldMessengerState? messenger,
  }) {
    final classification = _inputClassifier.classify(rawInput);
    final provider = classification.provider;
    if (provider == null || provider == ProviderKind.stalker) {
      return false;
    }

    final targetType = _loginProviderFor(provider);
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    var flowState = ref.read(loginFlowControllerProvider);

    final providerChanged = flowState.providerType != targetType;
    if (providerChanged) {
      flowController.selectProvider(targetType);
      flowState = ref.read(loginFlowControllerProvider);
    }

    bool updated = false;

    switch (targetType) {
      case LoginProviderType.xtream:
        final details = classification.xtream;
        if (details != null) {
          final base = details.baseUri.toString();
          _syncControllerText(
            flowState.xtream.serverUrl.value,
            base,
            _xtreamUrlController,
          );
          flowController.updateXtreamServerUrl(base);

          if (details.username != null && details.username!.isNotEmpty) {
            _syncControllerText(
              flowState.xtream.username.value,
              details.username!,
              _xtreamUsernameController,
            );
            flowController.updateXtreamUsername(details.username!);
          }

          if (details.password != null && details.password!.isNotEmpty) {
            _syncControllerText(
              flowState.xtream.password.value,
              details.password!,
              _xtreamPasswordController,
            );
            flowController.updateXtreamPassword(details.password!);
          }
          updated = true;
        }
        break;
      case LoginProviderType.m3u:
        final details = classification.m3u;
        if (details != null) {
          final mode = details.isLocalFile
              ? M3uInputMode.file
              : M3uInputMode.url;
          if (flowState.m3u.inputMode != mode) {
            flowController.selectM3uInputMode(mode);
            flowState = ref.read(loginFlowControllerProvider);
          }

          final resolved = details.resolvedInput;
          if (resolved.isNotEmpty) {
            final previousValue = flowState.m3u.inputMode == M3uInputMode.url
                ? flowState.m3u.playlistUrl.value
                : flowState.m3u.playlistFilePath.value;
            _syncControllerText(previousValue, resolved, _m3uInputController);
            if (mode == M3uInputMode.url) {
              flowController.updateM3uPlaylistUrl(resolved);
            } else {
              flowController.updateM3uPlaylistFilePath(resolved);
            }
            updated = true;
          }

          if (!details.isLocalFile && details.username != null) {
            final username = details.username!;
            if (username.isNotEmpty) {
              _syncControllerText(
                flowState.m3u.username.value,
                username,
                _m3uUsernameController,
              );
              flowController.updateM3uUsername(username);
              updated = true;
            }
          }

          if (!details.isLocalFile && details.password != null) {
            final password = details.password!;
            if (password.isNotEmpty) {
              _syncControllerText(
                flowState.m3u.password.value,
                password,
                _m3uPasswordController,
              );
              flowController.updateM3uPassword(password);
              updated = true;
            }
          }
        }
        break;
      case LoginProviderType.stalker:
        return false;
    }

    if (!providerChanged && !updated) {
      return false;
    }

    if (providerChanged) {
      final message = switch (targetType) {
        LoginProviderType.xtream =>
          'Detected Xtream link; switched to the Xtream form.',
        LoginProviderType.m3u =>
          'Detected M3U playlist; switched to the M3U form.',
        LoginProviderType.stalker => '',
      };

      flowController.setBannerMessage(
        '$message You can choose a different provider if this is incorrect.',
      );

      if (source == _ClassificationSource.paste && messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } else if (updated) {
      final providerLabel = targetType == LoginProviderType.xtream
          ? 'Xtream'
          : 'M3U';
      flowController.setBannerMessage(
        'Detected $providerLabel input and populated the form automatically.',
      );
      if (source == _ClassificationSource.paste && messenger != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Pasted $providerLabel details.')),
        );
      }
    }

    return true;
  }

  LoginProviderType _loginProviderFor(ProviderKind kind) {
    switch (kind) {
      case ProviderKind.stalker:
        return LoginProviderType.stalker;
      case ProviderKind.xtream:
        return LoginProviderType.xtream;
      case ProviderKind.m3u:
        return LoginProviderType.m3u;
    }
  }

  /// Attempts to paste clipboard text into the most relevant field.
  Future<void> _handlePaste(
    BuildContext context, {
    _PasteTarget? target,
  }) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (text == null || text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Clipboard is empty.')),
      );
      return;
    }

    final controller = ref.read(loginFlowControllerProvider.notifier);
    final flowState = ref.read(loginFlowControllerProvider);

    if (_applyInputClassification(
      text,
      source: _ClassificationSource.paste,
      messenger: messenger,
    )) {
      return;
    }

    final resolvedTarget =
        target ??
        switch (flowState.providerType) {
          LoginProviderType.stalker => _PasteTarget.stalkerPortal,
          LoginProviderType.xtream => _PasteTarget.xtreamBaseUrl,
          LoginProviderType.m3u =>
            flowState.m3u.inputMode == M3uInputMode.url
                ? _PasteTarget.m3uUrl
                : _PasteTarget.m3uUrl,
        };

    switch (resolvedTarget) {
      case _PasteTarget.stalkerPortal:
        _portalUrlController
          ..text = text
          ..selection = TextSelection.collapsed(offset: text.length);
        controller.updateStalkerPortalUrl(text);
        break;
      case _PasteTarget.xtreamBaseUrl:
        _xtreamUrlController
          ..text = text
          ..selection = TextSelection.collapsed(offset: text.length);
        controller.updateXtreamServerUrl(text);
        break;
      case _PasteTarget.m3uUrl:
        _m3uInputController
          ..text = text
          ..selection = TextSelection.collapsed(offset: text.length);
        if (flowState.m3u.inputMode == M3uInputMode.url) {
          controller.updateM3uPlaylistUrl(text);
        } else {
          controller.updateM3uPlaylistFilePath(text);
        }
        break;
    }

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Pasted clipboard contents.')),
    );
  }

  /// Temporary handler for the "Continue" affordance in the success summary.
  Future<void> _handleContinue(LoginTestSummary summary) async {
    final resolved = await _loadResolvedProfile(
          profileId: summary.profileId,
          record: summary.profile.record,
        ) ??
        summary.profile;

    await _navigateToPlayer(resolved);
    if (!mounted) return;
    ref.read(loginFlowControllerProvider.notifier).resetTestProgress();
  }

  Future<void> _connectSavedProfile(ProviderProfileRecord record) async {
    final resolved = await _loadResolvedProfile(
      profileId: record.id,
      record: record,
    );
    if (resolved == null) {
      _showSnack('Unable to open ${record.displayName}.');
      return;
    }
    await _navigateToPlayer(resolved);
  }

  /// Convenience helper to copy controller text updates without duplicate work.
  void _syncControllerText(
    String? previousValue,
    String nextValue,
    TextEditingController controller,
  ) {
    if (previousValue == nextValue) {
      return;
    }
    if (controller.text != nextValue) {
      controller.text = nextValue;
      controller.selection = TextSelection.collapsed(offset: nextValue.length);
    }
  }

  /// Displays a floating success message once flows complete.
  void _showSuccessSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

    if (!mounted || confirm != true) {
      return;
    }

    final secretsSnapshot = await repository.loadSecrets(record.id);

    await repository.deleteProfile(record.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${record.displayName}'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            unawaited(
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
              ),
            );
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _handleSaveDraft() async {
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    flowController.setBannerMessage(null);
    final repository = await ref.read(loginDraftRepositoryProvider.future);
    final current = ref.read(loginFlowControllerProvider);
    final now = DateTime.now().toUtc();

    final draft = _buildDraftFromState(current, now);
    if (draft == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add provider details before saving a draft.'),
        ),
      );
      return;
    }

    try {
      await repository.saveDraft(draft);
      if (!mounted) return;
      _showSuccessSnackBar('Draft saved for later.');
    } catch (error, stackTrace) {
      _logError('Draft save error', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save draft: $error')));
    }
  }

  LoginDraft? _buildDraftFromState(LoginFlowState state, DateTime timestamp) {
    final data = <String, dynamic>{};
    final secrets = <String, String>{};
    var hasContent = false;

    switch (state.providerType) {
      case LoginProviderType.stalker:
        final portal = state.stalker.portalUrl.value.trim();
        final mac = state.stalker.macAddress.value.trim();
        data.addAll({
          'displayName': _deriveDisplayName(
            providerType: LoginProviderType.stalker,
            portalUrl: portal,
          ),
          'portalUrl': portal,
          'macAddress': mac,
          'deviceProfile': state.stalker.deviceProfile,
          'allowSelfSignedTls': state.stalker.allowSelfSignedTls,
          'userAgent': state.stalker.userAgent.value,
          'customHeaders': state.stalker.customHeaders.value,
        });
        hasContent =
            portal.isNotEmpty ||
            mac.isNotEmpty ||
            state.stalker.userAgent.value.trim().isNotEmpty ||
            state.stalker.customHeaders.value.trim().isNotEmpty ||
            state.stalker.allowSelfSignedTls;
        break;
      case LoginProviderType.xtream:
        final baseUrl = state.xtream.serverUrl.value.trim();
        final username = state.xtream.username.value.trim();
        final password = state.xtream.password.value.trim();
        data.addAll({
          'displayName': _deriveDisplayName(
            providerType: LoginProviderType.xtream,
            baseUrl: baseUrl,
          ),
          'baseUrl': baseUrl,
          'outputFormat': state.xtream.outputFormat,
          'allowSelfSignedTls': state.xtream.allowSelfSignedTls,
          'userAgent': state.xtream.userAgent.value,
          'customHeaders': state.xtream.customHeaders.value,
        });
        if (username.isNotEmpty) {
          secrets['username'] = username;
        }
        if (password.isNotEmpty) {
          secrets['password'] = password;
        }
        hasContent =
            baseUrl.isNotEmpty ||
            secrets.isNotEmpty ||
            state.xtream.userAgent.value.trim().isNotEmpty ||
            state.xtream.customHeaders.value.trim().isNotEmpty ||
            state.xtream.allowSelfSignedTls;
        break;
      case LoginProviderType.m3u:
        final playlistInput = state.m3u.inputMode == M3uInputMode.url
            ? state.m3u.playlistUrl.value
            : state.m3u.playlistFilePath.value;
        final trimmedPlaylist = playlistInput.trim();
        final epgUrl = state.m3u.epgUrl.value.trim();
        final username = state.m3u.username.value.trim();
        final password = state.m3u.password.value.trim();
        data.addAll({
          'displayName': _deriveDisplayName(
            providerType: LoginProviderType.m3u,
            playlistInput: trimmedPlaylist,
            fileName: state.m3u.fileName,
          ),
          'inputMode': state.m3u.inputMode.name,
          'autoUpdate': state.m3u.autoUpdate,
          'followRedirects': state.m3u.followRedirects,
          'allowSelfSignedTls': state.m3u.allowSelfSignedTls,
          'userAgent': state.m3u.userAgent.value,
          'customHeaders': state.m3u.customHeaders.value,
          'epgUrl': epgUrl,
          'fileName': state.m3u.fileName,
          'fileSizeBytes': state.m3u.fileSizeBytes,
        });
        if (trimmedPlaylist.isNotEmpty) {
          secrets['playlistInput'] = trimmedPlaylist;
        }
        if (username.isNotEmpty) {
          secrets['username'] = username;
        }
        if (password.isNotEmpty) {
          secrets['password'] = password;
        }
        hasContent =
            trimmedPlaylist.isNotEmpty ||
            epgUrl.isNotEmpty ||
            secrets.isNotEmpty ||
            state.m3u.userAgent.value.trim().isNotEmpty ||
            state.m3u.customHeaders.value.trim().isNotEmpty ||
            state.m3u.allowSelfSignedTls;
        break;
    }

    if (!hasContent) {
      return null;
    }

    _pruneEmptyData(data);
    _pruneEmptySecrets(secrets);
    data.putIfAbsent(
      'displayName',
      () => _fallbackDisplayName(state.providerType),
    );

    return LoginDraft(
      id: LoginDraftRepository.allocateId(),
      providerType: state.providerType,
      createdAt: timestamp,
      updatedAt: timestamp,
      data: data,
      secrets: secrets,
    );
  }

  String _deriveDisplayName({
    required LoginProviderType providerType,
    String? portalUrl,
    String? baseUrl,
    String? playlistInput,
    String? fileName,
  }) {
    switch (providerType) {
      case LoginProviderType.stalker:
        final value = portalUrl?.trim();
        if (value != null && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri != null && uri.host.isNotEmpty) {
            return uri.host;
          }
          return value;
        }
        break;
      case LoginProviderType.xtream:
        final value = baseUrl?.trim();
        if (value != null && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri != null && uri.host.isNotEmpty) {
            return uri.host;
          }
          return value;
        }
        break;
      case LoginProviderType.m3u:
        final trimmed = playlistInput?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          final uri = Uri.tryParse(trimmed);
          if (uri != null && uri.host.isNotEmpty) {
            return uri.host;
          }
          return trimmed;
        }
        if (fileName != null && fileName.isNotEmpty) {
          return fileName;
        }
        break;
    }
    return _fallbackDisplayName(providerType);
  }

  String _fallbackDisplayName(LoginProviderType providerType) {
    switch (providerType) {
      case LoginProviderType.stalker:
        return 'Stalker draft';
      case LoginProviderType.xtream:
        return 'Xtream draft';
      case LoginProviderType.m3u:
        return 'M3U draft';
    }
  }

  void _pruneEmptyData(Map<String, dynamic> map) {
    final removalKeys = <String>[];
    map.forEach((key, value) {
      if (value == null) {
        removalKeys.add(key);
      } else if (value is String && value.trim().isEmpty) {
        removalKeys.add(key);
      }
    });
    for (final key in removalKeys) {
      map.remove(key);
    }
  }

  void _pruneEmptySecrets(Map<String, String> map) {
    final removalKeys = <String>[];
    map.forEach((key, value) {
      if (value.trim().isEmpty) {
        removalKeys.add(key);
      }
    });
    for (final key in removalKeys) {
      map.remove(key);
    }
  }

  String _stalkerAuthFailureMessage(String raw) {
    if (raw.isEmpty) {
      return 'Portal rejected the handshake. Confirm the MAC address and account status.';
    }
    return 'Portal rejected the handshake. Confirm the MAC address and account status. ($raw)';
  }

  String _xtreamAuthFailureMessage(String raw) {
    if (raw.isEmpty) {
      return 'Credentials were rejected. Confirm your username and password with your provider.';
    }
    return 'Credentials were rejected. Confirm your username and password with your provider. ($raw)';
  }

  String _m3uFailureMessage(String raw) {
    if (raw.isEmpty) {
      return 'Playlist validation failed. Confirm the playlist URL or file and any credentials.';
    }
    return 'Playlist validation failed. Confirm the playlist URL or file and any credentials. ($raw)';
  }

  String _unexpectedErrorMessage(Object error) {
    final description = error.toString();
    if (description.isEmpty) {
      return 'Unexpected error encountered. Please try again.';
    }
    return 'Unexpected error encountered: $description';
  }

  String _describeNetworkError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet connection or try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Disable TLS overrides only if you trust the portal.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status != null) {
          return 'Portal responded with HTTP $status. Confirm the server address and credentials.';
        }
        return 'Portal responded unexpectedly. Confirm the server address and credentials.';
      case DioExceptionType.cancel:
        return 'Request was cancelled before completion.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the portal. Check your network connection or provider status.';
      case DioExceptionType.unknown:
        final underlying = error.error?.toString() ?? '';
        if (underlying.toLowerCase().contains('socket')) {
          return 'Unable to reach the portal. Check your network connection or provider status.';
        }
        return 'Unexpected network error. Please try again.';
    }
  }

  int? _estimateM3uChannelCount(String playlist) {
    final matches = RegExp(
      r'^\s*#EXTINF',
      multiLine: true,
    ).allMatches(playlist);
    if (matches.isEmpty) {
      return null;
    }
    return matches.length;
  }

  int? _estimateXmltvDaySpan(String xml) {
    final programmeRegex = RegExp(
      r'<programme[^>]*start="([^"]+)"[^>]*?(?:stop="([^"]+)")?',
      caseSensitive: false,
    );
    DateTime? earliest;
    DateTime? latest;
    for (final match in programmeRegex.allMatches(xml)) {
      final start = _parseXmltvDate(match.group(1));
      final stop = _parseXmltvDate(match.group(2));
      if (start != null) {
        final currentEarliest = earliest;
        if (currentEarliest == null || start.isBefore(currentEarliest)) {
          earliest = start;
        }
        final currentLatest = latest;
        if (currentLatest == null || start.isAfter(currentLatest)) {
          latest = start;
        }
      }
      if (stop != null) {
        final currentLatest = latest;
        if (currentLatest == null || stop.isAfter(currentLatest)) {
          latest = stop;
        }
      }
    }
    if (earliest == null || latest == null) {
      return null;
    }
    final span = latest.difference(earliest);
    if (span.inHours <= 0) {
      return 1;
    }
    final days = (span.inHours / 24).ceil();
    return days > 0 ? days : 1;
  }

  DateTime? _parseXmltvDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(RegExp(r'\s+'));
    final timestamp = parts.first;
    if (timestamp.length < 14) {
      return null;
    }
    final year = int.tryParse(timestamp.substring(0, 4));
    final month = int.tryParse(timestamp.substring(4, 6));
    final day = int.tryParse(timestamp.substring(6, 8));
    final hour = int.tryParse(timestamp.substring(8, 10));
    final minute = int.tryParse(timestamp.substring(10, 12));
    final second = int.tryParse(timestamp.substring(12, 14));
    if ([
      year,
      month,
      day,
      hour,
      minute,
      second,
    ].any((value) => value == null)) {
      return null;
    }
    var result = DateTime.utc(year!, month!, day!, hour!, minute!, second!);
    if (parts.length > 1) {
      var offset = parts[1].replaceAll(':', '');
      if (offset.isNotEmpty &&
          (offset.startsWith('+') || offset.startsWith('-'))) {
        final sign = offset.startsWith('-') ? -1 : 1;
        offset = offset.substring(1);
        if (offset.length >= 4) {
          final offsetHours = int.tryParse(offset.substring(0, 2)) ?? 0;
          final offsetMinutes = int.tryParse(offset.substring(2, 4)) ?? 0;
          final delta = Duration(hours: offsetHours, minutes: offsetMinutes);
          result = sign == 1 ? result.subtract(delta) : result.add(delta);
        }
      }
    }
    return result;
  }

  List<dynamic>? _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, val) {
        result[key.toString()] = val;
      });
      return result;
    }
    return null;
  }

  String? _extractXtreamStreamId(List<dynamic>? streams) {
    if (streams == null || streams.isEmpty) {
      return null;
    }
    final first = streams.first;
    final map = _asMap(first);
    if (map == null) {
      return first?.toString();
    }
    final id = map['stream_id'] ?? map['id'] ?? map['streamId'];
    return id?.toString();
  }

  int? _calculateXtreamEpgSpan(dynamic body) {
    final map = _asMap(body);
    if (map == null) {
      return null;
    }
    final listings =
        _asList(map['epg_listings']) ??
        _asList(map['epg_listings_list']) ??
        _asList(map['results']);
    if (listings == null || listings.isEmpty) {
      return null;
    }
    DateTime? earliest;
    DateTime? latest;
    for (final entry in listings) {
      final data = _asMap(entry);
      if (data == null) continue;
      final start = _parseXtreamDate(
        data['start'] ?? data['start_time'] ?? data['time'],
      );
      final stop = _parseXtreamDate(
        data['end'] ?? data['stop_time'] ?? data['stop'],
      );
      if (start != null) {
        final currentEarliest = earliest;
        if (currentEarliest == null || start.isBefore(currentEarliest)) {
          earliest = start;
        }
        final currentLatest = latest;
        if (currentLatest == null || start.isAfter(currentLatest)) {
          latest = start;
        }
      }
      if (stop != null) {
        final currentLatest = latest;
        if (currentLatest == null || stop.isAfter(currentLatest)) {
          latest = stop;
        }
      }
    }
    if (earliest == null || latest == null) {
      return null;
    }
    final span = latest.difference(earliest);
    if (span.inHours <= 0) {
      return 1;
    }
    final days = (span.inHours / 24).ceil();
    return days > 0 ? days : 1;
  }

  DateTime? _parseXtreamDate(dynamic raw) {
    if (raw == null) return null;
    var text = raw.toString().trim();
    if (text.isEmpty) return null;

    DateTime? attempt = DateTime.tryParse(text);
    if (attempt != null) {
      return attempt.toUtc();
    }

    text = text.replaceAll(' ', 'T');
    attempt = DateTime.tryParse(text);
    if (attempt != null) {
      return attempt.toUtc();
    }

    final offsetMatch = RegExp(r'([+\-]\d{2}:?\d{2})$').firstMatch(text);
    if (offsetMatch != null) {
      final offset = offsetMatch.group(1)!;
      final normalizedOffset = offset.contains(':')
          ? offset
          : '${offset.substring(0, 3)}:${offset.substring(3)}';
      final withOffset = text.replaceRange(
        offsetMatch.start,
        offsetMatch.end,
        normalizedOffset,
      );
      attempt = DateTime.tryParse(withOffset);
      if (attempt != null) {
        return attempt.toUtc();
      }
    }

    if (!text.endsWith('Z') && !RegExp(r'[+\-]\d{2}:?\d{2}$').hasMatch(text)) {
      attempt = DateTime.tryParse('${text}Z');
      if (attempt != null) {
        return attempt.toUtc();
      }
    }

    return null;
  }

  int? _extractStalkerChannelCount(dynamic body) {
    try {
      dynamic decoded = body;
      if (decoded is String) {
        final trimmed = decoded.trim();
        if (trimmed.isEmpty) {
          return null;
        }
        decoded = jsonDecode(trimmed);
      }
      final map = _asMap(decoded);
      if (map == null) {
        final list = _asList(decoded);
        return list?.length;
      }
      final js = _asMap(map['js']);
      if (js != null) {
        final total = js['total_items'];
        if (total is int) {
          return total;
        }
        if (total is String) {
          final parsed = int.tryParse(total);
          if (parsed != null) {
            return parsed;
          }
        }
        final dataList =
            _asList(js['data']) ??
            _asList(js['results']) ??
            _asList(js['channels']);
        if (dataList != null) {
          return dataList.length;
        }
      }
      final fallback = _asList(map['data']) ?? _asList(map['results']);
      return fallback?.length;
    } catch (error, stackTrace) {
      _logError('Stalker count parse error', error, stackTrace);
      return null;
    }
  }
}


