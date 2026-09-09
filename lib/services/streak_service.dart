import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'global_state_manager.dart';

/// Service optimisé pour la gestion de la streak utilisateur
/// Utilise un cache en base de données pour éviter les recalculs
class StreakService {
  static SupabaseClient get _supabase => SupabaseConfig.client;
  
  /// Une série est faite de journées qui se suivent : une seule journée
  /// d'écart la casse.
  static const int _toleranceDays = 1;
  
  /// La série telle qu'elle est, sans la modifier.
  ///
  /// Lire une valeur ne doit pas la changer : c'est [notifyActivity] qui fait
  /// avancer la série, quand l'utilisateur note quelque chose. Une série dont
  /// la dernière journée est trop ancienne est déjà cassée, et vaut zéro tant
  /// que rien de neuf n'est noté.
  static Future<int> getCurrentStreak() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('users')
          .select('streak_count, streak_last_date')
          .eq('id', user.id)
          .maybeSingle();
      if (response == null) return 0;

      final count = response['streak_count'] as int? ?? 0;
      final last = response['streak_last_date'] as String?;

      // La valeur juste est propagée dans tous les cas, série cassée comprise.
      // Sans ce zéro, l'accueil gardait la flamme de l'état global — chargé
      // brut depuis `streak_count` — pendant que la Progression, qui passe
      // par ici, n'affichait plus rien : deux écrans, deux séries.
      final fresh = (count == 0 || last == null)
          ? 0
          : (_daysBetween(DateTime.parse(last), DateTime.now()) > _toleranceDays ? 0 : count);

      try {
        GlobalStateManager.instance.updateStreak(fresh, lastDate: last);
      } catch (e) {
        debugPrint('⚠️ GlobalStateManager streak update failed: $e');
      }
      return fresh;
    } catch (e) {
      debugPrint('❌ StreakService: lecture de la série: $e');
      return 0;
    }
  }
  
  /// Initialise la streak à 1 pour une première utilisation
  static Future<int> _initializeStreak(String userId, String date) async {
    try {
      await _supabase
          .from('users')
          .update({
            'streak_count': 1,
            'streak_last_date': date,
          })
          .eq('id', userId);

      debugPrint('🎯 Streak initialisée: 1 jour');

      // NOUVEAU: Notifier GlobalStateManager
      try {
        GlobalStateManager.instance.updateStreak(1, lastDate: date);
      } catch (e) {
        debugPrint('⚠️ GlobalStateManager streak update failed: $e');
      }

      return 1;
    } catch (e) {
      debugPrint('❌ Erreur initialisation streak: $e');
      return 0;
    }
  }
  
  /// Incrémente la streak de 1
  static Future<int> _incrementStreak(String userId, int currentStreak, String date) async {
    try {
      final newStreak = currentStreak + 1;

      await _supabase
          .from('users')
          .update({
            'streak_count': newStreak,
            'streak_last_date': date,
          })
          .eq('id', userId);

      debugPrint('📈 Streak incrémentée: $newStreak jours');

      // NOUVEAU: Notifier GlobalStateManager
      try {
        GlobalStateManager.instance.updateStreak(newStreak, lastDate: date);
      } catch (e) {
        debugPrint('⚠️ GlobalStateManager streak update failed: $e');
      }

      return newStreak;
    } catch (e) {
      debugPrint('❌ Erreur incrémentation streak: $e');
      return currentStreak; // Retourner l'ancienne valeur en cas d'erreur
    }
  }
  
  /// Reset la streak à 1
  static Future<int> _resetStreak(String userId, String date) async {
    try {
      await _supabase
          .from('users')
          .update({
            'streak_count': 1,
            'streak_last_date': date,
          })
          .eq('id', userId);

      debugPrint('🔄 Streak reset: 1 jour');

      // NOUVEAU: Notifier GlobalStateManager
      try {
        GlobalStateManager.instance.updateStreak(1, lastDate: date);
      } catch (e) {
        debugPrint('⚠️ GlobalStateManager streak update failed: $e');
      }

      return 1;
    } catch (e) {
      debugPrint('❌ Erreur reset streak: $e');
      return 0;
    }
  }
  
  /// L'utilisateur vient de noter quelque chose : c'est ce qui fait vivre la
  /// série. Même journée, rien ne bouge ; la journée d'après, elle avance ;
  /// après une coupure, elle repart à un.
  static Future<void> notifyActivity() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final todayString = _formatDate(today);

      final response = await _supabase
          .from('users')
          .select('streak_count, streak_last_date')
          .eq('id', user.id)
          .maybeSingle();
      if (response == null) return;

      final count = response['streak_count'] as int? ?? 0;
      final last = response['streak_last_date'] as String?;

      if (last == todayString) return;
      if (count == 0 || last == null) {
        await _initializeStreak(user.id, todayString);
        return;
      }

      if (_daysBetween(DateTime.parse(last), today) <= _toleranceDays) {
        await _incrementStreak(user.id, count, todayString);
      } else {
        await _resetStreak(user.id, todayString);
      }
    } catch (e) {
      debugPrint('❌ StreakService: notification d\'activité: $e');
    }
  }
  
  /// Récupère seulement la valeur actuelle sans recalcul
  /// Utile pour l'affichage rapide
  static Future<int> getStreakValue() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;
      
      final response = await _supabase
          .from('users')
          .select('streak_count')
          .eq('id', user.id)
          .maybeSingle();
          
      return response?['streak_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ StreakService: Erreur récupération streak: $e');
      return 0;
    }
  }
  
  /// Calcule le nombre de jours entre deux dates
  static int _daysBetween(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays;
  }
  
  /// Formate une date au format YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Debug: Affiche l'état actuel de la streak
  static Future<void> debugStreakState() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('🐛 Debug Streak: Utilisateur non connecté');
        return;
      }
      
      final response = await _supabase
          .from('users')
          .select('streak_count, streak_last_date')
          .eq('id', user.id)
          .maybeSingle();
          
      if (response != null) {
        final count = response['streak_count'];
        final date = response['streak_last_date'];
        debugPrint('🐛 Debug Streak - Count: $count, Last Date: $date');
      } else {
        debugPrint('🐛 Debug Streak: Aucune donnée trouvée');
      }
    } catch (e) {
      debugPrint('❌ Debug Streak: Erreur: $e');
    }
  }
}
