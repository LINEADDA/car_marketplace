import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_scaffold_with_nav.dart'; 
import '../../models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _profileService;
  Future<UserProfile?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _profileFuture = _profileService.getProfile(userId);
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'My Profile',
      currentRoute: '/profile',
      actions: [ 
        IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign Out', onPressed: _signOut),
        IconButton(icon: const Icon(Icons.settings_outlined), tooltip: 'Account Settings', onPressed: () => context.push('/profile/account-settings')),
      ],
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Could not load profile. Please set it up.'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => context.push('/profile/edit'), child: const Text('Setup Profile')),
              ]),
            );
          }
          final profile = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty ? NetworkImage(profile.avatarUrl!) : null,
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty ? const Icon(Icons.person, size: 50) : null,
              ),
              const SizedBox(height: 16),
              Center(child: Text(profile.fullName, style: Theme.of(context).textTheme.headlineSmall)),
              Center(child: Text(profile.role, style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(leading: const Icon(Icons.directions_car_outlined), title: const Text('My Cars'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/my-garage')),
              ListTile(leading: const Icon(Icons.build_circle_outlined), title: const Text('My Spare Parts'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/my-spare-parts')),
              ListTile(leading: const Icon(Icons.build_circle_outlined), title: const Text('My Repair Shops'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/my-repair-shops')),
              ListTile(leading: const Icon(Icons.work_history_outlined), title: const Text('My Job Activity'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/jobs/my-activity')),
              const Divider(),
              ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit Profile'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/profile/edit')),
            ],
          );
        },
      ),
    );
  }
}