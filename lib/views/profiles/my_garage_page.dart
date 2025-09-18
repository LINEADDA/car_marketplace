import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class MyGaragePage extends StatefulWidget {
  const MyGaragePage({super.key});

  @override
  State<MyGaragePage> createState() => _MyGaragePageState();
}

class _MyGaragePageState extends State<MyGaragePage> {
  late final CarService _carService;
  List<Car> _cars = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _fetchMyCars();
  }

  Future<void> _fetchMyCars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final cars = await _carService.getCarsByOwner();
        if (mounted) {
          setState(() {
            _cars = cars;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load your cars: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'My Garage',
      currentRoute: '/my-garage',
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cars/add'),
        tooltip: 'Add Car',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))
      );
    }
    
    if (_cars.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.garage, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Your garage is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to add your first car!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyCars,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 80.0),
        itemCount: _cars.length,
        itemBuilder: (context, index) {
          final car = _cars[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: car.mediaUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        car.mediaUrls.first,
                        width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Icon(Icons.directions_car, size: 60),
                      ),
                    )
                  : const Icon(Icons.directions_car, size: 60),
              title: Text('${car.make} ${car.model} (${car.year})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.forSale ? 'For Sale' : 'For Booking'),
                  if (car.forSale && car.salePrice != null)
                    Text('₹${car.salePrice!.toStringAsFixed(0)}')
                  else if (!car.forSale && car.bookingRatePerDay != null)
                    Text('₹${car.bookingRatePerDay!.toStringAsFixed(0)}/day'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/cars/edit/${car.id}');
                  } else if (value == 'delete') {
                    _showDeleteDialog(car);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => context.push('/cars/${car.id}'),
            ),
          );
        },
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
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              
              if (!mounted) return;
              
              try {
                await _carService.deleteCar(car.id);
                _fetchMyCars();
                
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Car deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete car: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}