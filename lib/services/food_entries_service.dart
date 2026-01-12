import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nutrition_models.dart';
import '../models/ai_analysis_models.dart';
import 'dashboard_service.dart';
import 'localization_service.dart';
import 'translations.dart';
import 'global_state_manager.dart';
import 'meal_widget_data_provider.dart';
import 'notification_service.dart';
import 'weekly_planner_service.dart';
import '../models/weekly_planner_models.dart';

class FoodEntriesService {
  static final _supabase = Supabase.instance.client;

  // Mapping des noms de repas français, anglais et allemand vers les meal_types en base
  static const Map<String, String> _mealTypeMapping = {
    // Français
    'Petit-déjeuner': 'breakfast',
    'Déjeuner': 'lunch',
    'Collation': 'snack',
    'Dîner': 'dinner',
    'Goûter': 'snack',
    // English & Deutsch (Snack is same in both)
    'Breakfast': 'breakfast',
    'Lunch': 'lunch',
    'Snack': 'snack',
    'Dinner': 'dinner',
    // Deutsch
    'Frühstück': 'breakfast',
    'Mittagessen': 'lunch',
    'Abendessen': 'dinner',
    'Zwischenmahlzeit': 'snack',
  };

  // Mapping inverse pour l'affichage
  static const Map<String, String> _mealTypeDisplayMapping = {
    'breakfast': 'Petit-déjeuner',
    'lunch': 'Déjeuner',
    'snack': 'Collation', 
    'dinner': 'Dîner',
  };

