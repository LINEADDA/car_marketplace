import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/spare_part_card.dart'; 
import 'spare_part_detail_page.dart';

class PublicSparePartsListPage extends StatefulWidget {
  const PublicSparePartsListPage({super.key});

  @override
  State<PublicSparePartsListPage> createState() => _PublicSparePartsListPageState();
}

class _PublicSparePartsListPageState extends State<PublicSparePartsListPage> {
  late final SparePartService _sparePartService;
  late Future<List<SparePart>> _partsFuture;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _refreshParts();
  }

  // Fetches all parts for the public marketplace view
  Future<void> _refreshParts() async {
    setState(() {
      _partsFuture = _sparePartService.getAllPublicSpareParts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Spare Parts Market'),
      body: FutureBuilder<List<SparePart>>(
        future: _partsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final parts = snapshot.data;
          if (parts == null || parts.isEmpty) {
            return const Center(
              child: Text(
                'No spare parts are listed for sale right now.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // Display the list of parts in a grid
          return RefreshIndicator(
            onRefresh: _refreshParts,
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.75, // Adjust this to fit your card design
              ),
              itemCount: parts.length,
              itemBuilder: (context, index) {
                final part = parts[index];
                return SparePartCard(
                  part: part,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SparePartDetailPage(partId: part.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}