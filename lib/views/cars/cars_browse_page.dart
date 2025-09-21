import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import 'car_detail_page.dart';
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
          return const Center(child: Text('No cars available'));
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
              final isMycar = car.ownerId == currentUserId;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isMycar ? 4 : 2,
                color:
                    isMycar
                        ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withAlpha(70)
                        : null,
                child: ListTile(
                  leading:
                      car.mediaUrls.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              car.mediaUrls.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.directions_car,
                                    size: 60,
                                  ),
                            ),
                          )
                          : const Icon(Icons.directions_car, size: 60),
                  title: Text(
                    '${car.make} ${car.model} (${car.year})',
                    style: TextStyle(
                      fontWeight: isMycar ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${car.forSale ? car.salePrice?.toStringAsFixed(0) ?? '0' : '${car.bookingRatePerDay?.toStringAsFixed(0) ?? '0'}/day'}',
                      ),
                      Text(car.location),
                      if (isMycar)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'My Car',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarDetailPage(carId: car.id),
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
}