  // Récupérer les entrées alimentaires pour une date donnée
  static Future<List<Meal>> getFoodEntriesForDate(String userId, DateTime date) async {
    try {
      // Définir le début et la fin de la journée
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Requête pour récupérer les entrées du jour
      final response = await _supabase
          .from('food_entries')
          .select('''
            id,
            meal_id,
            quantity,
            unit,
            meal_type,
            consumed_at,
            created_at,
            calories,
            proteins,
            carbs,
            fats,
            custom_food_id,
            food_id,
            recipe_id,
            has_modified_macros,
            scanned_food_name,
            is_scanned,
            food_database:food_id (
              id,
              name_fr,
              name_en
            ),
            custom_foods:custom_food_id (
              id,
              name,
              origin,
              barcode
            ),
            recipes_database:recipe_id (
              id,
              name_fr,
              name_en
            )
          ''')
          .eq('user_id', userId)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lte('consumed_at', endOfDay.toIso8601String())
          .order('created_at');

      // Grouper par meal_id pour créer des blocs uniques
      final Map<String, Map<String, dynamic>> mealBlocks = {};
      
      for (final entry in response) {
        final mealId = entry['meal_id'] as String;
        final mealType = entry['meal_type'] as String;
        final displayName = _mealTypeDisplayMapping[mealType] ?? mealType;
        
        // Créer le bloc de repas s'il n'existe pas
        if (!mealBlocks.containsKey(mealId)) {
          mealBlocks[mealId] = {
            'meal_id': mealId,
            'meal_type': mealType,
            'display_name': displayName,
            'consumed_at': entry['consumed_at'],
            'created_at': entry['created_at'],
            'min_created_at': entry['created_at'], // Pour le tri par ordre de création
            'items': <FoodItem>[],
          };
        } else {
          // Mettre à jour le created_at minimum pour ce bloc de repas
          final currentMinCreatedAt = DateTime.parse(mealBlocks[mealId]!['min_created_at']);
          final entryCreatedAt = DateTime.parse(entry['created_at']);
          if (entryCreatedAt.isBefore(currentMinCreatedAt)) {
            mealBlocks[mealId]!['min_created_at'] = entry['created_at'];
          }
        }
        
        // Déterminer le nom de l'aliment
        String foodName;
        bool isCustom = false;
        bool isRecipe = false;
        bool isScanned = entry['is_scanned'] ?? false;
        
        if (entry['scanned_food_name'] != null && entry['scanned_food_name'].isNotEmpty) {
          // Aliment scanné non sauvegardé
          foodName = entry['scanned_food_name'];
          isCustom = false;
          isScanned = true;
        } else if (entry['recipes_database'] != null) {
          // Recette
          final recipe = entry['recipes_database'];
          final locService = LocalizationService.instance;
          foodName = locService.getTextFromColumns(recipe['name_fr'], recipe['name_en']).isEmpty 
              ? 'Recette' 
              : locService.getTextFromColumns(recipe['name_fr'], recipe['name_en']);
          isCustom = false;
          isRecipe = true;
          isScanned = false;
        } else if (entry['custom_foods'] != null) {
          final customFood = entry['custom_foods'];
          foodName = customFood['name'] ?? 'custom_food'.tr(LocalizationService.instance.currentLanguageCode);
          isCustom = true;
          isScanned = customFood['origin'] == 'barcode';
        } else if (entry['food_database'] != null) {
          final food = entry['food_database'];
          final locService = LocalizationService.instance;
          foodName = locService.getTextFromColumns(food['name_fr'], food['name_en']).isEmpty 
              ? 'Aliment' 
              : locService.getTextFromColumns(food['name_fr'], food['name_en']);
          isCustom = false;
          isScanned = false;
        } else {
          foodName = 'Aliment inconnu';
        }

        final foodItem = FoodItem(
          id: entry['id'], // ✅ CORRECTION: Utiliser l'ID de l'entrée pour pouvoir la supprimer
          name: foodName,
          calories: (entry['calories'] as num).round(),
          proteins: (entry['proteins'] as num).toDouble(),
          carbs: (entry['carbs'] as num).toDouble(),
          fats: (entry['fats'] as num).toDouble(),
          portion: '${entry['quantity']} ${entry['unit']}',
          isCustom: isCustom,
          isRecipe: isRecipe,
          isScanned: isScanned,
          hasModifiedMacros: entry['has_modified_macros'] ?? false,
        );

        mealBlocks[mealId]!['items'].add(foodItem);
      }

      // Convertir les blocs en objets Meal
      final meals = <Meal>[];
      
      // Horaires par défaut
      final Map<String, String> defaultTimes = {
        'breakfast': '8h00',
        'lunch': '12h30',
        'snack': '16h00',
        'dinner': '19h30',
      };
      
      // Trier les blocs par ordre de création (created_at minimum de chaque bloc)
      final sortedBlocks = mealBlocks.values.toList()
        ..sort((a, b) => DateTime.parse(a['min_created_at']).compareTo(DateTime.parse(b['min_created_at'])));
      
      for (final block in sortedBlocks) {
        final mealType = block['meal_type'] as String;
        final mealId = block['meal_id'] as String;
        
        // Le meal_id contient maintenant directement le nom avec incrémentation
        // Si le meal_id ne contient que le nom de base, l'utiliser tel quel
        // Sinon, utiliser le meal_id qui contient déjà l'incrémentation
        String mealName = mealId;
        
        meals.add(Meal(
          id: mealId,
          time: defaultTimes[mealType] ?? '00h00',
          name: mealName,
          items: List<FoodItem>.from(block['items']),
        ));
      }

      // NE PAS ajouter de repas vides car ils n'ont pas d'ID
      // Les repas vides sans ID causent des problèmes lors de l'ajout d'aliments
      // Laissons la liste vide si aucun aliment n'a été ajouté
      // Le widget créera un nouveau repas avec un ID correct au besoin

      return meals;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des entrées: $e');
      return getDefaultMeals(); // Fallback vers les données statiques
    }
  }

