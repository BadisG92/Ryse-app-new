import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

import 'optimistic_update_service.dart';
import 'global_state_manager.dart';
import 'streak_service.dart';
import 'ryze_connectivity.dart';
import 'supabase_error_handler.dart';
import 'meal_widget_data_provider.dart';
import 'notification_service.dart';
import 'water_queue.dart';

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

  /// Ajouter une entrée d'eau avec mise à jour optimiste
  static Future<bool> addWaterEntry({
    required int amount,
    String sourceType = 'manual',
    String? notes,
    DateTime? consumedAt,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Le verre s'affiche tout de suite : l'écriture, elle, est attendue.
      GlobalStateManager.instance.updateWater(amount / 1000.0); // Convertir ml en L

      // OPTIMISATION: Mise à jour optimiste immédiate de l'UI (garde pour compatibilité)
      await OptimisticUpdateService.updateWaterOptimistic(amount);

      // L'identifiant vient d'ici, pas de la base : si l'écriture échoue et
      // que la file la rejoue, elle retombe sur la même clé primaire et ne
      // peut donc pas ajouter le verre deux fois.
      final at = consumedAt ?? DateTime.now();
      final id = const Uuid().v4();

      // Hors ligne, le verre était perdu : il s'affichait, l'écriture
      // échouait, il disparaissait. Il part maintenant dans la même file
      // durable que les séances de musculation, et le compteur le garde.
      if (!RyzeConnectivity.instance.online.value) {
        await WaterQueue.instance.keepAdd(
          userId: user.id,
          amount: amount,
          sourceType: sourceType,
          notes: notes,
          consumedAt: at,
          id: id,
        );
        return true;
      }

      try {
        await _supabase.from('water_entries').insert({
          'id': id,
          'user_id': user.id,
          'amount': amount,
          'source_type': sourceType,
          'notes': notes,
          'consumed_at': at.toIso8601String(),
        }).timeout(const Duration(seconds: 8));
      } catch (error) {
        // En ligne mais l'écriture n'est pas passée : même chemin que hors
        // ligne. « Hors ligne » et « ça a échoué » ne se traitent plus
        // différemment.
        debugPrint('⚠️ Écriture eau différée: $error');
        await WaterQueue.instance.keepAdd(
          userId: user.id,
          amount: amount,
          sourceType: sourceType,
          notes: notes,
          consumedAt: at,
          id: id,
        );
        return true;
      }

      // Ce qui suit ne conditionne pas la réussite : le verre est en base.
      debugPrint('✅ Eau ajoutée en base - sync rapide');
      unawaited(MealWidgetDataProvider.updateWidgetData());
      unawaited(NotificationService().updateLastActivity());
      unawaited(NotificationService().cancelWaterReminders());
      unawaited(NotificationService().cancelActivityBasedReminders());
      // Boire fait partie des journées suivies.
      unawaited(StreakService.notifyActivity());

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout d\'eau: $e');
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
    return await SupabaseErrorHandler.executeWithRetry(
      operation: () async {
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
      },
      operationName: 'getDailyWaterProgress',
      fallbackValue: null,
    );
  }

  /// Récupérer les entrées d'eau du jour, celles de la base et celles qui
  /// attendent encore sur le téléphone.
  ///
  /// Le journal lit cette liste pour savoir quel verre retirer. Hors ligne
  /// elle était vide, donc retirer un verre qu'on venait d'ajouter ne faisait
  /// rien : les verres gardés doivent s'y voir comme les autres.
  static Future<List<WaterEntry>> getTodayWaterEntries() async {
    final today = DateTime.now();
    final pending = await WaterQueue.instance.pendingAddsOn(today);
    final kept = [
      for (final glass in pending)
        WaterEntry(
          id: glass.id,
          userId: _supabase.auth.currentUser?.id ?? '',
          amount: glass.amount,
          consumedAt: glass.at,
          sourceType: glass.amount == 250 ? 'glass' : 'manual',
          createdAt: glass.at,
        ),
    ];

    final stored = await SupabaseErrorHandler.executeWithRetry(
      operation: () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');

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
      },
      operationName: 'getTodayWaterEntries',
      fallbackValue: <WaterEntry>[],
    );

    // Une ligne déjà partie peut figurer des deux côtés le temps d'un envoi :
    // l'identifiant vient de nous, donc le doublon se reconnaît.
    final ids = stored.map((e) => e.id).toSet();
    return [...stored, ...kept.where((e) => !ids.contains(e.id))]
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
  }

  /// Récupérer l'historique d'hydratation sur plusieurs jours
  static Future<List<DailyWaterSummary>> getWaterHistory({
    required int days,
  }) async {
    return await SupabaseErrorHandler.executeWithRetry(
      operation: () async {
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
      },
      operationName: 'getWaterHistory',
      fallbackValue: [],
    );
  }

  /// Supprimer une entrée d'eau avec mise à jour optimiste
  static Future<bool> deleteWaterEntry(String entryId, {int? amountToRemove}) async {
    try {
      // Si on connait la quantité, mise à jour optimiste
      if (amountToRemove != null) {
        GlobalStateManager.instance.updateWater(-amountToRemove / 1000.0); // NOUVEAU
        await OptimisticUpdateService.updateWaterOptimistic(-amountToRemove);
      }

      // Le retrait suit le même chemin que l'ajout : hors ligne il est gardé
      // sur le téléphone. Et si la ligne visée attend elle-même d'être
      // envoyée, la file la retire sans rien demander au serveur — elle n'y
      // a jamais existé.
      if (!RyzeConnectivity.instance.online.value) {
        await WaterQueue.instance.keepDelete(
          entryId: entryId,
          amount: amountToRemove ?? 0,
          at: DateTime.now(),
        );
        return true;
      }

      try {
        await _supabase.from('water_entries').delete().eq('id', entryId).timeout(const Duration(seconds: 8));
      } catch (error) {
        debugPrint('⚠️ Suppression eau différée: $error');
        await WaterQueue.instance.keepDelete(
          entryId: entryId,
          amount: amountToRemove ?? 0,
          at: DateTime.now(),
        );
        return true;
      }

      debugPrint('✅ Eau supprimée de la base');
      unawaited(MealWidgetDataProvider.updateWidgetData());

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
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

      // NOUVEAU: Mettre à jour GlobalStateManager pour synchronisation instantanée
      GlobalStateManager.instance.updateGoals(waterGoalL: goalMl / 1000.0);

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'objectif: $e');
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
      debugPrint('Erreur lors de la récupération de l\'objectif: $e');
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