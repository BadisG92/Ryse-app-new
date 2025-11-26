import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../screens/ai_chat_input_screen.dart';
import '../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../components/ui/nutrition_widgets.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';
import '../services/celebration_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/water_service.dart';
import '../models/nutrition_models.dart';
import 'meal_widget_data_provider.dart';

/// Handler pour les deep links depuis les widgets iOS
/// Gère la navigation depuis les widgets vers les bonnes fonctionnalités de l'app
class WidgetDeepLinkHandler {
  /// Clé globale pour la navigation
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Configure le handler avec la clé de navigation
  static void initialize(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    debugPrint('✅ WidgetDeepLinkHandler initialisé');
  }

  /// Handle deep links from widgets
  /// Format des URLs:
  /// - ryse://add-food?meal=dejeuner&mode=camera
  /// - ryse://add-food?meal=dejeuner
  /// - ryse://add-food?mode=camera
  /// - ryse://add-food
  /// - ryse://widget?action=prev-meal (navigation widget)
  /// - ryse://widget?action=next-meal (navigation widget)
  /// - ryse://dashboard (depuis le coach widget lock screen)
  static Future<void> handleDeepLink(Uri uri) async {
    if (kDebugMode) {
      debugPrint('🔗 Deep link reçu: ${uri.toString()}');
    }

    // Gérer les actions de navigation du widget
    if (uri.host == 'widget') {
      final action = uri.queryParameters['action'];
      if (action != null && (action == 'prev-meal' || action == 'next-meal')) {
        await _handleWidgetNavigation(action);
        return;
      }
    }

    // Gérer le deep link depuis le coach widget (lock screen)
    // Ouvre simplement l'app sur le dashboard principal
    if (uri.host == 'dashboard') {
      if (kDebugMode) {
        debugPrint('🏠 Deep link dashboard: ouverture de l\'app sur l\'écran principal');
      }
      // L'app s'ouvre naturellement sur le dashboard, rien de spécial à faire
      // Le widget sync sera déclenché automatiquement au lancement
      return;
    }

    // Gérer l'ajout d'eau
    if (uri.host == 'add-water') {
      await Future.delayed(const Duration(milliseconds: 300));
      final context = navigatorKey?.currentContext;
      if (context == null) {
        debugPrint('❌ Context non disponible pour le deep link');
        return;
      }
      await _openWaterFlow(context);
      return;
    }

    if (uri.host == 'add-food') {
      final mealType = uri.queryParameters['meal']; // 'dejeuner', 'petit-dejeuner', etc.
      final mode = uri.queryParameters['mode']; // 'manual', 'camera', 'barcode', etc.

      if (kDebugMode) {
        debugPrint('   - meal: $mealType');
        debugPrint('   - mode: $mode');
      }

      // Attendre que le context soit disponible
      await Future.delayed(const Duration(milliseconds: 300));

      final context = navigatorKey?.currentContext;
      if (context == null) {
        debugPrint('❌ Context non disponible pour le deep link');
        return;
      }

      // Différents flux selon les paramètres
      if (mealType != null && mode != null) {
        // Flux direct : repas + mode pré-sélectionnés
        await _openDirectFlow(context, mealType, mode);
      } else if (mealType != null) {
        // Afficher les 5 modes avec repas pré-sélectionné
        await _openQuickAddFlow(context, mealType);
      } else if (mode != null) {
        // Afficher sélection repas puis mode
        await _openMealSelectionThenMode(context, mode);
      } else {
        // Flux normal : sélection repas → mode
        await _openNormalFlow(context);
      }
    }
  }

