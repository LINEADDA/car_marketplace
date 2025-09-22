import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/job_posting.dart';
import '../../models/skilled_worker.dart';
import '../../services/job_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class MyJobListingPage extends StatefulWidget {
  const MyJobListingPage({super.key});

  @override
  State<MyJobListingPage> createState() => _MyJobListingPageState();
}

class _MyJobListingPageState extends State<MyJobListingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final JobService _jobService;
  late Future<List<JobPosting>> _jobPostingsFuture;
  late Future<List<SkilledWorker>> _skilledWorkersFuture;
  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _jobService = JobService(Supabase.instance.client);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _jobPostingsFuture = _jobService.getMyJobPostings(currentUserId!);
      _skilledWorkersFuture = _jobService.getMySkilledWorkers(currentUserId!);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'My Jobs and Applications',
      currentRoute: '/jobs/my-jobs-activity',
      tabs: TabBar(
        controller: _tabController,
        tabs: const [Tab(text: 'My Job Postings'), Tab(text: 'My Job Applications')],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobPostingsList(_jobPostingsFuture),
          _buildWorkersList(_skilledWorkersFuture),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/jobs/postings/add');
          } else {
            context.push('/jobs/skilled-workers/add');
          }
        },
        tooltip: 'Add New',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJobPostingsList(Future<List<JobPosting>> jobsFuture) {
    return FutureBuilder<List<JobPosting>>(
      future: jobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No jobs available.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/jobs/postings/add'),
                  child: const Text('Add Job Posting'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.business_center, size: 40),
                  title: Text(
                    job.jobTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(job.jobType),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') {
                        context.push('/jobs/postings/${job.id}');
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/jobs/postings/${job.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWorkersList(Future<List<SkilledWorker>> workersFuture) {
    return FutureBuilder<List<SkilledWorker>>(
      future: workersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final workers = snapshot.data ?? [];
        if (workers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No Application available.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/jobs/skilled-workers/add'),
                  child: const Text('Add Application'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.person, size: 40),
                  title: Text(
                    worker.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(worker.primarySkill),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') {
                        context.push('/jobs/skilled-workers/${worker.id}');
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/jobs/skilled-workers/${worker.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}