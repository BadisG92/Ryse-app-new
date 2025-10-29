import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

class SupabaseConfig {
  // ⚠️ MIGRATION VERS ENV_CONFIG
  // Les clés sont maintenant chargées depuis les variables d'environnement
  // Voir lib/config/env_config.dart pour plus de détails

  // Supabase credentials (from environment)
  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;

  // OAuth Configuration (from environment)
  static String get googleClientId => EnvConfig.googleClientId;
  static String get appleClientId => EnvConfig.appleClientId;

  /// Initialize Supabase with offline support
  static Future<void> initialize() async {
    try {
      // CRITICAL: Timeout très court (800ms) pour éviter blocage en mode avion
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
          timeout: Duration(milliseconds: 500), // Timeout ultra-court
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 0, // Aucune tentative pour éviter les blocages
        ),
      ).timeout(const Duration(milliseconds: 800));
      debugPrint('✅ Supabase initialized successfully');
    } on TimeoutException catch (e) {
      debugPrint('⚠️ Supabase initialization timeout (offline mode): $e');
      // Continue l'exécution en mode offline
    } catch (e) {
      debugPrint('⚠️ Supabase initialization failed (offline mode): $e');
      // Continue l'exécution même si Supabase n'est pas disponible
      // L'app peut fonctionner en mode offline
    }
  }

  /// Get Supabase client instance (safe but backward compatible)
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('⚠️ Supabase client not available (offline): $e');
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
      debugPrint('⚠️ Supabase client not available (offline): $e');
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
      final response = await client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 2));

      return true;
    } catch (e) {
      debugPrint('🔌 Network check failed: $e');
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
