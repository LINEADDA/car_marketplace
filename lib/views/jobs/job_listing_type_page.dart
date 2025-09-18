import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class JobListingTypePage extends StatelessWidget {
  const JobListingTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Jobs & Hiring',
      currentRoute: '/jobs',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOptionCard(
              context: context,
              title: 'Find a Job',
              subtitle: 'Browse available job vacancies posted by shops.',
              icon: Icons.business_center_outlined,
              onTap: () => context.push('/jobs/postings'),
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              context: context,
              title: 'Find a Professional',
              subtitle: 'Browse skilled workers available for hire.',
              icon: Icons.person_search_outlined,
              onTap: () => context.push('/jobs/skilled-workers'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
