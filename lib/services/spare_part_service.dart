// ignore_for_file: avoid_print

import 'dart:typed_data';
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
      return [];
    }
  }

  Future<List<SparePart>> getSparePartsForUser(String userId) async {
    try {
      final response = await _client.from('spare_parts').select().eq('owner_id', userId);
      return (response as List).map((e) => SparePart.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<SparePart?> getPartById(String id) async {
    try {
      final response = await _client.from('spare_parts').select().eq('id', id).maybeSingle();
      return response == null ? null : SparePart.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> createSparePart(SparePart part) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('spare_parts').insert(part.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete spare part media files when deleting a spare part
  Future<void> _deleteSparePartMedia(String userId, String sparePartId) async {
    try {
      final folderPath = '$userId/$sparePartId/';
      // List all files in the spare part folder
      final filesInFolder = await _client.storage.from('spare-parts').list(path: folderPath);

      if (filesInFolder.isNotEmpty) {
        final pathsToRemove = filesInFolder.map((file) => '$folderPath${file.name}').toList();
        await _client.storage.from('spare-parts').remove(pathsToRemove);
      }
    } catch (e) {
      print('Warning: Failed to delete spare part media: $e');
    }
  }

  /// Delete specific media files (used during updates)
  Future<void> _deleteSpecificMediaFiles(List<String> mediaUrls) async {
    try {
      if (mediaUrls.isEmpty) return;

      final pathsToRemove = <String>[];

      for (final url in mediaUrls) {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        final sparePartsIndex = pathSegments.indexOf('spare-parts');

        if (sparePartsIndex != -1 && sparePartsIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(sparePartsIndex + 1).join('/');
          pathsToRemove.add(filePath);
        }
      }

      if (pathsToRemove.isNotEmpty) {
        await _client.storage.from('spare-parts').remove(pathsToRemove);
      }
    } catch (e) {
      print('Warning: Failed to delete specific media files: $e');
    }
  }

  /// Delete spare part and its media
  Future<void> deleteSparePart(String id) async {
    try {
      final sparePart = await getPartById(id);
      if (sparePart != null) {
        await _deleteSparePartMedia(sparePart.ownerId, sparePart.id);
      }

      await _client.from('spare_parts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting spare part: $e');
    }
  }

  /// Update spare part with media management
  Future<void> updateSparePart(SparePart part, {List<String>? removedMediaUrls}) async {
    try {
      if (removedMediaUrls != null && removedMediaUrls.isNotEmpty) {
        await _deleteSpecificMediaFiles(removedMediaUrls);
      }

      await _client.from('spare_parts').update(part.toMap()).eq('id', part.id);
    } catch (e) {
      throw Exception('Error updating spare part: $e');
    }
  }

  /// Clean up orphaned media files (utility method)
  /// Should be called periodically
  Future<void> cleanupOrphanedMedia(String userId) async {
    try {
      final userSpareParts = await getSparePartsForUser(userId);
      final validSparePartIds = userSpareParts.map((sp) => sp.id).toSet();

      final userFolderPath = '$userId/';
      final foldersInStorage = await _client.storage.from('spare-parts').list(path: userFolderPath);

      for (final folder in foldersInStorage) {
        final folderId = folder.name;
        if (!validSparePartIds.contains(folderId)) {
          await _deleteSparePartMedia(userId, folderId);
        }
      }
    } catch (e) {
      print('Warning: Failed to cleanup orphaned media: $e');
    }
  }

  String _getFileExtensionFromBytes(Uint8List bytes) {
    if (bytes.length >= 8) {
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'jpeg';
      }
    }
    return 'jpeg';
  }

  /// Upload spare part media
  Future<String> uploadSparePartMedia(String userId, String sparePartId, Uint8List imageBytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtensionFromBytes(imageBytes);
      final fileName = '$userId/$sparePartId/$timestamp.$extension';

      await _client.storage.from('spare-parts').uploadBinary(fileName, imageBytes);

      final signedUrl = await _client.storage.from('spare-parts').createSignedUrl(fileName, 60 * 60 * 24 * 365);

      return signedUrl;
    } catch (e) {
      throw Exception('Error uploading spare part media: $e');
    }
  }

  /// Generate signed URLs for existing media
  Future<List<String>> getSignedMediaUrls(List<String> mediaUrls) async {
    final signedUrls = <String>[];

    for (final url in mediaUrls) {
      try {
        if (url.contains('token=') || url.contains('?')) {
          signedUrls.add(url);
          continue;
        }

        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        final sparePartsIndex = pathSegments.indexOf('spare-parts');

        if (sparePartsIndex != -1 && sparePartsIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(sparePartsIndex + 1).join('/');

          final signedUrl = await _client.storage.from('spare-parts').createSignedUrl(filePath, 60 * 60);

          signedUrls.add(signedUrl);
        } else {
          signedUrls.add(url);
        }
      } catch (e) {
        signedUrls.add(url);
      }
    }

    return signedUrls;
  }
}