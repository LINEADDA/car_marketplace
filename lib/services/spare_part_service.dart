import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spare_part.dart';

class SparePartService {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'spare_parts';
  static const String _storageBucket = 'spare-parts';

  SparePartService(this._supabaseClient);

  Future<String> uploadSparePartMediaFile(String userId, String partId, File file) async {
    try {
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$partId/$fileName';
      await _supabaseClient.storage.from(_storageBucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabaseClient.storage.from(_storageBucket).getPublicUrl(filePath);
    } catch (e) {
      print('An unexpected error occurred during spare part media upload: $e');
      rethrow;
    }
  }

  Future<List<SparePart>> getAllPublicSpareParts() async {
    try {
      final response = await _supabaseClient.from(_tableName).select().order('created_at', ascending: false);
      return response.map((map) => SparePart.fromMap(map)).toList();
    } catch (e) {
      print('An unexpected error occurred in getAllPublicSpareParts: $e');
      rethrow;
    }
  }

  Future<List<SparePart>> getSparePartsForUser(String userId) async {
    try {
      final response = await _supabaseClient.from(_tableName).select().eq('owner_id', userId).order('created_at', ascending: false);
      return response.map((map) => SparePart.fromMap(map)).toList();
    } catch (e) {
      print('An unexpected error occurred in getSparePartsForUser: $e');
      rethrow;
    }
  }

  Future<SparePart> createSparePart(SparePart part) async {
    try {
      final response = await _supabaseClient.from(_tableName).insert(part.toMap()).select().single();
      return SparePart.fromMap(response);
    } catch (e) {
      print('An unexpected error occurred in createSparePart: $e');
      rethrow;
    }
  }

  Future<SparePart> updateSparePart(SparePart part) async {
    try {
      final response = await _supabaseClient.from(_tableName).update(part.toMap()).eq('id', part.id).select().single();
      return SparePart.fromMap(response);
    } catch (e) {
      print('An unexpected error occurred in updateSparePart: $e');
      rethrow;
    }
  }

  Future<SparePart?> getPartById(String partId) async {
    try {
      final response = await _supabaseClient.from('spare_parts').select().eq('id', partId).single();
      return SparePart.fromMap(response);
    } catch (e) {
      print('Error fetching part by ID: $e');
      return null;
    }
  }

  // --- UPDATED METHOD: Now deletes associated storage files ---
  Future<void> deleteSparePart(String partId) async {
    try {
      // Step 1: Fetch the part to get its ownerId for the storage path.
      final part = await getPartById(partId);
      if (part == null) {
        print('Part not found, skipping delete.');
        return;
      }

      // Step 2: If the part has images, delete the entire folder from storage.
      if (part.mediaUrls.isNotEmpty) {
        final folderPath = '${part.ownerId}/${part.id}';
        final files = await _supabaseClient.storage.from(_storageBucket).list(path: folderPath);
        if (files.isNotEmpty) {
          final pathsToRemove = files.map((file) => '$folderPath/${file.name}').toList();
          await _supabaseClient.storage.from(_storageBucket).remove(pathsToRemove);
        }
      }

      // Step 3: Delete the database record.
      await _supabaseClient.from(_tableName).delete().eq('id', partId);
    } catch (e) {
      print('An error occurred during full deletion of spare part $partId: $e');
      rethrow;
    }
  }
}