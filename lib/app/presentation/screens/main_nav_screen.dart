import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/presentation/screens/admin_dashboard_screen.dart';
import 'package:duniakopi_project/app/presentation/screens/home_screen.dart';
import 'package:duniakopi_project/app/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    return userRole.when(
      data: (role) {
        final bool isAdmin = role == 'admin';

        final List<Widget> pages = [
          const HomeScreen(),
          const ProfileScreen(),
          if (isAdmin) const AdminDashboardScreen(),
        ];

        final List<BottomNavigationBarItem> items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Toko',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              label: 'Admin',
            ),
        ];
        
        if (_selectedIndex >= pages.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: items,
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            onTap: _onItemTapped,
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => const Scaffold(body: Center(child: Text("Gagal memuat data user."))),
    );
  }
}

