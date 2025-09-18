import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/home/home_page.dart';
import 'views/profiles/my_garage_page.dart';
import 'views/profiles/profile_page.dart';
import 'views/profiles/edit_profile_page.dart';
import 'views/profiles/account_settings_page.dart';
import 'views/cars/car_listing_type_page.dart';
import 'views/cars/car_list_page.dart';
import 'views/cars/car_detail_page.dart';
import 'views/cars/cars_browse_page.dart';
import 'views/cars/add_edit_car_page.dart';
import 'views/jobs/job_listing_type_page.dart';
import 'views/jobs/job_postings_list_page.dart';
import 'views/jobs/skilled_workers_list_page.dart';
import 'views/jobs/job_posting_detail_page.dart';
import 'views/profiles/my_jobs_page.dart';
import 'views/jobs/add_edit_job_posting_page.dart';
import 'views/spare_parts/spare_part_detail_page.dart';
import 'views/spare_parts/spare_part_list_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Car Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupPage(),
          ),
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/cars',
            builder: (context, state) => const CarListingTypePage(),
          ),
          GoRoute(
            path: '/cars/browse',
            builder: (context, state) => const CarsBrowsePage(),
          ),
          GoRoute(
            path: '/cars/sale',
            builder: (context, state) => const CarListPage(isForSale: true),
          ),
          GoRoute(
            path: '/cars/booking',
            builder: (context, state) => const CarListPage(isForSale: false),
          ),
          GoRoute(
            path: '/cars/add',
            builder: (context, state) => const AddEditCarPage(),
          ),
          GoRoute(
            path: '/cars/edit/:id',
            builder:
                (context, state) =>
                    AddEditCarPage(carId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/cars/:id',
            builder: (context, state) {
              final carId = state.pathParameters['id']!;
              return CarDetailPage(carId: carId);
            },
          ),
          GoRoute(
            path: '/jobs',
            builder: (context, state) => const JobListingTypePage(),
          ),
          GoRoute(
            path: '/jobs/postings',
            builder: (context, state) => const JobPostingsListPage(),
          ),
          GoRoute(
            path: '/jobs/skilled-workers',
            builder: (context, state) => const SkilledWorkersListPage(),
          ),
          GoRoute(
            path: '/jobs/postings/:id',
            builder:
                (context, state) => JobPostingDetailPage(
                  postingId: state.pathParameters['id']!,
                ),
          ),
          GoRoute(
            path: '/jobs/postings/add',
            builder: (context, state) => const AddEditJobPostingPage(),
          ),
          GoRoute(
            path: '/spare-parts',
            builder: (context, state) => const SparePartListPage(),
          ),
          GoRoute(
            path: '/spare-parts/:id',
            builder:
                (context, state) =>
                    SparePartDetailPage(partId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/my-garage',
            builder: (context, state) => const MyGaragePage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const EditProfilePage(),
          ),
          GoRoute(
            path: '/profile/settings',
            builder: (context, state) => const AccountSettingsPage(),
          ),
          GoRoute(
            path: '/jobs/my-activity',
            builder: (context, state) => const MyJobsPage(),
          ),
        ],

        redirect: (context, state) {
          final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
          final isAuthRoute =
              state.matchedLocation == '/login' ||
              state.matchedLocation == '/signup';

          if (isLoggedIn && isAuthRoute) {
            return '/';
          }

          return null;
        },
      ),
    );
  }
}