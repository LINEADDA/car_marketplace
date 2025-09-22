import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class JobPostingDetailPage extends StatefulWidget {
  final String postingId;

  const JobPostingDetailPage({super.key, required this.postingId});

  @override
  State<JobPostingDetailPage> createState() => _JobPostingDetailPageState();
}

class _JobPostingDetailPageState extends State<JobPostingDetailPage> {
  JobPosting? posting;
  bool isLoading = true;
  String? error;
  late final JobService _jobService;

  @override
  void initState() {
    super.initState();
    _jobService = JobService(Supabase.instance.client);
    _loadPosting();
  }

  Future<void> _loadPosting() async {
    try {
      final fetchedPosting = await _jobService.getJobPostingById(
        widget.postingId,
      );
      if (mounted) {
        setState(() {
          posting = fetchedPosting;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  bool get _isOwner {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return posting?.ownerId == currentUserId;
  }

  void _navigateToEditPage() {
    if (posting == null) return;
    context.push('/jobs/postings/edit/${posting!.id}');
  }

  Future<void> _handleDelete() async {
    if (posting == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Job Posting'),
            content: Text(
              'Are you sure you want to delete "${posting!.jobTitle}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _jobService.deleteJobPosting(posting!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job posting deleted successfully')),
          );
          context.go('/jobs/postings');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting job posting: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _launchPhoneDialer(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer.')),
      );
    }
  }

  Future<void> _launchMap(String location) async {
    final Uri mapUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ScaffoldWithNav(
        title: 'Loading...',
        currentRoute: '/jobs/postings/${widget.postingId}',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || posting == null) {
      return ScaffoldWithNav(
        title: 'Error',
        currentRoute: '/jobs',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading job posting: ${error ?? "Not found"}'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return ScaffoldWithNav(
      title: posting!.jobTitle,
      currentRoute: '/jobs/postings/${widget.postingId}',
      actions:
          _isOwner
              ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Job Posting',
                  onPressed: _navigateToEditPage,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Delete Job Posting',
                  onPressed: _handleDelete,
                ),
              ]
              : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              posting!.jobTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.work_outline, size: 20),
              label: Text(posting!.jobType.toUpperCase()),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.currency_rupee_rounded, size: 20),
              label: Text('${posting!.salary}/Month'),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Location'),
              subtitle: Text(
                posting!.location.isNotEmpty
                    ? posting!.location
                    : 'Not specified',
                style: TextStyle(
                  decoration:
                      posting!.location.isNotEmpty
                          ? TextDecoration.underline
                          : TextDecoration.none,
                  color:
                      posting!.location.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                ),
              ),
              onTap:
                  posting!.location.isNotEmpty
                      ? () => _launchMap(posting!.location)
                      : null,
            ),

            // Contact ListTile
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Contact Number'),
              subtitle: Text(
                posting!.contactNumber.isNotEmpty
                    ? posting!.contactNumber
                    : 'Not available',
                style: TextStyle(
                  decoration:
                      posting!.contactNumber.isNotEmpty
                          ? TextDecoration.underline
                          : TextDecoration.none,
                  color:
                      posting!.contactNumber.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                ),
              ),
              onTap:
                  posting!.contactNumber.isNotEmpty
                      ? () => _launchPhoneDialer(posting!.contactNumber)
                      : null,
            ),

            const SizedBox(height: 16),
            const Divider(),

            if (posting!.jobDescription != null &&
                posting!.jobDescription!.isNotEmpty) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Job Description'),
                subtitle: Text(posting!.jobDescription!),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Job Description'),
                subtitle: const Text('No description provided.'),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
