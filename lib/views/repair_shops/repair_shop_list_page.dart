import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/repair_shop_card.dart';
import 'repair_shop_detail_page.dart';

class RepairShopListPage extends StatefulWidget {
  const RepairShopListPage({super.key});

  @override
  State<RepairShopListPage> createState() => _RepairShopListPageState();
}

class _RepairShopListPageState extends State<RepairShopListPage> {
  late final RepairShopService _repairShopService;
  late Future<List<RepairShop>> _shopsFuture;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Repair Shops'),
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
              child: Text('No repair shops found.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshShopList(),
            child: ListView.builder(
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return RepairShopCard(
                  shop: shop,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RepairShopDetailPage(shopId: shop.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
