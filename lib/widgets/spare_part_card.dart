import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/spare_part.dart';

class SparePartCard extends StatelessWidget {
  final SparePart part;
  final VoidCallback? onTap;

  const SparePartCard({super.key, required this.part, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (part.mediaUrls.isNotEmpty)
              Image.network(part.mediaUrls.first, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 80))
            else
              Container(height: 150, color: Colors.grey[200], child: const Center(child: Icon(Icons.build, size: 60, color: Colors.grey))),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(currencyFormatter.format(part.price), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}