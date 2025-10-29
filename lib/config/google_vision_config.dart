import 'env_config.dart';

class GoogleVisionConfig {
  // ⚠️ MIGRATION VERS ENV_CONFIG
  // Les clés sont maintenant chargées depuis les variables d'environnement
  // Voir lib/config/env_config.dart pour plus de détails

  // Google Cloud Vision API Configuration
  static const String googleCloudProjectId = 'ryse-app'; // Project ID (can be adjusted if needed)
  static String get googleCloudApiKey => EnvConfig.googleVisionApiKey;

  // Google Vision API endpoint
  static const String visionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';

  // Features for food detection
  static const List<String> detectionFeatures = [
    'LABEL_DETECTION',
    'OBJECT_LOCALIZATION',
    'TEXT_DETECTION',
    'LOGO_DETECTION',
  ];

  // Maximum number of results per feature
  static const int maxResults = 10;

  // Confidence threshold for food detection (0.0 to 1.0)
  static const double confidenceThreshold = 0.7;

  // Food-related labels to prioritize
  static const List<String> foodKeywords = [
    'food',
    'meal',
    'dish',
    'cuisine',
    'vegetable',
    'fruit',
    'meat',
    'fish',
    'seafood',
    'pasta',
    'rice',
    'bread',
    'dessert',
    'drink',
    'beverage',
    'salad',
    'soup',
    'sandwich',
    'pizza',
    'burger',
  ];

  /// Check if Google Vision is properly configured
  static bool get isConfigured {
    return googleCloudProjectId != 'YOUR_PROJECT_ID' &&
           googleCloudApiKey != 'YOUR_API_KEY';
  }

  /// Get full API URL with key
  static String get fullApiUrl => '$visionApiUrl?key=$googleCloudApiKey';
}
