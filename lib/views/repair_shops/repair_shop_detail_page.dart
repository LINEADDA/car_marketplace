import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';
import '../../widgets/media_carousel.dart';
import '../../widgets/full_screen_media_viewer.dart';

class RepairShopDetailPage extends StatefulWidget {
  final String shopId;
  const RepairShopDetailPage({super.key, required this.shopId});

  @override
  State<RepairShopDetailPage> createState() => _RepairShopDetailPageState();
}

class _RepairShopDetailPageState extends State<RepairShopDetailPage> {
  late final RepairShopService _repairShopService;
  late final MediaService _mediaService;
  
  RepairShop? _shop;
  List<String> _signedMediaUrls = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  bool get _isOwner => _shop?.ownerId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    _mediaService = MediaService.forRepairShops(Supabase.instance.client);
    _fetchShopDetails();
  }

  Future<void> _fetchShopDetails() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final shop = await _repairShopService.getRepairShopById(widget.shopId);
      if (shop == null) throw Exception('Shop not found.');
      
      // Generate signed URLs for media
      final signedUrls = await _mediaService.getSignedMediaUrls(shop.mediaUrls);
      
      if (mounted) {
        setState(() {
          _shop = shop;
          _signedMediaUrls = signedUrls;
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

  void _showFullScreenMedia(List<String> mediaUrls) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenMediaViewer(mediaUrls: mediaUrls, initialIndex: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        barrierDismissible: true,
        opaque: false,
      ),
    );
  }

  Future<void> _handleDeleteShop() async {
    if (_shop == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to permanently delete "${_shop!.name}" and all its data? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repairShopService.deleteRepairShop(_shop!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop deleted successfully')),
          );
          context.go('/repair-shops');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open map.')));
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
            onPressed: () => context.push('/repair-shops/edit/${_shop!.id}'),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            tooltip: 'Delete Shop',
            onPressed: _handleDeleteShop,
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
        child: Text(_errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16)),
      );
    }

    if (_shop == null) {
      return const Center(
          child: Text('Repair shop not found.', style: TextStyle(fontSize: 16)));
    }

    final shop = _shop!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Carousel
          shop.mediaUrls.isNotEmpty
              ? MediaCarousel(
                  mediaUrls: _signedMediaUrls,
                  onFullScreen: () => _showFullScreenMedia(_signedMediaUrls),
                )
              : Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.home_repair_service,
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
                // Shop Name
                Text(
                  shop.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Pricing Info (if available)
                if (shop.pricingInfo.isNotEmpty) ...[
                  Text(
                    shop.pricingInfo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Services Chip (if available)
                if (shop.services.isNotEmpty) ...[
                  _buildSpecChip(
                    Icons.build_circle_outlined,
                    '${shop.services.length} Services',
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),

                // Location
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

                // Contact
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
                    shop.contactNumber.isNotEmpty
                        ? shop.contactNumber
                        : 'Not available',
                    style: TextStyle(
                      decoration: shop.contactNumber.isNotEmpty
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      color: shop.contactNumber.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ),

                const Divider(),

                // Services Section
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
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.build_outlined),
                        title: Text(service.name),
                        subtitle:
                            service.description.isNotEmpty
                                ? Text(service.description)
                                : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (service.price != null)
                              Text(
                                '₹${service.price?.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                        onTap:
                            () => context.push('/service-detail/${service.id}'),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }

}