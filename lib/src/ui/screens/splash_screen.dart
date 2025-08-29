
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/api_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final apiProvider = ref.read(stalkerApiProvider);
      await apiProvider.syncAllDataIfNeeded();
      
      // Navigate to the home screen on success.
      // Ensure you have a route named '/home' in your GoRouter configuration.
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // Handle error appropriately in a real app (e.g., show a dialog)
      debugPrint("Error during data synchronization: $e");
      // Optionally, navigate to an error screen or show a retry button.
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
