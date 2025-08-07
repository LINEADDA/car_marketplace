import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String phoneNumber,
    required String role,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user != null) {
      await _supabase.from('profiles').insert({
        'id': res.user!.id,
        'full_name': fullName,
        'username': username,
        'phone_number': phoneNumber,
        'role': role,
      });
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
