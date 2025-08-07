import 'package:flutter/material.dart';
import '../models/spare_part.dart';

class SparePartCard extends StatelessWidget {
  final SparePart part;
  final VoidCallback? onTap;

  const SparePartCard({
    super.key, // Corrected constructor
    required this.part,
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
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: part.mediaUrls.isNotEmpty
                  ? Image.network(
                      part.mediaUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.build_circle_outlined, size: 50, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    part.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(
                        part.condition.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: Colors.blueGrey[50],
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      visualDensity: VisualDensity.compact,
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
