// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../widgets/custom_app_bar.dart';

class CarListPage extends StatefulWidget {
  final bool? isForSale;
  final bool isOwnerView;

  const CarListPage({
    super.key,
    this.isForSale,
    this.isOwnerView = false,
  });

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  late final CarService _carService;
  late Future<List<Car>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _loadCars();
  }

  void _loadCars() {
    setState(() {
      if (widget.isOwnerView) {
        _carsFuture = _carService.getCarsByOwner();
      } else if (widget.isForSale == true) {
        _carsFuture = _carService.getCarsForSale();
      } else if (widget.isForSale == false) {
        _carsFuture = _carService.getCarsForBooking();
      } else {
        _carsFuture = _carService.getAllPublicCars();
      }
    });
  }

  String get _pageTitle {
    if (widget.isOwnerView) return 'My Cars';
    if (widget.isForSale == true) return 'Cars for Sale';
    if (widget.isForSale == false) return 'Cars for Booking';
    return 'All Cars';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _pageTitle),
      body: FutureBuilder<List<Car>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final cars = snapshot.data ?? [];

          if (cars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.car_rental, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No cars available',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isOwnerView
                        ? 'Add your first car to get started'
                        : 'Check back later for new listings',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadCars();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return _buildCarCard(car);
              },
            ),
          );
        },
      ),
      floatingActionButton: widget.isOwnerView
          ? FloatingActionButton(
              onPressed: () => context.push('/cars/add'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCarCard(Car car) {
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          if (isLoggedIn || !widget.isOwnerView) {
            context.push('/cars/${car.id}');
          } else {
            _showLoginPrompt();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[300],
              ),
              child: car.mediaUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        car.mediaUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.car_rental, size: 64, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.car_rental, size: 64, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.make} ${car.model} (${car.year})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    car.forSale
                        ? '₹${car.salePrice?.toStringAsFixed(0) ?? 'N/A'}'
                        : '₹${car.bookingRatePerDay?.toStringAsFixed(0) ?? 'N/A'}/day',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          car.location,
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isOwnerView) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push('/cars/edit/${car.id}'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: () => _showDeleteDialog(car),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to view car details and contact sellers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Car car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete ${car.make} ${car.model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _carService.deleteCar(car.id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadCars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Car deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting car: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}