import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_planner_models.dart';
import '../models/nutrition_models.dart';
import 'food_entries_service.dart';
import 'auth_service.dart';
import 'global_state_manager.dart';

/// Service de synchronisation bidirectionnelle Planner ↔ Journal
///
/// Source de vérité = Journal (food_entries)
/// - Validation checkbox → ajout au journal
/// - Dé-validation → suppression du journal
/// - Suppression journal → suppression lien planner
class MealPlannerSyncService {
  static final _supabase = Supabase.instance.client;

  // Mapping meal type → meal name pour FoodEntriesService
  static const Map<PlannedActivityType, String> _mealTypeToName = {
    PlannedActivityType.breakfast: 'Petit-déjeuner',
    PlannedActivityType.lunch: 'Déjeuner',
    PlannedActivityType.snack: 'Collation',
    PlannedActivityType.dinner: 'Dîner',
  };

  /// Valider un repas planifié → l'ajouter au journal
  /// Retourne l'ID du food_entry créé ou null si échec
  static Future<String?> validateMeal(PlannedActivity activity) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        debugPrint('❌ MealPlannerSyncService.validateMeal: user not logged in');
        return null;
      }

      final mealData = activity.mealData;
      if (mealData == null) {
        debugPrint('❌ MealPlannerSyncService.validateMeal: no meal data');
        return null;
      }

      // Créer un FoodItem à partir des données du repas planifié
      final foodItem = FoodItem(
        name: mealData.displayName,
        calories: mealData.calories ?? 0,
        proteins: mealData.proteins ?? 0.0,
        carbs: mealData.carbs ?? 0.0,
        fats: mealData.fats ?? 0.0,
        portion: '${mealData.estimatedQuantityG?.toStringAsFixed(0) ?? "200"} g',
        isScanned: false, // Généré par IA
      );

      // Obtenir le nom du repas pour FoodEntriesService
      final mealName = _mealTypeToName[activity.activityType] ?? 'Collation';

      // Ajouter au journal (skip planner sync pour éviter boucle infinie)
      final success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: mealName,
        foodItem: foodItem,
        consumedAt: activity.plannedDate,
        skipPlannerSync: true, // On gère déjà le lien planner ici
      );

      if (!success) {
        debugPrint('❌ MealPlannerSyncService.validateMeal: failed to add food entry');
        return null;
      }

      // Récupérer l'ID du food_entry créé (le dernier pour ce jour et type)
      final foodEntryId = await _findLatestFoodEntryId(
        user.id,
        activity.plannedDate,
        activity.activityType,
      );

      if (foodEntryId == null) {
        debugPrint('⚠️ MealPlannerSyncService.validateMeal: could not find created entry');
        return null;
      }

      // Mettre à jour l'activité planifiée avec le lien et status completed
      await _updateActivityWithLink(activity.id, foodEntryId);

      // Notifier le GlobalStateManager pour mettre à jour le planner
      GlobalStateManager.instance.invalidateWeeklyData();

      debugPrint('✅ Repas validé: ${mealData.displayName} → food_entry $foodEntryId');
      return foodEntryId;
    } catch (e) {
      debugPrint('❌ MealPlannerSyncService.validateMeal error: $e');
      return null;
    }
  }

  /// Valider un repas planifié avec des macros modifiées
  /// Permet à l'utilisateur d'ajuster les portions/macros avant validation
  /// Retourne l'ID du food_entry créé ou null si échec
  static Future<String?> validateMealWithMacros(
    PlannedActivity activity, {
    required int calories,
    required double proteins,
    required double carbs,
    required double fats,
    String? dishName,
    String? dishDescription,
  }) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        debugPrint('❌ MealPlannerSyncService.validateMealWithMacros: user not logged in');
        return null;
      }

      final mealData = activity.mealData;
      if (mealData == null) {
        debugPrint('❌ MealPlannerSyncService.validateMealWithMacros: no meal data');
        return null;
      }

      // Créer un FoodItem avec les macros modifiées par l'utilisateur
      final foodItem = FoodItem(
        name: dishName ?? mealData.displayName,
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        portion: '${mealData.estimatedQuantityG?.toStringAsFixed(0) ?? "200"} g',
        isScanned: false,
        hasModifiedMacros: true, // Marquer comme modifié
      );

      // Obtenir le nom du repas pour FoodEntriesService
      final mealName = _mealTypeToName[activity.activityType] ?? 'Collation';

      // Chercher un bloc existant du même type de repas pour cette journée
      // Si un bloc existe, on ajoute au même bloc au lieu de créer "Collation 2"
      final existingMealId = await FoodEntriesService.findExistingMealId(
        userId: user.id,
        mealName: mealName,
        forDate: activity.plannedDate,
      );

      // Ajouter au journal (skip planner sync pour éviter boucle infinie)
      final success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: mealName,
        foodItem: foodItem,
        consumedAt: activity.plannedDate,
        mealId: existingMealId, // Utiliser le bloc existant si trouvé
        skipPlannerSync: true,
      );

      if (!success) {
        debugPrint('❌ MealPlannerSyncService.validateMealWithMacros: failed to add food entry');
        return null;
      }

      // Récupérer l'ID du food_entry créé
      final foodEntryId = await _findLatestFoodEntryId(
        user.id,
        activity.plannedDate,
        activity.activityType,
      );

      if (foodEntryId == null) {
        debugPrint('⚠️ MealPlannerSyncService.validateMealWithMacros: could not find created entry');
        return null;
      }

      // Mettre à jour l'activité planifiée avec le lien, les nouvelles macros et status completed
      await _updateActivityWithLinkAndMacros(
        activity.id,
        foodEntryId,
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        dishName: dishName,
        dishDescription: dishDescription,
      );

      // Notifier le GlobalStateManager pour mettre à jour le planner
      GlobalStateManager.instance.invalidateWeeklyData();

      debugPrint('✅ Repas validé avec macros modifiées: ${dishName ?? mealData.displayName} → food_entry $foodEntryId');
      return foodEntryId;
    } catch (e) {
      debugPrint('❌ MealPlannerSyncService.validateMealWithMacros error: $e');
      return null;
    }
  }

  /// Mettre à jour l'activité avec le lien et les macros modifiées
  static Future<void> _updateActivityWithLinkAndMacros(
    String activityId,
    String foodEntryId, {
    required int calories,
    required double proteins,
    required double carbs,
    required double fats,
    String? dishName,
    String? dishDescription,
  }) async {
    // Récupérer d'abord les données existantes
    final existing = await _supabase
        .from('planned_activities')
        .select('activity_data')
        .eq('id', activityId)
        .single();

    final activityData = Map<String, dynamic>.from(existing['activity_data'] ?? {});
    activityData['linked_food_entry_id'] = foodEntryId;
    // Mettre à jour les macros avec les valeurs modifiées
    activityData['calories'] = calories;
    activityData['proteins'] = proteins;
    activityData['carbs'] = carbs;
    activityData['fats'] = fats;
    // Mettre à jour le nom et la description si fournis
    if (dishName != null) {
      activityData['dish_name'] = dishName;
    }
    if (dishDescription != null) {
      activityData['dish_description'] = dishDescription;
    }

    await _supabase
        .from('planned_activities')
        .update({
          'activity_data': activityData,
          'status': 'completed',
        })
        .eq('id', activityId);
  }

  /// Mettre à jour la description d'un repas planifié (ingrédients modifiés)
  static Future<void> updateMealDescription(String activityId, String newDescription) async {
    try {
      // Récupérer les données existantes
      final existing = await _supabase
          .from('planned_activities')
          .select('activity_data')
          .eq('id', activityId)
          .single();

      final activityData = Map<String, dynamic>.from(existing['activity_data'] ?? {});
      activityData['dish_description'] = newDescription;

      await _supabase
          .from('planned_activities')
          .update({'activity_data': activityData})
          .eq('id', activityId);

      debugPrint('✅ Description du repas mise à jour');
    } catch (e) {
      debugPrint('❌ updateMealDescription error: $e');
    }
  }

  /// Dé-valider un repas → supprimer du journal
  static Future<bool> unvalidateMeal(PlannedActivity activity) async {
    try {
      final mealData = activity.mealData;
      if (mealData == null) {
        debugPrint('❌ MealPlannerSyncService.unvalidateMeal: no meal data');
        return false;
      }

      final linkedId = mealData.effectiveLinkedId;
      if (linkedId == null) {
        debugPrint('⚠️ MealPlannerSyncService.unvalidateMeal: no linked entry');
        // Pas de lien = pas besoin de supprimer, juste réinitialiser le status
        await _removeActivityLink(activity.id);
        return true;
      }

      // Supprimer le food_entry (skip planner sync pour garder l'activité planifiée)
      final success = await FoodEntriesService.removeFoodEntry(linkedId, skipPlannerSync: true);
      if (!success) {
        debugPrint('⚠️ MealPlannerSyncService.unvalidateMeal: failed to remove entry');
        // Continuer quand même pour nettoyer le lien
      }

      // Retirer le lien et remettre status = planned
      await _removeActivityLink(activity.id);

      // Notifier le GlobalStateManager pour mettre à jour le planner
      GlobalStateManager.instance.invalidateWeeklyData();

      debugPrint('✅ Repas dé-validé: ${mealData.displayName}');
      return true;
    } catch (e) {
      debugPrint('❌ MealPlannerSyncService.unvalidateMeal error: $e');
      return false;
    }
  }

  /// Mettre à jour les macros d'un repas validé
  /// Met à jour à la fois le planner et le journal
  static Future<bool> updateMealMacros(
    PlannedActivity activity, {
    required int calories,
    required double proteins,
    required double carbs,
    required double fats,
    String? dishName,
    String? dishDescription,
  }) async {
    try {
      final mealData = activity.mealData;
      if (mealData == null) return false;

      // Mettre à jour les données de l'activité planifiée
      final updatedData = mealData.copyWith(
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        dishName: dishName,
        dishDescription: dishDescription,
      );

      await _supabase
          .from('planned_activities')
          .update({'activity_data': updatedData.toJson()})
          .eq('id', activity.id);

      // Si validé, mettre à jour aussi le food_entry
      final linkedId = mealData.effectiveLinkedId;
      if (linkedId != null) {
        await _supabase
            .from('food_entries')
            .update({
              'calories': calories,
              'proteins': proteins,
              'carbs': carbs,
              'fats': fats,
              'has_modified_macros': true,
            })
            .eq('id', linkedId);
      }

      debugPrint('✅ Macros mises à jour pour ${mealData.displayName}');
      return true;
    } catch (e) {
      debugPrint('❌ MealPlannerSyncService.updateMealMacros error: $e');
      return false;
    }
  }

  /// Trouver l'ID du dernier food_entry créé pour ce jour et type
  static Future<String?> _findLatestFoodEntryId(
    String userId,
    DateTime date,
    PlannedActivityType mealType,
  ) async {
    try {
      final dbMealType = mealType.value; // breakfast, lunch, etc.
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await _supabase
          .from('food_entries')
          .select('id')
          .eq('user_id', userId)
          .eq('meal_type', dbMealType)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return result?['id'] as String?;
    } catch (e) {
      debugPrint('❌ _findLatestFoodEntryId error: $e');
      return null;
    }
  }

  /// Mettre à jour l'activité avec le lien vers food_entry
  static Future<void> _updateActivityWithLink(String activityId, String foodEntryId) async {
    // Récupérer d'abord les données existantes
    final existing = await _supabase
        .from('planned_activities')
        .select('activity_data')
        .eq('id', activityId)
        .single();

    final activityData = Map<String, dynamic>.from(existing['activity_data'] ?? {});
    activityData['linked_food_entry_id'] = foodEntryId;

    await _supabase
        .from('planned_activities')
        .update({
          'activity_data': activityData,
          'status': 'completed',
        })
        .eq('id', activityId);
  }

  /// Retirer le lien et remettre status à planned
  static Future<void> _removeActivityLink(String activityId) async {
    try {
      // Récupérer d'abord les données existantes
      final existing = await _supabase
          .from('planned_activities')
          .select('activity_data')
          .eq('id', activityId)
          .single();

      final activityData = Map<String, dynamic>.from(existing['activity_data'] ?? {});
      activityData.remove('linked_food_entry_id');
      activityData.remove('linked_entry_id'); // Ancien champ aussi

      await _supabase
          .from('planned_activities')
          .update({
            'activity_data': activityData,
            'status': 'planned',
          })
          .eq('id', activityId);
    } catch (e) {
      debugPrint('❌ _removeActivityLink error: $e');
    }
  }

  /// Vérifier si un repas est validé (a un lien vers food_entries)
  static bool isMealValidated(PlannedActivity activity) {
    final mealData = activity.mealData;
    if (mealData == null) return false;
    return mealData.isValidated;
  }

  /// Vérifier si un repas peut être validé (aujourd'hui uniquement)
  static bool canValidateMeal(PlannedActivity activity) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(
      activity.plannedDate.year,
      activity.plannedDate.month,
      activity.plannedDate.day,
    );
    return activityDate == today;
  }

  /// Vérifier si un repas est manqué (passé et non validé)
  static bool isMealMissed(PlannedActivity activity) {
    if (activity.status == PlannedStatus.completed) return false;
    if (activity.status == PlannedStatus.missed) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(
      activity.plannedDate.year,
      activity.plannedDate.month,
      activity.plannedDate.day,
    );
    return activityDate.isBefore(today);
  }

  // ==================== SYNC JOURNAL → PLANNER ====================

  /// Créer une activité planifiée depuis un food_entry ajouté au journal
  /// Appelé automatiquement quand un repas est ajouté via scan/chat/manuel
  static Future<void> syncFoodEntryToPlanner({
    required String foodEntryId,
    required String mealType, // 'breakfast', 'lunch', 'dinner', 'snack'
    required DateTime consumedAt,
    required String foodName,
    required int calories,
    required double proteins,
    required double carbs,
    required double fats,
    double? quantity,
  }) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      // Vérifier si la date est dans la semaine courante
      if (!_isInCurrentWeek(consumedAt)) {
        debugPrint('📅 Food entry not in current week, skipping planner sync');
        return;
      }

      // Vérifier s'il n'existe pas déjà une activité liée à ce food_entry
      final existing = await _supabase
          .from('planned_activities')
          .select('id')
          .eq('user_id', user.id)
          .contains('activity_data', {'linked_food_entry_id': foodEntryId})
          .maybeSingle();

      if (existing != null) {
        debugPrint('📋 Activity already exists for food_entry $foodEntryId');
        return;
      }

      // Convertir le meal_type en PlannedActivityType
      final activityType = _mealTypeFromString(mealType);

      // Créer l'activité planifiée avec status = completed (car déjà dans le journal)
      final activityData = {
        'dish_name': foodName,
        'dish_description': '',
        'calories': calories,
        'proteins': proteins,
        'carbs': carbs,
        'fats': fats,
        'estimated_quantity_g': quantity ?? 100.0,
        'linked_food_entry_id': foodEntryId,
      };

      await _supabase.from('planned_activities').insert({
        'user_id': user.id,
        'planned_date': DateTime(consumedAt.year, consumedAt.month, consumedAt.day).toIso8601String().split('T')[0],
        'activity_type': activityType.value,
        'activity_data': activityData,
        'status': 'completed', // Déjà validé car vient du journal
        'is_ai_generated': false,
      });

      // Notifier le GlobalStateManager pour mettre à jour le planner
      GlobalStateManager.instance.invalidateWeeklyData();

      debugPrint('✅ Synced food_entry $foodEntryId to planner');
    } catch (e) {
      debugPrint('❌ syncFoodEntryToPlanner error: $e');
    }
  }

  /// Supprimer l'activité planifiée quand un food_entry est supprimé du journal
  static Future<void> onFoodEntryDeleted(String foodEntryId) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      // Trouver et supprimer l'activité liée
      // Note: On utilise une requête SQL brute car Supabase ne supporte pas bien
      // la recherche dans les JSONB avec contains pour des valeurs string
      final activities = await _supabase
          .from('planned_activities')
          .select('id, activity_data')
          .eq('user_id', user.id);

      for (final activity in activities) {
        final activityData = activity['activity_data'] as Map<String, dynamic>?;
        if (activityData != null) {
          final linkedId = activityData['linked_food_entry_id'] as String?;
          if (linkedId == foodEntryId) {
            await _supabase
                .from('planned_activities')
                .delete()
                .eq('id', activity['id']);

            // Notifier le GlobalStateManager pour mettre à jour le planner
            GlobalStateManager.instance.invalidateWeeklyData();

            debugPrint('✅ Deleted planner activity linked to food_entry $foodEntryId');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ onFoodEntryDeleted error: $e');
    }
  }

  /// Vérifier si une date est dans la semaine courante
  static bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final normalizedStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = normalizedStart.add(const Duration(days: 6));
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return !normalizedDate.isBefore(normalizedStart) && !normalizedDate.isAfter(weekEnd);
  }

  /// Convertir un string meal_type en PlannedActivityType
  static PlannedActivityType _mealTypeFromString(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return PlannedActivityType.breakfast;
      case 'lunch':
        return PlannedActivityType.lunch;
      case 'dinner':
        return PlannedActivityType.dinner;
      case 'snack':
        return PlannedActivityType.snack;
      default:
        return PlannedActivityType.snack;
    }
  }
}
