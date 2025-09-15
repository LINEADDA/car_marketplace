import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';

class CarService {
  final SupabaseClient _client;

  CarService(this._client);

  // Correctly defined method to fetch a single car.
  Future<Car?> getCarById(String carId) async {
    try {
      final response =
          await _client.from('cars').select().eq('id', carId).single();
      return Car.fromMap(response);
    } catch (e) {
      print('Error fetching car by ID: $e');
      return null;
    }
  }

  // Correctly defined method to get all cars for a specific user (replaces getCarsForUser).
  Future<List<Car>> getCarsByOwner(String ownerId) async {
    final response = await _client
        .from('cars')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (response as List).map((item) => Car.fromMap(item)).toList();
  }

  // Correctly defined method to create a car, accepting a Car object.
  Future<void> createCar(Car car) async {
    await _client.from('cars').insert(car.toMap());
  }

  // Correctly defined method to update a car, accepting a Car object.
  Future<void> updateCar(Car car) async {
    await _client.from('cars').update(car.toMap()).eq('id', car.id);
  }

  // Correctly defined method to upload media (replaces uploadCarMediaFile).
  Future<String> uploadCarMedia(String userId, String carId, File file) async {
    final path = '$userId/$carId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('car_media').upload(path, file);
    return _client.storage.from('car_media').getPublicUrl(path);
  }
  
  // Method to delete a car and its associated media.
  Future<void> deleteCar(String carId) async {
    final car = await getCarById(carId);
    if (car != null && car.mediaUrls.isNotEmpty) {
      final fileNames = car.mediaUrls.map((url) {
        final uri = Uri.parse(url);
        // The path in Supabase storage is the part after '/car_media/'
        return uri.path.split('/car_media/').last;
      }).toList();
      
      if (fileNames.isNotEmpty) {
        await _client.storage.from('car_media').remove(fileNames);
      }
    }
    await _client.from('cars').delete().eq('id', carId);
  }

  Future<List<Car>> getAllPublicCars() async {
    final response = await _client
        .from('cars')
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return (response as List).map((item) => Car.fromMap(item)).toList();
  }

  Future<List<Car>> getPublicCarsByListingType(bool isForSale) async {
  final response = await _client
      .from('cars')
      .select()
      .eq('is_public', true)
      .eq('for_sale', isForSale) // The key filtering condition
      .order('created_at', ascending: false);

  return (response as List).map((item) => Car.fromMap(item)).toList();
}
}