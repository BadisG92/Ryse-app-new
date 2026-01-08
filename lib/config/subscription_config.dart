/// Configuration des abonnements Ryse Premium
///
/// Ce fichier centralise tous les paramètres liés aux abonnements :
/// - Prix et périodes
/// - Identifiants des produits (App Store / Google Play)
/// - Features par tier
/// - Limites de la version gratuite
class SubscriptionConfig {
  // ═══════════════════════════════════════════════════════════════════════════
  // PRICING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Prix hebdomadaire (Weekly)
  static const double weeklyPrice = 2.99;
  static const String weeklyPriceDisplay = '2,99€';

  /// Prix mensuel (Monthly)
  static const double monthlyPrice = 9.99;
  static const String monthlyPriceDisplay = '9,99€';

  /// Prix annuel (Yearly)
  static const double yearlyPrice = 69.99;
  static const String yearlyPriceDisplay = '69,99€';

  /// Économie sur l'annuel vs mensuel
  static const String yearlySavings = '42%'; // (9.99 * 12 - 69.99) / (9.99 * 12)
  static const String yearlySavingsDisplay = 'Économisez 42%';

  // ═══════════════════════════════════════════════════════════════════════════
  // PRODUCT IDs - À CRÉER DANS APP STORE CONNECT & GOOGLE PLAY CONSOLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Identifiant du produit hebdomadaire
  /// iOS: Créer dans App Store Connect > Subscriptions
  /// Android: Créer dans Google Play Console > In-app products
  static const String weeklyProductId = 'ryse_premium_weekly';

  /// Identifiant du produit mensuel
  static const String monthlyProductId = 'ryse_premium_monthly';

  /// Identifiant du produit annuel
  static const String yearlyProductId = 'ryse_premium_yearly';

  /// Identifiant de l'entitlement RevenueCat
  /// À créer dans RevenueCat Dashboard > Entitlements
  static const String premiumEntitlementId = 'Ryze';

  /// Identifiant de l'offering principal
  /// À créer dans RevenueCat Dashboard > Offerings
  static const String defaultOfferingId = 'default';

  // ═══════════════════════════════════════════════════════════════════════════
  // TRIAL CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Durée du trial gratuit (jours)
  static const int trialDurationDays = 3;

  /// Message d'accroche trial
  static const String trialCallToAction = 'Essai gratuit de 3 jours';
  static const String trialDescription = 'Toutes les fonctionnalités IA débloquées pendant 3 jours';

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURES PAR TIER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Features disponibles en version GRATUITE
  static const List<String> freeFeatures = [
    'manual_food_entry', // Ajout nourriture manuel
    'manual_workout', // Workout manuel
    'basic_tracking', // Suivi basique calories/macros
    'limited_history', // Historique 30 jours
    'limited_recipes', // 10 recettes max
    'water_tracking', // Suivi hydratation
    'weight_tracking', // Suivi poids
  ];

