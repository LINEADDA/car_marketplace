// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spare_part.dart';
import 'media_service.dart';

class SparePartService {
  final SupabaseClient _client;
  late final MediaService mediaService;

  SparePartService(this._client) {
    mediaService = MediaService.forSpareParts(_client);
  }

  Future<void> createSparePart(SparePart part) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('spare_parts').insert(part.toMap());
    } catch (e) {
      throw Exception('Error creating spare part: $e');
    }
  }

  Future<SparePart?> getPartById(String id) async {
    try {
      final response =
          await _client.from('spare_parts').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return SparePart.fromMap(response);
    } catch (e) {
      throw Exception('Error fetching part by ID: $e');
    }
  }

  Future<List<SparePart>> getAllPublicSpareParts() async {
    try {
      final response = await _client.from('spare_parts').select();
      return (response as List).map((e) => SparePart.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error fetching all spare parts: $e');
    }
  }

  Future<List<SparePart>> getSparePartsByOwner(String userId) async {
    try {
      final response = await _client
          .from('spare_parts')
          .select()
          .eq('owner_id', userId);
      return (response as List).map((e) => SparePart.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error fetching user spare parts: $e');
    }
  }

  Future<void> updateSparePart(SparePart part, {List<String>? removedMediaUrls}) async {
    try {
      if (removedMediaUrls != null && removedMediaUrls.isNotEmpty) {
        await mediaService.deleteSpecificMediaFiles(removedMediaUrls);
      }

      await _client.from('spare_parts').update(part.toMap()).eq('id', part.id);
    } catch (e) {
      throw Exception('Error updating spare part: $e');
    }
  }

  Future<void> deleteSparePart(String id) async {
    try {
      final part = await getPartById(id);
      if (part != null) {
        await mediaService.deleteMedia(part.ownerId, part.id);
      }

      await _client.from('spare_parts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting spare part: $e');
    }
  }

}