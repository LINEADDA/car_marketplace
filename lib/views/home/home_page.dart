import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Marketplace Home'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFeatureCard(
            context,
            title: 'Cars',
            subtitle: 'View cars for booking and for sale',
            icon: Icons.directions_car,
            onTap: () => context.push('/cars'),
          ),
          _buildFeatureCard(
            context,
            title: 'Spare Parts',
            subtitle: 'View spare parts for sale',
            icon: Icons.build_circle_outlined,
            onTap: () => context.push('/spare-parts'),
          ),
          _buildFeatureCard(
            context,
            title: 'Repair Shops',
            subtitle: 'Browse and manage repair services',
            icon: Icons.storefront_outlined,
            onTap: () => context.push('/repair-shops'),
          ),
          _buildFeatureCard(
            context,
            title: 'Jobs',
            subtitle: 'Jobs listing and Seekers',
            icon: Icons.work_outline,
            onTap: () => context.push('/jobs'),
          ),
          _buildFeatureCard(
            context,
            title: 'My Profile',
            subtitle: 'View and edit your account details',
            icon: Icons.person_outline,
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
