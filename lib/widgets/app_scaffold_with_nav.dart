import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_app_bar.dart';

class ScaffoldWithNav extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;
  final bool showHomeIcon;
  final FloatingActionButton? floatingActionButton;
  final PreferredSizeWidget? tabs; 

  const ScaffoldWithNav({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
    this.showHomeIcon = true,
    this.floatingActionButton,
    this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        actions: actions,
        showHomeIcon: showHomeIcon,
        bottom: tabs,
      ),
      body: body,
      bottomNavigationBar: _buildBottomNav(context, currentRoute, isLoggedIn),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildBottomNav(BuildContext context, String currentRoute, bool isLoggedIn) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(currentRoute),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Cars'),
        BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: 'Parts'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Shops'),
        BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'You'),
      ],
      onTap: (index) => _handleNavTap(context, index, isLoggedIn),
    );
  }

  int _getCurrentIndex(String route) {
    if (route.startsWith('/cars')) return 0;
    if (route.startsWith('/spare-parts')) return 1;
    if (route.startsWith('/repair-shops')) return 2;
    if (route.startsWith('/jobs')) return 3;
    if (route.startsWith('/profile')) return 4;
    return 0;
  }

  void _handleNavTap(BuildContext context, int index, bool isLoggedIn) {
    final routes = ['/cars', '/spare-parts', '/repair-shops', '/jobs', '/profile'];
    
    if (index == 4 && !isLoggedIn) {
      context.push('/login');
      return;
    }
    
    context.go(routes[index]);
  }
}