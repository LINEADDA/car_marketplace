import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class RepairShopListPage extends StatefulWidget {
  const RepairShopListPage({super.key});

  @override
  State<RepairShopListPage> createState() => _RepairShopListPageState();
}

class _RepairShopListPageState extends State<RepairShopListPage> {
  late final RepairShopService _repairShopService;
  late final MediaService _mediaService;

  List<RepairShop> _allRepairShops = [];
  final Map<String, List<String>> _signedUrlsCache = {};
  bool _isLoading = false;
  String? _error;

  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    _mediaService = MediaService.forRepairShops(Supabase.instance.client);
    _loadRepairShops();
  }

  Future<void> _loadRepairShops() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all repair shops (single list as requested)
      final allRepairShops = await _repairShopService.getAllPublicRepairShops();

      // Generate signed URLs for all repair shops
      await _generateSignedUrls(allRepairShops);

      if (mounted) {
        setState(() {
          _allRepairShops = allRepairShops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateSignedUrls(List<RepairShop> repairShops) async {
    for (final shop in repairShops) {
      if (shop.mediaUrls.isNotEmpty) {
        try {
          final signedUrls = await _mediaService.getSignedMediaUrls(
            shop.mediaUrls,
          );
          _signedUrlsCache[shop.id] = signedUrls;
        } catch (e) {
          // If signing fails, use original URLs
          _signedUrlsCache[shop.id] = shop.mediaUrls;
        }
      }
    }
  }

  /// Launch phone dialer
  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not launch dialer.')));
    }
  }

  /// Launch Google Maps location search
  Future<void> _launchMap(String location) async {
    final Uri launchUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Repair Shops',
      currentRoute: '/repair-shops/browse',
      body: _buildRepairShopsList(_allRepairShops),
      // NO FloatingActionButton here - only for my_repair_shops_page
    );
  }

  Widget _buildRepairShopsList(List<RepairShop> repairShops) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadRepairShops, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (repairShops.isEmpty) {
      return const Center(
        child: Text(
          'No repair shops available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Put current user's shops first
    final myShops = repairShops.where((shop) => shop.ownerId == currentUserId).toList();
    final otherShops = repairShops.where((shop) => shop.ownerId != currentUserId).toList();
    final sortedShops = [...myShops, ...otherShops];

    return RefreshIndicator(
      onRefresh: _loadRepairShops,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedShops.length,
        itemBuilder: (context, index) {
          final shop = sortedShops[index];
          final isMyShop = shop.ownerId == currentUserId;
          final theme = Theme.of(context);

          // Get signed URLs for this repair shop
          final signedUrls = _signedUrlsCache[shop.id] ?? [];
          final firstImageUrl = signedUrls.isNotEmpty ? signedUrls.first : null;

          return Card(
            elevation: isMyShop ? 6 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            color:
                isMyShop
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : theme.cardColor,
            child: InkWell(
              onTap: () => context.push('/repair-shops/${shop.id}'),
              borderRadius: BorderRadius.circular(16.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    _buildRepairShopImage(firstImageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (shop.pricingInfo.isNotEmpty)
                            Text(
                              shop.pricingInfo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (shop.services.isNotEmpty)
                                _buildInfoChip(
                                  Icons.build_circle_outlined,
                                  '${shop.services.length} Services',
                                ),
                              _buildInfoChip(
                                Icons.location_on_outlined,
                                shop.location,
                                onTap: () => _launchMap(shop.location),
                              ),
                              _buildInfoChip(
                                Icons.phone_outlined,
                                shop.contactNumber,
                                onTap: () => _launchDialer(shop.contactNumber),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRepairShopImage(String? imageUrl) {
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
                        Icons.home_repair_service,
                        size: 40,
                        color: Colors.grey,
                      ),
                )
                : const Icon(
                  Icons.home_repair_service,
                  size: 40,
                  color: Colors.grey,
                ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}
