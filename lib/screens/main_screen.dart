import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import 'vessel_list_screen.dart';
import 'sync_history_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    VesselListScreen(),
    SyncHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final totalPending = sync.adjustments.where((a) => !a.isSynced).length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE3F2FD),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.directions_boat_outlined),
              selectedIcon: Icon(Icons.directions_boat_rounded),
              label: 'Kapal',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: totalPending > 0,
                label: Text('$totalPending'),
                child: const Icon(Icons.sync_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: totalPending > 0,
                label: Text('$totalPending'),
                child: const Icon(Icons.sync_rounded),
              ),
              label: 'Sinkronisasi',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
