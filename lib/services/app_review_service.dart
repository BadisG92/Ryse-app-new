import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

/// Service de gestion des demandes de review Apple App Store
///
/// Conforme aux guidelines Apple (mise à jour novembre 2025):
/// - Utilise l'API native StoreKit (in_app_review)
/// - Prompt optionnel et non-intrusif
/// - Respecte la limite iOS (3 prompts/an par utilisateur)
/// - Ne bloque jamais l'accès aux fonctionnalités
/// - Affiche uniquement à des moments positifs (accomplissements)
///
/// Stratégie Ryse:
/// - Premier prompt: Après avoir complété 2 objectifs quotidiens (Daily Goals)
/// - Prompts suivants: Après milestones significatifs (3 workouts, 7 jours streak, etc.)
/// - Minimum 3 jours entre chaque demande
/// - Maximum 3 demandes par an (géré automatiquement par iOS)
class AppReviewService {
  static final AppReviewService _instance = AppReviewService._internal();
  factory AppReviewService() => _instance;
  AppReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  // Clés SharedPreferences
  static const String _keyLastReviewRequest = 'last_review_request_date';
  static const String _keyReviewRequestCount = 'review_request_count';
  static const String _keyFirstReviewDone = 'first_review_done';
  static const String _keyInstallDate = 'app_install_date';

  // Configuration du timing
  static const int _minDaysBetweenRequests = 15; // 15 jours (agressif pour le lancement)
  static const int _maxRequestsPerYear = 3; // Limite interne (iOS limite aussi)
  // Note: PAS de délai minimum pour le premier review (peut être immédiat dès que 2 objectifs complétés)

