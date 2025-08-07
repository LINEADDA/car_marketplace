import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spare_part.dart';

class SparePartService {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'spare_parts';
  static const String _storageBucket = 'spare-parts'; // Storage bucket for part media

  SparePartService(this._supabaseClient);

  // Uploads a single media file (image or video) for a spare part.
  Future<String> uploadSparePartMediaFile(String userId, String partId, File file) async {
    try {
      // Create a unique file path.
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$partId/$fileName';

      // Upload the file to the 'spare-parts' bucket.
      await _supabaseClient.storage.from(_storageBucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Retrieve and return the public URL.
      final publicUrl =
          _supabaseClient.storage.from(_storageBucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('An unexpected error occurred during spare part media upload: $e');
      rethrow;
    }
  }

  // Fetches all public spare parts for the marketplace view.
  Future<List<SparePart>> getAllPublicSpareParts() async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return response.map((map) => SparePart.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      print('Error fetching all spare parts: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in getAllPublicSpareParts: $e');
      rethrow;
    }
  }

  // Fetches a list of spare parts owned by a specific user profile.
  Future<List<SparePart>> getSparePartsForUser(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('owner_id', userId);

      return response.map((map) => SparePart.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      print('Error fetching spare parts for user $userId: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in getSparePartsForUser: $e');
      rethrow;
    }
  }

  // Adds a new spare part to the database.
  Future<SparePart> createSparePart(SparePart part) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .insert(part.toMap())
          .select()
          .single();

      return SparePart.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error creating spare part: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in createSparePart: $e');
      rethrow;
    }
  }

  // Updates an existing spare part in the database.
  Future<SparePart> updateSparePart(SparePart part) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .update(part.toMap())
          .eq('id', part.id)
          .select()
          .single();

      return SparePart.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error updating spare part ${part.id}: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in updateSparePart: $e');
      rethrow;
    }
  }

  // Deletes a spare part from the database.
  Future<void> deleteSparePart(String partId) async {
    try {
      await _supabaseClient.from(_tableName).delete().eq('id', partId);
    } on PostgrestException catch (e) {
      print('Error deleting spare part $partId: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in deleteSparePart: $e');
      rethrow;
    }
  }
}
