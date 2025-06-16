import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Actual Supabase credentials
  static const String supabaseUrl = 'https://mfskwlzgxjhhknlwpblq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo';
  
  // OAuth Configuration
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String appleClientId = 'YOUR_APPLE_CLIENT_ID';
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ),
    );
  }
  
  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Check if Supabase is properly configured
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' && 
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
} 