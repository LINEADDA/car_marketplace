import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/custom_app_bar.dart';

class SparePartListPage extends StatefulWidget {
  
  final bool showMyParts;

  const SparePartListPage({super.key, this.showMyParts = false});

  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage> {
  late final SparePartService _sparePartService;
  List<SparePart> _parts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _fetchParts();
  }

  Future<void> _fetchParts() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      List<SparePart> parts;
      final user = Supabase.instance.client.auth.currentUser;

      if (widget.showMyParts && user != null) {
        parts = await _sparePartService.getSparePartsForUser(user.id);
      } else {
        parts = await _sparePartService.getAllSpareParts();
      }

      if (mounted) {
        setState(() {
          _parts = parts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load parts: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showMyParts ? 'My Spare Parts' : 'All Spare Parts';
    
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: _buildBody(),
      floatingActionButton: widget.showMyParts
          ? FloatingActionButton(
              onPressed: () => context.push('/spare-parts/add'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    if (_parts.isEmpty) {
      final message = widget.showMyParts ? 'You have not listed any parts yet.' : 'No spare parts are currently available.';
      return Center(child: Text(message));
    }

    return RefreshIndicator(
      onRefresh: _fetchParts,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _parts.length,
        itemBuilder: (context, index) {
          final part = _parts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: part.mediaUrls.isNotEmpty
                  ? Image.network(part.mediaUrls.first, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.build_circle_outlined, size: 40))
                  : const Icon(Icons.build_circle_outlined, size: 40),
              title: Text(part.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('₹${part.price.toStringAsFixed(2)}'),
              onTap: () => context.push('/spare-parts/${part.id}'),
            ),
          );
        },
      ),
    );
  }
}