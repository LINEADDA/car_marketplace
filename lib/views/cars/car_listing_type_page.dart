import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/car_service.dart';

class CarListingTypePage extends StatefulWidget {
  const CarListingTypePage({super.key});

  @override
  State<CarListingTypePage> createState() => _CarListingTypePageState();
}

class _CarListingTypePageState extends State<CarListingTypePage> {
  late final CarService _carService;
  int _carsForSaleCount = 0;
  int _carsForBookingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _loadCarCounts();
  }

  Future<void> _loadCarCounts() async {
    try {
      setState(() => _isLoading = true);

      // Load counts for both types
      final carsForSale = await _carService.getCarsForSale();
      final carsForBooking = await _carService.getCarsForBooking();

      setState(() {
        _carsForSaleCount = carsForSale.length;
        _carsForBookingCount = carsForBooking.length;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cars'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.car_rental,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose Car Type',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find your perfect car for purchase or booking',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Options
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        children: [
                          // Cars for Sale
                          Expanded(
                            child: _buildOptionCard(
                              context: context,
                              title: 'Cars for Sale',
                              subtitle: 'Buy a car permanently',
                              icon: Icons.sell,
                              count: _carsForSaleCount,
                              color: Colors.green,
                              onTap: () => context.push('/cars/sale'),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Cars for Booking
                          Expanded(
                            child: _buildOptionCard(
                              context: context,
                              title: 'Cars for Booking',
                              subtitle: 'Rent a car temporarily',
                              icon: Icons.schedule,
                              count: _carsForBookingCount,
                              color: Colors.blue,
                              onTap: () => context.push('/cars/booking'),
                            ),
                          ),
                        ],
                      ),
            ),

            const SizedBox(height: 20),

            // Browse All Cars Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/cars/browse'),
                icon: const Icon(Icons.search),
                label: const Text('Browse All Cars'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
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
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(icon, size: 48, color: color),
              ),

              const SizedBox(height: 16),

              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count cars available',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}