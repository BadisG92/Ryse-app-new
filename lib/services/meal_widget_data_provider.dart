import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/nutrition_models.dart';
import '../services/food_entries_service.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/coach_message_service.dart';

/// Provider de données pour les widgets iOS repas
/// Synchronise les données entre Flutter et les widgets iOS via UserDefaults partagé
class MealWidgetDataProvider {
  /// App Group ID pour partager les données avec les widgets iOS
  /// À configurer dans Xcode : Capabilities → App Groups
  static const String appGroupId = 'group.com.ryze.app';
  static const MethodChannel _widgetChannel =
      MethodChannel('com.ryze.widget/data');

  /// Mettre à jour les données du widget après chaque changement de repas
  /// Appelé automatiquement après ajout/suppression d'aliment
  static Future<void> updateWidgetData() async {
    try {
      if (kDebugMode) {
        debugPrint('📱 Mise à jour des données widget...');
      }

      final prefs = await SharedPreferences.getInstance();
      final user = SupabaseConfig.client.auth.currentUser;

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

      // Préparer la langue actuelle de l'app
      final localizationService = LocalizationService.instance;
      if (!localizationService.isInitialized) {
        await localizationService.initialize();
      }
      final languageCode = localizationService.currentLanguageCode;

      // Déterminer le repas contextuel selon l'heure
      final contextualMeal = _getContextualMealType();
      final contextualMealNames = _getStoredMealNames(contextualMeal);
      Meal? contextualMealData;
      try {
        contextualMealData = meals.firstWhere(
          (m) => contextualMealNames.contains(m.name.toLowerCase()),
        );
      } catch (e) {
        contextualMealData = null; // Aucun repas trouvé
      }

      // Calculer le total des calories du repas contextuel
      final contextualMealCalories = contextualMealData?.items.fold<int>(
        0,
        (sum, item) => sum + item.calories,
      ) ?? 0;

      // Récupérer les totaux depuis GlobalStateManager
      final globalState = GlobalStateManager.instance;

      // S'assurer que GlobalStateManager est initialisé avec les vraies valeurs
      if (globalState.calorieGoal == 0 || globalState.waterGoalL == 0) {
        if (kDebugMode) {
          debugPrint('⚠️ Les objectifs ne sont pas encore chargés, initialisation...');
        }
        await globalState.initialize();
      }

      // Préparer les données pour tous les repas (incluant snack)
      final allMealsData = <Map<String, dynamic>>[];
      for (final mealType in ['petit-dejeuner', 'dejeuner', 'diner', 'snack']) {
        final mealNames = _getStoredMealNames(mealType);
        Meal? mealData;
        try {
          mealData = meals.firstWhere(
            (m) => mealNames.contains(m.name.toLowerCase()),
          );
        } catch (e) {
          mealData = null; // Aucun repas trouvé pour ce type
        }

        // Calculer le total des calories à partir des items
        final totalCalories = mealData?.items.fold<int>(
          0,
          (sum, item) => sum + item.calories,
        ) ?? 0;

        allMealsData.add({
          'type': mealType,
          'name': _getLocalizedMealDisplayName(mealType, languageCode),
          'emoji': _getMealEmoji(mealType),
          'calories': totalCalories,
          'hasItems': mealData != null && mealData.items.isNotEmpty,
          'itemCount': mealData?.items.length ?? 0,
        });
      }

      // Récupérer les données d'eau depuis GlobalStateManager
      final currentWaterMl = (globalState.currentWaterL * 1000).toInt();
      final waterGoalMl = (globalState.waterGoalL * 1000).toInt();
      final waterPercentage = waterGoalMl > 0
          ? ((currentWaterMl / waterGoalMl) * 100).round().clamp(0, 100)
          : 0;

      // Générer le message du coach personnalisé
      final coachMessage = CoachMessageService.generateCoachMessage(languageCode);

      // Créer la structure de données pour le widget avec les VRAIES données utilisateur
      final widgetData = {
        'languageCode': languageCode,
        'translations': _buildWidgetTranslations(languageCode),
        'contextualMeal': {
          'type': contextualMeal,
          'name': _getLocalizedMealDisplayName(contextualMeal, languageCode),
          'emoji': _getMealEmoji(contextualMeal),
          'calories': contextualMealCalories,
          'hasItems': contextualMealData != null &&
              contextualMealData.items.isNotEmpty,
          'itemCount': contextualMealData?.items.length ?? 0,
        },
        'allMeals': allMealsData,
        'totals': {
          'current': globalState.currentCalories.toInt(),
          'goal': globalState.calorieGoal.toInt(), // VRAIE valeur depuis GlobalStateManager
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
        'water': {
          'current': currentWaterMl, // VRAIE valeur depuis GlobalStateManager
          'goal': waterGoalMl, // VRAIE valeur depuis GlobalStateManager
          'percentage': waterPercentage,
          'currentL': globalState.currentWaterL,
          'goalL': globalState.waterGoalL,
        },
        'coach': {
          'message': coachMessage,
          'streak': globalState.currentStreak,
        },
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      // Encoder une seule fois pour l'utiliser où nécessaire
      final encodedData = jsonEncode(widgetData);

      // Sauvegarder localement (toujours utile côté Flutter/debug)
      await prefs.setString('widget_meal_data', encodedData);

      // Écrire également dans l'App Group pour iOS afin que le widget lise les vraies données
      if (Platform.isIOS) {
        try {
          await _widgetChannel.invokeMethod('setString', {
            'key': 'widget_meal_data',
            'value': encodedData,
          });

          // Déclencher un refresh immédiat du widget
          await _widgetChannel.invokeMethod('reloadWidgetTimelines');
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Impossible de synchroniser les données widget côté iOS: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Données widget mises à jour:');
        final contextualMeal = widgetData['contextualMeal'] as Map<String, dynamic>;
        final totals = widgetData['totals'] as Map<String, dynamic>;
        final water = widgetData['water'] as Map<String, dynamic>;
        debugPrint('   - Repas contextuel: ${contextualMeal['name']} (${contextualMeal['calories']} kcal)');
        debugPrint('   - Total calories: ${totals['current']}/${totals['goal']} kcal (objectif réel: ${globalState.calorieGoal.toInt()})');
        debugPrint('   - Eau: ${water['current']}ml/${water['goal']}ml (objectif réel: ${globalState.waterGoalL.toStringAsFixed(1)}L)');
        debugPrint('   - Nombre de repas: ${allMealsData.length}');
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

  /// Obtenir le nom canonique (FR) du repas à partir du type
  static String _getCanonicalMealName(String mealType) {
    final mappings = {
      'petit-dejeuner': 'Petit-déjeuner',
      'breakfast': 'Petit-déjeuner',
      'dejeuner': 'Déjeuner',
      'lunch': 'Déjeuner',
      'diner': 'Dîner',
      'dinner': 'Dîner',
      'snack': 'Collation',
      'collation': 'Collation',
    };
    return mappings[mealType.toLowerCase()] ?? 'Repas';
  }

  /// Obtenir le nom localisé du repas pour l'affichage
  static String _getLocalizedMealDisplayName(
    String mealType,
    String languageCode,
  ) {
    final translationKey = _getMealTranslationKey(mealType);
    return AppTranslations.get(translationKey, languageCode);
  }

  /// Obtenir toutes les variantes possibles du nom du repas (FR/EN) pour matcher les données stockées
  static Set<String> _getStoredMealNames(String mealType) {
    final names = <String>{
      _getCanonicalMealName(mealType),
      _getLocalizedMealDisplayName(mealType, 'fr'),
      _getLocalizedMealDisplayName(mealType, 'en'),
    };
    return names.map((name) => name.toLowerCase()).toSet();
  }

  static String _getMealTranslationKey(String mealType) {
    final lower = mealType.toLowerCase();
    if (lower == 'petit-dejeuner' || lower == 'breakfast') {
      return 'breakfast';
    } else if (lower == 'dejeuner' || lower == 'lunch') {
      return 'lunch';
    } else if (lower == 'diner' || lower == 'dinner') {
      return 'dinner';
    } else if (lower == 'snack' || lower == 'collation') {
      return 'snack';
    }
    return 'widget_placeholder_meal';
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

  static Map<String, dynamic> _buildWidgetTranslations(String languageCode) {
    final shortBreakfast =
        AppTranslations.get('widget_short_breakfast', languageCode);
    final shortLunch = AppTranslations.get('widget_short_lunch', languageCode);
    final shortDinner =
        AppTranslations.get('widget_short_dinner', languageCode);
    final shortSnack = AppTranslations.get('widget_short_snack', languageCode);
    final shortDefault =
        AppTranslations.get('widget_short_default', languageCode);

    return {
      'languageCode': languageCode,
      'texts': {
        'widgetTitle': AppTranslations.get('widget_meals_title', languageCode),
        'widgetDescription':
            AppTranslations.get('widget_meals_description', languageCode),
        'placeholderMeal':
            AppTranslations.get('widget_placeholder_meal', languageCode),
        'addWaterTitle':
            AppTranslations.get('widget_add_water_title', languageCode),
        'addWaterDescription':
            AppTranslations.get('widget_add_water_description', languageCode),
        'addWaterPresetFormat':
            AppTranslations.get('widget_add_water_preset_format', languageCode),
        'coachWidgetTitle':
            AppTranslations.get('widget_coach_title', languageCode),
        'coachWidgetDescription':
            AppTranslations.get('widget_coach_description', languageCode),
      },
      'mealShortNames': {
        'petit-dejeuner': shortBreakfast,
        'breakfast': shortBreakfast,
        'dejeuner': shortLunch,
        'lunch': shortLunch,
        'diner': shortDinner,
        'dinner': shortDinner,
        'snack': shortSnack,
        'collation': shortSnack,
        'default': shortDefault,
      },
    };
  }

  /// Récupérer les données du widget (pour debug ou affichage)
  static Future<Map<String, dynamic>?> getWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? jsonString;
      if (Platform.isIOS) {
        try {
          jsonString = await _widgetChannel.invokeMethod<String>('getString', {
            'key': 'widget_meal_data',
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Impossible de récupérer les données via App Group: $e');
          }
        }
      }

      jsonString ??= prefs.getString('widget_meal_data');

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

  /// Forcer une mise à jour immédiate du widget avec les vraies données utilisateur
  /// Appelé après connexion ou au démarrage de l'app
  static Future<void> forceWidgetUpdate() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Force mise à jour widget avec vraies données utilisateur...');
      }

      // S'assurer que GlobalStateManager est bien initialisé
      final globalState = GlobalStateManager.instance;
      await globalState.initialize();

      // Attendre un court instant pour s'assurer que les données sont bien chargées
      await Future.delayed(const Duration(milliseconds: 500));

      // Mettre à jour les données du widget
      await updateWidgetData();

      if (kDebugMode) {
        debugPrint('✅ Widget forcé à se mettre à jour avec les vraies données');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la mise à jour forcée du widget: $e');
      }
    }
  }

  /// Effacer les données du widget (logout)
  static Future<void> clearWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('widget_meal_data');

      if (Platform.isIOS) {
        try {
          await _widgetChannel.invokeMethod('remove', {
            'key': 'widget_meal_data',
          });
          await _widgetChannel.invokeMethod('reloadWidgetTimelines');
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Impossible d\'effacer les données App Group: $e');
          }
        }
      }

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
