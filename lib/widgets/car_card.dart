import 'package:flutter/material.dart';
import '../models/car.dart';
import '../utils/helpers.dart';

class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;

  const CarCard({
    super.key, // Corrected constructor
    required this.car,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ... build method remains exactly the same
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
              child: car.mediaUrls.isNotEmpty
                  ? Image.network(
                      car.mediaUrls.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.directions_car, size: 80, color: Colors.grey),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.make} ${car.model}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${car.year} • ${Helpers.formatNumber(car.mileage)} miles',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          car.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Chip(
                      label: Text(
                        car.forSale ? 'For Sale' : 'Not For Sale',
                        style: TextStyle(
                          color: car.forSale ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: car.forSale ? Colors.green[100] : Colors.red[100],
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
