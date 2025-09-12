import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'dashboard_service.dart';

/// Service pour gérer le suivi d'hydratation
class WaterService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  /// Types de contenants disponibles avec leurs volumes par défaut
  static const Map<String, int> sourceTypeVolumes = {
    'glass': 250,        // Verre
    'bottle': 500,       // Bouteille
    'sports_bottle': 750, // Gourde de sport
    'cup': 200,          // Tasse
    'manual': 0,         // Saisie manuelle
  };

  /// Ajouter une entrée d'eau
  static Future<bool> addWaterEntry({
    required int amount,
    String sourceType = 'manual',
    String? notes,
    DateTime? consumedAt,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _supabase.from('water_entries').insert({
        'user_id': user.id,
        'amount': amount,
        'source_type': sourceType,
        'notes': notes,
        'consumed_at': (consumedAt ?? DateTime.now()).toIso8601String(),
      });

      // Mettre à jour les objectifs en temps réel
      await DashboardService.invalidateAndRefreshGoals();

      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout d\'eau: $e');
      return false;
    }
  }

  /// Ajouter de l'eau avec un type de contenant prédéfini
  static Future<bool> addWaterFromSource({
    required String sourceType,
    int? customAmount,
    String? notes,
  }) async {
    final amount = customAmount ?? sourceTypeVolumes[sourceType] ?? 250;
    return addWaterEntry(
      amount: amount,
      sourceType: sourceType,
      notes: notes,
    );
  }

  /// Récupérer le progrès d'hydratation du jour
  static Future<WaterProgress?> getDailyWaterProgress({DateTime? date}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final targetDate = date ?? DateTime.now();
      final response = await _supabase.rpc('get_daily_water_progress', params: {
        'target_user_id': user.id,
        'target_date': targetDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      });

      if (response.isNotEmpty) {
        final data = response[0];
        return WaterProgress.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Erreur lors de la récupération du progrès: $e');
      return null;
    }
  }

  /// Récupérer les entrées d'eau du jour
  static Future<List<WaterEntry>> getTodayWaterEntries() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('water_entries')
          .select('*')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String())
          .order('consumed_at', ascending: false);

      return response.map((data) => WaterEntry.fromJson(data)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des entrées: $e');
      return [];
    }
  }

  /// Récupérer l'historique d'hydratation sur plusieurs jours
  static Future<List<DailyWaterSummary>> getWaterHistory({
    required int days,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final response = await _supabase
          .from('daily_water_stats')
          .select('*')
          .eq('user_id', user.id)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      return response.map((data) => DailyWaterSummary.fromJson(data)).toList();
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Supprimer une entrée d'eau
  static Future<bool> deleteWaterEntry(String entryId) async {
    try {
      await _supabase.from('water_entries').delete().eq('id', entryId);
      
      // Mettre à jour les objectifs en temps réel
      await DashboardService.invalidateAndRefreshGoals();
      
      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Modifier l'objectif d'hydratation quotidien
  static Future<bool> updateDailyWaterGoal(int goalMl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _supabase
          .from('users')
          .update({'daily_water_goal': goalMl})
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'objectif: $e');
      return false;
    }
  }

  /// Récupérer l'objectif d'hydratation actuel de l'utilisateur
  static Future<int> getCurrentWaterGoal() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from('users')
          .select('daily_water_goal')
          .eq('id', user.id)
          .single();

      return response['daily_water_goal'] ?? 2000;
    } catch (e) {
      print('Erreur lors de la récupération de l\'objectif: $e');
      return 2000; // Valeur par défaut
    }
  }
}

/// Modèle pour représenter une entrée d'eau
class WaterEntry {
  final String id;
  final String userId;
  final int amount;
  final DateTime consumedAt;
  final String sourceType;
  final String? notes;
  final DateTime createdAt;

  WaterEntry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.consumedAt,
    required this.sourceType,
    this.notes,
    required this.createdAt,
  });

  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'],
      userId: json['user_id'],
      amount: json['amount'],
      consumedAt: DateTime.parse(json['consumed_at']),
      sourceType: json['source_type'] ?? 'manual',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Obtenir l'icône selon le type de source
  String get sourceIcon {
    switch (sourceType) {
      case 'glass':
        return '🥤';
      case 'bottle':
        return '🍼';
      case 'sports_bottle':
        return '🏃';
      case 'cup':
        return '☕';
      default:
        return '💧';
    }
  }

  /// Obtenir le nom du type de source
  String get sourceDisplayName {
    switch (sourceType) {
      case 'glass':
        return 'Verre';
      case 'bottle':
        return 'Bouteille';
      case 'sports_bottle':
        return 'Gourde sport';
      case 'cup':
        return 'Tasse';
      default:
        return 'Manuel';
    }
  }
}

/// Modèle pour représenter le progrès d'hydratation quotidien
class WaterProgress {
  final DateTime date;
  final int consumedMl;
  final int goalMl;
  final double progressPercentage;
  final int remainingMl;
  final int entriesCount;

  WaterProgress({
    required this.date,
    required this.consumedMl,
    required this.goalMl,
    required this.progressPercentage,
    required this.remainingMl,
    required this.entriesCount,
  });

  factory WaterProgress.fromJson(Map<String, dynamic> json) {
    return WaterProgress(
      date: DateTime.parse(json['date']),
      consumedMl: json['consumed_ml'],
      goalMl: json['goal_ml'],
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      remainingMl: json['remaining_ml'],
      entriesCount: json['entries_count'],
    );
  }

  /// Vérifier si l'objectif est atteint
  bool get isGoalReached => progressPercentage >= 100;

  /// Obtenir le pourcentage formaté
  String get formattedPercentage => '${progressPercentage.toStringAsFixed(1)}%';
}

/// Modèle pour représenter un résumé quotidien d'hydratation
class DailyWaterSummary {
  final DateTime date;
  final int totalWaterMl;
  final int entriesCount;
  final DateTime? firstEntry;
  final DateTime? lastEntry;

  DailyWaterSummary({
    required this.date,
    required this.totalWaterMl,
    required this.entriesCount,
    this.firstEntry,
    this.lastEntry,
  });

  factory DailyWaterSummary.fromJson(Map<String, dynamic> json) {
    return DailyWaterSummary(
      date: DateTime.parse(json['date']),
      totalWaterMl: json['total_water_ml'],
      entriesCount: json['entries_count'],
      firstEntry: json['first_entry'] != null 
          ? DateTime.parse(json['first_entry']) 
          : null,
      lastEntry: json['last_entry'] != null 
          ? DateTime.parse(json['last_entry']) 
          : null,
    );
  }

  /// Formatter la date pour l'affichage
  String get formattedDate {
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}';
  }
} 