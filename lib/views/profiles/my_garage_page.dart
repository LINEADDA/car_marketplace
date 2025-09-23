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
  String? _error;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cars = await _carService.getCarsByOwner();
      if (!mounted) return;
      setState(() => _cars = cars);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load cars: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _deleteCar(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Car'),
            content: const Text('Are you sure you want to delete this car?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (!mounted) return;

    if (confirm == true) {
      try {
        await _carService.deleteCar(id);

        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Car deleted successfully')),
        );

        _loadCars();
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete car: $e')),
        );
      }
    }
  }

  void _navigateToAddEdit({Car? car}) async {
    await context.push('/cars/add', extra: car);
    if (!mounted) {
      return;
    }
    _loadCars();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'My Garage',
      currentRoute: '/my-garage',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : _cars.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No cars found.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToAddEdit(),
                      child: const Text('Add Car'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadCars,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading:
                            car.mediaUrls.isNotEmpty
                                ? Image.network(
                                  car.mediaUrls.first,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (c, o, s) => const Icon(
                                        Icons.directions_car,
                                        size: 40,
                                      ),
                                )
                                : const Icon(Icons.directions_car, size: 40),
                        title: Text(
                          '${car.make} ${car.model} (${car.year})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          car.forSale
                              ? 'For Sale: ₹${car.salePrice?.toStringAsFixed(0)}'
                              : 'For Booking: ₹${car.bookingRatePerDay?.toStringAsFixed(0)}/day',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ToggleButtons(
                              isSelected: [car.isAvailable, !car.isAvailable],
                              onPressed: (index) async {
                                final messenger = ScaffoldMessenger.of(context);
                                final bool newValue = index == 0;
                                try {
                                  await _carService.updateCarVisibility(
                                    car.id,
                                    newValue,
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    car.isAvailable = newValue;
                                  });
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update booking status: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              selectedColor: Colors.white,
                              fillColor: Theme.of(context).colorScheme.primary,
                              constraints: const BoxConstraints(
                                minHeight: 36,
                                minWidth: 80,
                              ),
                              children:
                                  car.forSale
                                      ? const [
                                        Text('Not for sale'),
                                        Text('For sale'),
                                      ]
                                      : const [
                                        Text('Not booked'),
                                        Text('Booked'),
                                      ],
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _navigateToAddEdit(car: car);
                                } else if (value == 'delete') {
                                  _deleteCar(car.id);
                                }
                              },
                              itemBuilder:
                                  (ctx) => [
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
                                          Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                        onTap: () => context.push('/cars/${car.id}'),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        tooltip: 'Add Car',
        child: const Icon(Icons.add),
      ),
    );
  }
}