  /// Vérifie si l'app peut afficher le prompt de review
  Future<bool> canRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // 1. Vérifier si l'app est disponible pour review (iOS/Android compatible)
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        if (kDebugMode) debugPrint('⚠️ AppReview: Pas disponible sur cette plateforme');
        return false;
      }

      // 2. Enregistrer la date d'installation (pour stats uniquement)
      final installDateStr = prefs.getString(_keyInstallDate);
      if (installDateStr == null) {
        // Première fois: enregistrer la date d'install
        await prefs.setString(_keyInstallDate, now.toIso8601String());
        if (kDebugMode) debugPrint('📅 AppReview: Date d\'installation enregistrée');
        // Pas de return false - on peut afficher le review immédiatement !
      }

      // PAS de vérification de délai pour le premier review
      // L'utilisateur peut voir le prompt dès le premier jour s'il complète 2 objectifs

      // 3. Vérifier le nombre de demandes déjà faites cette année
      final requestCount = prefs.getInt(_keyReviewRequestCount) ?? 0;
      if (requestCount >= _maxRequestsPerYear) {
        if (kDebugMode) debugPrint('🚫 AppReview: Limite annuelle atteinte ($requestCount/$_maxRequestsPerYear)');
        return false;
      }

      // 4. Vérifier le délai depuis la dernière demande
      final lastRequestStr = prefs.getString(_keyLastReviewRequest);
      if (lastRequestStr != null) {
        final lastRequest = DateTime.parse(lastRequestStr);
        final daysSinceLastRequest = now.difference(lastRequest).inDays;

        if (daysSinceLastRequest < _minDaysBetweenRequests) {
          if (kDebugMode) debugPrint('⏳ AppReview: Délai insuffisant (${daysSinceLastRequest}j/${_minDaysBetweenRequests}j)');
          return false;
        }
      }

      // ✅ Tous les critères sont remplis
      if (kDebugMode) debugPrint('✅ AppReview: Peut afficher le prompt');
      return true;

    } catch (e) {
      if (kDebugMode) debugPrint('❌ AppReview: Erreur canRequestReview - $e');
      return false;
    }
  }

  /// Demande une review à l'utilisateur (affiche le prompt natif iOS)
  ///
  /// Cette méthode doit être appelée uniquement après un accomplissement positif:
  /// - Après avoir complété 2 objectifs quotidiens (première fois)
  /// - Après 3 workouts complétés
  /// - Après 7 jours de streak
  /// - Après avoir atteint un objectif de poids
  ///
  /// ⚠️ IMPORTANT: Le prompt iOS peut ne PAS s'afficher même si on l'appelle
  /// iOS décide lui-même si le timing est approprié (limite 3x/an)
  Future<void> requestReview({String? trigger}) async {
    try {
      // Vérifier si on peut demander une review
      final canRequest = await canRequestReview();
      if (!canRequest) {
        if (kDebugMode) debugPrint('⚠️ AppReview: Conditions non remplies pour afficher le prompt');
        return;
      }

      // Analytics: Track que nous tentons d'afficher le prompt
      await AnalyticsService.logEvent(
        'review_prompt_triggered',
        parameters: {
          'trigger': trigger ?? 'unknown',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) debugPrint('🌟 AppReview: Affichage du prompt natif iOS (trigger: $trigger)');

      // Afficher le prompt natif iOS (StoreKit)
      await _inAppReview.requestReview();

      // Enregistrer cette tentative
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setString(_keyLastReviewRequest, now.toIso8601String());

      final currentCount = prefs.getInt(_keyReviewRequestCount) ?? 0;
      await prefs.setInt(_keyReviewRequestCount, currentCount + 1);

      if (kDebugMode) debugPrint('✅ AppReview: Prompt affiché (tentative ${currentCount + 1}/$_maxRequestsPerYear)');

      // Analytics: Track que le prompt a été affiché avec succès
      await AnalyticsService.logEvent(
        'review_prompt_shown',
        parameters: {
          'trigger': trigger ?? 'unknown',
          'request_number': currentCount + 1,
        },
      );

    } catch (e) {
      if (kDebugMode) debugPrint('❌ AppReview: Erreur lors de la demande - $e');

      await AnalyticsService.logEvent(
        'review_prompt_error',
        parameters: {
          'error': e.toString(),
          'trigger': trigger ?? 'unknown',
        },
      );
    }
  }

  /// Demande une review après avoir complété 2 objectifs quotidiens (première fois)
  ///
  /// Cette méthode est appelée par GlobalStateManager quand:
  /// - Au moins 2 Daily Goals sont complétés
  /// - Priorité si Calories + Sport sont complétés ensemble
  /// - C'est la première fois qu'on demande une review
  Future<void> requestReviewAfterDailyGoals({
    required int completedGoalsCount,
    required bool hasCaloriesAndWorkout,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstReviewDone = prefs.getBool(_keyFirstReviewDone) ?? false;

      // Si la première review a déjà été faite, ignorer
      if (firstReviewDone) {
        if (kDebugMode) debugPrint('ℹ️ AppReview: Première review déjà effectuée, skip');
        return;
      }

      // Vérifier si au moins 2 objectifs sont complétés
      if (completedGoalsCount < 2) {
        if (kDebugMode) debugPrint('ℹ️ AppReview: Pas assez d\'objectifs complétés ($completedGoalsCount/2)');
        return;
      }

      // Déterminer le déclencheur pour analytics
      final trigger = hasCaloriesAndWorkout
          ? 'first_review_calories_and_workout'
          : 'first_review_two_goals';

      if (kDebugMode) debugPrint('🎯 AppReview: Déclenchement première review ($completedGoalsCount objectifs, trigger: $trigger)');

      // Demander la review
      await requestReview(trigger: trigger);

      // Marquer que la première review a été demandée
      await prefs.setBool(_keyFirstReviewDone, true);

      if (kDebugMode) debugPrint('✅ AppReview: Première review marquée comme effectuée');

    } catch (e) {
      if (kDebugMode) debugPrint('❌ AppReview: Erreur requestReviewAfterDailyGoals - $e');
    }
  }

  /// Demande une review après avoir complété un milestone significatif
  ///
  /// Milestones suggérés (pour les reviews 2 et 3):
  /// - Après 3 workouts complétés
  /// - Après 7 jours de streak
  /// - Après 10 scans alimentaires réussis
  /// - Après avoir atteint un objectif de poids
  Future<void> requestReviewAfterMilestone(String milestoneName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstReviewDone = prefs.getBool(_keyFirstReviewDone) ?? false;

      // Attendre que la première review soit faite avant les milestones
      if (!firstReviewDone) {
        if (kDebugMode) debugPrint('ℹ️ AppReview: Attendre première review avant milestones');
        return;
      }

      if (kDebugMode) debugPrint('🏆 AppReview: Milestone atteint - $milestoneName');

      // Demander la review
      await requestReview(trigger: 'milestone_$milestoneName');

    } catch (e) {
      if (kDebugMode) debugPrint('❌ AppReview: Erreur requestReviewAfterMilestone - $e');
    }
  }

  /// Ouvre l'App Store pour laisser un avis (bouton manuel dans settings)
  ///
  /// À utiliser uniquement si l'utilisateur clique volontairement sur
  /// un bouton "Noter l'application" dans les paramètres.
  ///
  /// ⚠️ Ceci ouvre l'App Store (sort de l'app) - ne pas utiliser automatiquement
  Future<void> openAppStore() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: '6752426474', // Ryse App Store ID
      );

      await AnalyticsService.logEvent('review_manual_app_store_opened');

      if (kDebugMode) debugPrint('✅ AppReview: App Store ouvert manuellement');

    } catch (e) {
      if (kDebugMode) debugPrint('❌ AppReview: Erreur openAppStore - $e');
    }
  }

  /// Réinitialise les compteurs de review (DEVELOPMENT ONLY)
  ///
  /// ⚠️ À utiliser UNIQUEMENT pour tester le système de review en développement
  /// NE JAMAIS APPELER EN PRODUCTION
  Future<void> resetReviewCounters() async {
    if (!kDebugMode) {
      debugPrint('⚠️ AppReview: resetReviewCounters ignoré (pas en mode debug)');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastReviewRequest);
      await prefs.remove(_keyReviewRequestCount);
      await prefs.remove(_keyFirstReviewDone);
      await prefs.remove(_keyInstallDate);

      debugPrint('🔄 AppReview: Compteurs réinitialisés (DEV MODE)');

    } catch (e) {
      debugPrint('❌ AppReview: Erreur resetReviewCounters - $e');
    }
  }

  /// Obtient les statistiques de review (pour debugging)
  Future<Map<String, dynamic>> getReviewStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final installDateStr = prefs.getString(_keyInstallDate);
      final lastRequestStr = prefs.getString(_keyLastReviewRequest);
      final requestCount = prefs.getInt(_keyReviewRequestCount) ?? 0;
      final firstReviewDone = prefs.getBool(_keyFirstReviewDone) ?? false;

      int? daysSinceInstall;
      if (installDateStr != null) {
        final installDate = DateTime.parse(installDateStr);
        daysSinceInstall = now.difference(installDate).inDays;
      }

      int? daysSinceLastRequest;
      if (lastRequestStr != null) {
        final lastRequest = DateTime.parse(lastRequestStr);
        daysSinceLastRequest = now.difference(lastRequest).inDays;
      }

      final stats = {
        'can_request': await canRequestReview(),
        'install_date': installDateStr,
        'days_since_install': daysSinceInstall,
        'last_request_date': lastRequestStr,
        'days_since_last_request': daysSinceLastRequest,
        'request_count': requestCount,
        'first_review_done': firstReviewDone,
        'max_requests_per_year': _maxRequestsPerYear,
        'min_days_between_requests': _minDaysBetweenRequests,
      };

      if (kDebugMode) {
        debugPrint('📊 AppReview Stats:');
        stats.forEach((key, value) {
          debugPrint('   $key: $value');
        });
      }

      return stats;

    } catch (e) {
      if (kDebugMode) debugPrint('❌ AppReview: Erreur getReviewStats - $e');
      return {};
    }
  }
}
