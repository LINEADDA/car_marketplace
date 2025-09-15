import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_edit_car_page.dart';
import 'car_detail_page.dart';

class CarListPage extends StatefulWidget {
  const CarListPage({super.key});

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  late final CarService _carService;
  List<Car> _myCars = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _fetchMyCars();
  }

  Future<void> _fetchMyCars() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final cars = await _carService.getCarsByOwner(user.id);
      if (mounted) setState(() { _myCars = cars; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Failed to load cars: $e"; _isLoading = false; });
    }
  }

  void _navigateToAddOrEditCar({Car? carToEdit}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditCarPage(carToEdit: carToEdit))).then((result) {
      if (result == true) _fetchMyCars();
    });
  }

  // --- CORRECTED: Handles car deletion using the correct service method ---
  Future<void> _handleDeleteCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete this ${car.make} ${car.model}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _carService.deleteCar(car.id); // Passes only the carId
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Car deleted successfully')));
          _fetchMyCars(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete car: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(title: 'My Garage'),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(onPressed: () => _navigateToAddOrEditCar(), child: const Icon(Icons.add)),
      );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    if (_myCars.isEmpty) return const Center(child: Text('Your garage is empty.', textAlign: TextAlign.center));
    
    return RefreshIndicator(
      onRefresh: _fetchMyCars,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0).copyWith(bottom: 80),
        itemCount: _myCars.length,
        itemBuilder: (context, index) {
          final car = _myCars[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                if (car.mediaUrls.isNotEmpty)
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CarDetailPage(carId: car.id))),
                    child: Image.network(car.mediaUrls.first, height: 150, width: double.infinity, fit: BoxFit.cover),
                  )
                else
                  Container(height: 150, color: Colors.grey[300], child: const Icon(Icons.directions_car, size: 60)),
                ListTile(
                  title: Text('${car.year} ${car.make} ${car.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(car.forSale ? 'For Sale' : 'For Booking'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToAddOrEditCar(carToEdit: car);
                      } else if (value == 'delete') {
                        _handleDeleteCar(car);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}