import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://okxvrddwocogpdzubtip.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9reHZyZGR3b2NvZ3BkenVidGlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQwMzIwNDMsImV4cCI6MjA2OTYwODA0M30.AVYcGYLNZ8uGQjv5CRpLapfLrSVY3GHgFUf08Z2kGJM';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}
