import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/src/providers/login_flow_controller.dart';
import 'package:openiptv/src/providers/protocol_auth_providers.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_authenticator.dart';
import 'package:openiptv/src/protocols/stalker/stalker_authenticator.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/xtream/xtream_authenticator.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';

/// Formats user input into a canonical MAC address representation.
class MacAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^0-9A-F]'),
      '',
    );
    final buffer = StringBuffer();
    for (var i = 0; i < text.length && i < 12; i++) {
      if (i > 0 && i.isEven) {
        buffer.write(':');
      }
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _stalkerFormKey = GlobalKey<FormState>();
  final _xtreamFormKey = GlobalKey<FormState>();
  final _m3uFormKey = GlobalKey<FormState>();

  final _portalUrlController = TextEditingController();
  final _macAddressController = TextEditingController(text: '00:1A:79:');

  final _xtreamUrlController = TextEditingController();
  final _xtreamUsernameController = TextEditingController();
  final _xtreamPasswordController = TextEditingController();

  final _m3uInputController = TextEditingController();
  final _m3uUsernameController = TextEditingController();
  final _m3uPasswordController = TextEditingController();

  late final TabController _tabController;
  ProviderSubscription<LoginFlowState>? _flowSubscription;

  @override
  void initState() {
    super.initState();
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

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _indexForProvider(flow.providerType),
    );
    _tabController.addListener(_handleTabSelection);

    ref.listen<LoginFlowState>(loginFlowControllerProvider, (previous, next) {
      final nextIndex = _indexForProvider(next.providerType);
      if (_tabController.index != nextIndex &&
          !_tabController.indexIsChanging) {
        _tabController.index = nextIndex;
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
      final m3uInput = next.m3u.inputMode == M3uInputMode.url
          ? next.m3u.playlistUrl.value
          : next.m3u.playlistFilePath.value;
      final previousM3uInput = previous == null
          ? null
          : previous.m3u.inputMode == M3uInputMode.url
          ? previous.m3u.playlistUrl.value
          : previous.m3u.playlistFilePath.value;
      _syncControllerText(previousM3uInput, m3uInput, _m3uInputController);
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
    });
  }

  @override
  void dispose() {
    _flowSubscription?.close();
    _tabController
      ..removeListener(_handleTabSelection)
      ..dispose();
    _portalUrlController.dispose();
    _macAddressController.dispose();
    _xtreamUrlController.dispose();
    _xtreamUsernameController.dispose();
    _xtreamPasswordController.dispose();
    _m3uInputController.dispose();
    _m3uUsernameController.dispose();
    _m3uPasswordController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final controller = ref.read(loginFlowControllerProvider.notifier);
    controller.selectProvider(_providerForIndex(_tabController.index));
  }

  int _indexForProvider(LoginProviderType type) {
    switch (type) {
      case LoginProviderType.stalker:
        return 0;
      case LoginProviderType.xtream:
        return 1;
      case LoginProviderType.m3u:
        return 2;
    }
  }

  LoginProviderType _providerForIndex(int index) {
    switch (index) {
      case 0:
        return LoginProviderType.stalker;
      case 1:
        return LoginProviderType.xtream;
      default:
        return LoginProviderType.m3u;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(loginFlowControllerProvider);
    final isBusy = flowState.testProgress.inProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenIPTV Login'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stalker / Ministra'),
            Tab(text: 'Xtream Codes'),
            Tab(text: 'M3U / XMLTV'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (flowState.bannerMessage != null)
            Container(
              width: double.infinity,
              color: const Color.fromARGB(32, 244, 67, 54),
              padding: const EdgeInsets.all(12),
              child: Text(
                flowState.bannerMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStalkerLogin(context, flowState, isBusy),
                _buildXtreamLogin(context, flowState, isBusy),
                _buildM3uLogin(context, flowState, isBusy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStalkerLogin(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    final controller = ref.read(loginFlowControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _stalkerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provide the portal URL and the MAC address your provider registered.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portalUrlController,
              enabled: !isBusy,
              decoration: InputDecoration(
                labelText: 'Portal URL',
                hintText: 'http://portal.example.com',
                errorText: flowState.stalker.portalUrl.error,
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
            const SizedBox(height: 24),
            _buildActionButton(
              label: 'Handshake',
              isBusy: isBusy,
              onPressed: isBusy ? null : _handleStalkerLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXtreamLogin(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    final controller = ref.read(loginFlowControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _xtreamFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the base URL along with your Xtream username and password.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _xtreamUrlController,
              enabled: !isBusy,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://example.com:8080',
                errorText: flowState.xtream.serverUrl.error,
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
            const SizedBox(height: 24),
            _buildActionButton(
              label: 'Login',
              isBusy: isBusy,
              onPressed: isBusy ? null : _handleXtreamLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3uLogin(
    BuildContext context,
    LoginFlowState flowState,
    bool isBusy,
  ) {
    final controller = ref.read(loginFlowControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _m3uFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supply an M3U URL (or local path) and optional credentials.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _m3uInputController,
              enabled: !isBusy,
              decoration: InputDecoration(
                labelText: flowState.m3u.inputMode == M3uInputMode.url
                    ? 'M3U URL'
                    : 'M3U file path',
                errorText: flowState.m3u.inputMode == M3uInputMode.url
                    ? flowState.m3u.playlistUrl.error
                    : flowState.m3u.playlistFilePath.error,
              ),
              onChanged: (value) {
                if (flowState.m3u.inputMode == M3uInputMode.url) {
                  controller.updateM3uPlaylistUrl(value);
                } else {
                  controller.updateM3uPlaylistFilePath(value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _m3uUsernameController,
              enabled: !isBusy,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
              ),
              onChanged: controller.updateM3uUsername,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _m3uPasswordController,
              enabled: !isBusy,
              decoration: const InputDecoration(
                labelText: 'Password (optional)',
              ),
              obscureText: true,
              onChanged: controller.updateM3uPassword,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              label: 'Validate Playlist',
              onPressed: isBusy ? null : _handleM3uLogin,
              isBusy: isBusy,
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _handleStalkerLogin() async {
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    if (!flowController.validateActiveForm()) {
      flowController.setBannerMessage('Please review the highlighted fields.');
      return;
    }

    flowController.beginTestSequence(includeEpgStep: false);

    try {
      flowController.markStepActive(LoginTestStep.reachServer);
      final current = ref.read(loginFlowControllerProvider);
      var portalUrl = current.stalker.portalUrl.value.trim();
      if (!portalUrl.startsWith('http://') &&
          !portalUrl.startsWith('https://')) {
        portalUrl = 'http://$portalUrl';
      }
      portalUrl = portalUrl
          .replaceAll('/c/', '/')
          .replaceAll(RegExp(r'/+$'), '');

      final configuration = StalkerPortalConfiguration(
        baseUri: Uri.parse(portalUrl),
        macAddress: current.stalker.macAddress.value.trim(),
      );

      await ref.read(stalkerSessionProvider(configuration).future);

      flowController.markStepSuccess(LoginTestStep.reachServer);
      flowController.markStepSuccess(
        LoginTestStep.authenticate,
        message: 'Token acquired',
      );
      flowController.markStepSuccess(LoginTestStep.fetchChannels);
      flowController.markStepSuccess(LoginTestStep.saveProfile);
      flowController.resetTestProgress();
      flowController.setBannerMessage(null);
      _showSuccessSnackBar('Handshake succeeded. Token acquired.');
    } on StalkerAuthenticationException catch (error) {
      flowController.markStepFailure(
        LoginTestStep.authenticate,
        message: error.message,
      );
    } catch (error, stackTrace) {
      debugPrint('Stalker login error: $error\n$stackTrace');
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: error.toString(),
      );
    }
  }

  Future<void> _handleXtreamLogin() async {
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    if (!flowController.validateActiveForm()) {
      flowController.setBannerMessage('Please review the highlighted fields.');
      return;
    }

    flowController.beginTestSequence(includeEpgStep: true);

    try {
      flowController.markStepActive(LoginTestStep.reachServer);
      final current = ref.read(loginFlowControllerProvider);
      var baseUrl = current.xtream.serverUrl.value.trim();
      if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
        baseUrl = 'http://$baseUrl';
      }
      baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

      final configuration = XtreamPortalConfiguration(
        baseUri: Uri.parse(baseUrl),
        username: current.xtream.username.value.trim(),
        password: current.xtream.password.value.trim(),
      );

      await ref.read(xtreamSessionProvider(configuration).future);

      flowController.markStepSuccess(LoginTestStep.reachServer);
      flowController.markStepSuccess(LoginTestStep.authenticate);
      flowController.markStepSuccess(LoginTestStep.fetchChannels);
      flowController.markStepSuccess(LoginTestStep.fetchEpg);
      flowController.markStepSuccess(LoginTestStep.saveProfile);
      flowController.resetTestProgress();
      flowController.setBannerMessage(null);
      _showSuccessSnackBar('Xtream login success. Profile retrieved.');
    } on XtreamAuthenticationException catch (error) {
      flowController.markStepFailure(
        LoginTestStep.authenticate,
        message: error.message,
      );
    } catch (error, stackTrace) {
      debugPrint('Xtream login error: $error\n$stackTrace');
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: error.toString(),
      );
    }
  }

  Future<void> _handleM3uLogin() async {
    final flowController = ref.read(loginFlowControllerProvider.notifier);
    if (!flowController.validateActiveForm()) {
      flowController.setBannerMessage('Please review the highlighted fields.');
      return;
    }

    flowController.beginTestSequence(includeEpgStep: true);

    try {
      flowController.markStepActive(LoginTestStep.reachServer);
      final current = ref.read(loginFlowControllerProvider);
      final playlistInput = current.m3u.inputMode == M3uInputMode.url
          ? current.m3u.playlistUrl.value
          : current.m3u.playlistFilePath.value;
      final configuration = buildM3uConfiguration(
        portalId: 'm3u-${DateTime.now().millisecondsSinceEpoch}',
        playlistInput: playlistInput,
        username: current.m3u.username.value.trim().isEmpty
            ? null
            : current.m3u.username.value.trim(),
        password: current.m3u.password.value.trim().isEmpty
            ? null
            : current.m3u.password.value.trim(),
      );

      await ref.read(m3uXmlSessionProvider(configuration).future);

      flowController.markStepSuccess(LoginTestStep.reachServer);
      flowController.markStepSuccess(LoginTestStep.authenticate);
      flowController.markStepSuccess(LoginTestStep.fetchChannels);
      flowController.markStepSuccess(LoginTestStep.fetchEpg);
      flowController.markStepSuccess(LoginTestStep.saveProfile);
      flowController.resetTestProgress();
      flowController.setBannerMessage(null);
      _showSuccessSnackBar('Playlist validated successfully.');
    } on M3uXmlAuthenticationException catch (error) {
      flowController.markStepFailure(
        LoginTestStep.fetchChannels,
        message: error.message,
      );
    } catch (error, stackTrace) {
      debugPrint('M3U validation error: $error\n$stackTrace');
      flowController.markStepFailure(
        LoginTestStep.reachServer,
        message: error.toString(),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
