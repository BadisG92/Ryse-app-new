import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nutrition_models.dart';
import '../models/ai_analysis_models.dart';
import 'dashboard_service.dart';
import 'localization_service.dart';
import 'translations.dart';
import 'global_state_manager.dart';
import 'ryze_gain.dart';
import 'streak_service.dart';
import 'meal_widget_data_provider.dart';
import 'notification_service.dart';
import 'weekly_planner_service.dart';
import 'meal_planner_sync_service.dart';

class FoodEntriesService {
  static final _supabase = Supabase.instance.client;

  /// L'état global ne décrit que la journée en cours : une écriture qui porte
  /// sur un autre jour ne doit pas le toucher. Une seule définition, utilisée
  /// par l'ajout, la suppression et la correction de portion.
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

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
              name_en,
              name_de
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
              name_en,
              name_de
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
            'min_consumed_at': entry['consumed_at'], // L'heure réelle du repas
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
          final currentMinConsumed = DateTime.parse(mealBlocks[mealId]!['min_consumed_at']);
          final entryConsumed = DateTime.parse(entry['consumed_at']);
          if (entryConsumed.isBefore(currentMinConsumed)) {
            mealBlocks[mealId]!['min_consumed_at'] = entry['consumed_at'];
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
          foodName = locService.getTextFromColumns(recipe['name_fr'], recipe['name_en'], recipe['name_de']).isEmpty
              ? 'Recette'
              : locService.getTextFromColumns(recipe['name_fr'], recipe['name_en'], recipe['name_de']);
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
          foodName = locService.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']).isEmpty
              ? 'Aliment'
              : locService.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']);
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
        
        // L'heure affichée est celle du premier aliment du bloc, pas une
        // constante par type de repas : c'est la seule que l'utilisateur
        // reconnaît quand il relit sa journée.
        final at = DateTime.parse(block['min_consumed_at'] as String).toLocal();
        meals.add(Meal(
          id: mealId,
          time: '${at.hour} h ${at.minute.toString().padLeft(2, '0')}',
          name: mealName,
          mealType: mealType,
          items: List<FoodItem>.from(block['items']),
          at: at,
        ));
      }

      // NE PAS ajouter de repas vides car ils n'ont pas d'ID
      // Les repas vides sans ID causent des problèmes lors de l'ajout d'aliments
      // Laissons la liste vide si aucun aliment n'a été ajouté
      // Le widget créera un nouveau repas avec un ID correct au besoin

