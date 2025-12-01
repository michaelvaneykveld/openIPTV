import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/src/player/summary_models.dart';
import 'package:openiptv/src/ui/live/live_tv_screen.dart';
import 'package:openiptv/src/ui/vod/vod_grid_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final ResolvedProviderProfile profile;

  const DashboardScreen({super.key, required this.profile});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              if (index == 5) {
                Navigator.of(context).pop();
                return;
              }
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.tv),
                label: Text('Live TV'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.movie),
                label: Text('Movies'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.video_library),
                label: Text('Series'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.radio),
                label: Text('Radio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
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
