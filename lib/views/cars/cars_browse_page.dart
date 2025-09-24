import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class CarsBrowsePage extends StatefulWidget {
  const CarsBrowsePage({super.key});

  @override
  State<CarsBrowsePage> createState() => _CarsBrowsePageState();
}

class _CarsBrowsePageState extends State<CarsBrowsePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CarService _carService;

  List<Car> _carsForSale = [];
  List<Car> _carsForBooking = [];
  final Map<String, List<String>> _signedUrlsCache = {};
  bool _isLoading = false;
  String? _error;

  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carService = CarService(Supabase.instance.client);
    _loadCars();
  }

  Future<void> _loadCars() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _carService.getCarsForSale(),
        _carService.getCarsForBooking(),
      ]);

      final carsForSale = results[0];
      final carsForBooking = results[1];

      // Generate signed URLs for all cars
      await _generateSignedUrls([...carsForSale, ...carsForBooking]);

      if (mounted) {
        setState(() {
          _carsForSale = carsForSale;
          _carsForBooking = carsForBooking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateSignedUrls(List<Car> cars) async {
    for (final car in cars) {
      if (car.mediaUrls.isNotEmpty) {
        try {
          final signedUrls = await _carService.getSignedMediaUrls(
            car.mediaUrls,
          );
          _signedUrlsCache[car.id] = signedUrls;
        } catch (e) {
          // If signing fails, use original URLs
          _signedUrlsCache[car.id] = car.mediaUrls;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Launch phone dialer
  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not launch dialer.')));
    }
  }

  /// Launch Google Maps location search
  Future<void> _launchMap(String location) async {
    final Uri launchUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Cars and Rentals',
      currentRoute: '/cars/browse',
      tabs: TabBar(
        controller: _tabController,
        tabs: const [Tab(text: 'For Booking'), Tab(text: 'For Sale')],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCarsList(_carsForBooking),
          _buildCarsList(_carsForSale),
        ],
      ),
    );
  }

  Widget _buildCarsList(List<Car> cars) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadCars, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (cars.isEmpty) {
      return const Center(
        child: Text(
          'No cars available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Put current user's cars first
    final myCars = cars.where((car) => car.ownerId == currentUserId).toList();
    final otherCars =
        cars.where((car) => car.ownerId != currentUserId).toList();
    final sortedCars = [...myCars, ...otherCars];

    return RefreshIndicator(
      onRefresh: _loadCars,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedCars.length,
        itemBuilder: (context, index) {
          final car = sortedCars[index];
          final isMyCar = car.ownerId == currentUserId;
          final theme = Theme.of(context);
          final currencyFormatter = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '',
            decimalDigits: 0,
          );

          // Get signed URLs for this car
          final signedUrls = _signedUrlsCache[car.id] ?? [];
          final firstImageUrl = signedUrls.isNotEmpty ? signedUrls.first : null;

          return Card(
            elevation: isMyCar ? 6 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            color:
                isMyCar
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : theme.cardColor,
            child: InkWell(
              onTap: () => context.push('/cars/${car.id}'),
              borderRadius: BorderRadius.circular(16.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    _buildCarImage(firstImageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${car.make} ${car.model} ${car.year}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip(
                                Icons.currency_rupee_rounded,
                                car.forSale
                                    ? currencyFormatter.format(
                                      car.salePrice ?? 0,
                                    )
                                    : '${currencyFormatter.format(car.bookingRatePerDay ?? 0)}/Hr',
                              ),
                              _buildInfoChip(
                                Icons.location_on_outlined,
                                car.location,
                                onTap: () => _launchMap(car.location),
                              ),
                              _buildInfoChip(
                                Icons.phone_outlined,
                                car.contact,
                                onTap: () => _launchDialer(car.contact),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildInfoChip(IconData icon, String label, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
