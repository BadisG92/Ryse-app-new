import 'env_config.dart';

class GeminiConfig {
  // ⚠️ MIGRATION VERS ENV_CONFIG
  // Les clés sont maintenant chargées depuis les variables d'environnement
  // Voir lib/config/env_config.dart pour plus de détails

  // Google Gemini API Configuration (from environment)
  static String get geminiApiKey => EnvConfig.geminiApiKey;

  // Le modèle : rapide, non-thinking, pour tous les usages.
  static const String modelName = 'gemini-3.1-flash-lite';

  // Le modèle de secours, quand le premier est saturé chez Google.
  //
  // Les modèles 3.x répondent régulièrement 503 « high demand » : relevé le
  // 23 septembre 2026, gemini-3.1-flash-lite, 3.5-flash-lite et 3.8-flash
  // étaient à 0 réussite sur 5, pendant que la génération 2.5 répondait
  // 5 sur 5. L'application n'avait aucun plan B : deux reprises en une
  // seconde, puis « Something went wrong ».
  //
  // 2.5-flash plutôt que 2.5-flash-lite : il tient mieux l'appel d'outils et
  // la vision, qui sont le cœur du coach et du scan. Il n'est utilisé que
  // quand le premier refuse, donc son prix ne pèse que sur ces tours-là.
  static const String fallbackModelName = 'gemini-2.5-flash';

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
