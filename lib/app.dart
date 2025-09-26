import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/home/home_page.dart';
import 'views/jobs/add_edit_skilled_worker_page.dart';
import 'views/jobs/skilled_worker_detail_page.dart';
import 'views/profiles/profile_page.dart';
import 'views/profiles/edit_profile_page.dart';
import 'views/profiles/account_settings_page.dart';
import 'views/profiles/my_garage_page.dart';
import 'views/profiles/my_spare_parts.dart';
import 'views/profiles/my_repair_shop_page.dart';
import 'views/profiles/my_jobs_page.dart';
import 'views/cars/car_detail_page.dart';
import 'views/cars/cars_browse_page.dart';
import 'views/cars/add_edit_car_page.dart';
import 'views/jobs/job_listing_type_page.dart';
import 'views/jobs/job_posting_detail_page.dart';
import 'views/jobs/add_edit_job_posting_page.dart';
import 'views/repair_shops/add_edit_repair_shop_page.dart';
import 'views/repair_shops/repair_shop_detail_page.dart';
import 'views/repair_shops/repair_shop_list_page.dart';
import 'views/repair_shops/service_detail_page.dart';
import 'views/spare_parts/spare_part_detail_page.dart';
import 'views/spare_parts/spare_part_list_page.dart';
import 'views/spare_parts/add_edit_spare_part_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
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
          //////////////////////////////////////////////////////////////////////////////////////
          GoRoute(
            path: '/cars/browse',
            builder: (context, state) => const CarsBrowsePage(),
          ),
          GoRoute(
            path: '/cars/add',
            builder: (context, state) => const AddEditCarPage(),
          ),
          GoRoute(
            path: '/cars/:id',
            builder: (context, state) {
              final carId = state.pathParameters['id']!;
              return CarDetailPage(carId: carId);
            },
          ),
          GoRoute(
            path: '/cars/edit/:id',
            builder:
                (context, state) =>
                    AddEditCarPage(carId: state.pathParameters['id']!),
          ),
          //////////////////////////////////////////////////////////////////////////////////////
          GoRoute(
            path: '/spare-parts',
            builder: (context, state) => const SparePartListPage(),
          ),
          GoRoute(
            path: '/spare-parts/add',
            builder: (context, state) => const AddEditSparePartPage(),
          ),
          GoRoute(
            path: '/spare-parts/:id',
            builder:
                (context, state) =>
                    SparePartDetailPage(partId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/spare-parts/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddEditSparePartPage(partId: id);
            },
          ),
          //////////////////////////////////////////////////////////////////////////////////////
          GoRoute(
            path: '/repair-shops',
            builder: (context, state) => const RepairShopListPage(),
          ),
          GoRoute(
            path: '/repair-shop/add',
            builder: (context, state) => const AddEditRepairShopPage(),
          ),
          GoRoute(
            path: '/repair-shops/:id',
            builder:
                (context, state) =>
                    RepairShopDetailPage(shopId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/repair-shops/edit/:id',
            builder:
                (context, state) =>
                    AddEditRepairShopPage(shopId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/service-detail/:id',
            builder: (context, state) {
              final service = state.pathParameters['id']!;
              return ServiceDetailPage(serviceId: service);
            },
          ),
          //////////////////////////////////////////////////////////////////////////////////////
          GoRoute(
            path: '/jobs',
            builder: (context, state) => const JobListingTypePage(),
          ),
          GoRoute(
            path: '/jobs/postings/add',
            builder: (context, state) => const AddEditJobPostingPage(),
          ),
          GoRoute(
            path: '/jobs/postings/edit/:id',
            builder:
                (context, state) => AddEditJobPostingPage(
                  postingId: state.pathParameters['id']!,
                ),
          ),
          GoRoute(
            path: '/jobs/postings/:id',
            builder:
                (context, state) => JobPostingDetailPage(
                  postingId: state.pathParameters['id']!,
                ),
          ),
          /////////////
          GoRoute(
            path: '/jobs/skilled-workers/add',
            builder: (context, state) => const AddEditSkilledWorkerPage(),
          ),
          GoRoute(
            path: '/jobs/skilled-workers/edit/:id',
            builder:
                (context, state) => AddEditSkilledWorkerPage(
                  workerId: state.pathParameters['id']!,
                ),
          ),
          GoRoute(
            path: '/jobs/skilled-workers/:id',
            builder:
                (context, state) => SkilledWorkerDetailPage(
                  workerId: state.pathParameters['id']!,
                ),
          ),
          //////////////////////////////////////////////////////////////////////////////////////
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
            path: '/my-garage',
            builder: (context, state) => const MyGaragePage(),
          ),
          GoRoute(
            path: '/my-spare-parts',
            builder: (context, state) => const MySparePartsPage(),
          ),
          GoRoute(
            path: '/my-repair-shops',
            builder: (context, state) => const MyRepairShopPage(),
          ),
          GoRoute(
            path: '/jobs/my-jobs-activity',
            builder: (context, state) => const MyJobListingPage(),
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
