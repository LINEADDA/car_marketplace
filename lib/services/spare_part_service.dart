// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spare_part.dart';

class SparePartService {
  final SupabaseClient _client;

  SparePartService(this._client);

  Future<void> createSparePart(SparePart part) async {
    try {
      // The 'toMap()' method from your model handles the conversion perfectly.
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

  Future<List<SparePart>> getAllSpareParts() async {
    try {
      final response = await _client.from('spare_parts').select();
      return (response as List).map((e) => SparePart.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error fetching all spare parts: $e');
    }
  }

  Future<List<SparePart>> getSparePartsByOwner(String userId) async {
    try {
      // Corrected to use 'owner_id' to match your model and database schema
      final response = await _client
          .from('spare_parts')
          .select()
          .eq('owner_id', userId);
      return (response as List).map((e) => SparePart.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error fetching user spare parts: $e');
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

  Future<String> uploadSparePartMedia(String userId, String partId, Uint8List imageBytes) async {
    try {
      // Create a unique filename with timestamp and proper extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtensionFromBytes(imageBytes);
      final fileName = '$userId/$partId/$timestamp.$extension';

      await _client.storage
          .from('spare-parts')
          .uploadBinary(fileName, imageBytes);

      // Get signed URL (valid for 1 year)
      final signedUrl = await _client.storage
          .from('spare-parts')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);

      return signedUrl;
    } catch (e) {
      throw Exception('Error uploading spare part media: $e');
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

        final sparePartIndex = pathSegments.indexOf('spare-parts');
        if (sparePartIndex != -1 && sparePartIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(sparePartIndex + 1).join('/');

          // Generate signed URL (valid for 1 hour)
          final signedUrl = await _client.storage
              .from('spare-part')
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

  Future<void> _deleteSparePartMedia(String userId, String sparePartId) async {
    try {
      final folderPath = '$userId/$sparePartId/';

      // List all files in the car folder
      final filesInFolder = await _client.storage
          .from('spare-parts')
          .list(path: folderPath);

      if (filesInFolder.isNotEmpty) {
        // Create list of file paths to remove
        final pathsToRemove =
            filesInFolder.map((file) => '$folderPath${file.name}').toList();

        // Remove all files
        await _client.storage.from('spare-parts').remove(pathsToRemove);
      }
    } catch (e) {
      print('Warning: Failed to delete spare part media: $e');
    }
  }

  // Future<void> _deleteSpecificMediaFiles(List<String> mediaUrls) async {
  //   try {
  //     if (mediaUrls.isEmpty) return;

  //     final pathsToRemove = <String>[];

  //     for (final url in mediaUrls) {
  //       final uri = Uri.parse(url);
  //       final pathSegments = uri.pathSegments;

  //       final sparePartIndex = pathSegments.indexOf('spare-parts');
  //       if (sparePartIndex != -1 && sparePartIndex < pathSegments.length - 1) {
  //         final filePath = pathSegments.sublist(sparePartIndex + 1).join('/');
  //         pathsToRemove.add(filePath);
  //       }
  //     }

  //     if (pathsToRemove.isNotEmpty) {
  //       await _client.storage.from('spare-parts').remove(pathsToRemove);
  //     }
  //   } catch (e) {
  //     print('Warning: Failed to delete specific media files: $e');
  //   }
  // }

  Future<void> cleanupOrphanedMedia(String userId) async {
    try {
      // Get all cars for this user
      final userSpareParts = await getSparePartsByOwner(userId);
      final validCarIds = userSpareParts.map((part) => part.id).toSet();

      // List all folders in user's storage
      final userFolderPath = '$userId/';
      final foldersInStorage = await _client.storage
          .from('spare-parts')
          .list(path: userFolderPath);

      for (final folder in foldersInStorage) {
        final folderId = folder.name;

        if (!validCarIds.contains(folderId)) {
          await _deleteSparePartMedia(userId, folderId);
        }
      }
    } catch (e) {
      print('Warning: Failed to cleanup orphaned media: $e');
    }
  }
}