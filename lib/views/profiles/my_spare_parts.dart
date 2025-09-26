import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class MySparePartsPage extends StatefulWidget {
  const MySparePartsPage({super.key});

  @override
  State<MySparePartsPage> createState() => _MySparePartsPageState();
}

class _MySparePartsPageState extends State<MySparePartsPage> {
  late final SparePartService _sparePartService;
  late final MediaService _mediaService;
  late final String _currentUserId; 

  List<SparePart> _parts = [];
  final Map<String, String?> _thumbnailCache = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _error = 'User not logged in.';
      _isLoading = false;
      return;
    }

    _currentUserId = currentUser.id; 
    _sparePartService = SparePartService(Supabase.instance.client);
    _mediaService = MediaService.forSpareParts(Supabase.instance.client);
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Pass the _currentUserId to the method - THIS FIXES THE ERROR
      final parts = await _sparePartService.getSparePartsByOwner(
        _currentUserId,
      );
      if (!mounted) return;

      // Generate signed URLs for first image of each spare part
      await _generateThumbnails(parts);

      setState(() => _parts = parts);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load spare parts: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _generateThumbnails(List<SparePart> parts) async {
    for (final part in parts) {
      if (part.mediaUrls.isNotEmpty) {
        try {
          // Generate signed URL for just the first image (thumbnail)
          final signedUrls = await _mediaService.getSignedMediaUrls([
            part.mediaUrls.first,
          ]);
          _thumbnailCache[part.id] =
              signedUrls.isNotEmpty ? signedUrls.first : null;
        } catch (e) {
          // If signing fails, use original URL
          _thumbnailCache[part.id] = part.mediaUrls.first;
        }
      } else {
        _thumbnailCache[part.id] = null;
      }
    }
  }

  Future<void> _deletePart(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Spare Part'),
            content: const Text(
              'Are you sure you want to delete this spare part?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
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
        messenger.showSnackBar(
          const SnackBar(content: Text('Spare part deleted successfully')),
        );
        // Remove from cache
        _thumbnailCache.remove(id);
        _loadParts();
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete spare part: $e')),
        );
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
      await context.push('/spare-parts/edit/${part!.id}');
    }
    if (!mounted) return;
    _loadParts();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return ScaffoldWithNav(
      title: 'My Spare Parts',
      currentRoute: '/my-spare-parts',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadParts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
                    final thumbnailUrl = _thumbnailCache[part.id];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: _buildSparePartImage(thumbnailUrl),
                        title: Text(
                          part.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${currencyFormatter.format(part.price)} • ${part.condition.name.toUpperCase()}',
                        ),
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

  Widget _buildSparePartImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 75,
        color: Colors.grey.shade200,
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.build_circle_outlined,
                        size: 30,
                        color: Colors.grey,
                      ),
                )
                : const Icon(
                  Icons.build_circle_outlined,
                  size: 30,
                  color: Colors.grey,
                ),
      ),
    );
  }

}
