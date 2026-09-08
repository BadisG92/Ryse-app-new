import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../onboarding/onboarding_state.dart';
import '../services/auth_service.dart';

/// L'objectif de séances par semaine — celui que l'utilisateur a fixé, ou
/// rien.
///
/// Il n'existe nulle part ailleurs : ni colonne en base, ni écran. La
/// question d'onboarding « combien de fois par semaine tu bouges ? » décrit
/// une habitude, pas une visée ; elle ne sert ici qu'à **pré-sélectionner**
/// la feuille de choix. Tant que rien n'est fixé, l'onglet montre les faits
/// sans jauge ni « restantes » — un objectif qu'on n'a pas choisi n'en est
/// pas un.
///
/// Stocké sur le téléphone, par utilisateur. Une colonne côté serveur est une
/// migration à décider à part.
class SportGoal {
  SportGoal._();

  static const _key = 'sport_weekly_goal_v1';
  static const List<int> choices = [2, 3, 4, 5, 6];

  static String _keyFor() {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    return '${_key}_$uid';
  }

  /// Le palier de la semaine se fête une fois, et une seule.
  ///
  /// Vrai au premier retour où l'objectif est atteint ; faux ensuite, pour
  /// cette semaine-là. Sans ce verrou, l'onde repartirait à chaque ouverture
  /// de l'onglet jusqu'à dimanche, et une fête qui se répète n'en est plus une.
  static Future<bool> claimWeeklyHit(DateTime monday) async {
    final key = '${_keyFor()}_hit_${monday.year}-${monday.month}-${monday.day}';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) ?? false) return false;
      await prefs.setBool(key, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// L'objectif fixé, ou nul.
  static Future<int?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_keyFor());
      return v != null && v > 0 ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Fixe l'objectif ; `null` le retire.
  static Future<void> save(int? goal) async {
    final prefs = await SharedPreferences.getInstance();
    if (goal == null || goal <= 0) {
      await prefs.remove(_keyFor());
    } else {
      await prefs.setInt(_keyFor(), goal);
    }
  }

  /// Le point de départ proposé dans la feuille : la fréquence déclarée à
  /// l'inscription. Une suggestion, jamais un objectif par défaut.
  static int suggested() => OnbMetabolics.sessionsPerWeekFor(AuthService().currentUser?.activityLevel).clamp(choices.first, choices.last);
}
