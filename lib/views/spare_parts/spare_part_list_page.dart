import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class SparePartListPage extends StatefulWidget {
  const SparePartListPage({super.key});

  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage> {
  late final SparePartService _sparePartService;
  late final MediaService _mediaService;

  List<SparePart> _allSpareParts = [];
  final Map<String, List<String>> _signedUrlsCache = {};
  bool _isLoading = false;
  String? _error;

  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _mediaService = MediaService.forSpareParts(Supabase.instance.client);
    _loadSpareParts();
  }

  Future<void> _loadSpareParts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all spare parts (single list as requested)
      final allSpareParts = await _sparePartService.getAllSpareParts();

      // Generate signed URLs for all spare parts
      await _generateSignedUrls(allSpareParts);

      if (mounted) {
        setState(() {
          _allSpareParts = allSpareParts;
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

  Future<void> _generateSignedUrls(List<SparePart> spareParts) async {
    for (final part in spareParts) {
      if (part.mediaUrls.isNotEmpty) {
        try {
          final signedUrls = await _mediaService.getSignedMediaUrls(
            part.mediaUrls,
          );
          _signedUrlsCache[part.id] = signedUrls;
        } catch (e) {
          // If signing fails, use original URLs
          _signedUrlsCache[part.id] = part.mediaUrls;
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
      title: 'Spare Parts',
      currentRoute: '/spare-parts/browse',
      body: _buildSparePartsList(_allSpareParts),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/spare-parts/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSparePartsList(List<SparePart> spareParts) {
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
            ElevatedButton(onPressed: _loadSpareParts, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (spareParts.isEmpty) {
      return const Center(
        child: Text(
          'No spare parts available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Put current user's parts first
    final myParts = spareParts.where((part) => part.ownerId == currentUserId).toList();
    final otherParts = spareParts.where((part) => part.ownerId != currentUserId).toList();
    final sortedParts = [...myParts, ...otherParts];

    return RefreshIndicator(
      onRefresh: _loadSpareParts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedParts.length,
        itemBuilder: (context, index) {
          final part = sortedParts[index];
          final isMyPart = part.ownerId == currentUserId;
          final theme = Theme.of(context);
          final currencyFormatter = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '',
            decimalDigits: 0,
          );

          // Get signed URLs for this spare part
          final signedUrls = _signedUrlsCache[part.id] ?? [];
          final firstImageUrl = signedUrls.isNotEmpty ? signedUrls.first : null;

          return Card(
            elevation: isMyPart ? 6 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            color:
                isMyPart
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : theme.cardColor,
            child: InkWell(
              onTap: () => context.push('/spare-parts/${part.id}'),
              borderRadius: BorderRadius.circular(16.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    _buildSparePartImage(firstImageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            part.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Condition: ${part.condition.name.toUpperCase()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip(
                                Icons.currency_rupee_rounded,
                                currencyFormatter.format(part.price),
                              ),
                              _buildInfoChip(
                                Icons.location_on_outlined,
                                part.location,
                                onTap: () => _launchMap(part.location),
                              ),
                              _buildInfoChip(
                                Icons.phone_outlined,
                                part.contact,
                                onTap: () => _launchDialer(part.contact),
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
                        size: 40,
                        color: Colors.grey,
                      ),
                )
                : const Icon(
                  Icons.build_circle_outlined,
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