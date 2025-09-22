import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/repair_shop.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceId;
  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  ShopService? _service;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch the repair shops from the database
      final response =
          await Supabase.instance.client
              .from('repair_shops')
              .select('services')
              .single();

      // Extract the services list
      final servicesList = response['services'] as List<dynamic>;

      // Find the service with the matching ID
      final serviceData = servicesList.firstWhere(
        (service) => service['id'] == widget.serviceId,
        orElse: () => null,
      );

      if (serviceData == null) {
        throw Exception('Service not found.');
      }

      final service = ShopService.fromMap(serviceData as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          _service = service;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load service details: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: _isLoading ? 'Loading...' : _service?.name ?? 'Service Details',
      currentRoute: '/service-detail',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_service == null) {
      return const Center(child: Text('Service not available.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Service Details
          Text(
            _service!.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_service!.price != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '₹${_service!.price?.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _service!.description.isNotEmpty
                ? _service!.description
                : 'No description provided.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
