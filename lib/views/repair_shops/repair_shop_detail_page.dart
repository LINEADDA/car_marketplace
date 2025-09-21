import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_edit_repair_shop_page.dart';
import 'service_detail_page.dart';

class RepairShopDetailPage extends StatefulWidget {
  final String shopId;
  const RepairShopDetailPage({super.key, required this.shopId});

  @override
  State<RepairShopDetailPage> createState() => _RepairShopDetailPageState();
}

class _RepairShopDetailPageState extends State<RepairShopDetailPage> {
  late final RepairShopService _repairShopService;
  RepairShop? _shop;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    _fetchShopDetails();
  }

  Future<void> _fetchShopDetails() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final shop = await _repairShopService.getRepairShopById(widget.shopId);
      if (mounted) {
        setState(() {
          _shop = shop;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load shop details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  bool get _isOwner => _shop?.ownerId == Supabase.instance.client.auth.currentUser?.id;

  // --- NEW METHOD: Handle deleting the entire shop ---
  Future<void> _handleDeleteShop(RepairShop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop?'),
        content: Text('Are you sure you want to permanently delete "${shop.name}" and all its data? This cannot be undone.'),
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
        await _repairShopService.deleteRepairShop(shop.id, shop.ownerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop deleted successfully')));
          Navigator.of(context).pop(); // Go back to the previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- NEW METHOD: Handle deleting a single service ---
  Future<void> _handleDeleteService(ShopService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text('Are you sure you want to delete the service "${service.name}"?'),
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
        await _repairShopService.deleteShopService(_shop!.id, service.id);
        // Refresh the page to show the updated list of services
        _fetchShopDetails();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isLoading ? 'Loading...' : (_shop?.name ?? 'Shop Details'),
        actions: [
          if (_isOwner && _shop != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Shop',
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => AddEditRepairShopPage(shopToEdit: _shop)))
                    .then((_) => _fetchShopDetails());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              tooltip: 'Delete Shop',
              onPressed: () => _handleDeleteShop(_shop!),
            ),
          ]
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    if (_shop == null) return const Center(child: Text('Shop not found.'));

    final shop = _shop!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shop.mediaUrls.isNotEmpty)
            SizedBox(height: 250, child: PageView.builder(itemCount: shop.mediaUrls.length, itemBuilder: (context, index) => Image.network(shop.mediaUrls[index], fit: BoxFit.cover))),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Location: ${shop.location}'),
                Text('Contact: ${shop.contactNumber}'),
                Text('Pricing: ${shop.pricingInfo}'),
                const SizedBox(height: 16),
                const Divider(),
                Text('Services Offered', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (shop.services.isEmpty)
                  const Text('No specific services listed.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shop.services.length,
                    itemBuilder: (context, index) {
                      final service = shop.services[index];
                      return ListTile(
                        title: Text(service.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (service.price != null) Text('\$${service.price?.toStringAsFixed(2)}'),
                            // Show delete button for each service only to the owner
                            if (_isOwner)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _handleDeleteService(service),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ServiceDetailPage(service: service)),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}