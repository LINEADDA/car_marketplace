// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repair_shop.dart';
import 'media_service.dart';

class RepairShopService {
  final SupabaseClient _client;
  late final MediaService mediaService;
  
  RepairShopService(this._client) {
    mediaService = MediaService.forRepairShops(_client);
  }

  Future<void> createRepairShop(RepairShop shop) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('repair_shops').insert(shop.toMap());
    } catch (e) {
      throw Exception('Error creating repair shop: $e');
    }
  }

  Future<RepairShop?> getRepairShopById(String shopId) async {
    try {
      final response =
          await _client
              .from('repair_shops')
              .select()
              .eq('id', shopId)
              .maybeSingle();

      if (response == null) return null;
      return RepairShop.fromMap(response);
    } catch (e) {
      throw Exception('Error fetching repair shop by ID: $e');
    }
  }

  Future<List<RepairShop>> getAllPublicRepairShops() async {
    try {
      final response = await _client.from('repair_shops').select();
      return (response as List)
          .map((item) => RepairShop.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching public repair shops: $e');
    }
  }

  Future<List<RepairShop>> getShopsByOwner([String? userId]) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final ownerId = userId ?? user.id;

    try {
      final response = await _client
          .from('repair_shops')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => RepairShop.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching shops by owner: $e');
    }
  }
  
  Future<void> updateRepairShop(RepairShop shop, {List<String>? removedMediaUrls}) async {
    try {
      if (removedMediaUrls != null && removedMediaUrls.isNotEmpty) {
        await mediaService.deleteSpecificMediaFiles(removedMediaUrls);
      }

      await _client.from('repair_shops').update(shop.toMap()).eq('id', shop.id);
    } catch (e) {
      throw Exception('Error updating repair shop: $e');
    }
  }

  Future<void> deleteRepairShop(String shopId) async {
    try {
      final shop = await getRepairShopById(shopId);
      if (shop != null) {
        await mediaService.deleteMedia(shop.ownerId, shop.id);
      }

      await _client.from('repair_shops').delete().eq('id', shopId);
    } catch (e) {
      throw Exception('Error deleting repair shop: $e');
    }
  }

  Future<void> updateShopService(String shopId, Map<String, dynamic> service) async {
    try {
      final shopData =
          await _client
              .from('repair_shops')
              .select('services')
              .eq('id', shopId)
              .single();

      final currentServices = List<Map<String, dynamic>>.from(
        shopData['services'] ?? [],
      );

      // Find existing service by ID or add new one
      final existingIndex = currentServices.indexWhere(
        (s) => s['id'] == service['id'],
      );

      if (existingIndex != -1) {
        // Update existing service
        currentServices[existingIndex] = service;
      } else {
        // Add new service
        currentServices.add(service);
      }

      await _client
          .from('repair_shops')
          .update({'services': currentServices})
          .eq('id', shopId);
    } catch (e) {
      throw Exception('Error updating shop service: $e');
    }
  }

  Future<void> deleteShopService(String shopId, String serviceId) async {
    try {
      final shopData =
          await _client
              .from('repair_shops')
              .select('services')
              .eq('id', shopId)
              .single();

      final currentServices = List<Map<String, dynamic>>.from(
        shopData['services'] ?? [],
      );

      // Remove service with matching ID
      currentServices.removeWhere((service) => service['id'] == serviceId);

      await _client
          .from('repair_shops')
          .update({'services': currentServices})
          .eq('id', shopId);
    } catch (e) {
      throw Exception('Error deleting shop service: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getShopServices(String shopId) async {
    try {
      final shopData =
          await _client
              .from('repair_shops')
              .select('services')
              .eq('id', shopId)
              .single();

      return List<Map<String, dynamic>>.from(shopData['services'] ?? []);
    } catch (e) {
      throw Exception('Error fetching shop services: $e');
    }
  }

}
