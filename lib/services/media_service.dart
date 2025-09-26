// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration for media service operations
class MediaConfig {
  final String bucketName;
  final int maxFileSizeBytes;
  final int imageQuality;
  final Duration urlValidityDuration;
  final List<String> allowedExtensions;

  const MediaConfig({
    required this.bucketName,
    this.maxFileSizeBytes = 10 * 1024 * 1024, // 10MB default
    this.imageQuality = 80,
    this.urlValidityDuration = const Duration(days: 365),
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'webp'],
  });

  static const MediaConfig cars = MediaConfig(bucketName: 'cars',
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],);
  static const MediaConfig spareParts = MediaConfig(bucketName: 'spare-parts',
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],);
  static const MediaConfig repairShops = MediaConfig(bucketName: 'repair-shops',
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],);
}

/// Result of media validation
class MediaValidationResult {
  final List<XFile> validFiles;
  final List<String> invalidFileNames;
  final List<String> errors;

  MediaValidationResult({
    required this.validFiles,
    required this.invalidFileNames,
    required this.errors,
  });

  bool get hasValidFiles => validFiles.isNotEmpty;
  bool get hasInvalidFiles => invalidFileNames.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// Callbacks for UI interaction
class MediaServiceCallbacks {
  final Function(List<XFile> validFiles) onFilesAdded;
  final Function(int index) onFileRemoved;
  final Function(int index) onExistingFileRemoved;
  final Function(String message, {Color? backgroundColor}) onShowSnackBar;
  final Function() onShowLoading;
  final Function() onHideLoading;

  MediaServiceCallbacks({
    required this.onFilesAdded,
    required this.onFileRemoved,
    required this.onExistingFileRemoved,
    required this.onShowSnackBar,
    required this.onShowLoading,
    required this.onHideLoading,
  });
}

class MediaService {
  final SupabaseClient _client;
  final MediaConfig _config;

  MediaService(this._client, this._config);

  factory MediaService.forCars(SupabaseClient client) => MediaService(client, MediaConfig.cars);

  factory MediaService.forSpareParts(SupabaseClient client) => MediaService(client, MediaConfig.spareParts);

  factory MediaService.forRepairShops(SupabaseClient client) => MediaService(client, MediaConfig.repairShops);

  Future<bool> validateImageFile(XFile file) async {
    try {
      final fileSize = await file.length();
      if (fileSize > _config.maxFileSizeBytes) return false;
      if (fileSize < 1024) return false; 
      final fileName = file.name.toLowerCase();
      final hasValidExtension = _config.allowedExtensions.any(
        (ext) => fileName.endsWith('.$ext'),
      );
      if (!hasValidExtension) return false;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return false;

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image.width > 0 && frame.image.height > 0;
    } catch (e) {
      return false;
    }
  }

  Future<MediaValidationResult> validateFiles(List<XFile> files) async {
    final validFiles = <XFile>[];
    final invalidFileNames = <String>[];
    final errors = <String>[];

    for (final file in files) {
      try {
        final isValid = await validateImageFile(file);
        if (isValid) {
          validFiles.add(file);
        } else {
          invalidFileNames.add(file.name);
        }
      } catch (e) {
        errors.add('Error validating ${file.name}: $e');
        invalidFileNames.add(file.name);
      }
    }

    return MediaValidationResult(
      validFiles: validFiles,
      invalidFileNames: invalidFileNames,
      errors: errors,
    );
  }

