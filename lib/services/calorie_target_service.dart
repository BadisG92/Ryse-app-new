import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour calculer l'objectif hebdomadaire intelligent de calories brûlées
class CalorieTargetService {
  static final _client = Supabase.instance.client;

  /// Calcule l'objectif hebdomadaire intelligent pour un utilisateur
  static Future<int> calculateWeeklyTarget(String userId) async {
    try {
      // 1. Récupérer le profil utilisateur
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        return 1500; // Objectif par défaut si pas de profil
      }

      // 2. Calculer l'objectif de base selon le profil
      final baseTarget = _calculateBaseTarget(userProfile);

      // 3. Récupérer l'historique des 4 dernières semaines actives
      final weeklyHistory = await _getWeeklyCaloriesHistory(userId, weeksCount: 4);

      // 4. Calculer les jours d'inactivité
      final daysSinceLastActivity = await _getDaysSinceLastActivity(userId);

      // 5. Appliquer l'adaptation intelligente
      final adaptedTarget = _applyIntelligentAdaptation(
        baseTarget: baseTarget,
        weeklyHistory: weeklyHistory,
        daysSinceLastActivity: daysSinceLastActivity,
      );

      // 6. Arrondir à la 100aine la plus proche
      return _roundToNearest100(adaptedTarget);
    } catch (e) {
      debugPrint('❌ Erreur calcul objectif calories: $e');
      return 1500; // Fallback sécurisé
    }
  }

  /// Récupère le profil utilisateur depuis Supabase
  static Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final result = await _client
          .from('users')
          .select('bmr, activity_level, fitness_goal, weight, age, gender')
          .eq('id', userId)
          .maybeSingle();
      
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération profil: $e');
      return null;
    }
  }

  /// Calcule l'objectif de base selon le profil utilisateur
  static int _calculateBaseTarget(Map<String, dynamic> profile) {
    final bmr = (profile['bmr'] as num?)?.toDouble() ?? 1600.0;
    final activityLevel = profile['activity_level'] as String? ?? 'moderate';
    final fitnessGoal = profile['fitness_goal'] as String? ?? 'maintain';

    // Multiplicateurs selon le niveau d'activité déclaré
    final activityMultiplier = switch (activityLevel) {
      'sedentary' => 0.08,   // 800-1000 kcal/semaine
      'light' => 0.10,       // 1000-1300 kcal/semaine  
      'moderate' => 0.12,    // 1300-1600 kcal/semaine
      'active' => 0.15,      // 1600-2000 kcal/semaine
      'very_active' => 0.18, // 1800+ kcal/semaine
      _ => 0.12,
    };

    // Multiplicateurs selon l'objectif fitness
    final goalMultiplier = switch (fitnessGoal) {
      'lose' => 1.4,         // Plus de calories à brûler pour déficit
      'maintain' => 1.0,     // Objectif équilibré
      'gain' => 0.7,         // Moins pour préserver la masse musculaire
      _ => 1.0,
    };

    // Calcul : BMR × 7 jours × activité × objectif
    final baseTarget = bmr * 7 * activityMultiplier * goalMultiplier;
    
    return baseTarget.round();
  }

  /// Récupère l'historique des calories brûlées des N dernières semaines actives
  static Future<List<int>> _getWeeklyCaloriesHistory(String userId, {int weeksCount = 4}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: weeksCount * 7 * 2)); // Chercher sur plus de période

      // Récupérer les sessions cardio
      final cardioSessions = await _client
          .from('cardio_sessions')
          .select('calories, session_date')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .order('session_date', ascending: false);

      // Récupérer les sessions musculation
      final musculationSessions = await _client
          .from('workout_session_summaries')
          .select('calories_burned, session_date')
          .eq('user_id', userId)
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .order('session_date', ascending: false);

      // Grouper par semaine et calculer les totaux
      final weeklyTotals = <int, int>{}; // weekNumber -> totalCalories

      // Traiter les sessions cardio
      for (final session in cardioSessions) {
        final date = DateTime.parse(session['session_date']);
        final weekNumber = _getWeekNumber(date);
        final calories = session['calories'] as int? ?? 0;
        weeklyTotals[weekNumber] = (weeklyTotals[weekNumber] ?? 0) + calories;
      }

      // Traiter les sessions musculation
      for (final session in musculationSessions) {
        final date = DateTime.parse(session['session_date']);
        final weekNumber = _getWeekNumber(date);
        final calories = session['calories_burned'] as int? ?? 0;
        weeklyTotals[weekNumber] = (weeklyTotals[weekNumber] ?? 0) + calories;
      }

      // Retourner les N dernières semaines avec activité
      final sortedWeeks = weeklyTotals.entries
          .where((entry) => entry.value > 0) // Seulement les semaines actives
          .toList()
        ..sort((a, b) => b.key.compareTo(a.key)); // Trier par semaine décroissante

      return sortedWeeks
          .take(weeksCount)
          .map((entry) => entry.value)
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération historique: $e');
      return [];
    }
  }

  /// Calcule le nombre de jours depuis la dernière activité
  static Future<int> _getDaysSinceLastActivity(String userId) async {
    try {
      // Dernière session cardio
      final lastCardio = await _client
          .from('cardio_sessions')
          .select('session_date')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('session_date', ascending: false)
          .limit(1);

      // Dernière session musculation
      final lastMusculation = await _client
          .from('workout_session_summaries')
          .select('session_date')
          .eq('user_id', userId)
          .order('session_date', ascending: false)
          .limit(1);

      DateTime? lastActivity;

      // Trouver la plus récente des deux
      if (lastCardio.isNotEmpty) {
        final cardioDate = DateTime.parse(lastCardio.first['session_date']);
        lastActivity = cardioDate;
      }

      if (lastMusculation.isNotEmpty) {
        final musculationDate = DateTime.parse(lastMusculation.first['session_date']);
        if (lastActivity == null || musculationDate.isAfter(lastActivity)) {
          lastActivity = musculationDate;
        }
      }

      if (lastActivity == null) {
        return 365; // Pas d'activité trouvée = considérer comme très inactif
      }

      return DateTime.now().difference(lastActivity).inDays;
    } catch (e) {
      debugPrint('❌ Erreur calcul inactivité: $e');
      return 30; // Fallback modéré
    }
  }

  /// Applique l'adaptation intelligente selon l'historique et l'inactivité
  static int _applyIntelligentAdaptation({
    required int baseTarget,
    required List<int> weeklyHistory,
    required int daysSinceLastActivity,
  }) {
    // 1. Si l'utilisateur est régulier (actif dans les 7 derniers jours)
    if (daysSinceLastActivity <= 7 && weeklyHistory.isNotEmpty) {
      final avgHistory = weeklyHistory.reduce((a, b) => a + b) / weeklyHistory.length;
      
      // Mélange intelligent : 70% base calculée + 30% moyenne historique
      final adaptedTarget = (baseTarget * 0.7 + avgHistory * 0.3).round();
      
      debugPrint('🎯 Objectif adaptatif régulier: $adaptedTarget kcal (base: $baseTarget, hist: ${avgHistory.round()})');
      return adaptedTarget;
    }
    
    // 2. Gestion de l'inactivité avec remise en forme progressive
    double inactivityMultiplier = 1.0;
    
    if (daysSinceLastActivity <= 14) {
      // 0-2 semaines : objectif normal
      inactivityMultiplier = 1.0;
      debugPrint('🟢 Utilisateur récent: objectif normal');
    } else if (daysSinceLastActivity <= 30) {
      // 2-4 semaines : réduction légère pour remise en forme
      inactivityMultiplier = 0.75;
      debugPrint('🟡 Remise en forme douce: -25%');
    } else if (daysSinceLastActivity <= 90) {
      // 1-3 mois : réduction importante pour redémarrage progressif
      inactivityMultiplier = 0.5;
      debugPrint('🟠 Redémarrage progressif: -50%');
    } else {
      // >3 mois : retour au calcul de base (fresh start)
      inactivityMultiplier = 0.6; // Légèrement réduit pour éviter la démotivation
      debugPrint('🔴 Fresh start: -40%');
    }

    final adaptedTarget = (baseTarget * inactivityMultiplier).round();
    
    debugPrint('🎯 Objectif adapté inactivité ($daysSinceLastActivity jours): $adaptedTarget kcal');
    return adaptedTarget;
  }

  /// Arrondit à la centaine la plus proche (100, 200, 300...)
  static int _roundToNearest100(int value) {
    return ((value / 100).round() * 100).clamp(500, 5000);
  }

  /// Calcule le numéro de semaine pour grouper les données
  static int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    return (dayOfYear / 7).floor();
  }

  /// Met à jour l'objectif dans le cache (à appeler après calcul)
  static Future<void> updateCachedTarget(String userId, int target) async {
    try {
      // Optionnel : sauvegarder l'objectif calculé pour éviter les recalculs fréquents
      await _client
          .from('user_preferences')
          .upsert({
            'user_id': userId,
            'weekly_calorie_target': target,
            'target_calculated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('⚠️ Impossible de mettre en cache l\'objectif: $e');
    }
  }
}

/// Modèle pour les préférences utilisateur (optionnel)
class UserCaloriePreferences {
  final String userId;
  final int weeklyTarget;
  final DateTime calculatedAt;

  const UserCaloriePreferences({
    required this.userId,
    required this.weeklyTarget,
    required this.calculatedAt,
  });

  /// Vérifie si l'objectif doit être recalculé (>24h)
  bool get needsRecalculation {
    return DateTime.now().difference(calculatedAt).inHours > 24;
  }
}

