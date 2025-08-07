import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';

class CarService {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'cars';
  static const String _storageBucket = 'cars'; // Storage bucket for car media

  CarService(this._supabaseClient);

  // Uploads a single media file (image or video) for a car.
  Future<String> uploadCarMediaFile(String userId, String carId, File file) async {
    try {
      // Create a unique file path to prevent overwrites.
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$carId/$fileName';

      // Upload the file to the 'cars' bucket.
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
      print('An unexpected error occurred during car media upload: $e');
      rethrow;
    }
  }

  // Fetches all public cars for the marketplace view.
  Future<List<Car>> getAllPublicCars() async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('is_public', true)
          .eq('for_sale', true)
          .order('created_at', ascending: false);

      return response.map((map) => Car.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      print('Error fetching all public cars: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in getAllPublicCars: $e');
      rethrow;
    }
  }

  // Fetches a list of all cars owned by a specific user profile.
  Future<List<Car>> getCarsForUser(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('owner_id', userId);

      return response.map((map) => Car.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      print('Error fetching cars for user: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in getCarsForUser: $e');
      rethrow;
    }
  }

  // Adds a new car to the database.
  Future<Car> createCar(Car car) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .insert(car.toMap())
          .select()
          .single();

      return Car.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error creating car: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in createCar: $e');
      rethrow;
    }
  }

  // Updates an existing car in the database.
  Future<Car> updateCar(Car car) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .update(car.toMap())
          .eq('id', car.id)
          .select()
          .single();

      return Car.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error updating car: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in updateCar: $e');
      rethrow;
    }
  }

  // Deletes a car from the database.
  Future<void> deleteCar(String carId) async {
    try {
      await _supabaseClient.from(_tableName).delete().eq('id', carId);
    } on PostgrestException catch (e) {
      print('Error deleting car: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in deleteCar: $e');
      rethrow;
    }
  }
}
