import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../widgets/car_card.dart';
import '../../widgets/custom_app_bar.dart';
import 'car_detail_page.dart';

class PublicCarListPage extends StatefulWidget {
  final bool isForSale;
  const PublicCarListPage({super.key, required this.isForSale});

  @override
  State<PublicCarListPage> createState() => _PublicCarListPageState();
}

class _PublicCarListPageState extends State<PublicCarListPage> {
  late final CarService _carService;
  late Future<List<Car>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _carsFuture = _carService.getPublicCarsByListingType(widget.isForSale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isForSale ? 'Cars for Sale' : 'Cars for Booking',
      ),
      body: FutureBuilder<List<Car>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final cars = snapshot.data;
          if (cars == null || cars.isEmpty) {
            return const Center(child: Text('No cars found for this category.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return CarCard(
                car: car,
                showListingType: false, // --- This is the key change ---
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CarDetailPage(carId: car.id),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}