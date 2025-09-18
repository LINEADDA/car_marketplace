import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';
import 'job_posting_detail_page.dart';

class JobPostingsListPage extends StatefulWidget {
  const JobPostingsListPage({super.key});

  @override
  State<JobPostingsListPage> createState() => _JobPostingsListPageState();
}

class _JobPostingsListPageState extends State<JobPostingsListPage> {
  late final JobService _jobService;
  late Future<List<JobPosting>> _postingsFuture;

  @override
  void initState() {
    super.initState();
    _jobService = JobService(Supabase.instance.client);
    _postingsFuture = _jobService.getJobPostings();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Job Vacancies',
      currentRoute: '/jobs/postings', 
      body: FutureBuilder<List<JobPosting>>(
        future: _postingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final postings = snapshot.data;
          if (postings == null || postings.isEmpty) {
            return const Center(child: Text('No job postings found.'));
          }

          return ListView.builder(
            itemCount: postings.length,
            itemBuilder: (context, index) {
              final post = postings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    post.jobTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${post.jobType} - ${post.location}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                JobPostingDetailPage(postingId: post.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}