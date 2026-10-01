import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'note_list_screen.dart';
import 'profile_screen.dart';

/// Bottom navigation: Notes / Dashboard / Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const NoteListScreen(),
          // Not const on purpose, so it refreshes (e.g. new name) on tab switch.
          DashboardScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.mintDark,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined, color: AppTheme.forest),
            selectedIcon: Icon(Icons.description, color: AppTheme.forest),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppTheme.forest),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.forest),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppTheme.forest),
            selectedIcon: Icon(Icons.person, color: AppTheme.forest),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
