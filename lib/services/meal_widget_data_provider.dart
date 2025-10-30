import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/food_entries_service.dart';
import '../services/global_state_manager.dart';

/// Provider de données pour les widgets iOS repas
/// Synchronise les données entre Flutter et les widgets iOS via UserDefaults partagé
class MealWidgetDataProvider {
  /// App Group ID pour partager les données avec les widgets iOS
  /// À configurer dans Xcode : Capabilities → App Groups
  static const String appGroupId = 'group.com.ryse.app';

  /// Mettre à jour les données du widget après chaque changement de repas
  /// Appelé automatiquement après ajout/suppression d'aliment
  static Future<void> updateWidgetData() async {
    try {
      if (kDebugMode) {
        debugPrint('📱 Mise à jour des données widget...');
      }

      final prefs = await SharedPreferences.getInstance();
      final user = AuthService().currentUser;

      if (user == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Pas d\'utilisateur connecté, pas de mise à jour widget');
        }
        return;
      }

      // Récupérer les repas du jour
      final meals = await FoodEntriesService.getFoodEntriesForDate(
        user.id,
        DateTime.now(),
      );

      // Déterminer le repas contextuel selon l'heure
      final contextualMeal = _getContextualMealType();
      final contextualMealData = meals.cast<dynamic>().firstWhere(
            (m) => m.name.toLowerCase() == _getMealName(contextualMeal).toLowerCase(),
            orElse: () => null,
          );

      // Récupérer les totaux depuis GlobalStateManager
      final globalState = GlobalStateManager.instance;

      // Préparer les données pour tous les repas
      final allMealsData = <Map<String, dynamic>>[];
      for (final mealType in ['petit-dejeuner', 'dejeuner', 'diner']) {
        final mealName = _getMealName(mealType);
        final mealData = meals.cast<dynamic>().firstWhere(
              (m) => m.name.toLowerCase() == mealName.toLowerCase(),
              orElse: () => null,
            );

        allMealsData.add({
          'type': mealType,
          'name': mealName,
          'emoji': _getMealEmoji(mealType),
          'calories': mealData?.totalCalories ?? 0,
          'hasItems': mealData != null && mealData.items.isNotEmpty,
          'itemCount': mealData?.items.length ?? 0,
        });
      }

      // Créer la structure de données pour le widget
      final widgetData = {
        'contextualMeal': {
          'type': contextualMeal,
          'name': _getMealName(contextualMeal),
          'emoji': _getMealEmoji(contextualMeal),
          'calories': contextualMealData?.totalCalories ?? 0,
          'hasItems': contextualMealData != null &&
              contextualMealData.items.isNotEmpty,
          'itemCount': contextualMealData?.items.length ?? 0,
        },
        'allMeals': allMealsData,
        'totals': {
          'current': globalState.currentCalories.toInt(),
          'goal': globalState.calorieGoal.toInt(),
          'percentage': globalState.calorieGoal > 0
              ? (globalState.currentCalories / globalState.calorieGoal * 100)
                  .round()
              : 0,
        },
        'macros': {
          'protein': globalState.currentProteins.toInt(),
          'carbs': globalState.currentCarbs.toInt(),
          'fats': globalState.currentFats.toInt(),
        },
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      // Sauvegarder dans SharedPreferences (utilisé par les widgets iOS)
      await prefs.setString('widget_meal_data', jsonEncode(widgetData));

      if (kDebugMode) {
        debugPrint('✅ Données widget mises à jour:');
        final contextualMeal = widgetData['contextualMeal'] as Map<String, dynamic>;
        final totals = widgetData['totals'] as Map<String, dynamic>;
        debugPrint('   - Repas contextuel: ${contextualMeal['name']} (${contextualMeal['calories']} kcal)');
        debugPrint('   - Total: ${totals['current']}/${totals['goal']} kcal');
      }

      // Notifier iOS que les données ont changé (si disponible)
      if (Platform.isIOS) {
        try {
          // TODO: Ajouter l'appel WidgetKit.reloadAllTimelines()
          // via platform channel quand le plugin sera ajouté
          if (kDebugMode) {
            debugPrint('📱 Notification iOS: reload widget timelines');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Impossible de notifier iOS: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur mise à jour données widget: $e');
      }
    }
  }

  /// Obtenir le type de repas contextuel selon l'heure actuelle
  static String _getContextualMealType() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 10) {
      return 'petit-dejeuner';
    } else if (hour >= 11 && hour < 14) {
      return 'dejeuner';
    } else if (hour >= 18 && hour < 21) {
      return 'diner';
    } else {
      return 'snack';
    }
  }

  /// Obtenir le nom français du repas à partir du type
  static String _getMealName(String mealType) {
    final mappings = {
      'petit-dejeuner': 'Petit-déjeuner',
      'dejeuner': 'Déjeuner',
      'diner': 'Dîner',
      'snack': 'Snack',
    };
    return mappings[mealType.toLowerCase()] ?? 'Repas';
  }

  /// Obtenir l'emoji du repas
  static String _getMealEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'petit-dejeuner':
        return '🌅';
      case 'dejeuner':
        return '🌤️';
      case 'diner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }

  /// Récupérer les données du widget (pour debug ou affichage)
  static Future<Map<String, dynamic>?> getWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('widget_meal_data');

      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur récupération données widget: $e');
      }
      return null;
    }
  }

  /// Effacer les données du widget (logout)
  static Future<void> clearWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('widget_meal_data');

      if (kDebugMode) {
        debugPrint('🗑️ Données widget effacées');
      }

      // Notifier iOS
      if (Platform.isIOS) {
        try {
          // TODO: Ajouter l'appel WidgetKit.reloadAllTimelines()
          if (kDebugMode) {
            debugPrint('📱 Notification iOS: reload widget timelines après clear');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Impossible de notifier iOS: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur effacement données widget: $e');
      }
    }
  }
}
