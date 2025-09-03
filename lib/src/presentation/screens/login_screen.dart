import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/models/credentials.dart'; // Import Credentials model (plural)
import 'package:openiptv/src/core/models/stalker_credentials.dart'; // Import StalkerCredentials
import 'package:openiptv/src/core/models/m3u_credentials.dart'; // Import M3uCredentials
import 'package:openiptv/src/core/models/xtream_credentials.dart'; // Import XtreamCredentials
import 'package:openiptv/src/data/xtream_api_service.dart'; // Import XtreamApiService

// Custom TextInputFormatter for MAC address
class MacAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    var newText = '';

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 2 == 0 && i < 12) {
        newText += ':';
      }
      newText += text[i];
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// Provider for saved credentials
final savedCredentialsProvider = FutureProvider<List<Credentials>>((ref) async {
  final credentialsRepository = ref.watch(credentialsRepositoryProvider);
  return credentialsRepository.getSavedCredentials();
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _portalUrlController = TextEditingController();
  final _macAddressController = TextEditingController(text: '00:1A:79:');
  bool _isLoading = false;

  final _xtreamUrlController = TextEditingController();
  final _xtreamUsernameController = TextEditingController();
  final _xtreamPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _xtreamUrlController.addListener(_parseXtreamUrl);
  }

  @override
  void dispose() {
    _portalUrlController.dispose();
    _macAddressController.dispose();
    _xtreamUrlController.removeListener(_parseXtreamUrl);
    _xtreamUrlController.dispose();
    _xtreamUsernameController.dispose();
    _xtreamPasswordController.dispose();
    super.dispose();
  }

  void _parseXtreamUrl() {
    final text = _xtreamUrlController.text;
    if (text.contains('get.php') && text.contains('username=') && text.contains('password=')) {
      try {
        final uri = Uri.parse(text);
        final username = uri.queryParameters['username'];
        final password = uri.queryParameters['password'];
        final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';

        if (username != null && password != null) {
          // This avoids getting into a loop
          _xtreamUrlController.removeListener(_parseXtreamUrl);
          setState(() {
            _xtreamUrlController.text = baseUrl;
            _xtreamUsernameController.text = username;
            _xtreamPasswordController.text = password;
          });
          _xtreamUrlController.addListener(_parseXtreamUrl);
        }
      } catch (e) {
        // Ignore parsing errors, the user might still be typing
        developer.log('Error parsing Xtream URL: $e', name: 'LoginScreen');
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final stalkerApi = ref.read(stalkerApiProvider);
      String portalUrl = _portalUrlController.text;
      final macAddress = _macAddressController.text;

      if (!portalUrl.startsWith('http://') && !portalUrl.startsWith('https://')) {
        portalUrl = 'http://$portalUrl';
      }

      // Sanitize portalUrl: remove '/c/' if present
      if (portalUrl.contains('/c/')) {
        portalUrl = portalUrl.replaceAll('/c/', '/');
      }

      developer.log('Attempting login with Portal URL: $portalUrl and MAC Address: $macAddress', name: 'LoginScreen');

      final success = await stalkerApi.login(portalUrl, macAddress);

      if (success) {
        // No need to save credential here, it's handled within stalkerApi.login
        // Invalidate the provider to refresh the list of saved credentials
        ref.invalidate(savedCredentialsProvider);

        if (mounted) {
          context.go('/');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _xtreamLogin() async {
    final xtreamUrl = _xtreamUrlController.text.trim();
    final xtreamUsername = _xtreamUsernameController.text.trim();
    final xtreamPassword = _xtreamPasswordController.text.trim();

    if (xtreamUrl.isEmpty || xtreamUsername.isEmpty || xtreamPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all Xtream login fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Create an instance of XtreamApiService with the provided URL
    final xtreamApi = XtreamApiService(xtreamUrl);

    developer.log('Attempting Xtream login with URL: $xtreamUrl, Username: $xtreamUsername', name: 'LoginScreen');

    final success = await xtreamApi.login(xtreamUsername, xtreamPassword);

    if (success) {
      final credentialsRepository = ref.read(credentialsRepositoryProvider);
      final newCredential = XtreamCredentials(
        id: xtreamUrl, // Using URL as ID for simplicity
        name: 'Xtream: $xtreamUsername', // User-friendly name
        url: xtreamUrl,
        username: xtreamUsername,
        password: xtreamPassword,
      );
      await credentialsRepository.saveCredential(newCredential);
      ref.invalidate(savedCredentialsProvider);

      if (mounted) {
        context.go('/');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xtream login failed. Please check your credentials and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCredential(Credentials credential) async {
    final credentialsRepository = ref.read(credentialsRepositoryProvider);
    await credentialsRepository.deleteCredential(credential.id); // Use credential.id for deletion
    ref.invalidate(savedCredentialsProvider); // Refresh the list
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credential deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedCredentialsAsyncValue = ref.watch(savedCredentialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Stalker Portal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Use SingleChildScrollView for scrollability
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _portalUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Portal URL',
                        hintText: 'portal.example.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a portal URL';
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
                      inputFormatters: [
                        MacAddressInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a MAC address';
                        }
                        final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
                        if (!macRegex.hasMatch(value)) {
                          return 'Please enter a valid MAC address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            child: const Text('Login'),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Xtream Login',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Form(
                // No GlobalKey for now, as validation is not yet implemented for Xtream
                child: Column(
                  children: [
                    TextFormField(
                      controller: _xtreamUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        hintText: 'http://your-xtream-url.com',
                      ),
                      // No validator for now
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _xtreamUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'your_username',
                      ),
                      // No validator for now
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _xtreamPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'your_password',
                      ),
                      obscureText: true, // Hide password
                      // No validator for now
                    ),
                    const SizedBox(height: 32),
                    // New Xtream Login Button (will add _xtreamLogin method later)
                    ElevatedButton(
                      onPressed: _xtreamLogin,
                      child: const Text('Xtream Login'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Saved Logins',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              savedCredentialsAsyncValue.when(
                data: (credentials) {
                  if (credentials.isEmpty) {
                    return const Text('No saved logins.');
                  }
                  return ListView.builder(
                    shrinkWrap: true, // Important for nested ListView in SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                    itemCount: credentials.length,
                    itemBuilder: (context, index) {
                      final credential = credentials[index];
                      String displayUrl = '';
                      String displayMac = '';

                      if (credential is StalkerCredentials) {
                        displayUrl = credential.baseUrl;
                        displayMac = credential.macAddress;
                      } else if (credential is M3uCredentials) {
                        displayUrl = credential.m3uUrl; // Changed to m3uUrl
                        displayMac = 'N/A'; // M3U doesn't have MAC address
                      } else if (credential is XtreamCredentials) {
                        final xtreamCred = credential; // Explicit cast
                        displayUrl = xtreamCred.url;
                        displayMac = xtreamCred.username; // Display username for Xtream
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(displayUrl),
                          subtitle: Text(displayMac),
                          onTap: () {
                            if (credential is StalkerCredentials) {
                              _portalUrlController.text = credential.baseUrl;
                              _macAddressController.text = credential.macAddress;
                            } else if (credential is M3uCredentials) {
                              _portalUrlController.text = credential.m3uUrl; // Changed to m3uUrl
                              _macAddressController.text = ''; // Clear MAC for M3U
                            } else if (credential is XtreamCredentials) {
                              final xtreamCred = credential; // Explicit cast
                              _xtreamUrlController.text = xtreamCred.url;
                              _xtreamUsernameController.text = xtreamCred.username;
                              _xtreamPasswordController.text = xtreamCred.password;
                            }
                            // Optionally, trigger login automatically or let user click login button
                            // _login();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCredential(credential),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error loading saved logins: ${err.toString()}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