  Future<void> pickImages(BuildContext context, MediaServiceCallbacks callbacks) async {
    try {
      final images = await ImagePicker().pickMultiImage(
        imageQuality: _config.imageQuality,
      );

      if (images.isEmpty) return;

      callbacks.onShowLoading();

      final validationResult = await validateFiles(images);

      callbacks.onHideLoading();

      if (validationResult.hasValidFiles) {
        callbacks.onFilesAdded(validationResult.validFiles);
      }

      if (validationResult.hasInvalidFiles) {
        callbacks.onShowSnackBar(
          'Only image files (JPG, PNG, WebP) are allowed. Videos are not supported.',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      callbacks.onHideLoading();
      callbacks.onShowSnackBar(
        'Error picking images: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> takePicture(BuildContext context, MediaServiceCallbacks callbacks) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: _config.imageQuality,
      );

      if (pickedFile == null) return;

      callbacks.onShowLoading();

      final isValid = await validateImageFile(pickedFile);

      callbacks.onHideLoading();

      if (isValid) {
        callbacks.onFilesAdded([pickedFile]);
      } else {
        callbacks.onShowSnackBar(
          'Invalid image captured. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      callbacks.onHideLoading();
      callbacks.onShowSnackBar(
        'Error taking picture: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  void removeFile(int index, MediaServiceCallbacks callbacks) {
    callbacks.onFileRemoved(index);
  }

  void removeExistingFile(int index, MediaServiceCallbacks callbacks) {
    callbacks.onExistingFileRemoved(index);
  }

  bool isVideoFile(XFile file) {
    return false; 
  }

  void previewMedia(BuildContext context, ImageProvider imageProvider, XFile? file, {bool isVideo = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            isVideo
                                ? buildVideoPreview(imageProvider)
                                : Image(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget buildVideoPreview(ImageProvider imageProvider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image(image: imageProvider, fit: BoxFit.contain),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(16),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'VIDEO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String getFileExtensionFromBytes(Uint8List bytes) {
    if (bytes.length >= 8) {
      // PNG signature
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      // JPEG signature
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'jpeg';
      }
    }
    return 'jpeg';
  }

  Future<String> uploadMedia(String userId, String itemId, Uint8List imageBytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = getFileExtensionFromBytes(imageBytes);
      final fileName = '$userId/$itemId/$timestamp.$extension';

      await _client.storage
          .from(_config.bucketName)
          .uploadBinary(fileName, imageBytes);

      final signedUrl = await _client.storage
          .from(_config.bucketName)
          .createSignedUrl(fileName, _config.urlValidityDuration.inSeconds);

      return signedUrl;
    } catch (e) {
      throw Exception('Error uploading media: $e');
    }
  }

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
        final bucketIndex = pathSegments.indexOf(_config.bucketName);

        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          final signedUrl = await _client.storage
              .from(_config.bucketName)
              .createSignedUrl(filePath, 60 * 60); // 1 hour validity

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

  Future<void> deleteMedia(String userId, String itemId) async {
    try {
      final folderPath = '$userId/$itemId/';

      final filesInFolder = await _client.storage
          .from(_config.bucketName)
          .list(path: folderPath);

      if (filesInFolder.isNotEmpty) {
        final pathsToRemove =
            filesInFolder.map((file) => '$folderPath${file.name}').toList();

        await _client.storage.from(_config.bucketName).remove(pathsToRemove);
      }
    } catch (e) {
      print('Warning: Failed to delete media for ${_config.bucketName}: $e');
    }
  }

  Future<void> deleteSpecificMediaFiles(List<String> mediaUrls) async {
    try {
      if (mediaUrls.isEmpty) return;

      final pathsToRemove = <String>[];

      for (final url in mediaUrls) {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf(_config.bucketName);

        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          pathsToRemove.add(filePath);
        }
      }

      if (pathsToRemove.isNotEmpty) {
        await _client.storage.from(_config.bucketName).remove(pathsToRemove);
      }
    } catch (e) {
      print('Warning: Failed to delete specific media files: $e');
    }
  }

  Future<void> cleanupOrphanedMedia(String userId, Set<String> validItemIds) async {
    try {
      final userFolderPath = '$userId/';
      final foldersInStorage = await _client.storage
          .from(_config.bucketName)
          .list(path: userFolderPath);

      for (final folder in foldersInStorage) {
        final folderId = folder.name;

        if (!validItemIds.contains(folderId)) {
          await deleteMedia(userId, folderId);
        }
      }
    } catch (e) {
      print('Warning: Failed to cleanup orphaned media: $e');
    }
  }

}

class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(message),
        ],
      ),
    );
  }
}