  /// Flux direct : ouvre directement le mode avec le repas pré-sélectionné
  static Future<void> _openDirectFlow(
    BuildContext context,
    String mealType,
    String mode,
  ) async {
    if (kDebugMode) {
      debugPrint('🎯 Flux direct: $mealType → $mode');
    }

    final mealName = _getMealName(mealType);
    final user = AuthService().currentUser;

    if (user == null) {
      debugPrint('❌ Utilisateur non connecté');
      return;
    }

    // Récupérer les repas pour voir si le repas existe
    final meals = await FoodEntriesService.getFoodEntriesForDate(
      user.id,
      DateTime.now(),
    );

    // Chercher le repas existant
    dynamic targetMeal;
    try {
      targetMeal = meals.firstWhere(
        (m) => m.name.toLowerCase() == mealName.toLowerCase(),
      );
    } catch (e) {
      targetMeal = null; // Aucun repas trouvé
    }

    final mealId = targetMeal?.id;

    if (kDebugMode) {
      if (targetMeal != null) {
        debugPrint('✅ Repas existant trouvé: ${targetMeal.name} (ID: $mealId)');
      } else {
        debugPrint('🆕 Nouveau repas sera créé: $mealName');
      }
    }

    // Ouvrir directement selon le mode
    switch (mode) {
      case 'manual':
        ManualFoodSearchBottomSheet.show(
          context,
          mealName: mealName,
          mealId: mealId,
          onFoodCreated: (foodItem) async {
            // Ajouter l'aliment au repas
            await _addFoodToMeal(context, foodItem, mealName, mealId);
          },
        );
        break;
      case 'camera':
      case 'scanner':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIScannerScreen(
              isFromDashboard: mealId == null,
              mealName: mealName,
              mealId: mealId,
            ),
          ),
        );
        break;
      case 'barcode':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BarcodeScannerScreen(
              isFromDashboard: mealId == null,
              mealName: mealName,
              mealId: mealId,
            ),
          ),
        );
        break;
      case 'recipe':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectRecipeScreen(
              isFromDashboard: mealId == null,
              mealName: mealName,
              mealId: mealId,
            ),
          ),
        );
        break;
      case 'chat':
        AIChatInputScreen.showAsBottomSheet(
          context,
          isFromDashboard: mealId == null,
          mealName: mealName,
          mealId: mealId,
        );
        break;
      default:
        debugPrint('⚠️ Mode inconnu: $mode');
        await _openNormalFlow(context);
    }
  }

  /// Flux avec repas pré-sélectionné : afficher les 5 modes
  static Future<void> _openQuickAddFlow(
    BuildContext context,
    String mealType,
  ) async {
    if (kDebugMode) {
      debugPrint('🎯 Flux quick add: $mealType');
    }

    // Récupérer la langue actuelle de l'app
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final currentLanguage = locService.currentLanguageCode;

    // Obtenir le nom du repas dans la langue de l'app
    final mealName = _getMealNameForLanguage(mealType, currentLanguage);
    final user = AuthService().currentUser;

    if (user == null) {
      debugPrint('❌ Utilisateur non connecté');
      return;
    }

    // Mapper le type de repas français vers anglais pour la DB
    final mealTypeEnglish = _getMealTypeEnglish(mealType);

    // Lancer les deux requêtes EN PARALLÈLE pour optimiser le temps total
    // Pas de timeout car l'app peut être fermée et doit se connecter à Supabase
    final quickCheckFuture = FoodEntriesService.checkMealExistsQuick(
      user.id,
      mealTypeEnglish,
      DateTime.now(),
    );

    final detailsFuture = FoodEntriesService.getFoodEntriesForDate(
      user.id,
      DateTime.now(),
    );

    try {
      // Attendre la vérification rapide (généralement < 500ms même si app fermée)
      final mealExists = await quickCheckFuture;

      if (!mealExists) {
        if (kDebugMode) {
          debugPrint('🚀 Vérification: Aucun repas ${mealName}, création immédiate');
        }

        await NutritionQuickActionsSection.showAddFoodOptionsForNewMeal(
          context,
          mealName,
          mealTime: _getMealTimeString(mealType),
        );
        return;
      }

      // LE REPAS EXISTE - on doit attendre les détails pour avoir le bon meal_id
      if (kDebugMode) {
        debugPrint('⏳ Repas ${mealName} existe, récupération du meal_id...');
      }

      final meals = await detailsFuture;
      Meal? existingMeal;

      // Chercher le repas qui correspond au type
      // Le nom peut être "Collation", "Collation 2", etc.
      // On vérifie si le nom commence par le nom de base du repas
      for (final meal in meals) {
        if (meal.name.toLowerCase().startsWith(mealName.toLowerCase()) ||
            meal.name.toLowerCase().replaceAll(' ', '') == mealName.toLowerCase().replaceAll(' ', '')) {
          existingMeal = meal;
          break;
        }
      }

      if (kDebugMode) {
        if (existingMeal != null) {
          debugPrint('✅ Repas existant trouvé: ${existingMeal.name} (ID: ${existingMeal.id})');
        } else {
          debugPrint('⚠️ Aucun repas trouvé correspondant à "$mealName" parmi: ${meals.map((m) => m.name).join(', ')}');
        }
      }

      // Afficher le bottom sheet avec le bon repas
      NutritionQuickActionsSection.showAddFoodOptionsForExistingMeal(
        context,
        Meal(
          id: existingMeal?.id,
          name: mealName,
          time: existingMeal?.time ?? _getMealTimeString(mealType),
          items: existingMeal?.items ?? [],
        ),
      );

    } catch (e) {
      // En cas d'erreur, on affiche quand même le bottom sheet avec un nouveau repas
      if (kDebugMode) {
        debugPrint('⚠️ Erreur lors de la vérification: $e');
      }

      await NutritionQuickActionsSection.showAddFoodOptionsForNewMeal(
        context,
        mealName,
        mealTime: _getMealTimeString(mealType),
      );
    }

  }

  /// Flux avec mode pré-sélectionné : sélection repas puis mode
  static Future<void> _openMealSelectionThenMode(
    BuildContext context,
    String mode,
  ) async {
    if (kDebugMode) {
      debugPrint('🎯 Flux sélection repas puis mode: $mode');
    }

    // Pour l'instant, on ouvre le flux normal
    // TODO: Améliorer pour pré-sélectionner le mode après sélection repas
    await _openNormalFlow(context);
  }

  /// Flux normal : sélection repas → mode
  static Future<void> _openNormalFlow(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('🎯 Flux normal: sélection repas → mode');
    }

    // Utiliser le flux existant du dashboard
    NutritionQuickActionsSection.showMealSelectionForDashboard(context);
  }

  /// Obtenir le nom du repas selon la langue de l'app
  static String _getMealNameForLanguage(String mealType, String languageCode) {
    // Types de repas en base de données (anglais)
    final dbTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

    // D'abord, normaliser le type de repas vers la clé DB anglaise
    final mealTypeEnglish = _getMealTypeEnglish(mealType);

    // Ensuite, retourner le nom selon la langue
    if (languageCode == 'en') {
      // Noms anglais
      final englishNames = {
        'breakfast': 'Breakfast',
        'lunch': 'Lunch',
        'dinner': 'Dinner',
        'snack': 'Snack',
      };
      return englishNames[mealTypeEnglish] ?? 'Meal';
    } else {
      // Noms français (par défaut)
      final frenchNames = {
        'breakfast': 'Petit-déjeuner',
        'lunch': 'Déjeuner',
        'dinner': 'Dîner',
        'snack': 'Collation',
      };
      return frenchNames[mealTypeEnglish] ?? 'Repas';
    }
  }

  /// Mapper le type de repas vers le nom d'affichage (français ou anglais selon l'app)
  static String _getMealName(String mealType) {
    // D'abord essayer le mapping français
    final frenchMappings = {
      'petit-dejeuner': 'Petit-déjeuner',
      'dejeuner': 'Déjeuner',
      'diner': 'Dîner',
      'snack': 'Collation',
    };

    // Puis le mapping anglais
    final englishMappings = {
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'snack': 'Snack',
    };

    final lowerType = mealType.toLowerCase();

    // Essayer français d'abord (cas du widget iOS en français)
    if (frenchMappings.containsKey(lowerType)) {
      return frenchMappings[lowerType]!;
    }

    // Puis essayer anglais (cas du widget iOS en anglais)
    if (englishMappings.containsKey(lowerType)) {
      return englishMappings[lowerType]!;
    }

    // Fallback
    return 'Meal';
  }

  /// Mapper le type de repas (français ou anglais) vers anglais pour la DB
  static String _getMealTypeEnglish(String mealType) {
    // Mapping depuis le français
    final frenchToEnglish = {
      'petit-dejeuner': 'breakfast',
      'dejeuner': 'lunch',
      'diner': 'dinner',
      'snack': 'snack',  // snack est identique
      'collation': 'snack',
    };

    // Mapping depuis l'anglais (identité)
    final englishToEnglish = {
      'breakfast': 'breakfast',
      'lunch': 'lunch',
      'dinner': 'dinner',
      'snack': 'snack',
    };

    final lowerType = mealType.toLowerCase();

    // Essayer le mapping français
    if (frenchToEnglish.containsKey(lowerType)) {
      return frenchToEnglish[lowerType]!;
    }

    // Essayer le mapping anglais
    if (englishToEnglish.containsKey(lowerType)) {
      return englishToEnglish[lowerType]!;
    }

    return 'other';
  }

  /// Obtenir l'heure typique pour un type de repas
  static String _getMealTimeString(String mealType) {
    final timeMap = {
      'petit-dejeuner': '08:00',
      'dejeuner': '12:30',
      'diner': '19:30',
      'snack': '16:00',
    };
    return timeMap[mealType.toLowerCase()] ?? '12:00';
  }

  /// Ajouter un aliment au repas (existant ou nouveau)
  static Future<void> _addFoodToMeal(
    BuildContext context,
    dynamic foodItem,
    String mealName,
    String? mealId,
  ) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (context.mounted) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_user_not_connected'.tr(locService.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔄 Ajout de ${foodItem.name} au repas $mealName (ID: $mealId)');
      }

      // Si mealId existe, ajouter au repas existant
      // Sinon, créer un nouveau repas
      final success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: mealName,
        mealId: mealId,
        foodItem: foodItem,
        consumedAt: DateTime.now(),
      );

      if (success) {
        if (kDebugMode) {
          debugPrint('✅ Aliment ${foodItem.name} ajouté avec succès');
        }

        // Afficher la célébration
        CelebrationService().celebrateFoodEntryGlobal(
          foodName: foodItem.name,
          mealName: mealName,
        );

        // Afficher une notification de succès
        if (context.mounted) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('food_added_success'.tr(locService.currentLanguageCode).replaceAll('{foodName}', foodItem.name)),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Échec de l\'ajout à la base de données');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de l\'ajout de l\'aliment: $e');
      }
      if (context.mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_adding_food'.tr(locService.currentLanguageCode).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Gérer la navigation entre les repas dans le widget
  static Future<void> _handleWidgetNavigation(String action) async {
    try {
      if (Platform.isIOS) {
        const MethodChannel channel = MethodChannel('com.ryze.widget/data');
        
        // Récupérer l'index actuel
        final currentIndexString = await channel.invokeMethod<String>('getString', {
          'key': 'widget_selected_meal_index',
        });
        int currentIndex = int.tryParse(currentIndexString ?? '0') ?? 0;
        
        // Récupérer la liste des repas pour connaître le nombre total
        final widgetDataString = await channel.invokeMethod<String>('getString', {
          'key': 'widget_meal_data',
        });
        
        if (widgetDataString != null) {
          final widgetData = jsonDecode(widgetDataString) as Map<String, dynamic>;
          final allMeals = widgetData['allMeals'] as List? ?? [];
          final maxIndex = allMeals.length - 1;
          
          // Calculer le nouvel index
          int newIndex;
          if (action == 'prev-meal') {
            newIndex = currentIndex > 0 ? currentIndex - 1 : maxIndex;
          } else {
            newIndex = currentIndex < maxIndex ? currentIndex + 1 : 0;
          }
          
          // Sauvegarder le nouvel index
          await channel.invokeMethod('setString', {
            'key': 'widget_selected_meal_index',
            'value': newIndex.toString(),
          });
          
          // Recharger le widget
          await channel.invokeMethod('reloadWidgetTimelines');
          
          if (kDebugMode) {
            debugPrint('🔄 Navigation widget: $action (index: $currentIndex → $newIndex)');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur navigation widget: $e');
      }
    }
  }

  /// Ouvrir le bottom sheet d'ajout d'eau
  static Future<void> _openWaterFlow(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('💧 Ouverture du bottom sheet d\'ajout d\'eau');
    }

    NutritionBottomSheetHelper.showWaterSheet(
      context,
      (int milliliters) async {
        // Ajouter l'eau
        final success = await WaterService.addWaterEntry(
          amount: milliliters,
          sourceType: _getSourceTypeFromAmount(milliliters),
        );

        if (success) {
          if (kDebugMode) {
            debugPrint('✅ Eau ajoutée: ${milliliters}ml');
          }

          // Mettre à jour les données du widget
          await MealWidgetDataProvider.updateWidgetData();

          // Afficher une notification de succès
          if (context.mounted) {
            final locService = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('water_added_success'.tr(locService.currentLanguageCode).replaceAll('{amount}', milliliters.toString())),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (context.mounted) {
            final locService = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('water_add_error'.tr(locService.currentLanguageCode)),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }

  /// Déterminer le type de source selon la quantité
  static String _getSourceTypeFromAmount(int milliliters) {
    switch (milliliters) {
      case 250:
        return 'glass';
      case 500:
        return 'bottle';
      case 750:
        return 'sports_bottle';
      case 200:
        return 'cup';
      case 1000:
        return 'bottle';
      default:
        return 'manual';
    }
  }
}
