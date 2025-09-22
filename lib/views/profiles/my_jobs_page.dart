import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not launch dialer.')));
    }
  }

  Future<void> _launchMap(String location) async {
    final Uri launchUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open map.')));
    }
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
          return const Center(child: Text('No jobs available'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final theme = Theme.of(context);

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                color: theme.colorScheme.primaryContainer.withAlpha(128),
                child: InkWell(
                  onTap: () => context.push('/jobs/postings/${job.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildOptionIcon(Icons.business_center, theme),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.jobTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildInfoChip(Icons.work_outline, job.jobType),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildInfoChip(
                                      Icons.location_on_outlined,
                                      job.location,
                                      onTap: () => _launchMap(job.location)),
                                  _buildInfoChip(
                                      Icons.phone_outlined,
                                      job.contactNumber,
                                      onTap: () => _launchDialer(job.contactNumber)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
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
          return const Center(child: Text('No workers available'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              final theme = Theme.of(context);

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                color: theme.colorScheme.primaryContainer.withAlpha(128),
                child: InkWell(
                  onTap: () =>
                      context.push('/jobs/skilled-workers/${worker.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildOptionIcon(Icons.person, theme),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                worker.fullName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildInfoChip(Icons.work_outline,
                                  worker.primarySkill),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildInfoChip(
                                      Icons.location_on_outlined,
                                      worker.location,
                                      onTap: () => _launchMap(worker.location)),
                                  _buildInfoChip(
                                      Icons.phone_outlined,
                                      worker.contactNumber,
                                      onTap: () =>
                                          _launchDialer(worker.contactNumber)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOptionIcon(IconData icon, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: theme.colorScheme.primaryContainer,
        child: Icon(icon, size: 40, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}