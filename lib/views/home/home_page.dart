import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'AppName',
      currentRoute: '/',
      showHomeIcon: false,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFeatureCard(
            context,
            title: 'Cars',
            subtitle: 'View cars for booking and for sale',
            icon: Icons.directions_car,
            onTap: () => context.push('/cars/browse'), 
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Spare Parts',
            subtitle: 'Buy and sell automotive parts',
            icon: Icons.build_circle_outlined,
            onTap: () => context.push('/spare-parts'),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Repair Shops',
            subtitle: 'Find trusted repair services',
            icon: Icons.storefront_outlined,
            onTap: () => context.push('/repair-shops'),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            title: 'Jobs & Hiring',
            subtitle: 'Find jobs or hire professionals',
            icon: Icons.work_outline,
            onTap: () => context.push('/jobs'),
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
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
