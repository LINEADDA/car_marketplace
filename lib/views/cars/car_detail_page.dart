import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../services/config_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_edit_car_page.dart';

class CarDetailPage extends StatefulWidget {
  final String carId;
  const CarDetailPage({super.key, required this.carId});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  late final CarService _carService;
  late final ConfigService _configService;
  Car? _car;
  String? _adminContactNumber;
  bool _isLoading = true;
  String? _errorMessage;
  String get _carTitle => _car != null ? '${_car!.year} ${_car!.make} ${_car!.model}' : 'Car Details';

  bool get _isOwner => _car?.ownerId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _configService = ConfigService(Supabase.instance.client);
    _fetchDetails();
  }

  // --- THIS METHOD IS NOW CORRECTED ---
  Future<void> _fetchDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final carFuture = _carService.getCarById(widget.carId);
      final contactFuture = _configService.getAdminContactNumber();
      
      // Future.wait returns a List<Object?>
      final results = await Future.wait([carFuture, contactFuture]);

      // We must explicitly cast the results to their expected types.
      final car = results[0] as Car?;
      final adminContact = results[1] as String?;

      if (car == null) {
        throw Exception('Car not found.');
      }
      if (mounted) {
        setState(() {
          _car = car;
          _adminContactNumber = adminContact;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load details: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeleteCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to permanently delete this ${car.make} ${car.model}?'),
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
        await _carService.deleteCar(car.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Car deleted successfully')));
          Navigator.of(context).pop(true);
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
      appBar: CustomAppBar(
        title: _isLoading ? 'Loading...' : _carTitle,
        actions: [
          if (_isOwner && _car != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Car',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditCarPage(carToEdit: _car))).then((result) {
                  if (result == true) _fetchDetails();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              tooltip: 'Delete Car',
              onPressed: () => _handleDeleteCar(_car!),
            ),
          ]
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_car == null) {
      return const Center(child: Text('Car details not available.'));
    }
    final car = _car!;
    final mileageFormatter = NumberFormat.decimalPattern('en_US');
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (car.mediaUrls.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: car.mediaUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(car.mediaUrls[index], fit: BoxFit.cover, errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 100));
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _carTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPriceDisplay(car, currencyFormatter),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: [
                    _buildSpecChip(Icons.speed_outlined, '${mileageFormatter.format(car.mileage)} mi'),
                    _buildSpecChip(Icons.local_gas_station_outlined, car.fuelType.name.toUpperCase()),
                    _buildSpecChip(Icons.settings_outlined, car.transmission.name.toUpperCase()),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Description'),
                  subtitle: Text(car.description.isNotEmpty ? car.description : 'No description provided.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Location'),
                  subtitle: Text(car.location),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Interested in this vehicle?', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('To arrange a viewing or make a purchase, please contact our main office at the number below.', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Center(
                          child: SelectableText(
                            _adminContactNumber ?? 'N/A',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(Car car, NumberFormat currencyFormatter) {
    if (car.forSale && car.salePrice != null) {
      return Text(
        currencyFormatter.format(car.salePrice),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      );
    } else if (!car.forSale && car.bookingRatePerDay != null) {
      return RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
          children: [
            TextSpan(text: currencyFormatter.format(car.bookingRatePerDay)),
            TextSpan(
              text: ' / day',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        'Price not available',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
      );
    }
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}