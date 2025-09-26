import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class MySparePartsPage extends StatefulWidget {
  const MySparePartsPage({super.key});

  @override
  State<MySparePartsPage> createState() => _MySparePartsPageState();
}

class _MySparePartsPageState extends State<MySparePartsPage> {
  final _sparePartService = SparePartService(Supabase.instance.client);
  late final String _currentUserId;
  List<SparePart> _parts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _error = 'User not logged in.';
      _isLoading = false;
    } else {
      _currentUserId = currentUser.id;
      _loadParts();
    }
  }

  Future<void> _loadParts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final parts = await _sparePartService.getSparePartsByOwner(
        _currentUserId,
      );
      if (!mounted) return;
      setState(() => _parts = parts);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load parts: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _deletePart(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Spare Part'),
            content: const Text('Are you sure you want to delete this part?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirm == true) {
      try {
        await _sparePartService.deleteSparePart(id);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Part deleted')));
        _loadParts();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void _navigateToAddEdit() async {
    await context.push('/spare-parts/add');

    if (!mounted) return;
    _loadParts();
  }

  void _navigateToEdit({SparePart? part}) async {
    if (part?.id != null) {
      context.push('/spare-parts/edit/${part!.id}');
    }
    if (!mounted) return;
    _loadParts();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'My Spare Parts',
      currentRoute: '/my-spare-parts',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : _parts.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No spare parts found.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToAddEdit(),
                      child: const Text('Add Spare Part'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadParts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _parts.length,
                  itemBuilder: (context, index) {
                    final part = _parts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading:
                            part.mediaUrls.isNotEmpty
                                ? Image.network(
                                  part.mediaUrls.first,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (c, o, s) => const Icon(
                                        Icons.build_circle_outlined,
                                        size: 40,
                                      ),
                                )
                                : const Icon(
                                  Icons.build_circle_outlined,
                                  size: 40,
                                ),
                        title: Text(
                          part.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('₹${part.price.toStringAsFixed(2)}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToEdit(part: part);
                            } else if (value == 'delete') {
                              _deletePart(part.id);
                            }
                          },
                          itemBuilder:
                              (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                        onTap: () => context.push('/spare-parts/${part.id}'),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        tooltip: 'Add Spare Part',
        child: const Icon(Icons.add),
      ),
    );
  }

}