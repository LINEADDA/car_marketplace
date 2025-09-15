import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigService {
  final SupabaseClient _client;
  static String? _adminContactNumber;

  ConfigService(this._client);

  Future<String> getAdminContactNumber() async {

    if (_adminContactNumber != null) {
      return _adminContactNumber!;
    }

    try {
      final response = await _client
          .from('app_config')
          .select('value')
          .eq('key', 'admin_contact_number')
          .single();
      
      final number = response['value'] as String? ?? 'Contact info not available';
      _adminContactNumber = number; 
      return number;
    } catch (e) {
      return 'Contact info not available';
    }
  }
}