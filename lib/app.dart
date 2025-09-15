import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import all your page widgets
import 'views/home/home_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/cars/car_list_page.dart';
import 'views/jobs/job_listing_type_page.dart'; // Make sure you have this page
import 'views/repair_shops/repair_shop_list_page.dart';
import 'views/spare_parts/spare_part_list_page.dart';
import 'views/profiles/profile_page.dart';

// Helper class to make GoRouter react to auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }
}

// Main application widget
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;

    _router = GoRouter(
      refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
        GoRoute(path: '/cars', builder: (context, state) => const CarListPage()),
        GoRoute(path: '/repair-shops', builder: (context, state) => const RepairShopListPage()),
        GoRoute(path: '/spare-parts', builder: (context, state) => const SparePartListPage()),
        GoRoute(path: '/jobs', builder: (context, state) => const JobListingTypePage()), // Added /jobs route
        GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final bool loggedIn = supabase.auth.currentUser != null;
        final bool isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

        // --- NEW AND IMPROVED LOGIC ---
        // 1. Define all your public routes that anyone can access.
        final publicRoutes = ['/', '/login', '/signup', '/cars', '/repair-shops', '/spare-parts', '/jobs'];

        // 2. Check if the user is trying to access a route that is NOT public.
        final isTryingToAccessProtectedRoute = !publicRoutes.contains(state.matchedLocation);

        // 3. If the user is not logged in and is trying to access a protected route,
        //    redirect them to the login page.
        if (!loggedIn && isTryingToAccessProtectedRoute) {
          return '/login';
        }

        // 4. If a logged-in user tries to go to the login/signup page,
        //    redirect them to the home page.
        if (loggedIn && isLoggingIn) {
          return '/';
        }

        // For all other cases, allow the navigation.
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CarXchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: _router,
    );
  }
}