import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/presentation/screens/login_screen.dart';

import 'src/core/models/channel.dart';
import 'src/ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChannelAdapter());
  await Hive.openBox<Channel>('channels');

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
      if (!isLoggedIn) return loggingIn ? null : '/login';

      if (loggingIn) return '/';

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
