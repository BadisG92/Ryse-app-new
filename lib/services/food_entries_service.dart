import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nutrition_models.dart';
import 'dashboard_service.dart';

class FoodEntriesService {
  static final _supabase = Supabase.instance.client;

  // Mapping des noms de repas français vers les meal_types en base
  static const Map<String, String> _mealTypeMapping = {
    'Petit-déjeuner': 'breakfast',
    'Déjeuner': 'lunch', 
    'Collation': 'snack',
    'Dîner': 'dinner',
    'Goûter': 'snack',
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
            foods:food_id (
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
            recipes:recipe_id (
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
        } else if (entry['recipes'] != null) {
          // Recette
          final recipe = entry['recipes'];
          foodName = recipe['name_fr'] ?? recipe['name_en'] ?? 'Recette';
          isCustom = false;
          isRecipe = true;
          isScanned = false;
        } else if (entry['custom_foods'] != null) {
          final customFood = entry['custom_foods'];
          foodName = customFood['name'] ?? 'Aliment personnalisé';
          isCustom = true;
          isScanned = customFood['origin'] == 'barcode';
        } else if (entry['foods'] != null) {
          final food = entry['foods'];
          foodName = food['name_fr'] ?? food['name_en'] ?? 'Aliment';
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

      // Ajouter des repas vides si aucun aliment n'a été ajouté
      if (meals.isEmpty) {
        for (final mealType in ['Petit-déjeuner', 'Déjeuner', 'Collation', 'Dîner']) {
          meals.add(Meal(
            time: defaultTimes[_mealTypeMapping[mealType]] ?? '00h00',
            name: mealType,
            items: [],
          ));
        }
      }

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
      final macronutrients = await _getMacronutrientsFromUserView(foodItem, quantity);
      
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

      await _supabase.from('food_entries').insert(entry);
      
      // Déclencher la mise à jour des calculs nutritionnels
      await _notifyNutritionUpdate(userId, now);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'entrée: $e');
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
    return [
      Meal(
        time: '8h00',
        name: 'Petit-déjeuner',
        items: [],
      ),
      Meal(
        time: '12h30',
        name: 'Déjeuner',
        items: [],
      ),
      Meal(
        time: '16h00',
        name: 'Collation',
        items: [],
      ),
      Meal(
        time: '19h30',
        name: 'Dîner',
        items: [],
      ),
    ];
  }
} 