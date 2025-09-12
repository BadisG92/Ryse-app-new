import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Actual Supabase credentials
  static const String supabaseUrl = 'https://mfskwlzgxjhhknlwpblq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo';
  
  // OAuth Configuration
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String appleClientId = 'YOUR_APPLE_CLIENT_ID';
  
  /// Initialize Supabase with offline support
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
          timeout: const Duration(seconds: 3), // Timeout court
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 1, // Moins de tentatives pour éviter les blocages
        ),
      );
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('⚠️ Supabase initialization failed (offline mode): $e');
      // Continue l'exécution même si Supabase n'est pas disponible
      // L'app peut fonctionner en mode offline
    }
  }
  
  /// Get Supabase client instance (safe but backward compatible)
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('⚠️ Supabase client not available (offline): $e');
      // Create a temporary client with dummy values for offline mode
      // This prevents null crashes while keeping backward compatibility
      return SupabaseClient(supabaseUrl, supabaseAnonKey);
    }
  }
  
  /// Get Supabase client instance (safe nullable)
  static SupabaseClient? get clientSafe {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('⚠️ Supabase client not available (offline): $e');
      return null;
    }
  }
  
  /// Check if Supabase is properly configured
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' && 
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
  
  /// Check if we're online and can connect to Supabase
  static Future<bool> get isOnline async {
    try {
      if (client == null) return false;
      
      // Test simple de connectivité avec timeout
      final response = await client!
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 2));
      
      return true;
    } catch (e) {
      print('🔌 Network check failed: $e');
      return false;
    }
  }
  
  /// Check if Supabase is available (initialized)
  static bool get isAvailable {
    try {
      return Supabase.instance.client != null;
    } catch (e) {
      return false;
    }
  }
} 