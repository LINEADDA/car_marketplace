import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  late TabController _tabController;
  late final CarService _carService;
  late Future<List<Car>> _carsForSaleFuture;
  late Future<List<Car>> _carsForBookingFuture;
  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carService = CarService(Supabase.instance.client);
    _loadCars();
  }

  void _loadCars() {
    setState(() {
      _carsForSaleFuture = _carService.getCarsForSale();
      _carsForBookingFuture = _carService.getCarsForBooking();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // New function to launch the dialer
  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer.')),
        );
      }
    }
  }

  // New function to launch a map with a location search
  Future<void> _launchMap(String location) async {
    final Uri launchUri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': location},
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
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
          _buildCarsList(_carsForBookingFuture),
          _buildCarsList(_carsForSaleFuture),
        ],
      ),
    );
  }

  Widget _buildCarsList(Future<List<Car>> carsFuture) {
    return FutureBuilder<List<Car>>(
      future: carsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allCars = snapshot.data ?? [];
        if (allCars.isEmpty) {
          return const Center(
            child: Text(
              'No cars available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final myCars =
            allCars.where((car) => car.ownerId == currentUserId).toList();
        final otherCars =
            allCars.where((car) => car.ownerId != currentUserId).toList();
        final sortedCars = [...myCars, ...otherCars];

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadCars());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedCars.length,
            itemBuilder: (context, index) {
              final car = sortedCars[index];
              final isMyCar = car.ownerId == currentUserId;
              final theme = Theme.of(context);

              return Card(
                elevation: isMyCar ? 6 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                color:
                    isMyCar
                        ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            )
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
                        _buildCarImage(car.mediaUrls.firstOrNull),
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
                              const SizedBox(height: 4),
                              _buildInfoChip(
                                Icons.currency_rupee_rounded,
                                car.forSale
                                    ? car.salePrice?.toStringAsFixed(0) ?? '0'
                                    : '${car.bookingRatePerDay?.toStringAsFixed(0) ?? '0'}/Hr',
                                onTap: null, 
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
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
                              if (isMyCar) ...[
                                const SizedBox(height: 8),
                                _buildMyCarTag(context),
                              ],
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
      },
    );
  }

  Widget _buildCarImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade200,
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.directions_car,
                          size: 40,
                          color: Colors.grey,
                        ),
                  )
                : const Icon(
                    Icons.directions_car,
                    size: 40,
                    color: Colors.grey,
                  ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
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

  Widget _buildMyCarTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'My Car',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}