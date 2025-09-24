// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';

class CarService {
  final SupabaseClient _client;

  CarService(this._client);

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

  Future<List<Car>> getPublicCarsByListingType(
    bool bool, {
    bool? isForSale,
  }) async {
    try {
      var query = _client
          .from('cars')
          .select('*')
          .eq('is_public', true)
          .eq('is_available', true);

      if (isForSale != null) {
        query = query.eq('for_sale', isForSale);
      }

      final response = await query.order('created_at', ascending: false);
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

  Future<void> createCar(Car car) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('cars').insert(car.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete car media files when deleting a car
  Future<void> _deleteCarMedia(String userId, String carId) async {
    try {
      final folderPath = '$userId/$carId/';

      // List all files in the car folder
      final filesInFolder = await _client.storage
          .from('cars')
          .list(path: folderPath);

      if (filesInFolder.isNotEmpty) {
        // Create list of file paths to remove
        final pathsToRemove =
            filesInFolder.map((file) => '$folderPath${file.name}').toList();

        // Remove all files
        await _client.storage.from('cars').remove(pathsToRemove);
      }
    } catch (e) {
      // Don't throw here as we still want to delete the car record
      // even if media deletion fails
      print('Warning: Failed to delete car media: $e');
    }
  }

  /// Delete specific media files (used during updates)
  Future<void> _deleteSpecificMediaFiles(List<String> mediaUrls) async {
    try {
      if (mediaUrls.isEmpty) return;

      final pathsToRemove = <String>[];

      for (final url in mediaUrls) {
        // Extract the file path from the URL
        // URL format: https://your-project.supabase.co/storage/v1/object/public/cars/userId/carId/timestamp.jpg
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;

        // Find 'cars' in the path and extract everything after it
        final carsIndex = pathSegments.indexOf('cars');
        if (carsIndex != -1 && carsIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(carsIndex + 1).join('/');
          pathsToRemove.add(filePath);
        }
      }

      if (pathsToRemove.isNotEmpty) {
        await _client.storage.from('cars').remove(pathsToRemove);
      }
    } catch (e) {
      print('Warning: Failed to delete specific media files: $e');
    }
  }

  /// Updated deleteCar method with media cleanup
  Future<void> deleteCar(String id) async {
    try {
      // First, get the car to extract media info
      final car = await getCarById(id);
      if (car != null) {
        // Delete associated media files
        await _deleteCarMedia(car.ownerId, car.id);
      }

      // Then delete the car record
      await _client.from('cars').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting car: $e');
    }
  }

  /// Updated updateCar method with intelligent media management
  Future<void> updateCar(Car car, {List<String>? removedMediaUrls}) async {
    try {
      // First, delete any media files that were removed during editing
      if (removedMediaUrls != null && removedMediaUrls.isNotEmpty) {
        await _deleteSpecificMediaFiles(removedMediaUrls);
      }

      // Then update the car record
      await _client.from('cars').update(car.toMap()).eq('id', car.id);
    } catch (e) {
      throw Exception('Error updating car: $e');
    }
  }

  /// Clean up orphaned media files (utility method)
  /// This can be called periodically to clean up any orphaned files
  Future<void> cleanupOrphanedMedia(String userId) async {
    try {
      // Get all cars for this user
      final userCars = await getCarsByOwner(userId);
      final validCarIds = userCars.map((car) => car.id).toSet();

      // List all folders in user's storage
      final userFolderPath = '$userId/';
      final foldersInStorage = await _client.storage
          .from('cars')
          .list(path: userFolderPath);

      for (final folder in foldersInStorage) {
        final folderId = folder.name;

        // If this folder doesn't correspond to a valid car, delete it
        if (!validCarIds.contains(folderId)) {
          await _deleteCarMedia(userId, folderId);
        }
      }
    } catch (e) {
      print('Warning: Failed to cleanup orphaned media: $e');
    }
  }

  String _getFileExtensionFromBytes(Uint8List bytes) {
    // Check file signature (magic numbers)
    if (bytes.length >= 8) {
      // PNG signature
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      // JPEG signature (covers both .jpg and .jpeg files)
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'jpeg'; // Always use 'jpeg' to match bucket restrictions
      }
    }
    // Default to jpeg if can't determine (most images are JPEG)
    return 'jpeg';
  }

  Future<String> uploadCarMedia(
    String userId,
    String carId,
    Uint8List imageBytes,
  ) async {
    try {
      // Create a unique filename with timestamp and proper extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtensionFromBytes(imageBytes);
      final fileName = '$userId/$carId/$timestamp.$extension';

      // Upload to the private 'cars' bucket
      await _client.storage.from('cars').uploadBinary(fileName, imageBytes);

      // Get signed URL (valid for 1 year)
      final signedUrl = await _client.storage
          .from('cars')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);

      return signedUrl;
    } catch (e) {
      throw Exception('Error uploading car media: $e');
    }
  }

  Future<List<String>> getSignedMediaUrls(List<String> mediaUrls) async {
    final signedUrls = <String>[];

    for (final url in mediaUrls) {
      try {
        // Check if URL is already a signed URL or contains signed parameters
        if (url.contains('token=') || url.contains('?')) {
          // Already a signed URL, use as-is
          signedUrls.add(url);
          continue;
        }

        // Extract the file path from the URL
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;

        // Find 'cars' in the path and extract everything after it
        final carsIndex = pathSegments.indexOf('cars');
        if (carsIndex != -1 && carsIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(carsIndex + 1).join('/');

          // Generate signed URL (valid for 1 hour)
          final signedUrl = await _client.storage
              .from('cars')
              .createSignedUrl(filePath, 60 * 60);

          signedUrls.add(signedUrl);
        } else {
          // If we can't parse the URL, add it as-is and let error handling deal with it
          signedUrls.add(url);
        }
      } catch (e) {
        // If signing fails, add the original URL and let error handling deal with it
        signedUrls.add(url);
      }
    }

    return signedUrls;
  }
}
