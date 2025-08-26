import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://ktoodrfhfmyzbybvjrfy.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0b29kcmZoZm15emJ5YnZqcmZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4OTAxNTksImV4cCI6MjA3MDQ2NjE1OX0.FfEeWtPoOTjCK3vkZRHO6MnueKbm9D9ixCv65IIl5PI',
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}