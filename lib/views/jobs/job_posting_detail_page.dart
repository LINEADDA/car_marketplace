import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPosting();
  }

  Future<void> _loadPosting() async {
    try {
      final jobService = JobService(Supabase.instance.client);
      final fetchedPosting = await jobService.getJobPostingById(
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Chip(label: Text(posting!.location)),
                Chip(
                  label: Text(posting!.jobType),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Contact Number'),
              subtitle: Text(posting!.contactNumber),
              onTap: () => _launchPhoneDialer(posting!.contactNumber, context),
            ),
            if (posting!.jobDescription != null &&
                posting!.jobDescription!.isNotEmpty) ...[
              const Divider(),
              _buildSectionTitle(context, 'Job Description'),
              Text(posting!.jobDescription!),
            ],
          ],
        ),
      ),
    );
  }

  // Keep your existing helper methods
  Future<void> _launchPhoneDialer(
    String phoneNumber,
    BuildContext context,
  ) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to launch dialer: $e')));
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}