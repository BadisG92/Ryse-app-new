import 'package:flutter/foundation.dart';

/// Configuration sécurisée via variables d'environnement
///
/// Les valeurs sont injectées au build via --dart-define-from-file
///
/// Exemple:
/// flutter run --dart-define-from-file=.env.local
/// flutter build ios --dart-define-from-file=.env.production
class EnvConfig {
  // ===================================
  // SUPABASE
  // ===================================

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mfskwlzgxjhhknlwpblq.supabase.co', // Fallback pour Xcode
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mc2t3bHpneGpoaGtubHdwYmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MzU0ODIsImV4cCI6MjA2NTQxMTQ4Mn0.pAIhzY7oDOSGVk2c6Jj0fslSozwYeIzjXQhhMpORFXo', // Fallback pour Xcode
  );

  // ===================================
  // GOOGLE SERVICES
  // ===================================

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCZ40oCAMe-A5YNeAFfXAcdGeEqzNythZY', // Fallback pour Xcode
  );

  static const String googleVisionApiKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: 'AIzaSyCZ40oCAMe-A5YNeAFfXAcdGeEqzNythZY', // Fallback pour Xcode
  );

  // ===================================
  // OAUTH
  // ===================================

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String appleClientId = String.fromEnvironment(
    'APPLE_CLIENT_ID',
    defaultValue: 'com.BadisG.ryzeApp',
  );

  // ===================================
  // REVENUECAT
  // ===================================

  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
    defaultValue: '',
  );

  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
    defaultValue: '',
  );

  // ===================================
  // ENVIRONMENT
  // ===================================

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const bool testMode = bool.fromEnvironment(
    'TEST_MODE',
    defaultValue: false, // Changed to false pour utiliser les vraies données par défaut
  );

  static const bool enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: true,
  );

  // ===================================
  // VALIDATORS
  // ===================================

  /// Vérifie que toutes les clés requises sont présentes
  static bool get isConfigured {
    final hasSupabase = supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
    final hasGemini = geminiApiKey.isNotEmpty;
    final hasVision = googleVisionApiKey.isNotEmpty;
    // RevenueCat n'est pas obligatoire (peut être en mode test)

    return hasSupabase && hasGemini && hasVision;
  }

  /// Vérifie si on est en production
  static bool get isProduction => environment == 'production';

  /// Vérifie si on est en développement
  static bool get isDevelopment => environment == 'development';

  /// Vérifie si on est en staging
  static bool get isStaging => environment == 'staging';

  // ===================================
  // LOGGING
  // ===================================

  /// Log la configuration (sans exposer les secrets)
  static void logConfiguration() {
    if (!enableDebugLogs) return;

    debugPrint('🔧 Environment Configuration:');
    debugPrint('  Environment: $environment');
    debugPrint('  Test Mode: $testMode');
    debugPrint('  Debug Logs: $enableDebugLogs');
    debugPrint('  Supabase URL: ${_maskSecret(supabaseUrl)}');
    debugPrint('  Supabase Key: ${_maskSecret(supabaseAnonKey)}');
    debugPrint('  Gemini Key: ${_maskSecret(geminiApiKey)}');
    debugPrint('  Vision Key: ${_maskSecret(googleVisionApiKey)}');
    debugPrint('  Google OAuth: ${_maskSecret(googleClientId)}');
    debugPrint('  RevenueCat Apple: ${_maskSecret(revenueCatAppleApiKey)}');
    debugPrint('  RevenueCat Google: ${_maskSecret(revenueCatGoogleApiKey)}');
    debugPrint('  Is Configured: $isConfigured');
  }

  /// Masque les secrets pour les logs
  static String _maskSecret(String secret) {
    if (secret.isEmpty) return '❌ NOT SET';
    if (secret.length < 10) return '✅ SET';
    return '✅ ${secret.substring(0, 8)}...${secret.substring(secret.length - 4)}';
  }

  /// Valide la configuration et lance des erreurs si invalide
  static void validateConfiguration() {
    if (!isConfigured) {
      final errors = <String>[];

      if (supabaseUrl.isEmpty) errors.add('SUPABASE_URL');
      if (supabaseAnonKey.isEmpty) errors.add('SUPABASE_ANON_KEY');
      if (geminiApiKey.isEmpty) errors.add('GEMINI_API_KEY');
      if (googleVisionApiKey.isEmpty) errors.add('GOOGLE_VISION_API_KEY');

      throw ConfigurationException(
        'Missing required environment variables: ${errors.join(", ")}\n'
        'Please create .env.local from .env.example and set all values.\n'
        'Then run: flutter run --dart-define-from-file=.env.local'
      );
    }

    if (isProduction && testMode) {
      debugPrint('⚠️ WARNING: TEST_MODE is enabled in PRODUCTION environment!');
      debugPrint('   Set TEST_MODE=false in .env.production');
    }
  }
}

/// Exception lancée quand la configuration est invalide
class ConfigurationException implements Exception {
  final String message;

  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}
