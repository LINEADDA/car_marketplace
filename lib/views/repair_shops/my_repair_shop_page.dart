import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_edit_repair_shop_page.dart';

class MyRepairShopPage extends StatefulWidget {
  const MyRepairShopPage({super.key});

  @override
  State<MyRepairShopPage> createState() => _MyRepairShopPageState();
}

class _MyRepairShopPageState extends State<MyRepairShopPage> {
  late final RepairShopService _repairShopService;
  List<RepairShop> _myShops = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    _fetchMyShops();
  }

  Future<void> _fetchMyShops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final shops = await _repairShopService.getShopsByOwnerId(user.id);
      if (mounted) {
        setState(() {
          _myShops = shops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load your shops: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddOrEditShop({RepairShop? shopToEdit}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditRepairShopPage(shopToEdit: shopToEdit),
          ),
        )
        .then((result) {
      if (result == true) {
        _fetchMyShops(); // Refresh the list after saving
      }
    });
  }

  // --- NEW: Method to handle the delete process ---
  Future<void> _handleDelete(RepairShop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop?'),
        content: Text('Are you sure you want to permanently delete "${shop.name}"?'),
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
        // We call the same robust delete method from the service
        await _repairShopService.deleteRepairShop(shop.id, shop.ownerId);
        
        // Refresh the list to remove the item from the UI
        _fetchMyShops();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting shop: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(title: 'My Shops'),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToAddOrEditShop(),
          icon: const Icon(Icons.add),
          label: const Text('Add Shop'),
        ),
      );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_myShops.isEmpty) {
      return const Center(
        child: Text(
          'You have not listed any shops yet.\nTap the "Add Shop" button to get started.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyShops,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0).copyWith(bottom: 80), // Avoid FAB
        itemCount: _myShops.length,
        itemBuilder: (context, index) {
          final shop = _myShops[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(shop.location),
              // --- UPDATED: Added a popup menu for actions ---
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToAddOrEditShop(shopToEdit: shop);
                  } else if (value == 'delete') {
                    _handleDelete(shop);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
              onTap: () => _navigateToAddOrEditShop(shopToEdit: shop), // Keep tap for quick edit
            ),
          );
        },
      ),
    );
  }
}