      return meals;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des entrées: $e');
      // Une lecture qui échoue ne doit pas inventer des repas : l'appelant
      // affiche son état vide, et le prochain rafraîchissement réessaie.
      return <Meal>[];
    }
  }

  /// Les calories de chaque jour d'une période, en une seule requête.
  ///
  /// La bande d'historique en a besoin pour trente jours d'un coup : trente
  /// appels séparés feraient trente allers-retours pour une rangée de barres.
  /// Clé : 'année-mois-jour'.
  static Future<Map<String, int>> getDailyCalories({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final start = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
      final rows = await _supabase
          .from('food_entries')
          .select('calories, consumed_at')
          .eq('user_id', userId)
          .gte('consumed_at', start.toIso8601String())
          .lt('consumed_at', end.toIso8601String());

      final out = <String, int>{};
      for (final row in rows) {
        final at = DateTime.tryParse(row['consumed_at'] as String? ?? '')?.toLocal();
        if (at == null) continue;
        final key = '${at.year}-${at.month}-${at.day}';
        out[key] = (out[key] ?? 0) + ((row['calories'] as num?)?.round() ?? 0);
      }
      return out;
    } catch (e) {
      debugPrint('❌ getDailyCalories: $e');
      return <String, int>{};
    }
  }

  /// L'entrée la plus récente d'un aliment donné, pour pouvoir annuler l'ajout
  /// qu'on vient de faire sans avoir à recharger la journée d'abord.
  static Future<String?> findLastEntryId({
    required String userId,
    required String name,
    required DateTime onDate,
  }) async {
    if (userId.isEmpty) return null;
    try {
      final start = DateTime(onDate.year, onDate.month, onDate.day);
      final end = start.add(const Duration(days: 1));
      final rows = await _supabase
          .from('food_entries')
          .select('''
            id,
            scanned_food_name,
            food_database:food_id ( name_fr, name_en, name_de ),
            custom_foods:custom_food_id ( name ),
            recipes_database:recipe_id ( name_fr, name_en, name_de )
          ''')
          .eq('user_id', userId)
          .gte('consumed_at', start.toIso8601String())
          .lt('consumed_at', end.toIso8601String())
          .order('created_at', ascending: false)
          .limit(40);

      final loc = LocalizationService.instance;
      final wanted = name.trim().toLowerCase();
      for (final row in rows) {
        final scanned = row['scanned_food_name'] as String?;
        final recipe = row['recipes_database'];
        final custom = row['custom_foods'];
        final food = row['food_database'];
        final rowName = scanned != null && scanned.isNotEmpty
            ? scanned
            : recipe != null
                ? loc.getTextFromColumns(recipe['name_fr'], recipe['name_en'], recipe['name_de'])
                : custom != null
                    ? (custom['name'] as String? ?? '')
                    : food != null
                        ? loc.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de'])
                        : '';
        if (rowName.trim().toLowerCase() == wanted) return row['id'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ findLastEntryId: $e');
      return null;
    }
  }

  /// Ce que l'utilisateur remet le plus souvent dans ce repas.
  ///
  /// Filtré par type de repas : on ne propose pas du poulet au petit-déjeuner.
  /// Un même aliment n'apparaît qu'une fois, dans la portion de sa dernière
  /// occurrence, et les plus fréquents passent devant. Si le repas n'a pas
  /// assez d'histoire, on complète avec les récents tous repas confondus
  /// plutôt que de montrer une rangée vide.
  static Future<List<FoodItem>> getRecentFoodsForMealType(
    String userId,
    String mealName, {
    int limit = 6,
    int days = 30,
  }) async {
    final mealType = _mealTypeMapping[mealName];
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final rows = await _supabase
          .from('food_entries')
          .select('''
            quantity,
            unit,
            meal_type,
            consumed_at,
            calories,
            proteins,
            carbs,
            fats,
            has_modified_macros,
            scanned_food_name,
            is_scanned,
            food_database:food_id ( name_fr, name_en, name_de ),
            custom_foods:custom_food_id ( name, origin ),
            recipes_database:recipe_id ( name_fr, name_en, name_de )
          ''')
          .eq('user_id', userId)
          .gte('consumed_at', since.toIso8601String())
          .order('consumed_at', ascending: false)
          .limit(300);

      final matching = <FoodItem>[];
      final others = <FoodItem>[];
      final seenMatching = <String>{};
      final seenOthers = <String>{};

      for (final row in rows) {
        final item = _recentItemFrom(row);
        if (item == null) continue;
        final key = item.name.toLowerCase();
        if (mealType != null && row['meal_type'] == mealType) {
          if (seenMatching.add(key)) matching.add(item);
        } else {
          if (seenOthers.add(key)) others.add(item);
        }
      }

      final out = <FoodItem>[...matching.take(limit)];
      for (final item in others) {
        if (out.length >= limit) break;
        if (seenMatching.contains(item.name.toLowerCase())) continue;
        out.add(item);
      }
      return out;
    } catch (e) {
      debugPrint('❌ getRecentFoodsForMealType: $e');
      return <FoodItem>[];
    }
  }

  /// Le nom d'une ligne de journal, résolu comme dans la lecture du jour.
  static FoodItem? _recentItemFrom(Map<String, dynamic> row) {
    final loc = LocalizationService.instance;
    String name;
    var isCustom = false;
    var isRecipe = false;
    var isScanned = row['is_scanned'] ?? false;

    final scanned = row['scanned_food_name'];
    if (scanned != null && (scanned as String).isNotEmpty) {
      name = scanned;
      isScanned = true;
    } else if (row['recipes_database'] != null) {
      final recipe = row['recipes_database'];
      name = loc.getTextFromColumns(recipe['name_fr'], recipe['name_en'], recipe['name_de']);
      isRecipe = true;
      isScanned = false;
    } else if (row['custom_foods'] != null) {
      final custom = row['custom_foods'];
      name = custom['name'] ?? '';
      isCustom = true;
      isScanned = custom['origin'] == 'barcode';
    } else if (row['food_database'] != null) {
      final food = row['food_database'];
      name = loc.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']);
      isScanned = false;
    } else {
      return null;
    }
    if (name.trim().isEmpty) return null;

    return FoodItem(
      name: name,
      calories: (row['calories'] as num?)?.round() ?? 0,
      proteins: (row['proteins'] as num?)?.toDouble() ?? 0,
      carbs: (row['carbs'] as num?)?.toDouble() ?? 0,
      fats: (row['fats'] as num?)?.toDouble() ?? 0,
      portion: '${row['quantity']} ${row['unit']}',
      isCustom: isCustom,
      isRecipe: isRecipe,
      isScanned: isScanned,
      hasModifiedMacros: row['has_modified_macros'] ?? false,
    );
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

  /// Trouver le premier meal_id existant pour un type de repas à une date donnée
  /// Retourne null si aucun bloc de ce type n'existe pour cette journée
  static Future<String?> findExistingMealId({
    required String userId,
    required String mealName,
    required DateTime forDate,
  }) async {
    try {
      final mealType = _mealTypeMapping[mealName];
      if (mealType == null) {
        debugPrint('Type de repas non reconnu: $mealName');
        return null;
      }

      final startOfDay = DateTime(forDate.year, forDate.month, forDate.day);
      final endOfDay = DateTime(forDate.year, forDate.month, forDate.day, 23, 59, 59);

      // Chercher le premier meal_id existant de ce type pour cette journée
      final existingEntry = await _supabase
          .from('food_entries')
          .select('meal_id')
          .eq('user_id', userId)
          .eq('meal_type', mealType)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lte('consumed_at', endOfDay.toIso8601String())
          .order('consumed_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (existingEntry != null) {
        final mealId = existingEntry['meal_id'] as String?;
        if (mealId != null && mealId.isNotEmpty) {
          debugPrint('✅ Bloc existant trouvé: $mealId pour $mealName');
          return mealId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de la recherche du meal_id existant: $e');
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
    bool skipPlannerSync = false, // Skip la sync vers le planner (utilisé par MealPlannerSyncService)
  }) async {
    // Déclarer les variables en dehors du try pour qu'elles soient accessibles dans le catch
    Map<String, dynamic>? macronutrients;
    // Vrai une fois l'état global effectivement modifié : c'est la seule
    // condition sous laquelle le rollback du catch a un sens.
    var touchedToday = false;

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
      } else {
        // Fallback: utiliser scanned_food_name pour les aliments scannés ou planifiés
        // Cela inclut les repas validés depuis le planificateur
        entry['scanned_food_name'] = foodItem.name;
      }

      // L'etat global est celui du jour : un repas oublie ajoute a une journee
      // passee depuis l'historique ne doit pas gonfler le compteur d'aujourd'hui.
      // La suppression et la correction de portion posaient deja cette garde ;
      // l'ajout, non.
      final touchesToday = _isToday(now);
      touchedToday = touchesToday;
      if (touchesToday) {
        // Ce qui vient d'être ajouté, gardé le temps que l'accueil le montre :
        // son grand chiffre roulait à chaque visite, de la même façon qu'on
        // vienne de noter un repas ou qu'on revienne des réglages.
        RyzeGain.add((macronutrients['calories'] as num).round());
        GlobalStateManager.instance.updateCalories(macronutrients['calories'].toDouble());
        GlobalStateManager.instance.updateMacros(
          proteins: macronutrients['proteins'].toDouble(),
          carbs: macronutrients['carbs'].toDouble(),
          fats: macronutrients['fats'].toDouble(),
        );
      }

      // Insérer et récupérer l'ID créé
      final insertResult = await _supabase
          .from('food_entries')
          .insert(entry)
          .select('id')
          .single();

      final foodEntryId = insertResult['id'] as String;

      // Recompter les repas uniques depuis la base pour avoir le bon nombre
      if (touchesToday) await GlobalStateManager.instance.refreshMealsCount();

      // Déclencher la mise à jour des calculs nutritionnels
      await _notifyNutritionUpdate(userId, now);

      // NOUVEAU: Mettre à jour les données du widget iOS
      await MealWidgetDataProvider.updateWidgetData();

      // Mettre à jour l'activité pour les notifications de réengagement
      unawaited(NotificationService().updateLastActivity());

      // Le premier repas note est le moment ou la permission de notifier a un
      // sens : il y a desormais quelque chose a rappeler. Elle ne part qu une
      // fois, et ne fait rien si elle a deja ete demandee.
      unawaited(NotificationService().requestAfterFirstEntry());

      // Annuler la notification de rappel pour ce type de repas
      // (évite de recevoir "N'oublie pas ton déjeuner" après l'avoir loggé)
      unawaited(NotificationService().cancelMealReminderForType(mealType));
      // Annuler les notifications "rien logué" et "streak protection"
      unawaited(NotificationService().cancelActivityBasedReminders());

      // WEEKLY PLANNER SYNC: Sync bidirectionnelle planner ↔ journal
      // Skip si appelé depuis MealPlannerSyncService.validateMeal pour éviter boucle infinie
      if (!skipPlannerSync) {
        try {
          // Chercher s'il existe un repas planifié pour ce créneau
          final plannedMeal = await WeeklyPlannerService.findPlannedMealForDate(mealType, now);
          if (plannedMeal != null) {
            // Marquer comme complété *et* lier au food_entry : c'est ce lien
            // qui permettra de rouvrir le créneau si l'aliment est retiré.
            await MealPlannerSyncService.markPlannedMealDone(plannedMeal.id, foodEntryId);
            debugPrint('✅ Weekly Planner: Meal $mealType marqué comme complété');
          } else {
            // Pas de repas planifié → créer une activité liée (sync journal → planner)
            await MealPlannerSyncService.syncFoodEntryToPlanner(
              foodEntryId: foodEntryId,
              mealType: mealType,
              consumedAt: now,
              foodName: foodItem.name,
              calories: macronutrients['calories'],
              proteins: macronutrients['proteins'],
              carbs: macronutrients['carbs'],
              fats: macronutrients['fats'],
              quantity: quantity,
            );
          }
        } catch (plannerError) {
          debugPrint('⚠️ Erreur sync Weekly Planner: $plannerError');
        }
      }

      // La série vit des journées où l'utilisateur note quelque chose : c'est
      // ici, pas à la lecture de la valeur, qu'elle avance.
      unawaited(StreakService.notifyActivity());

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'entrée: $e');

      // ROLLBACK GlobalState : uniquement si on l'avait effectivement touché,
      // c'est-à-dire pour une entrée du jour dont les macros étaient calculées.
      if (macronutrients != null && touchedToday) {
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
  /// Corrige la quantité d'une entrée déjà enregistrée.
  ///
  /// L'app savait ajouter et supprimer, mais pas rectifier : se tromper de
  /// portion obligeait à retirer l'aliment et à le ressaisir. Les calories et
  /// les macros sont recalculées au prorata de l'ancienne quantité, et l'écart
  /// est répercuté sur le total du jour comme le font l'ajout et le retrait.
  static Future<bool> updateFoodEntryQuantity(String entryId, double quantity) async {
    if (quantity <= 0) return false;
    try {
      final row = await _supabase
          .from('food_entries')
          .select('user_id, consumed_at, quantity, calories, proteins, carbs, fats')
          .eq('id', entryId)
          .maybeSingle();
      if (row == null) return false;

      final before = (row['quantity'] as num?)?.toDouble() ?? 0;
      if (before <= 0) return false;
      final ratio = quantity / before;
      if ((ratio - 1).abs() < 0.0001) return true;

      final calories = (row['calories'] as num?)?.toDouble() ?? 0;
      final proteins = (row['proteins'] as num?)?.toDouble() ?? 0;
      final carbs = (row['carbs'] as num?)?.toDouble() ?? 0;
      final fats = (row['fats'] as num?)?.toDouble() ?? 0;

      final after = {
        'quantity': quantity,
        'calories': (calories * ratio).round(),
        'proteins': proteins * ratio,
        'carbs': carbs * ratio,
        'fats': fats * ratio,
      };

      await _supabase.from('food_entries').update(after).eq('id', entryId);

      final consumedAt = DateTime.parse(row['consumed_at'] as String);
      if (_isToday(consumedAt)) {
        GlobalStateManager.instance.updateCalories((after['calories'] as int).toDouble() - calories);
        GlobalStateManager.instance.updateMacros(
          proteins: (after['proteins'] as double) - proteins,
          carbs: (after['carbs'] as double) - carbs,
          fats: (after['fats'] as double) - fats,
        );
      }

      await _notifyNutritionUpdate(row['user_id'] as String, consumedAt);
      await MealWidgetDataProvider.updateWidgetData();
      return true;
    } catch (e) {
      debugPrint('❌ updateFoodEntryQuantity: $e');
      return false;
    }
  }

  static Future<bool> removeFoodEntry(String entryId, {bool skipPlannerSync = false}) async {
    try {
      debugPrint('🗑️ Tentative de suppression de l\'entrée: $entryId');

      // Récupérer l'info de l'entrée avant suppression (incluant les macros pour GlobalState)
      final entryInfo = await _supabase
          .from('food_entries')
          .select('user_id, consumed_at, meal_id, calories, proteins, carbs, fats')
          .eq('id', entryId)
          .maybeSingle();

      if (entryInfo == null) {
        debugPrint('❌ Entrée introuvable avec l\'ID: $entryId');
        return false;
      }

      debugPrint('📋 Entrée trouvée: ${entryInfo['meal_id']} pour utilisateur ${entryInfo['user_id']}');

      // Récupérer les macros avant suppression pour mettre à jour GlobalState
      final calories = (entryInfo['calories'] as num?)?.toDouble() ?? 0;
      final proteins = (entryInfo['proteins'] as num?)?.toDouble() ?? 0;
      final carbs = (entryInfo['carbs'] as num?)?.toDouble() ?? 0;
      final fats = (entryInfo['fats'] as num?)?.toDouble() ?? 0;

      // Supprimer l'entrée
      await _supabase
          .from('food_entries')
          .delete()
          .eq('id', entryId);

      debugPrint('✅ Entrée supprimée avec succès de la base de données');

      // MISE À JOUR GLOBALSTATE: Soustraire les calories/macros de l'entrée supprimée
      // Vérifier si c'est aujourd'hui pour mettre à jour le GlobalState
      final consumedAt = DateTime.parse(entryInfo['consumed_at'] as String);

      if (_isToday(consumedAt) && calories > 0) {
        debugPrint('🔄 GlobalState: Soustraction de $calories kcal après suppression');
        GlobalStateManager.instance.updateCalories(-calories);
        GlobalStateManager.instance.updateMacros(
          proteins: -proteins,
          carbs: -carbs,
          fats: -fats,
        );
        // Décrémenter le compteur de repas
        await GlobalStateManager.instance.refreshMealsCount();
      }

      // Déclencher la mise à jour des calculs nutritionnels
      await _notifyNutritionUpdate(
        entryInfo['user_id'] as String,
        consumedAt,
      );

      debugPrint('🔔 Notification de mise à jour envoyée');

      // NOUVEAU: Mettre à jour les données du widget iOS
      await MealWidgetDataProvider.updateWidgetData();

      // WEEKLY PLANNER SYNC: Supprimer l'activité planifiée liée
      // Skip si appelé depuis unvalidateMeal (on veut garder l'activité planifiée)
      if (!skipPlannerSync) {
        try {
          await MealPlannerSyncService.onFoodEntryDeleted(entryId);
        } catch (plannerError) {
          debugPrint('⚠️ Erreur sync Weekly Planner (delete): $plannerError');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  // Notifier la mise à jour nutritionnelle
  static Future<void> _notifyNutritionUpdate(String userId, DateTime date) async {
    try {
      // Le rafraîchissement du dashboard était attendu : chaque aliment ajouté
      // payait un aller-retour réseau avant que l'écran ne reprenne la main,
      // pour un cache que plus aucun écran de l'app refondue ne lit.
      unawaited(DashboardService.invalidateAndRefreshGoals());
      
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
    var touchedToday = false;

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

      // Insérer dans food_entries avec les bonnes colonnes.
      // Comme pour l'ajout ordinaire, l'état global ne bouge que si l'entrée
      // tombe aujourd'hui : sinon un repas rattrapé sur un jour passé gonflait
      // le compteur du jour.
      touchedToday = _isToday(targetDate);
      if (touchedToday) {
        GlobalStateManager.instance.updateCalories(totalCalories);
        GlobalStateManager.instance.updateMacros(
          proteins: totalProteins,
          carbs: totalCarbs,
          fats: totalFats,
        );
      }

      final aiInsert = await _supabase.from('food_entries').insert({
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
      }).select('id').single();
      final aiFoodEntryId = aiInsert['id'] as String;

      debugPrint('✅ Entrée food_entries créée avec succès');

      // Recompter les repas uniques depuis la base pour avoir le bon nombre
      if (touchedToday) await GlobalStateManager.instance.refreshMealsCount();

      // Notifier la mise à jour de la nutrition
      await _notifyNutritionUpdate(userId, targetDate);

      // NOUVEAU: Mettre à jour les données du widget iOS
      await MealWidgetDataProvider.updateWidgetData();

      // WEEKLY PLANNER SYNC: Marquer le repas planifié comme complété
      try {
        final plannedMeal = await WeeklyPlannerService.findPlannedMealForDate(mealType, targetDate);
        if (plannedMeal != null) {
          await MealPlannerSyncService.markPlannedMealDone(plannedMeal.id, aiFoodEntryId);
          debugPrint('✅ Weekly Planner: Meal $mealType marqué comme complété');
        }
      } catch (plannerError) {
        debugPrint('⚠️ Erreur sync Weekly Planner: $plannerError');
      }

      // Mettre à jour l'activité pour les notifications de réengagement
      unawaited(NotificationService().updateLastActivity());

      // Annuler la notification de rappel pour ce type de repas
      // (évite de recevoir "N'oublie pas ton déjeuner" après l'avoir loggé)
      unawaited(NotificationService().cancelMealReminderForType(mealType));
      // Annuler les notifications "rien logué" et "streak protection"
      unawaited(NotificationService().cancelActivityBasedReminders());

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'aliment IA: $e');

      // ROLLBACK GlobalState : seulement s'il a effectivement été touché.
      if (touchedToday) {
        GlobalStateManager.instance.updateCalories(-totalCalories);
        GlobalStateManager.instance.updateMacros(
          proteins: -totalProteins,
          carbs: -totalCarbs,
          fats: -totalFats,
        );
        // Recompter les repas pour être sûr d'avoir la bonne valeur même après erreur
        await GlobalStateManager.instance.refreshMealsCount();
      }

      return false;
    }
  }
} 