  /// Features disponibles uniquement en PREMIUM
  static const List<String> premiumOnlyFeatures = [
    // IA Features (0 en gratuit après trial)
    'ai_food_scanner', // Scanner nourriture IA
    'ai_nutrition_analysis', // Analyse nutrition par coach IA
    'ai_workout_generator', // Générateur séances sport IA
    'ai_chat_nutrition', // Chat nutrition IA
    'ai_chat_sport', // Chat sport IA
    'ai_recipe_generator', // Générateur recettes IA

    // Advanced Features
    'unlimited_history', // Historique complet illimité
    'unlimited_recipes', // Recettes illimitées
    'advanced_charts', // Graphiques avancés
    'data_export', // Export données CSV/PDF
    'offline_mode', // Mode hors ligne complet
    'no_ads', // Sans publicité
    'priority_support', // Support prioritaire
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // LIMITES VERSION GRATUITE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Limite de scans IA par jour en gratuit (0 = désactivé)
  static const int freeDailyAiScansLimit = 0;

  /// Limite de scans IA par jour en Premium
  static const int premiumDailyAiScansLimit = 10;

  /// Limite d'analyses nutrition IA en gratuit (0 = désactivé)
  static const int freeDailyNutritionAnalysisLimit = 0;

  /// Limite de chat IA en gratuit (0 = désactivé)
  static const int freeDailyAiChatLimit = 0;

  /// Limite de recettes sauvegardées en gratuit
  static const int freeMaxRecipes = 10;

  /// Limite d'historique en gratuit (jours)
  static const int freeHistoryDays = 30;

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGES UI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Message quand limite atteinte
  static const String limitReachedTitle = 'Version Gratuite Limitée';
  static const String limitReachedMessage =
      'Cette fonctionnalité IA est réservée aux membres Premium. '
      'Essayez Premium gratuitement pendant 3 jours !';

  /// Message trial expiré
  static const String trialExpiredTitle = 'Essai Gratuit Terminé';
  static const String trialExpiredMessage =
      'Votre période d\'essai de 3 jours est terminée. '
      'Passez à Premium pour continuer à utiliser les fonctionnalités IA !';

  /// Avantages Premium (pour le paywall)
  static const List<String> premiumBenefits = [
    '🤖 IA illimitée : Scanner, analyse, chat nutrition & sport',
    '🏋️ Générateur de séances personnalisées',
    '📊 Analyse quotidienne par votre coach IA',
    '📈 Graphiques avancés et statistiques détaillées',
    '📁 Export de données et historique complet',
    '🔒 Mode hors ligne premium',
    '⚡ Support prioritaire',
    '🚫 Sans publicité',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie si une feature est disponible en gratuit
  static bool isFeatureAvailableInFree(String featureName) {
    return freeFeatures.contains(featureName);
  }

  /// Vérifie si une feature nécessite Premium
  static bool isFeaturePremiumOnly(String featureName) {
    return premiumOnlyFeatures.contains(featureName);
  }

  /// Obtient le prix formaté pour l'affichage
  static String getFormattedPrice(String period) {
    switch (period.toLowerCase()) {
      case 'weekly':
      case 'week':
        return weeklyPriceDisplay;
      case 'monthly':
      case 'month':
        return monthlyPriceDisplay;
      case 'yearly':
      case 'year':
        return yearlyPriceDisplay;
      default:
        return monthlyPriceDisplay;
    }
  }

  /// Calcule l'économie par rapport au mensuel
  static String calculateSavings(String period) {
    switch (period.toLowerCase()) {
      case 'yearly':
      case 'year':
        final monthlyTotal = monthlyPrice * 12;
        final savings = monthlyTotal - yearlyPrice;
        final savingsPercent = ((savings / monthlyTotal) * 100).round();
        return 'Économisez $savingsPercent% (${savings.toStringAsFixed(2)}€/an)';
      case 'weekly':
      case 'week':
        final monthlyEquivalent = weeklyPrice * 4.33; // Moyenne semaines/mois
        if (monthlyEquivalent > monthlyPrice) {
          return 'Flexible, sans engagement';
        }
        return 'Parfait pour essayer';
      default:
        return 'Le plus populaire';
    }
  }

  /// Obtient la description de l'offre
  static String getOfferDescription(String period) {
    switch (period.toLowerCase()) {
      case 'weekly':
        return 'Engagement hebdomadaire • Flexible';
      case 'monthly':
        return 'Facturation mensuelle • Annulable à tout moment';
      case 'yearly':
        return 'Meilleure offre • Économisez 42%';
      default:
        return '';
    }
  }

  /// Message de bienvenue trial
  static String getTrialWelcomeMessage() {
    return 'Bienvenue dans Ryse Premium ! 🎉\n\n'
        'Vous avez accès à toutes les fonctionnalités IA pendant $trialDurationDays jours.\n\n'
        'Profitez-en pour découvrir votre coach nutrition et sport personnel !';
  }

  /// Message de rappel fin de trial
  static String getTrialEndingSoonMessage(int daysRemaining) {
    if (daysRemaining == 1) {
      return 'Votre essai gratuit se termine demain ! ⏰\n\n'
          'Passez à Premium pour continuer à profiter de votre coach IA.';
    }
    return 'Plus que $daysRemaining jours d\'essai gratuit ! ⏰\n\n'
        'N\'oubliez pas de souscrire à Premium pour ne rien perdre.';
  }
}
