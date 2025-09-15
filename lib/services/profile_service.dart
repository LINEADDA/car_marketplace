import 'dart:io'; // Required for using the 'File' type for uploads.
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart'; // Ensure this path is correct

class ProfileService {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'profiles';
  static const String _avatarBucket = 'avatars'; // The name of your Supabase Storage bucket for avatars.

  ProfileService(this._supabaseClient);

  // --- THIS IS THE MISSING METHOD, NOW ADDED BACK ---
  /// Uploads a user avatar image to Supabase Storage and returns its public URL.
  Future<String> uploadAvatar(String userId, File file) async {
    try {
      // We create a unique file path based on the user's ID to ensure
      // each user has one avatar, and it can be overwritten easily.
      final fileExtension = file.path.split('.').last.toLowerCase();
      final filePath = '$userId/avatar.$fileExtension';

      // Upload the file. `upsert: true` will overwrite the file if it already exists.
      await _supabaseClient.storage.from(_avatarBucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Retrieve the public URL of the uploaded file.
      final publicUrl = _supabaseClient.storage
          .from(_avatarBucket)
          .getPublicUrl(filePath);
          
      return publicUrl;
    } catch (e) {
      print('An unexpected error occurred during avatar upload: $e');
      rethrow;
    }
  }

  /// Fetches a single user profile by their ID.
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in getProfile: $e');
      rethrow;
    }
  }

  /// Creates a new user profile record.
  Future<UserProfile> createProfile(UserProfile profile) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .insert(profile.toMap())
          .select()
          .single();
      return UserProfile.fromMap(response);
    } catch (e) {
      print('An unexpected error occurred in createProfile: $e');
      rethrow;
    }
  }

  /// Updates an existing user profile.
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .update(profile.toMap())
          .eq('id', profile.id)
          .select()
          .single();
      return UserProfile.fromMap(response);
    } catch (e) {
      print('An unexpected error occurred in updateProfile: $e');
      rethrow;
    }
  }
}
