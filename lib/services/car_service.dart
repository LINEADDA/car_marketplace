import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';

class CarService {
  final SupabaseClient _client;

  CarService(this._client);

  Future<void> updateCarVisibility(String carId, bool isPublic) async {
    await _client.from('cars').update({'is_public': isPublic}).eq('id', carId);
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
          .eq('for_sale', false)
          .order('created_at', ascending: false);
      return (response as List).map((item) => Car.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Car>> getPublicCarsByListingType(
    bool bool, {
    bool? isForSale,
  }) async {
    try {
      var query = _client.from('cars').select('*').eq('is_public', true);

      if (isForSale != null) {
        query = query.eq('for_sale', isForSale);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((item) => Car.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Car>> getCarsByOwner() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('cars')
          .select('*')
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((item) => Car.fromMap(item)).toList();
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

  Future<void> updateCar(Car car) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('cars').update(car.toMap()).eq('id', car.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCar(String carId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('cars').delete().eq('id', carId);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadCarMedia(String userId, String carId, File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final path = 'cars/$userId/$carId/$fileName';

    await _client.storage.from('car-images').upload(path, file);
    return _client.storage.from('car-images').getPublicUrl(path);
  }
}
