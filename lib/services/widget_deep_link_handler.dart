import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../screens/ai_chat_input_screen.dart';
import '../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../components/ui/nutrition_widgets.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';

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
  static Future<void> handleDeepLink(Uri uri) async {
    if (kDebugMode) {
      debugPrint('🔗 Deep link reçu: ${uri.toString()}');
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
    final targetMeal = meals.cast<dynamic>().firstWhere(
          (m) => m.name.toLowerCase() == mealName.toLowerCase(),
          orElse: () => null,
        );

    final mealId = targetMeal?.id;

    // Ouvrir directement selon le mode
    switch (mode) {
      case 'manual':
        ManualFoodSearchBottomSheet.show(
          context,
          mealName: mealName,
          mealId: mealId,
          onFoodCreated: (foodItem) {
            // L'ajout est géré par le bottom sheet lui-même
            if (kDebugMode) {
              debugPrint('✅ Food created from widget: ${foodItem.name}');
            }
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
            builder: (_) => const BarcodeScannerScreen(),
          ),
        );
        break;
      case 'recipe':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SelectRecipeScreen(),
          ),
        );
        break;
      case 'chat':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIChatInputScreen(
              mealName: mealName,
              mealId: mealId,
            ),
          ),
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

    final mealName = _getMealName(mealType);
    final user = AuthService().currentUser;

    if (user == null) {
      debugPrint('❌ Utilisateur non connecté');
      return;
    }

    // Récupérer les repas existants
    final meals = await FoodEntriesService.getFoodEntriesForDate(
      user.id,
      DateTime.now(),
    );
    final targetMeal = meals.cast<dynamic>().firstWhere(
          (m) => m.name.toLowerCase() == mealName.toLowerCase(),
          orElse: () => null,
        );

    if (targetMeal != null) {
      // Repas existe → afficher 5 options pour repas existant
      NutritionQuickActionsSection.showAddFoodOptionsForExistingMeal(
        context,
        targetMeal,
      );
    } else {
      // Nouveau repas → afficher 5 options pour nouveau repas
      NutritionQuickActionsSection.showAddFoodOptionsForNewMeal(
        context,
        mealType,
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

  /// Mapper le type de repas vers le nom français
  static String _getMealName(String mealType) {
    final mappings = {
      'petit-dejeuner': 'Petit-déjeuner',
      'dejeuner': 'Déjeuner',
      'diner': 'Dîner',
      'snack': 'Snack',
    };
    return mappings[mealType.toLowerCase()] ?? 'Repas';
  }
}
