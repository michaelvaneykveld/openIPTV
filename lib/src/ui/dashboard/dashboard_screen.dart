import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/ui/live/live_tv_screen.dart';
import 'package:openiptv/src/ui/vod/vod_grid_screen.dart';
import 'package:openiptv/src/ui/dashboard/portal_info_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final ResolvedProviderProfile profile;

  const DashboardScreen({super.key, required this.profile});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isRefreshing = false;

  Future<void> _refreshPortal() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // TODO: Implement portal refresh logic
      // This should fetch the latest playlist/categories from the provider
      await Future.delayed(const Duration(seconds: 2)); // Placeholder

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portal refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showPortalInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: PortalInfoCard(profile: widget.profile),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              if (index == 5) {
                // Info button
                _showPortalInfo();
                return;
              }
              if (index == 6) {
                // Refresh button
                _refreshPortal();
                return;
              }
              if (index == 7) {
                // Back button
                Navigator.of(context).pop();
                return;
              }
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: <NavigationRailDestination>[
              const NavigationRailDestination(
                icon: Icon(Icons.tv),
                label: Text('Live TV'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.movie),
                label: Text('Movies'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.video_library),
                label: Text('Series'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.radio),
                label: Text('Radio'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: Text('Info'),
              ),
              NavigationRailDestination(
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.arrow_back),
                label: Text('Back'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return LiveTvScreen(profile: widget.profile);
      case 1:
        return VodGridScreen(profile: widget.profile, type: 'movie');
      case 2:
        return VodGridScreen(profile: widget.profile, type: 'series');
      case 3:
        return LiveTvScreen(
          profile: widget.profile,
          categoryKind: CategoryKind.radio,
        );
      case 4:
        return const Center(child: Text('Settings Placeholder'));
      default:
        return const SizedBox.shrink();
    }
  }
}
