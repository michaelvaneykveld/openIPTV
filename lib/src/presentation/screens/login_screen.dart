import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'package:openiptv/src/application/providers/api_provider.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/models/credential.dart'; // Import Credential model

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
final savedCredentialsProvider = FutureProvider<List<Credential>>((ref) async {
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

  @override
  void dispose() {
    _portalUrlController.dispose();
    _macAddressController.dispose();
    super.dispose();
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
        portalUrl = 'http://' + portalUrl;
      }

      // Sanitize portalUrl: remove '/c/' if present
      if (portalUrl.contains('/c/')) {
        portalUrl = portalUrl.replaceAll('/c/', '/');
      }

      developer.log('Attempting login with Portal URL: $portalUrl and MAC Address: $macAddress', name: 'LoginScreen');

      final token = await stalkerApi.login(portalUrl, macAddress);

      if (token != null) {
        final credentialsRepository = ref.read(credentialsRepositoryProvider);
        // Save the newly logged-in credential
        await credentialsRepository.saveCredential(Credential(portalUrl: portalUrl, macAddress: macAddress));
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

  Future<void> _deleteCredential(Credential credential) async {
    final credentialsRepository = ref.read(credentialsRepositoryProvider);
    await credentialsRepository.deleteCredential(credential);
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
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(credential.portalUrl),
                          subtitle: Text(credential.macAddress),
                          onTap: () {
                            _portalUrlController.text = credential.portalUrl;
                            _macAddressController.text = credential.macAddress;
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