  // Pré-générer un meal_id pour un nouveau repas sans créer l'entrée
  static Future<String?> generateMealId({
    required String userId,
    required String mealName,
    DateTime? forDate,
  }) async {
    try {
      final mealType = _mealTypeMapping[mealName];
      if (mealType == null) {
        debugPrint('Type de repas non reconnu pour génération: $mealName');
        return null;
      }

      final targetDate = forDate ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
      
      // Compter les repas existants de ce type POUR LA JOURNÉE CIBLÉE
      final existingMealsResponse = await _supabase
          .from('food_entries')
          .select('meal_id')
          .eq('user_id', userId)
          .eq('meal_type', mealType)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lte('consumed_at', endOfDay.toIso8601String());
      
      // Obtenir les meal_ids uniques pour cette journée
      final uniqueMealIds = <String>{};
      for (final meal in existingMealsResponse) {
        final mealId = meal['meal_id'] as String?;
        if (mealId != null && mealId.isNotEmpty) {
          uniqueMealIds.add(mealId);
        }
      }
      
      // Déterminer le numéro d'incrémentation pour cette journée
      final mealCount = uniqueMealIds.length + 1;
      
      // Créer le meal_id avec incrémentation par jour
      String mealId;
      if (mealCount > 1) {
        mealId = '$mealName $mealCount';
      } else {
        mealId = mealName;
      }
      
      return mealId;
    } catch (e) {
      debugPrint('Erreur lors de la génération du meal_id: $e');
      return null;
    }
  }

  // Ajouter une entrée alimentaire
  static Future<bool> addFoodEntry({
    required String userId,
    required String mealName,
    required FoodItem foodItem,
    DateTime? consumedAt,
    String? mealId, // Optionnel : pour ajouter à un bloc existant
  }) async {
    // Déclarer les variables en dehors du try pour qu'elles soient accessibles dans le catch
    Map<String, dynamic>? macronutrients;

    try {
      final mealType = _mealTypeMapping[mealName];
      if (mealType == null) {
        debugPrint('Type de repas non reconnu: $mealName');
        return false;
      }

      // Extraire la quantité et l'unité depuis portion
      final portionParts = foodItem.portion.split(' ');
      final quantity = double.tryParse(portionParts.first) ?? 100.0;
      final unit = portionParts.length > 1 ? portionParts.sublist(1).join(' ') : 'g';

      // Utiliser les macronutriments tels que vus par l'utilisateur (après ajustements et modifications)
      macronutrients = await _getMacronutrientsFromUserView(foodItem, quantity);
      
      final now = consumedAt ?? DateTime.now();
      final entry = {
        'user_id': userId,
        'meal_type': mealType,
        'quantity': quantity,
        'unit': unit,
        'calories': macronutrients['calories'],
        'proteins': macronutrients['proteins'],
        'carbs': macronutrients['carbs'],
        'fats': macronutrients['fats'],
        'has_modified_macros': macronutrients['has_modified_macros'],
        'is_scanned': foodItem.isScanned,
        'consumed_at': now.toIso8601String(),
      };

      // Si mealId est fourni, utiliser le bloc existant ou pré-généré
      if (mealId != null) {
        entry['meal_id'] = mealId;
      } else {
        // Générer un nouveau meal_id (fallback si pas fourni)
        final generatedMealId = await generateMealId(
          userId: userId,
          mealName: mealName,
          forDate: now,
        );
        
        if (generatedMealId == null) {
          debugPrint('Impossible de générer un meal_id');
          return false;
        }
        
        entry['meal_id'] = generatedMealId;
      }

      // Ajouter food_id, custom_food_id, recipe_id ou scanned_food_name selon le type
      if (foodItem.isRecipe && foodItem.id != null) {
        // Si c'est une recette, utiliser recipe_id
        entry['recipe_id'] = foodItem.id!;
      } else if (foodItem.isCustom && foodItem.id != null) {
        // Si c'est un aliment personnalisé, utiliser custom_food_id
        final customFoodId = int.tryParse(foodItem.id!);
        if (customFoodId != null) {
          entry['custom_food_id'] = customFoodId;
        }
      } else if (foodItem.id != null && foodItem.id!.isNotEmpty && !foodItem.isScanned) {
        // Si c'est un aliment de base (pas scanné), utiliser food_id (UUID)
        entry['food_id'] = foodItem.id!;
      } else if (foodItem.isScanned && !foodItem.isCustom) {
        // Si c'est un aliment scanné non sauvegardé, utiliser scanned_food_name
        entry['scanned_food_name'] = foodItem.name;
      }

      // NOUVEAU: Mise à jour instantanée via GlobalStateManager
      GlobalStateManager.instance.updateCalories(macronutrients['calories'].toDouble());
      GlobalStateManager.instance.updateMacros(
        proteins: macronutrients['proteins'].toDouble(),
        carbs: macronutrients['carbs'].toDouble(),
        fats: macronutrients['fats'].toDouble(),
      );

      await _supabase.from('food_entries').insert(entry);

      // Recompter les repas uniques depuis la base pour avoir le bon nombre
      await GlobalStateManager.instance.refreshMealsCount();

      // Déclencher la mise à jour des calculs nutritionnels
      await _notifyNutritionUpdate(userId, now);

      // NOUVEAU: Mettre à jour les données du widget iOS
      await MealWidgetDataProvider.updateWidgetData();

      // Mettre à jour l'activité pour les notifications de réengagement
      unawaited(NotificationService().updateLastActivity());

      // WEEKLY PLANNER SYNC: Marquer le repas planifié comme complété
      try {
        final plannedMeal = await WeeklyPlannerService.findPlannedMealForDate(mealType!, now);
        if (plannedMeal != null) {
          await WeeklyPlannerService.updateActivityStatus(
            plannedMeal.id,
            PlannedStatus.completed,
          );
          debugPrint('✅ Weekly Planner: Meal $mealType marqué comme complété');
        }
      } catch (plannerError) {
        debugPrint('⚠️ Erreur sync Weekly Planner: $plannerError');
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'entrée: $e');

      // ROLLBACK GlobalState en cas d'erreur (seulement si macronutrients a été calculé)
      if (macronutrients != null) {
        GlobalStateManager.instance.updateCalories(-macronutrients['calories'].toDouble());
        GlobalStateManager.instance.updateMacros(
          proteins: -macronutrients['proteins'].toDouble(),
          carbs: -macronutrients['carbs'].toDouble(),
          fats: -macronutrients['fats'].toDouble(),
        );
        // Recompter les repas pour être sûr d'avoir la bonne valeur même après erreur
        await GlobalStateManager.instance.refreshMealsCount();
      }

      return false;
    }
  }

