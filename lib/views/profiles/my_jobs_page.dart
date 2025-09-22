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

  List<JobPosting> _jobPostings = [];
  List<SkilledWorker> _skilledWorkers = [];

  bool _isLoading = true;
  String? _error;

  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _jobService = JobService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobs = await _jobService.getMyJobPostings(currentUserId!);
      final workers = await _jobService.getMySkilledWorkers(currentUserId!);
      if (!mounted) return;
      setState(() {
        _jobPostings = jobs;
        _skilledWorkers = workers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load data: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _deleteJobPosting(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Job Posting'),
            content: const Text(
              'Are you sure you want to delete this job posting?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirm == true) {
      try {
        await _jobService.deleteJobPosting(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posting deleted successfully')),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete job posting: $e')),
        );
      }
    }
  }

  Future<void> _deleteSkilledWorker(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Skilled Worker'),
            content: const Text('Are you sure you want to delete this worker?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirm == true) {
      try {
        await _jobService.deleteSkilledWorker(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker deleted successfully')),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete worker: $e')));
      }
    }
  }

  void _navigateToAddEditJobPosting({JobPosting? posting}) async {
    await context.push(
      posting == null
          ? '/jobs/postings/add'
          : '/jobs/postings/edit/${posting.id}',
    );
    if (!mounted) return;
    _loadData();
  }

  void _navigateToAddEditSkilledWorker({SkilledWorker? worker}) async {
    await context.push(
      worker == null
          ? '/jobs/skilled-workers/add'
          : '/jobs/skilled-workers/edit/${worker.id}',
    );
    if (!mounted) return;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildJobPostingCard(JobPosting job) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.business_center, size: 40),
        title: Text(
          job.jobTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${job.jobType} • ${job.location}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToAddEditJobPosting(posting: job);
            } else if (value == 'delete') {
              _deleteJobPosting(job.id);
            }
          },
          itemBuilder:
              (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () => context.push('/jobs/postings/${job.id}'),
      ),
    );
  }

  Widget _buildSkilledWorkerCard(SkilledWorker worker) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.person, size: 40),
        title: Text(
          worker.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${worker.primarySkill} • ${worker.location}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToAddEditSkilledWorker(worker: worker);
            } else if (value == 'delete') {
              _deleteSkilledWorker(worker.id);
            }
          },
          itemBuilder:
              (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () => context.push('/jobs/skilled-workers/${worker.id}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'My Jobs and Applications',
      currentRoute: '/jobs/my-jobs-activity',
      tabs: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'My Job Postings'),
          Tab(text: 'My Job Applications'),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _jobPostings.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No job postings found.'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _navigateToAddEditJobPosting(),
                              child: const Text('Add Job Posting'),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _jobPostings.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildJobPostingCard(_jobPostings[index]),
                        ),
                      ),
                  _skilledWorkers.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No job applications found.'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  () => _navigateToAddEditSkilledWorker(),
                              child: const Text('Add Worker'),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _skilledWorkers.length,
                          itemBuilder:
                              (context, index) => _buildSkilledWorkerCard(
                                _skilledWorkers[index],
                              ),
                        ),
                      ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _navigateToAddEditJobPosting();
          } else {
            _navigateToAddEditSkilledWorker();
          }
        },
        tooltip: _tabController.index == 0 ? 'Add Job Posting' : 'Add Worker',
        child: const Icon(Icons.add),
      ),
    );
  }
}
