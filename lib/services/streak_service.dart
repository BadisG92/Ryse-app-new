import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service optimisé pour la gestion de la streak utilisateur
/// Utilise un cache en base de données pour éviter les recalculs
class StreakService {
  static final SupabaseClient _client = SupabaseConfig.client;
  
  /// Nombre de jours de tolérance avant reset de la streak
  static const int _toleranceDays = 7;
  
  /// Récupère ou calcule la streak actuelle de l'utilisateur
  /// Système intelligent : 
  /// - 1ère utilisation : streak = 1
  /// - Utilisation dans la tolérance : streak + 1
  /// - Utilisation hors tolérance : reset à 1
  static Future<int> getCurrentStreak() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('❌ StreakService: Utilisateur non connecté');
        return 0;
      }
      
      final today = DateTime.now();
      final todayString = _formatDate(today);
      
      print('🔥 StreakService: Calcul streak pour ${user.id} le $todayString');
      
      // Récupérer les données de streak actuelles
      final response = await _client
          .from('users')
          .select('streak_count, streak_last_date')
          .eq('id', user.id)
          .maybeSingle();
          
      if (response == null) {
        print('❌ StreakService: Utilisateur non trouvé');
        return 0;
      }
      
      final currentStreakCount = response['streak_count'] as int? ?? 0;
      final lastStreakDate = response['streak_last_date'] as String?;
      
      print('📊 État actuel - Streak: $currentStreakCount, Dernière date: $lastStreakDate');
      
      // Premier cas : Première utilisation ou pas de streak
      if (currentStreakCount == 0 || lastStreakDate == null) {
        print('🆕 Première utilisation - Initialisation de la streak');
        return await _initializeStreak(user.id, todayString);
      }
      
      // Convertir la date de la dernière streak
      final lastDate = DateTime.parse(lastStreakDate);
      final daysDifference = _daysBetween(lastDate, today);
      
      print('📅 Différence: $daysDifference jours depuis la dernière activité');
      
      // Cas 1: Même jour - pas de changement
      if (daysDifference == 0) {
        print('📅 Même jour - Streak inchangée: $currentStreakCount');
        return currentStreakCount;
      }
      
      // Cas 2: Dans la tolérance - incrémenter
      if (daysDifference <= _toleranceDays) {
        print('✅ Dans la tolérance - Incrémentation de la streak');
        return await _incrementStreak(user.id, currentStreakCount, todayString);
      }
      
      // Cas 3: Hors tolérance - reset
      print('🔄 Hors tolérance - Reset de la streak');
      return await _resetStreak(user.id, todayString);
      
    } catch (e) {
      print('❌ StreakService: Erreur lors du calcul de streak: $e');
      return 0;
    }
  }
  
  /// Initialise la streak à 1 pour une première utilisation
  static Future<int> _initializeStreak(String userId, String date) async {
    try {
      await _client
          .from('users')
          .update({
            'streak_count': 1,
            'streak_last_date': date,
          })
          .eq('id', userId);
          
      print('🎯 Streak initialisée: 1 jour');
      return 1;
    } catch (e) {
      print('❌ Erreur initialisation streak: $e');
      return 0;
    }
  }
  
  /// Incrémente la streak de 1
  static Future<int> _incrementStreak(String userId, int currentStreak, String date) async {
    try {
      final newStreak = currentStreak + 1;
      
      await _client
          .from('users')
          .update({
            'streak_count': newStreak,
            'streak_last_date': date,
          })
          .eq('id', userId);
          
      print('📈 Streak incrémentée: $newStreak jours');
      return newStreak;
    } catch (e) {
      print('❌ Erreur incrémentation streak: $e');
      return currentStreak; // Retourner l'ancienne valeur en cas d'erreur
    }
  }
  
  /// Reset la streak à 1
  static Future<int> _resetStreak(String userId, String date) async {
    try {
      await _client
          .from('users')
          .update({
            'streak_count': 1,
            'streak_last_date': date,
          })
          .eq('id', userId);
          
      print('🔄 Streak reset: 1 jour');
      return 1;
    } catch (e) {
      print('❌ Erreur reset streak: $e');
      return 0;
    }
  }
  
  /// Force la mise à jour de la streak (appelé après une activité)
  /// Utile quand l'utilisateur fait une activité dans la journée
  static Future<void> notifyActivity() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      
      final today = DateTime.now();
      final todayString = _formatDate(today);
      
      print('🎯 StreakService: Notification d\'activité pour $todayString');
      
      // Mettre à jour la dernière date d'activité si pas déjà fait aujourd'hui
      final response = await _client
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
      print('❌ StreakService: Erreur notification activité: $e');
    }
  }
  
  /// Récupère seulement la valeur actuelle sans recalcul
  /// Utile pour l'affichage rapide
  static Future<int> getStreakValue() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;
      
      final response = await _client
          .from('users')
          .select('streak_count')
          .eq('id', user.id)
          .maybeSingle();
          
      return response?['streak_count'] as int? ?? 0;
    } catch (e) {
      print('❌ StreakService: Erreur récupération streak: $e');
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
      final user = _client.auth.currentUser;
      if (user == null) {
        print('🐛 Debug Streak: Utilisateur non connecté');
        return;
      }
      
      final response = await _client
          .from('users')
          .select('streak_count, streak_last_date')
          .eq('id', user.id)
          .maybeSingle();
          
      if (response != null) {
        final count = response['streak_count'];
        final date = response['streak_last_date'];
        print('🐛 Debug Streak - Count: $count, Last Date: $date');
      } else {
        print('🐛 Debug Streak: Aucune donnée trouvée');
      }
    } catch (e) {
      print('❌ Debug Streak: Erreur: $e');
    }
  }
}
