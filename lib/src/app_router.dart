import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/presentation/screens/login_screen.dart';
import 'package:openiptv/src/ui/home_screen.dart';
import 'package:openiptv/src/ui/screens/channel_manager_screen.dart';
import 'package:openiptv/src/ui/screens/debug_screen.dart';
import 'package:openiptv/src/ui/screens/player_screen.dart';
import 'package:openiptv/src/ui/screens/recording_center_screen.dart';
import 'package:openiptv/src/ui/screens/reminder_center_screen.dart';
import 'package:openiptv/src/ui/screens/sync_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final credentialsAsync = ref.watch(credentialsProvider);

  return credentialsAsync.when(
    data: (credentials) => GoRouter(
      initialLocation: credentials.isNotEmpty ? '/home' : '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/player',
          builder: (context, state) =>
              PlayerScreen(channel: state.extra as Channel),
        ),
        GoRoute(
          path: '/debug',
          builder: (context, state) => const DebugScreen(),
        ),
        GoRoute(
          path: '/channels/manage',
          builder: (context, state) => const ChannelManagerScreen(),
        ),
        GoRoute(
          path: '/recordings',
          builder: (context, state) => const RecordingCenterScreen(),
        ),
        GoRoute(
          path: '/reminders',
          builder: (context, state) => const ReminderCenterScreen(),
        ),
        GoRoute(
          path: '/settings/sync',
          builder: (context, state) => const SyncSettingsScreen(),
        ),
      ],
    ),
    loading: () => GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (context, state) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ],
    ),
    error: (error, stack) => GoRouter(
      initialLocation: '/error',
      routes: [
        GoRoute(
          path: '/error',
          builder: (context, state) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
        ),
      ],
    ),
  );
});
