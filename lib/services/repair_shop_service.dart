import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repair_shop.dart';

class RepairShopService {
  final SupabaseClient _client;

  RepairShopService(this._client);

  // Fetches ALL repair shops for the public listing (no RLS for shop services here)
  Future<List<RepairShop>> getAllPublicRepairShops() async {
    final response = await _client.from('repair_shops').select();
    final data = response as List;
    return data.map((item) => RepairShop.fromMap(item)).toList();
  }

  // Creates a new repair shop (media_urls is handled separately)
  Future<Map<String, dynamic>> createRepairShop(
    Map<String, dynamic> shopData,
  ) async {
    shopData.remove('id'); // Ensure ID is not sent for new creation
    final response =
        await _client.from('repair_shops').insert(shopData).select().single();
    return response;
  }

  // Updates an existing repair shop
  Future<void> updateRepairShop(RepairShop shop) async {
    // When updating, we convert the ShopService list back to a list of maps (JSONB)
    await _client.from('repair_shops').update(shop.toMap()).eq('id', shop.id);
  }

  // Uploads shop media files (remains largely the same)
  Future<String> uploadShopMediaFile(
    String userId,
    String shopId,
    File file,
  ) async {
    final path = '$userId/$shopId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('repair_shop_media').upload(path, file);
    return _client.storage.from('repair_shop_media').getPublicUrl(path);
  }

  // Updates ONLY the media URLs for a shop (useful after initial creation)
  Future<void> updateShopMedia(String shopId, List<String> mediaUrls) async {
    await _client
        .from('repair_shops')
        .update({'media_urls': mediaUrls}).eq('id', shopId);
  }

  // Fetches a single repair shop by its ID (for detail view)
  // This now directly uses the ShopService list from the JSONB column
  Future<RepairShop> getRepairShopById(String shopId) async {
    final response =
        await _client.from('repair_shops').select().eq('id', shopId).single();
    return RepairShop.fromMap(response);
  }

  // Fetches a repair shop for a specific owner (for 'My Repair Shop' page)
  // This also directly uses the ShopService list from the JSONB column
  Future<RepairShop?> getShopForOwner(String ownerId) async {
    final response =
        await _client
            .from('repair_shops')
            .select()
            .eq('owner_id', ownerId)
            .maybeSingle();
    if (response == null) {
      return null;
    }
    return RepairShop.fromMap(response);
  }

  Future<List<RepairShop>> getShopsByOwnerId(String ownerId) async {
    final response = await _client
        .from('repair_shops')
        .select()
        .eq('owner_id', ownerId);
    final data = response as List;
    return data.map((item) => RepairShop.fromMap(item)).toList();
  }

  /// Deletes an entire repair shop, including all associated files in storage.
  Future<void> deleteRepairShop(String shopId, String ownerId) async {
    try {
      final folderPath = '$ownerId/$shopId';
      final filesInFolder = await _client.storage.from('repair_shop_media').list(path: folderPath);

      if (filesInFolder.isNotEmpty) {
        final pathsToRemove = filesInFolder.map((file) => '$folderPath/${file.name}').toList();
        await _client.storage.from('repair_shop_media').remove(pathsToRemove);
      }

      await _client.from('repair_shops').delete().eq('id', shopId);
      
    } catch (e) {
      print('Error during full deletion of shop $shopId: $e');
      rethrow;
    }
  }

  Future<void> deleteShopService(String shopId, String serviceId) async {
    try {

      final shopData = await _client
          .from('repair_shops')
          .select('services')
          .eq('id', shopId)
          .single();
      
      final currentServices = List<Map<String, dynamic>>.from(shopData['services'] ?? []);

      currentServices.removeWhere((service) => service['id'] == serviceId);

      await _client
          .from('repair_shops')
          .update({'services': currentServices})
          .eq('id', shopId);

    } catch (e) {
      print('Error deleting service $serviceId from shop $shopId: $e');
      rethrow;
    }
  }
}