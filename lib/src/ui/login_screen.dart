import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
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
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
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
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              color: const Color.fromARGB(32, 244, 67, 54),
              padding: const EdgeInsets.all(12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStalkerLogin(context),
                _buildXtreamLogin(context),
                _buildM3uLogin(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStalkerLogin(BuildContext context) {
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
              decoration: const InputDecoration(
                labelText: 'Portal URL',
                hintText: 'http://portal.example.com',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a portal URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _macAddressController,
              decoration: const InputDecoration(
                labelText: 'MAC Address',
                hintText: '00:1A:79:12:34:56',
              ),
              inputFormatters: [MacAddressInputFormatter()],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a MAC address';
                }
                final macRegex =
                    RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
                if (!macRegex.hasMatch(value.trim())) {
                  return 'Enter a valid MAC address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              label: 'Handshake',
              onPressed: _isAuthenticating ? null : _handleStalkerLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXtreamLogin(BuildContext context) {
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
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://example.com:8080',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the Xtream base URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _xtreamUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _xtreamPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a password' : null,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              label: 'Login',
              onPressed: _isAuthenticating ? null : _handleXtreamLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3uLogin(BuildContext context) {
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
              decoration: const InputDecoration(
                labelText: 'M3U URL or file path',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an M3U source';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _m3uUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _m3uPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password (optional)',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              label: 'Validate Playlist',
              onPressed: _isAuthenticating ? null : _handleM3uLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: _isAuthenticating
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
    if (!_stalkerFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      var portalUrl = _portalUrlController.text.trim();
      if (!portalUrl.startsWith('http://') && !portalUrl.startsWith('https://')) {
        portalUrl = 'http://$portalUrl';
      }
      portalUrl = portalUrl.replaceAll('/c/', '/').replaceAll(RegExp(r'/+$'), '');

      final configuration = StalkerPortalConfiguration(
        baseUri: Uri.parse(portalUrl),
        macAddress: _macAddressController.text.trim(),
      );

      await ref.read(stalkerSessionProvider(configuration).future);

      _showSuccessSnackBar('Handshake succeeded. Token acquired.');
    } on StalkerAuthenticationException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error, stackTrace) {
      setState(() {
        _errorMessage = error.toString();
      });
      debugPrint('Stalker login error: $error\n$stackTrace');
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _handleXtreamLogin() async {
    if (!_xtreamFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      var baseUrl = _xtreamUrlController.text.trim();
      if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
        baseUrl = 'http://$baseUrl';
      }
      baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

      final configuration = XtreamPortalConfiguration(
        baseUri: Uri.parse(baseUrl),
        username: _xtreamUsernameController.text.trim(),
        password: _xtreamPasswordController.text.trim(),
      );

      await ref.read(xtreamSessionProvider(configuration).future);
      _showSuccessSnackBar('Xtream login success. Profile retrieved.');
    } on XtreamAuthenticationException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error, stackTrace) {
      setState(() {
        _errorMessage = error.toString();
      });
      debugPrint('Xtream login error: $error\n$stackTrace');
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _handleM3uLogin() async {
    if (!_m3uFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final configuration = buildM3uConfiguration(
        portalId: 'm3u-${DateTime.now().millisecondsSinceEpoch}',
        playlistInput: _m3uInputController.text,
        username: _m3uUsernameController.text.trim().isEmpty
            ? null
            : _m3uUsernameController.text.trim(),
        password: _m3uPasswordController.text.trim().isEmpty
            ? null
            : _m3uPasswordController.text.trim(),
      );

      await ref.read(m3uXmlSessionProvider(configuration).future);
      _showSuccessSnackBar('Playlist validated successfully.');
    } on M3uXmlAuthenticationException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error, stackTrace) {
      setState(() {
        _errorMessage = error.toString();
      });
      debugPrint('M3U validation error: $error\n$stackTrace');
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
