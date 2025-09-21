import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class SparePartListPage extends StatefulWidget {
  final bool showMyParts;

  const SparePartListPage({super.key, this.showMyParts = false});

  @override
  State<SparePartListPage> createState() => _SparePartListPageState();
}

class _SparePartListPageState extends State<SparePartListPage> {
  late final SparePartService _sparePartService;
  List<SparePart> _parts = [];
  bool _isLoading = true;
  String? _errorMessage;
  final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _fetchParts();
  }

  Future<void> _fetchParts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<SparePart> parts;
      final user = Supabase.instance.client.auth.currentUser;

      if (widget.showMyParts && user != null) {
        parts = await _sparePartService.getSparePartsForUser(user.id);
      } else {
        parts = await _sparePartService.getAllSpareParts();
      }

      if (mounted) {
        setState(() {
          _parts = parts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load parts: $e";
          _isLoading = false;
        });
      }
    }
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
      title: 'Spare Parts',
      currentRoute: '/spare-parts',
      body: _buildBody(),
      floatingActionButton: widget.showMyParts
          ? FloatingActionButton(
              onPressed: () => context.push('/spare-parts/add'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_parts.isEmpty) {
      final message = widget.showMyParts
          ? 'You have not listed any parts yet.'
          : 'No spare parts are currently available.';
      return Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final myParts =
        _parts.where((part) => part.ownerId == currentUserId).toList();
    final otherParts =
        _parts.where((part) => part.ownerId != currentUserId).toList();
    final sortedParts = [...myParts, ...otherParts];

    return RefreshIndicator(
      onRefresh: _fetchParts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedParts.length,
        itemBuilder: (context, index) {
          final part = sortedParts[index];
          final isMyPart = part.ownerId == currentUserId;
          final theme = Theme.of(context);

          return Card(
            elevation: isMyPart ? 6 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            color: isMyPart
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
                    _buildPartImage(part.mediaUrls.firstOrNull),
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
                          _buildInfoChip(
                            Icons.currency_rupee_rounded,
                            part.price.toStringAsFixed(0),
                            onTap: null,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
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
                          if (isMyPart) ...[
                            const SizedBox(height: 8),
                            _buildMyPartTag(context),
                          ],
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

  Widget _buildPartImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade200,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
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

  Widget _buildMyPartTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'My Part',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}