import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repair_shop.dart'; // Assuming a RepairShop model exists

class RepairShopService {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'repair_shops';
  static const String _storageBucket = 'shop-media'; // Storage bucket for shop logos/photos

  RepairShopService(this._supabaseClient);

  // Uploads a single media file (image or video) for a repair shop.
  Future<String> uploadShopMediaFile(String userId, String shopId, File file) async {
    try {
      // Create a unique file path to prevent overwrites.
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$shopId/$fileName';

      // Upload the file to the 'shop-media' bucket.
      await _supabaseClient.storage.from(_storageBucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Retrieve and return the public URL for the uploaded file.
      final publicUrl =
          _supabaseClient.storage.from(_storageBucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('An unexpected error occurred during shop media upload: $e');
      rethrow;
    }
  }

  // Fetches all public repair shops for users to browse.
  Future<List<RepairShop>> getAllPublicRepairShops() async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('is_public', true) // Only fetch shops marked as public
          .order('name', ascending: true); // Order alphabetically by name

      return response.map((map) => RepairShop.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      print('Error fetching all repair shops: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in getAllPublicRepairShops: $e');
      rethrow;
    }
  }

  // Fetches the repair shop owned by a specific user profile.
  // Returns null if the user does not own a shop.
  Future<RepairShop?> getRepairShopForUser(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('owner_id', userId)
          .maybeSingle(); // Use maybeSingle() to safely handle 0 or 1 result.

      if (response == null) {
        return null;
      }
      return RepairShop.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error fetching repair shop for user $userId: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in getRepairShopForUser: $e');
      rethrow;
    }
  }

  // Creates a new repair shop record.
  Future<RepairShop> createRepairShop(RepairShop shop) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .insert(shop.toMap())
          .select()
          .single();

      return RepairShop.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error creating repair shop: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in createRepairShop: $e');
      rethrow;
    }
  }

  // Updates an existing repair shop.
  Future<RepairShop> updateRepairShop(RepairShop shop) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .update(shop.toMap())
          .eq('id', shop.id)
          .select()
          .single();

      return RepairShop.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error updating repair shop ${shop.id}: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in updateRepairShop: $e');
      rethrow;
    }
  }

  // Deletes a repair shop.
  Future<void> deleteRepairShop(String shopId) async {
    try {
      await _supabaseClient.from(_tableName).delete().eq('id', shopId);
    } on PostgrestException catch (e) {
      print('Error deleting repair shop $shopId: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in deleteRepairShop: $e');
      rethrow;
    }
  }
}
