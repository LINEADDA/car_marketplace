import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/skilled_worker.dart';
import '../../widgets/app_scaffold_with_nav.dart'; 

class SkilledWorkerDetailPage extends StatelessWidget {
  final SkilledWorker worker;

  const SkilledWorkerDetailPage({super.key, required this.worker});

  Future _launchPhoneDialer(String phoneNumber, BuildContext context) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch dialer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(  
      title: worker.fullName,  
      currentRoute: '/jobs/skilled-workers/${worker.id}', 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              worker.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              worker.primarySkill,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            if (worker.experienceHeadline != null && worker.experienceHeadline!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  worker.experienceHeadline!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Location'),
              subtitle: Text(worker.location),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Contact Number'),
              subtitle: Text(worker.contactNumber),
              onTap: () => _launchPhoneDialer(worker.contactNumber, context),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call Now'),
                onPressed: () => _launchPhoneDialer(worker.contactNumber, context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}