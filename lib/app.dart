import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'views/home/home_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
// import 'views/cars/car_list_page.dart';
// import 'views/repair_shops/repair_shop_list_page.dart';
// import 'views/spare_parts/spare_part_list_page.dart';
// import 'views/profiles/profile_page.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    // GoRoute(path: '/cars', builder: (context, state) => const CarListPage()),
    // GoRoute(path: '/repair-shops', builder: (context, state) => const RepairShopListPage()),
    // GoRoute(path: '/spare-parts', builder: (context, state) => const SparePartListPage()),
    // GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CarXchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
    );
  }
}
