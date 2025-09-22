import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';
import 'repair_shop_detail_page.dart';

class RepairShopListPage extends StatefulWidget {
  const RepairShopListPage({super.key});

  @override
  State<RepairShopListPage> createState() => _RepairShopListPageState();
}

class _RepairShopListPageState extends State<RepairShopListPage> {
  late final RepairShopService _repairShopService;
  late Future<List<RepairShop>> _shopsFuture;
  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    _shopsFuture = _fetchPublicShops();
  }

  Future<List<RepairShop>> _fetchPublicShops() {
    return _repairShopService.getAllPublicRepairShops();
  }

  void _refreshShopList() {
    setState(() {
      _shopsFuture = _fetchPublicShops();
    });
  }

  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
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
    final Uri launchUri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': location},
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Repair Shops',
      currentRoute: '/repair-shops',
      body: FutureBuilder<List<RepairShop>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final shops = snapshot.data;

          if (shops == null || shops.isEmpty) {
            return const Center(
              child: Text(
                'No repair shops found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final myShops =
              shops.where((shop) => shop.ownerId == currentUserId).toList();
          final otherShops =
              shops.where((shop) => shop.ownerId != currentUserId).toList();
          final sortedShops = [...myShops, ...otherShops];

          return RefreshIndicator(
            onRefresh: () async => _refreshShopList(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sortedShops.length,
              itemBuilder: (context, index) {
                final shop = sortedShops[index];
                final isMyShop = shop.ownerId == currentUserId;
                final theme = Theme.of(context);

                return Card(
                  elevation: isMyShop ? 6 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: isMyShop
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : theme.cardColor,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RepairShopDetailPage(shopId: shop.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      child: Row(
                        children: [
                          _buildShopImage(),
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildInfoChip(
                                      Icons.location_on_outlined,
                                      shop.location,
                                      onTap: () => _launchMap(shop.location),
                                    ),
                                    _buildInfoChip(
                                      Icons.phone_outlined,
                                      shop.contactNumber,
                                      onTap: () =>
                                          _launchDialer(shop.contactNumber),
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
        },
      ),
    );
  }

  Widget _buildShopImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.home_repair_service,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
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