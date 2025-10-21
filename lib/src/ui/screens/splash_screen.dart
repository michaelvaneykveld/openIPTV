
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/application/services/channel_sync_service.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/utils/app_logger.dart';

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
      final credentialsRepository = ref.read(credentialsRepositoryProvider);
      final credentials = await credentialsRepository.getSavedCredentials();

      if (!mounted) return;

      if (credentials.isEmpty) {
        context.go('/login');
        return;
      }

      final channelSyncService = ref.read(channelSyncServiceProvider);
      final dbHelper = DatabaseHelper.instance;

      for (final credential in credentials) {
        final portalId = credential.id;
        final hasChannelData = await _hasAnyData(dbHelper, portalId);

        if (!hasChannelData) {
          await channelSyncService.syncChannels(portalId);
        }
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e, stackTrace) {
      appLogger.e('Error during data synchronization', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<bool> _hasAnyData(DatabaseHelper dbHelper, String portalId) async {
    try {
      final List<Map<String, dynamic>> existingChannels = await dbHelper.getAllChannels(portalId);
      if (existingChannels.isNotEmpty) {
        return true;
      }
      final vodCategories = await dbHelper.getAllVodCategories(portalId);
      return vodCategories.isNotEmpty;
    } catch (e, stackTrace) {
      appLogger.w('Failed to read cached data for portal $portalId: $e', stackTrace: stackTrace);
      return false;
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
