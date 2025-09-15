import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_edit_spare_part_page.dart';
import 'spare_part_detail_page.dart';

class SparePartListPage extends StatefulWidget {
  const SparePartListPage({super.key});

  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage> {
  late final SparePartService _sparePartService;
  List<SparePart> _myParts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _fetchMyParts();
  }

  Future<void> _fetchMyParts() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() { _isLoading = false; _errorMessage = 'You must be logged in.'; });
      return;
    }
    try {
      final parts = await _sparePartService.getSparePartsForUser(userId);
      if (mounted) setState(() { _myParts = parts; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Failed to load your parts: $e"; _isLoading = false; });
    }
  }

  void _navigateToAddOrEditPage({SparePart? partToEdit}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEditSparePartPage(partToEdit: partToEdit))).then((result) {
      if (result == true) _fetchMyParts();
    });
  }

  Future<void> _handleDeletePart(SparePart part) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Part'),
        content: Text('Are you sure you want to delete "${part.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _sparePartService.deleteSparePart(part.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Part deleted successfully')));
          _fetchMyParts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting part: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(title: 'My Spare Parts'),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddOrEditPage(),
          child: const Icon(Icons.add),
        ),
      );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    if (_myParts.isEmpty) return const Center(child: Text('You have not listed any parts yet.'));
    
    return RefreshIndicator(
      onRefresh: _fetchMyParts,
      child: ListView.builder(
        itemCount: _myParts.length,
        itemBuilder: (context, index) {
          final part = _myParts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: part.mediaUrls.isNotEmpty
                  ? Image.network(part.mediaUrls.first, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.build_circle_outlined, size: 40),
              title: Text(part.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('\$${part.price.toStringAsFixed(2)}'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => SparePartDetailPage(partId: part.id))),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _navigateToAddOrEditPage(partToEdit: part);
                  if (value == 'delete') _handleDeletePart(part);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}