import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final bool showDrawer;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      drawer: showDrawer ? _buildDrawer(context) : null,
      body: body,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vigil',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Safety Companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            route: '/home',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Guardian View',
            route: '/guardian-view',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.map_outlined,
            title: 'Geofence View',
            route: '/geofence',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.security,
            title: 'Risk Monitoring',
            route: '/risk-monitoring',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'Alert History',
            route: '/alert-history',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_add,
            title: 'Trusted Circle',
            route: '/trusted-circle',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile Setup',
            route: '/profile-setup',
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy & Permissions',
            route: '/privacy',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            route: '/login',
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isLogout = false,
  }) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (isLogout) {
          // Show confirmation dialog for logout
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    context.go('/login');
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        } else {
          context.go(route);
        }
      },
    );
  }
}
