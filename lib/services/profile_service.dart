import 'dart:io'; // Required for using the 'File' type for uploads.
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart'; // Import the UserProfile model.

class ProfileService {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'profiles';
  static const String _avatarBucket = 'avatars'; // The name of your Supabase Storage bucket for avatars.

  ProfileService(this._supabaseClient);

  // Fetches a single user profile by their ID.
  // Returns null if the profile doesn't exist, which is common for new users.
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('id', userId)
          .single(); // .single() will throw an error if no row is found.
      
      return UserProfile.fromMap(response);
    } on PostgrestException catch (e) {
      // Supabase throws a 'PGRST116' error when .single() finds 0 rows.
      // We can safely ignore this and return null, as it means the profile is not yet created.
      if (e.code == 'PGRST116') {
        print('Profile for user $userId not found. This might be a new user.');
        return null;
      }
      print('Error fetching profile for user $userId: ${e.message}');
      rethrow; // Rethrow other database errors to be handled by the UI.
    } catch (e) {
      print('An unexpected error occurred in getProfile: $e');
      rethrow;
    }
  }

  // Creates a new user profile. Typically called once after user sign-up.
  Future<UserProfile> createProfile(UserProfile profile) async {
    try {
      // The 'id' in the profile object must match the user's auth.users.id
      final response = await _supabaseClient
          .from(_tableName)
          .insert(profile.toMap())
          .select()
          .single();

      return UserProfile.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error creating profile: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in createProfile: $e');
      rethrow;
    }
  }

  // Updates an existing user profile (e.g., changing full_name or avatar_url).
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .update(profile.toMap())
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromMap(response);
    } on PostgrestException catch (e) {
      print('Error updating profile ${profile.id}: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred in updateProfile: $e');
      rethrow;
    }
  }

  // Uploads a user avatar image to Supabase Storage and returns its public URL.
  Future<String> uploadAvatar(String userId, File file) async {
    try {
      // We create a unique file path based on the user's ID.
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
}
