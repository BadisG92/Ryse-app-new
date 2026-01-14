import 'env_config.dart';

class GeminiConfig {
  // ⚠️ MIGRATION VERS ENV_CONFIG
  // Les clés sont maintenant chargées depuis les variables d'environnement
  // Voir lib/config/env_config.dart pour plus de détails

  // Google Gemini API Configuration (from environment)
  static String get geminiApiKey => EnvConfig.geminiApiKey;

  // Gemini API endpoints par usage
  // - gemini-2.5-flash-lite : scan food, analyse rapide (économique)
  // - gemini-2.5-flash : planner avec function calling (meilleur raisonnement)

  /// URL par défaut (scan food, analyses simples)
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  /// URL pour le planner (function calling, raisonnement complexe)
  static const String plannerApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Model configuration
  static const String modelName = 'gemini-2.5-flash-lite';
  static const String plannerModelName = 'gemini-2.5-flash';

  // Generation parameters
  static const double temperature = 0.3; // Lower for more consistent results
  static const int maxOutputTokens = 2000;
  static const double topP = 0.8;
  static const int topK = 40;

  // Safety settings for food analysis
  static const Map<String, String> safetySettings = {
    'HARM_CATEGORY_HATE_SPEECH': 'BLOCK_ONLY_HIGH',
    'HARM_CATEGORY_DANGEROUS_CONTENT': 'BLOCK_ONLY_HIGH',
    'HARM_CATEGORY_SEXUALLY_EXPLICIT': 'BLOCK_ONLY_HIGH',
    'HARM_CATEGORY_HARASSMENT': 'BLOCK_ONLY_HIGH',
  };

  // Confidence threshold for food detection (0.0 to 1.0)
  static const double confidenceThreshold = 0.6;

  /// Check if Gemini is properly configured
  static bool get isConfigured {
    return geminiApiKey != 'YOUR_GEMINI_API_KEY' && geminiApiKey.isNotEmpty;
  }

  /// Get full API URL with key
  static String get fullApiUrl => '$geminiApiUrl?key=$geminiApiKey';

  /// Get generation config
  static Map<String, dynamic> get generationConfig => {
    'temperature': temperature,
    'topK': topK,
    'topP': topP,
    'maxOutputTokens': maxOutputTokens,
  };

  /// Get safety settings for API
  static List<Map<String, String>> get safetySettingsList =>
    safetySettings.entries.map((entry) => {
      'category': entry.key,
      'threshold': entry.value,
    }).toList();
}
