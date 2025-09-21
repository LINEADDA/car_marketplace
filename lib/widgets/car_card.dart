import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';

class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;
  final bool showListingType; // Add this new property

  const CarCard({
    super.key,
    required this.car,
    this.onTap,
    this.showListingType = true, // Default to true to not break other pages
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (car.mediaUrls.isNotEmpty)
              Image.network(
                car.mediaUrls.first,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              )
            else
              _buildPlaceholderImage(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.year} ${car.make} ${car.model}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // --- Conditionally display the subtitle ---
                  if (showListingType)
                    Text(
                      car.forSale ? 'For Sale' : 'For Booking',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  
                  const SizedBox(height: 8),
                  _buildPriceDisplay(context, car, currencyFormatter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to keep the build method clean
  Widget _buildPlaceholderImage() {
    return Container(
      height: 150,
      color: Colors.grey,
      child: const Center(child: Icon(Icons.directions_car_filled, size: 80, color: Colors.grey)),
    );
  }

  Widget _buildPriceDisplay(BuildContext context, Car car, NumberFormat currencyFormatter) {
    if (car.forSale && car.salePrice != null) {
      return Text(
        currencyFormatter.format(car.salePrice),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      );
    } else if (!car.forSale && car.bookingRatePerDay != null) {
      return RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: currencyFormatter.format(car.bookingRatePerDay)),
            const TextSpan(
              text: ' / day',
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink(); // Don't show anything if no price
  }
}