  // Utiliser les macronutriments tels que vus par l'utilisateur (après ajustements de quantité et modifications)
  static Future<Map<String, dynamic>> _getMacronutrientsFromUserView(FoodItem foodItem, double quantity) async {
    try {
      // 🎯 LOGIQUE CORRECTE : Utiliser directement les valeurs du FoodItem
      // Ces valeurs reflètent exactement ce que l'utilisateur voit à l'écran :
      // - Quantité ajustée par l'utilisateur
      // - Modifications manuelles éventuelles des macronutriments
      // - Calculs proportionnels effectués dans l'interface
      
      debugPrint('📊 Utilisation des macronutriments vus par l\'utilisateur pour: ${foodItem.name}');
      debugPrint('   📏 Quantité: ${quantity}g');
      debugPrint('   🔥 Calories affichées: ${foodItem.calories}kcal');
      debugPrint('   🥩 Protéines affichées: ${foodItem.proteins}g');
      debugPrint('   🍞 Glucides affichés: ${foodItem.carbs}g');
      debugPrint('   🥑 Lipides affichés: ${foodItem.fats}g');
      debugPrint('   ✏️ Modifiés manuellement: ${foodItem.hasModifiedMacros}');

      return {
        'calories': foodItem.calories,
        'proteins': foodItem.proteins,
        'carbs': foodItem.carbs,
        'fats': foodItem.fats,
        'has_modified_macros': foodItem.hasModifiedMacros,
      };
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des macronutriments vus par l\'utilisateur: $e');
      // En cas d'erreur, utiliser les valeurs du foodItem (fallback)
      return {
        'calories': foodItem.calories,
        'proteins': foodItem.proteins,
        'carbs': foodItem.carbs,
        'fats': foodItem.fats,
        'has_modified_macros': foodItem.hasModifiedMacros,
      };
    }
  }

  // Créer un nouveau bloc de repas et y ajouter un aliment
  static Future<String?> createNewMeal({
    required String userId,
    required String mealName,
    required FoodItem foodItem,
    DateTime? consumedAt,
  }) async {
    try {
      // Ajouter l'aliment sans spécifier de meal_id pour créer un nouveau bloc
      final success = await addFoodEntry(
        userId: userId,
        mealName: mealName,
        foodItem: foodItem,
        consumedAt: consumedAt,
        // Ne pas spécifier mealId pour créer un nouveau bloc
      );
      
      if (success) {
        // Récupérer le meal_id qui vient d'être créé
        final mealType = _mealTypeMapping[mealName];
        if (mealType == null) {
          debugPrint('Type de repas non reconnu lors de la récupération: $mealName');
          return null;
        }
        
        final now = consumedAt ?? DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        
        // Récupérer le dernier meal_id créé pour ce type de repas
        final response = await _supabase
            .from('food_entries')
            .select('meal_id')
            .eq('user_id', userId)
            .eq('meal_type', mealType)
            .gte('consumed_at', startOfDay.toIso8601String())
            .lte('consumed_at', endOfDay.toIso8601String())
            .order('consumed_at', ascending: false)
            .limit(1)
            .single();
        
        return response['meal_id'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la création du nouveau repas: $e');
      return null;
    }
  }

  /// Vérifie rapidement si un repas existe pour aujourd'hui
  /// Retourne true s'il y a des calories > 0 pour ce type de repas
  static Future<bool> checkMealExistsQuick(String userId, String mealType, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Requête TRÈS LÉGÈRE : juste vérifier si des entrées existent
      final response = await _supabase
          .from('food_entries')
          .select('calories')
          .eq('user_id', userId)
          .eq('meal_type', mealType)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lte('consumed_at', endOfDay.toIso8601String())
          .limit(1); // On veut juste savoir s'il existe au moins une entrée

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la vérification rapide du repas: $e');
      }
      return false;
    }
  }

  // Supprimer une entrée alimentaire
  static Future<bool> removeFoodEntry(String entryId) async {
    try {
      debugPrint('🗑️ Tentative de suppression de l\'entrée: $entryId');
      
      // Récupérer l'info de l'entrée avant suppression pour notification
      final entryInfo = await _supabase
          .from('food_entries')
          .select('user_id, consumed_at, meal_id')
          .eq('id', entryId)
          .maybeSingle();
      
      if (entryInfo == null) {
        debugPrint('❌ Entrée introuvable avec l\'ID: $entryId');
        return false;
      }
      
      debugPrint('📋 Entrée trouvée: ${entryInfo['meal_id']} pour utilisateur ${entryInfo['user_id']}');
      
      // Supprimer l'entrée
      final deleteResult = await _supabase
          .from('food_entries')
          .delete()
          .eq('id', entryId);
      
      debugPrint('✅ Entrée supprimée avec succès de la base de données');

      // Déclencher la mise à jour des calculs nutritionnels
      await _notifyNutritionUpdate(
        entryInfo['user_id'] as String,
        DateTime.parse(entryInfo['consumed_at'] as String),
      );

      debugPrint('🔔 Notification de mise à jour envoyée');

      // NOUVEAU: Mettre à jour les données du widget iOS
      await MealWidgetDataProvider.updateWidgetData();

      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  // Notifier la mise à jour nutritionnelle
  static Future<void> _notifyNutritionUpdate(String userId, DateTime date) async {
    try {
      // Mettre à jour les objectifs du dashboard en temps réel
      await DashboardService.invalidateAndRefreshGoals();
      
      // Notifier via le stream controller pour la mise à jour en temps réel
      _nutritionUpdateController.add({
        'user_id': userId,
        'date': date,
        'timestamp': DateTime.now(),
      });
      
      debugPrint('🔔 Notification de mise à jour nutritionnelle envoyée pour $userId');
    } catch (e) {
      debugPrint('❌ Erreur lors de la notification: $e');
    }
  }

  // Stream controller pour les mises à jour nutritionnelles
  static final _nutritionUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream public pour écouter les mises à jour
  static Stream<Map<String, dynamic>> get nutritionUpdates => _nutritionUpdateController.stream;

  // Données par défaut en cas d'erreur
  static List<Meal> getDefaultMeals() {
    final langCode = LocalizationService.instance.currentLanguageCode;
    return [
      Meal(
        time: '8h00',
        name: 'breakfast'.tr(langCode),
        items: [],
      ),
      Meal(
        time: '12h30',
        name: 'lunch'.tr(langCode),
        items: [],
      ),
      Meal(
        time: '16h00',
        name: 'snack'.tr(langCode),
        items: [],
      ),
      Meal(
        time: '19h30',
        name: 'dinner'.tr(langCode),
        items: [],
      ),
    ];
  }

  /// Créer un aliment personnalisé à partir des détections IA
  static Future<String?> createAICustomFood({
    required String userId,
    required String mealName,
    required List<DetectedFood> detectedFoods,
    required double totalCalories,
    required double totalProteins,
    required double totalCarbs,
    required double totalFats,
    required double totalWeight,
  }) async {
    try {
      debugPrint('🎯 Création custom_food avec données IA:');
      debugPrint('   - name: $mealName');
      debugPrint('   - totalWeight: ${totalWeight}g');
      debugPrint('   - totalCalories: $totalCalories');
      debugPrint('   - totalProteins: $totalProteins');
      debugPrint('   - totalCarbs: $totalCarbs');  
      debugPrint('   - totalFats: $totalFats');
      debugPrint('   - calories (pour 100g): ${((totalCalories / totalWeight) * 100).round()}');
      debugPrint('   - proteins (pour 100g): ${((totalProteins / totalWeight) * 100).round()}');
      debugPrint('   - carbs (pour 100g): ${((totalCarbs / totalWeight) * 100).round()}');
      debugPrint('   - fats (pour 100g): ${((totalFats / totalWeight) * 100).round()}');
      debugPrint('   - user_id: $userId');
      
      // Insérer dans custom_foods avec les bons noms de colonnes
      final response = await _supabase
          .from('custom_foods')
          .insert({
            'name': mealName,
            'calories': ((totalCalories / totalWeight) * 100).round(),
            'proteins': ((totalProteins / totalWeight) * 100).round(),
            'carbs': ((totalCarbs / totalWeight) * 100).round(),
            'fats': ((totalFats / totalWeight) * 100).round(),
            'user_id': userId,
            'origin': 'photo_ia',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint('✅ Custom food créé avec succès: ${response['id']}');
      return response['id'].toString();
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'aliment personnalisé IA: $e');
      return null;
    }
  }

  /// Ajouter un aliment personnalisé IA au journal
  static Future<bool> addAIFoodEntry({
    required String userId,
    required String mealName,
    required List<DetectedFood> detectedFoods,
    required String aiMealName,
    String? mealId, // meal_id optionnel pour ajouter à un repas existant
    DateTime? consumedAt,
  }) async {
    // Déclarer les variables hors du try pour le rollback en cas d'erreur
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    double totalWeight = 0;

    try {
      // Calculer les totaux

      for (final food in detectedFoods) {
        totalCalories += food.calories;
        totalProteins += food.nutrition.proteins;
        totalCarbs += food.nutrition.carbs;
        totalFats += food.nutrition.fats;
        totalWeight += food.estimatedQuantity;
      }

      // Créer l'aliment personnalisé
      final customFoodId = await createAICustomFood(
        userId: userId,
        mealName: aiMealName,
        detectedFoods: detectedFoods,
        totalCalories: totalCalories,
        totalProteins: totalProteins,
        totalCarbs: totalCarbs,
        totalFats: totalFats,
        totalWeight: totalWeight,
      );

      if (customFoodId == null) {
        return false;
      }

      // Ajouter l'entrée au journal
      // Extraire le type de base du nom (ex: "Breakfast 2" -> "Breakfast")
      String baseMealName = mealId ?? mealName;
      final regex = RegExp(r'^(.+?)\s+\d+$');
      final match = regex.firstMatch(baseMealName);
      if (match != null && match.group(1) != null) {
        baseMealName = match.group(1)!;
      }

      final mealType = _mealTypeMapping[baseMealName];
      if (mealType == null) {
        debugPrint('Type de repas non reconnu: $mealName (base: $baseMealName)');
        return false;
      }

      final targetDate = consumedAt ?? DateTime.now();

      // Utiliser le meal_id fourni OU en générer un nouveau
      String? finalMealId = mealId;
      if (finalMealId == null) {
        finalMealId = await generateMealId(
          userId: userId,
          mealName: mealName,
          forDate: targetDate,
        );

        if (finalMealId == null) {
          return false;
        }
      }

      // Déterminer l'unité selon le nombre d'aliments détectés
      // Si un seul aliment ET c'est un liquide → ml
      // Sinon (plusieurs aliments OU pas liquide) → g
      final unit = detectedFoods.length == 1 && detectedFoods.first.isLiquid
          ? 'ml'
          : 'g';

      debugPrint('🍽️ Création entrée food_entries:');
      debugPrint('   - user_id: $userId');
      debugPrint('   - meal_type: $mealType');
      debugPrint('   - meal_id: $finalMealId');
      debugPrint('   - custom_food_id: $customFoodId');
      debugPrint('   - quantity: $totalWeight');
      debugPrint('   - unit: $unit');
      debugPrint('   - calories: $totalCalories');
      debugPrint('   - proteins: $totalProteins');
      debugPrint('   - carbs: $totalCarbs');
      debugPrint('   - fats: $totalFats');

      // Insérer dans food_entries avec les bonnes colonnes
      // NOUVEAU: Mise à jour instantanée via GlobalStateManager
      GlobalStateManager.instance.updateCalories(totalCalories);
      GlobalStateManager.instance.updateMacros(
        proteins: totalProteins,
        carbs: totalCarbs,
        fats: totalFats,
      );

      await _supabase.from('food_entries').insert({
        'user_id': userId,
        'meal_type': mealType,
        'meal_id': finalMealId,
        'custom_food_id': int.parse(customFoodId),
        'quantity': totalWeight,
        'unit': unit,
        'calories': totalCalories.round(),
        'proteins': totalProteins,
        'carbs': totalCarbs,
        'fats': totalFats,
        'consumed_at': targetDate.toIso8601String(),
      });

      debugPrint('✅ Entrée food_entries créée avec succès');

      // Recompter les repas uniques depuis la base pour avoir le bon nombre
      await GlobalStateManager.instance.refreshMealsCount();

      // Notifier la mise à jour de la nutrition
      await _notifyNutritionUpdate(userId, targetDate);

      // NOUVEAU: Mettre à jour les données du widget iOS
      await MealWidgetDataProvider.updateWidgetData();

      // WEEKLY PLANNER SYNC: Marquer le repas planifié comme complété
      try {
        final plannedMeal = await WeeklyPlannerService.findPlannedMealForDate(mealType!, targetDate);
        if (plannedMeal != null) {
          await WeeklyPlannerService.updateActivityStatus(
            plannedMeal.id,
            PlannedStatus.completed,
          );
          debugPrint('✅ Weekly Planner: Meal $mealType marqué comme complété');
        }
      } catch (plannerError) {
        debugPrint('⚠️ Erreur sync Weekly Planner: $plannerError');
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'aliment IA: $e');

      // ROLLBACK GlobalState en cas d'erreur
      GlobalStateManager.instance.updateCalories(-totalCalories);
      GlobalStateManager.instance.updateMacros(
        proteins: -totalProteins,
        carbs: -totalCarbs,
        fats: -totalFats,
      );
      // Recompter les repas pour être sûr d'avoir la bonne valeur même après erreur
      await GlobalStateManager.instance.refreshMealsCount();

      return false;
    }
  }
} 