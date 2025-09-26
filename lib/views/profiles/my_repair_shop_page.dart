import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class MyRepairShopPage extends StatefulWidget {
  const MyRepairShopPage({super.key});

  @override
  State<MyRepairShopPage> createState() => _MyRepairShopPageState();
}

class _MyRepairShopPageState extends State<MyRepairShopPage> {
  late final RepairShopService _repairShopService;
  late final String _currentUserId;
  List<RepairShop> _myShops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _error = 'User not logged in.';
      _isLoading = false;
    } else {
      _currentUserId = currentUser.id;
      _loadShops();
    }
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final shops = await _repairShopService.getShopsByOwner(_currentUserId);
      if (!mounted) return;
      setState(() => _myShops = shops);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load your shops: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _deleteShop(String id, String ownerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Repair Shop'),
            content: const Text('Are you sure you want to delete this shop?'),
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
        await _repairShopService.deleteRepairShop(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop deleted successfully')),
        );
        _loadShops();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete shop: $e')));
      }
    }
  }

  void _navigateToAddEdit({RepairShop? shop}) async {
    await context.push('/repair-shop/add', extra: shop);
    if (!mounted) return;
    _loadShops();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'My Shops',
      currentRoute: '/my-repair-shops',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : _myShops.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No repair shops found.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToAddEdit(),
                      child: const Text('Add Repair Shop'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadShops,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _myShops.length,
                  itemBuilder: (context, index) {
                    final shop = _myShops[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: const Icon(
                          Icons.storefront_outlined,
                          size: 40,
                        ),
                        title: Text(
                          shop.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Location: ${shop.location}'),
                            Text('Contact: ${shop.contactNumber}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToAddEdit(shop: shop);
                            } else if (value == 'delete') {
                              _deleteShop(shop.id, shop.ownerId);
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
                        onTap: () => context.push('/repair-shops/${shop.id}'),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        tooltip: 'Add Repair Shop',
        child: const Icon(Icons.add),
      ),
    );
  }
}