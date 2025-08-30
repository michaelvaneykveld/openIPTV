import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/presentation/screens/login_screen.dart';
import 'package:openiptv/src/ui/home_screen.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/data/stalker_api_service.dart';
import 'package:openiptv/src/data/stalker_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DatabaseHelper
  final databaseHelper = DatabaseHelper.instance;

  // Initialize StalkerApiService with a base URL
  // IMPORTANT: Replace with your actual Stalker Portal base URL
  final stalkerApiService = StalkerApiService('http://your-stalker-portal-url.com'); 

  // Initialize StalkerRepository
  final stalkerRepository = StalkerRepository(stalkerApiService, databaseHelper);

  // Trigger data synchronization
  await stalkerRepository.synchronizeData();
  

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final _routerProvider = Provider<GoRouter>((ref) {
  final credentialsRepository = ref.watch(credentialsRepositoryProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
    redirect: (context, state) async {
      final savedCredentials = await credentialsRepository.getSavedCredentials();
      final isLoggedIn = savedCredentials.isNotEmpty; // Check if any credentials exist

      final loggingIn = state.matchedLocation == '/login';

      // If not logged in, always go to login screen (unless already there)
      if (!isLoggedIn) {
        return loggingIn ? null : '/login';
      }

      // If logged in, and trying to go to login screen, don't redirect.
      // This allows the user to explicitly go to the login screen even if logged in (e.g., for logout).
      if (loggingIn) {
        return null; // Allow navigation to /login
      }

      // If logged in and trying to go to root, allow it.
      if (state.matchedLocation == '/') {
        return null; // Allow navigation to /
      }

      // Otherwise, no redirect needed.
      return null;
    },
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'OpenIPTV',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
