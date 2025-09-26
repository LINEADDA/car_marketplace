// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';
import '../services/media_service.dart';

class CarService {
  final SupabaseClient _client;
  late final MediaService mediaService;
  
  CarService(this._client) {
    mediaService = MediaService.forCars(_client);
  }

  Future<void> updateCarVisibility(String carId, bool isAvailable) async {
    try {
      await _client
          .from('cars')
          .update({'is_available': isAvailable})
          .eq('id', carId)
          .select();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createCar(Car car) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('cars').insert(car.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<Car?> getCarById(String carId) async {
    try {
      if (carId.isEmpty ||
          carId == 'browse' ||
          carId == 'sale' ||
          carId == 'booking') {
        return null;
      }

      final response =
          await _client
              .from('cars')
              .select('*')
              .eq('id', carId)
              .eq('is_public', true)
              .eq('is_available', true)
              .maybeSingle();

      return response == null ? null : Car.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Car>> getAllPublicCars() async {
    try {
      final response = await _client
          .from('cars')
          .select('*')
          .eq('is_public', true)
          .eq('is_available', true)
          .order('created_at', ascending: false);

      return (response as List).map((item) => Car.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Car>> getCarsForSale() async {
    try {
      final response = await _client
          .from('cars')
          .select('*')
          .eq('is_public', true)
          .eq('is_available', true)
          .eq('for_sale', true)
          .order('created_at', ascending: false);
      return (response as List).map((item) => Car.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Car>> getCarsForBooking() async {
    try {
      final response = await _client
          .from('cars')
          .select('*')
          .eq('is_public', true)
          .eq('is_available', true)
          .eq('for_sale', false)
          .order('created_at', ascending: false);
      return (response as List).map((item) => Car.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Car>> getCarsByOwner([String? userId]) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Use provided userId or current user's id
    final ownerId = userId ?? user.id;

    try {
      final response = await _client
          .from('cars')
          .select('*')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => Car.fromMap(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCar(Car car, {List<String>? removedMediaUrls}) async {
    try {
      if (removedMediaUrls != null && removedMediaUrls.isNotEmpty) {
        await mediaService.deleteSpecificMediaFiles(removedMediaUrls);
      }

      await _client.from('cars').update(car.toMap()).eq('id', car.id);
    } catch (e) {
      throw Exception('Error updating car: $e');
    }
  }

  Future<void> deleteCar(String id) async {
    try {
      final car = await getCarById(id);
      if (car != null) {
        await mediaService.deleteMedia(car.ownerId, car.id);
      }

      await _client.from('cars').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting car: $e');
    }
  }

}
