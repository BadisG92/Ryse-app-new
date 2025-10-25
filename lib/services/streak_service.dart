import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'global_state_manager.dart';

/// Service optimisé pour la gestion de la streak utilisateur
/// Utilise un cache en base de données pour éviter les recalculs
class StreakService {
  static SupabaseClient get _supabase => SupabaseConfig.client;
  
  /// Nombre de jours de tolérance avant reset de la streak
  static const int _toleranceDays = 7;
  
  /// Récupère ou calcule la streak actuelle de l'utilisateur
  /// Système intelligent : 
  /// - 1ère utilisation : streak = 1
  /// - Utilisation dans la tolérance : streak + 1
  /// - Utilisation hors tolérance : reset à 1
  static Future<int> getCurrentStreak() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ StreakService: Utilisateur non connecté');
        return 0;
      }
      
      final today = DateTime.now();
      final todayString = _formatDate(today);
      
      debugPrint('🔥 StreakService: Calcul streak pour ${user.id} le $todayString');
      
      // Récupérer les données de streak actuelles
      final response = await _supabase
          .from('users')
          .select('streak_count, streak_last_date')
          .eq('id', user.id)
          .maybeSingle();
          
      if (response == null) {
        debugPrint('❌ StreakService: Utilisateur non trouvé');
        return 0;
      }
      
      final currentStreakCount = response['streak_count'] as int? ?? 0;
      final lastStreakDate = response['streak_last_date'] as String?;
      
      debugPrint('📊 État actuel - Streak: $currentStreakCount, Dernière date: $lastStreakDate');
      
      // Premier cas : Première utilisation ou pas de streak
      if (currentStreakCount == 0 || lastStreakDate == null) {
        debugPrint('🆕 Première utilisation - Initialisation de la streak');
        return await _initializeStreak(user.id, todayString);
      }
      
      // Convertir la date de la dernière streak
      final lastDate = DateTime.parse(lastStreakDate);
      final daysDifference = _daysBetween(lastDate, today);
      
      debugPrint('📅 Différence: $daysDifference jours depuis la dernière activité');
      
      // Cas 1: Même jour - pas de changement
      if (daysDifference == 0) {
        debugPrint('📅 Même jour - Streak inchangée: $currentStreakCount');
        return currentStreakCount;
      }
      
      // Cas 2: Dans la tolérance - incrémenter
      if (daysDifference <= _toleranceDays) {
        debugPrint('✅ Dans la tolérance - Incrémentation de la streak');
        return await _incrementStreak(user.id, currentStreakCount, todayString);
      }
      
      // Cas 3: Hors tolérance - reset
      debugPrint('🔄 Hors tolérance - Reset de la streak');
      return await _resetStreak(user.id, todayString);
      
    } catch (e) {
      debugPrint('❌ StreakService: Erreur lors du calcul de streak: $e');
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
        GlobalStateManager.instance.updateStreak(1);
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
        GlobalStateManager.instance.updateStreak(newStreak);
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
        GlobalStateManager.instance.updateStreak(1);
      } catch (e) {
        debugPrint('⚠️ GlobalStateManager streak update failed: $e');
      }

      return 1;
    } catch (e) {
      debugPrint('❌ Erreur reset streak: $e');
      return 0;
    }
  }
  
  /// Force la mise à jour de la streak (appelé après une activité)
  /// Utile quand l'utilisateur fait une activité dans la journée
  static Future<void> notifyActivity() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final today = DateTime.now();
      final todayString = _formatDate(today);
      
      debugPrint('🎯 StreakService: Notification d\'activité pour $todayString');
      
      // Mettre à jour la dernière date d'activité si pas déjà fait aujourd'hui
      final response = await _supabase
          .from('users')
          .select('streak_last_date')
          .eq('id', user.id)
          .maybeSingle();
          
      if (response != null) {
        final lastDate = response['streak_last_date'] as String?;
        if (lastDate != todayString) {
          // Recalculer la streak avec l'activité d'aujourd'hui
          await getCurrentStreak();
        }
      }
    } catch (e) {
      debugPrint('❌ StreakService: Erreur notification activité: $e');
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
