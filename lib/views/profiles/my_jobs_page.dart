import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/job_posting.dart';
import '../../models/skilled_worker.dart';
import '../../models/user_profile.dart';
import '../../services/job_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../jobs/add_edit_job_posting_page.dart';
import '../jobs/add_edit_skilled_worker_page.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  late final ProfileService _profileService;
  late final JobService _jobService;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _jobService = JobService(Supabase.instance.client);
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final profile = await _profileService.getProfile(userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'My Job Activity'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile?.role == 'shop_owner'
              ? _buildShopOwnerView()
              : _buildWorkerView(),
    );
  }

  /// Fetches and displays job postings for a shop owner.
  Widget _buildShopOwnerView() {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditJobPostingPage()));
          if (result == true) {
            setState(() {});
          }
        },
      ),
      body: FutureBuilder<List<JobPosting>>(
        future: _jobService.getJobPostingsForOwner(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final postings = snapshot.data ?? [];

          if (postings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('You have not posted any jobs yet.\nTap the + button to create one.', textAlign: TextAlign.center),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              itemCount: postings.length,
              itemBuilder: (context, index) {
                final post = postings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(post.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(post.location),
                    trailing: Switch(
                      value: post.isActive,
                      onChanged: (value) => _toggleStatus(post),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () async {
                       final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditJobPostingPage(postingToEdit: post)));
                       if (result == true) {
                         setState(() {});
                       }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Displays the skilled worker profile for a regular user or driver.
  Widget _buildWorkerView() {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return FutureBuilder<SkilledWorker?>(
      future: _jobService.getSkilledWorkerForOwner(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final worker = snapshot.data;

        if (worker == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are not listed as available for hire.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    child: const Text('Create Your Worker Profile'),
                    onPressed: () async {
                       final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditSkilledWorkerPage()));
                       if (result == true) {
                         setState(() {});
                       }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Public Worker Profile', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(worker.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(worker.primarySkill),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditSkilledWorkerPage(workerToEdit: worker)));
                    if (result == true) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Toggles the 'is_active' status of a job posting.
  Future<void> _toggleStatus(JobPosting post) async {
    try {
      await _jobService.toggleJobPostingStatus(post.id, post.isActive);
      // Refresh the list to show the updated status
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}