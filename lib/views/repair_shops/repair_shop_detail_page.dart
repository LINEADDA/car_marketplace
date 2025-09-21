import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';
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

  bool get _isOwner =>
      _shop?.ownerId == Supabase.instance.client.auth.currentUser?.id;

  Future<void> _handleDeleteShop(RepairShop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Shop?'),
            content: Text(
              'Are you sure you want to permanently delete "${shop.name}" and all its data? This cannot be undone.',
            ),
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
        await _repairShopService.deleteRepairShop(shop.id, shop.ownerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop deleted successfully')),
          );
          Navigator.of(context).pop(); // Go back to the previous screen
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

  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer.')),
        );
      }
    }
  }

  Future<void> _launchMap(String location) async {
    final Uri launchUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: _isLoading ? 'Loading...' : (_shop?.name ?? 'Shop Details'),
      currentRoute: '/repair-shops/:id',
      actions: [
        if (_isOwner && _shop != null) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Shop',
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder:
                          (context) => AddEditRepairShopPage(shopToEdit: _shop),
                    ),
                  )
                  .then((_) => _fetchShopDetails());
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            tooltip: 'Delete Shop',
            onPressed: () => _handleDeleteShop(_shop!),
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
    if (_shop == null) return const Center(child: Text('Shop not found.'));

    final shop = _shop!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shop.mediaUrls.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: shop.mediaUrls.length,
                itemBuilder:
                    (context, index) => Image.network(
                      shop.mediaUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stack) => const Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.grey,
                          ),
                    ),
              ),
            )
          else
            Container(
              height: 250,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.store, size: 100, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  onTap: () => _launchMap(shop.location),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Location'),
                  subtitle: Text(
                    shop.location,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                ListTile(
                  onTap: () {
                    if (shop.contactNumber.isNotEmpty) {
                      _launchDialer(shop.contactNumber);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Contact'),
                  subtitle: Text(
                    shop.contactNumber,
                    style: TextStyle(
                      decoration:
                          shop.contactNumber.isNotEmpty
                              ? TextDecoration.underline
                              : TextDecoration.none,
                      color:
                          shop.contactNumber.isNotEmpty
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                    ),
                  ),
                ),
                if (shop.pricingInfo.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.price_change_outlined),
                    title: const Text('Pricing'),
                    subtitle: Text(shop.pricingInfo),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  'Services Offered',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                        title: Text(
                          service.price != null
                              ? '${service.name} - ₹${service.price?.toStringAsFixed(2)}'
                              : service.name,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ServiceDetailPage(service: service),
                            ),
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