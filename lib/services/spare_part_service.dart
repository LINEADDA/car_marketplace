import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spare_part.dart';

class SparePartService {
  final SupabaseClient _client;

  SparePartService(this._client);

  Future<List<SparePart>> getAllSpareParts() async {
    try {
      final response = await _client.from('spare_parts').select();
      return (response as List).map((e) => SparePart.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error fetching all spare parts: $e');
    }
  }

  Future<List<SparePart>> getSparePartsForUser(String userId) async {
    try {
      // Corrected to use 'owner_id' to match your model and database schema
      final response = await _client.from('spare_parts').select().eq('owner_id', userId);
      return (response as List).map((e) => SparePart.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error fetching user spare parts: $e');
    }
  }

  Future<SparePart?> getPartById(String id) async {
    try {
      final response = await _client.from('spare_parts').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return SparePart.fromMap(response);
    } catch (e) {
      throw Exception('Error fetching part by ID: $e');
    }
  }

  Future<void> createSparePart(SparePart part) async {
    try {
      // The 'toMap()' method from your model handles the conversion perfectly.
      await _client.from('spare_parts').insert(part.toMap());
    } catch (e) {
      throw Exception('Error creating spare part: $e');
    }
  }

  Future<void> updateSparePart(SparePart part) async {
    try {
      await _client.from('spare_parts').update(part.toMap()).eq('id', part.id);
    } catch (e) {
      throw Exception('Error updating spare part: $e');
    }
  }

  Future<void> deleteSparePart(String id) async {
    try {
      await _client.from('spare_parts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting spare part: $e');
    }
  }
}