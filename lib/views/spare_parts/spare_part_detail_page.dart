import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class SparePartDetailPage extends StatefulWidget {
  final String partId;
  const SparePartDetailPage({super.key, required this.partId});

  @override
  State<SparePartDetailPage> createState() => _SparePartDetailPageState();
}

class _SparePartDetailPageState extends State<SparePartDetailPage> {
  late final SparePartService _sparePartService;
  SparePart? _part;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _fetchPartDetails();
  }

  Future<void> _fetchPartDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final part = await _sparePartService.getPartById(widget.partId);
      if (mounted) {
        setState(() {
          _part = part;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load part details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  bool get _isOwner =>
      _part?.ownerId == Supabase.instance.client.auth.currentUser?.id;

  void _navigateToEditPage() {
    if (_part == null) return;
    context.push('/spare-parts/edit/${_part!.id}');
  }

  Future<void> _handleDeletePart() async {
    if (_part == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Part'),
            content: Text('Are you sure you want to delete "${_part!.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
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
        await _sparePartService.deleteSparePart(_part!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part deleted successfully')),
          );
          context.push('/spare-parts');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: _isLoading ? 'Loading...' : (_part?.title ?? 'Part Details'),
      currentRoute: '/spare-parts/:id',
      actions: [
        if (_isOwner) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Part',
            onPressed: _navigateToEditPage,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            tooltip: 'Delete Part',
            onPressed: _handleDeletePart,
          ),
        ],
      ],

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_part == null) {
      return const Center(child: Text('Spare part not found.'));
    }

    final part = _part!;
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (part.mediaUrls.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: part.mediaUrls.length,
                itemBuilder:
                    (context, index) => Image.network(
                      part.mediaUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (c, o, s) =>
                              const Icon(Icons.broken_image, size: 100),
                    ),
              ),
            )
          else
            Container(
              height: 250,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.build_circle_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(part.price),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _buildSectionTitle('Condition'),
                Chip(
                  label: Text(part.condition.name),
                  backgroundColor: Colors.blueGrey[50],
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Description'),
                Text(
                  part.description.isNotEmpty
                      ? part.description
                      : 'No description provided.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
