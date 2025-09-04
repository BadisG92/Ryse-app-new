class AppConfig {
  // Langue par défaut de l'application
  static const String defaultLanguage = 'fr';
  
  // Langue actuelle (pourra être modifiée plus tard via les préférences)
  static String currentLanguage = 'fr';
  
  // Helper pour savoir si on est en français
  static bool get isFrench => currentLanguage == 'fr';
  
  // Helper pour savoir si on est en anglais  
  static bool get isEnglish => currentLanguage == 'en';
}