import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/user_avatar.dart';
import '../cars/car_list_page.dart';
import '../repair_shops/my_repair_shop_page.dart';
import '../spare_parts/spare_part_list_page.dart';
import 'edit_profile_page.dart';
import 'my_jobs_page.dart';
import 'account_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _profileService;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _profileService.getProfile(user.id);
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load profile: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

 Future<void> _logout() async {
    Object? error;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      error = e;
    }

    if (!mounted) return; // guard
    final router = GoRouter.of(context); // capture router

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }

    router.go('/');
  }



  void _navigateToEditProfile() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditProfilePage(profile: _userProfile),
          ),
        )
        .then((result) {
      if (result == true) {
        _fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(title: 'My Profile'),
        body: _buildBody(),
      );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Your profile isn't set up yet."),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToEditProfile,
              child: const Text('Create Profile'),
            ),
          ],
        ),
      );
    }

    final profile = _userProfile!;
    final isShopOwner = profile.role == 'shop_owner';
    final jobsTitle = isShopOwner ? 'Manage Hiring' : 'My Worker Profile';

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          Column(
            children: [
              UserAvatar(profile: profile, radius: 50),
              const SizedBox(height: 16),
              Text(
                profile.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                Supabase.instance.client.auth.currentUser?.email ?? '',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Menu
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _navigateToEditProfile,
          ),

          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Account Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('My Garage'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CarListPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('My Spare Parts'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SparePartListPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.work_history_outlined),
            title: Text(jobsTitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyJobsPage()),
              );
            },
          ),

          if (isShopOwner)
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Manage My Shop'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyRepairShopPage(),
                  ),
                );
              },
            ),

          const Divider(),

          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[700]),
            title: Text('Logout', style: TextStyle(color: Colors.red[700])),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}