import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseConfig {
  static Future<void> initialize() async {
    // Load environment variables
    await dotenv.load(fileName: "../.env");
    
    final supabaseUrl = dotenv.get('SUPABASE_URL');
    final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}