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
  final Map<String, String?> _thumbnailCache = {};
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

      // Generate signed URLs for first image of each car
      await _generateThumbnails(cars);

      setState(() => _cars = cars);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load cars: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _generateThumbnails(List<Car> cars) async {
    for (final car in cars) {
      if (car.mediaUrls.isNotEmpty) {
        try {
          // Generate signed URL for just the first image (thumbnail)
          final signedUrls = await _carService.getSignedMediaUrls([
            car.mediaUrls.first,
          ]);
          _thumbnailCache[car.id] =
              signedUrls.isNotEmpty ? signedUrls.first : null;
        } catch (e) {
          // If signing fails, use original URL
          _thumbnailCache[car.id] = car.mediaUrls.first;
        }
      } else {
        _thumbnailCache[car.id] = null;
      }
    }
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
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

        // Remove from cache
        _thumbnailCache.remove(id);
        _loadCars();
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete car: $e')),
        );
      }
    }
  }

  void _navigateToAddEdit() async {
    await context.push('/cars/add');
    if (!mounted) return;
    _loadCars();
  }

  void _navigateToEdit({Car? car}) async {
    if (car?.id != null) {
      await context.push('/cars/edit/${car!.id}');
    }
    if (!mounted) return;
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCars,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
                    final thumbnailUrl = _thumbnailCache[car.id];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: _buildCarImage(thumbnailUrl),
                        title: Text(
                          '${car.make} ${car.model} (${car.year})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          car.forSale
                              ? 'For Sale: ₹${car.salePrice?.toStringAsFixed(0) ?? 'N/A'}'
                              : 'For Booking: ₹${car.bookingRatePerDay?.toStringAsFixed(0) ?? 'N/A'}/day',
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
                                    _cars[_cars.indexWhere(
                                          (c) => c.id == car.id,
                                        )]
                                        .isAvailable = newValue;
                                  });
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update availability: $e',
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
                              children: const [
                                Text('Available'),
                                Text('Unavailable'),
                              ],
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _navigateToEdit(car: car);
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

  Widget _buildCarImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 75,
        color: Colors.grey.shade200,
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.directions_car,
                        size: 30,
                        color: Colors.grey,
                      ),
                )
                : const Icon(
                  Icons.directions_car,
                  size: 30,
                  color: Colors.grey,
                ),
      ),
    );
  }
}
