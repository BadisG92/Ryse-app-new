import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'translations.dart';
import '../components/ui/tutorial_welcome_screen.dart';

/// Service de gestion des tutoriels interactifs (Feature Discovery)
/// Utilise tutorial_coach_mark pour afficher des overlays explicatifs
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  // Mode debug - Force l'affichage du tutorial à chaque fois
  static const bool _debugMode = true; // ⚠️ Mettre à false en production

  // Clés SharedPreferences pour sauvegarder l'état
  static const String _dashboardTutorialKey = 'tutorial_dashboard_completed';
  static const String _nutritionTutorialKey = 'tutorial_nutrition_completed';
  static const String _sportTutorialKey = 'tutorial_sport_completed';

  TutorialCoachMark? _tutorialCoachMark;

  /// Vérifie si un tutorial a déjà été complété
  Future<bool> _isTutorialCompleted(String key) async {
    if (_debugMode) return false; // En mode debug, toujours afficher
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  /// Marque un tutorial comme complété
  Future<void> _markTutorialAsCompleted(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    debugPrint('✅ Tutorial marqué comme complété: $key');
  }

  /// Réinitialise tous les tutoriels (utile pour debug)
  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dashboardTutorialKey);
    await prefs.remove(_nutritionTutorialKey);
    await prefs.remove(_sportTutorialKey);
    debugPrint('🔄 Tous les tutoriels ont été réinitialisés');
  }

  /// Crée un target (élément à mettre en évidence) avec le style de l'app
  /// Le paramètre nextTargetKey permet de scroller vers le prochain target après clic sur "Compris"
  TargetFocus _createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
    ShapeLightFocus shape = ShapeLightFocus.Circle,
    double? radius,
    String? avatarPath, // Optionnel : chemin vers l'avatar à afficher
    GlobalKey? nextTargetKey, // Clé du prochain target pour scroll après clic
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      shape: shape,
      radius: radius,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bouton "Compris" en bas à droite
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Passer au prochain step immédiatement
                        controller.next();

                        // 🎯 SCROLL vers le prochain target APRÈS l'animation de transition
                        if (nextTargetKey != null) {
                          // Attendre que l'animation de transition soit terminée (~500ms)
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _ensureWidgetVisible(nextTargetKey, context);
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'understood'.tr('fr'), // Par défaut FR, sera dynamique
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Affiche le tutorial du Dashboard principal
  Future<void> showDashboardTutorial({
    required BuildContext context,
    required GlobalKey addFoodKey,
    required GlobalKey addExerciseKey,
    required GlobalKey caloriesCardKey,
    required GlobalKey nutritionTabKey,
    required GlobalKey sportTabKey,
    String languageCode = 'fr',
    String? pandaImagePath, // Optionnel : chemin vers l'image du panda
    String? userName, // Optionnel : prénom de l'utilisateur
  }) async {
    // Vérifier si déjà complété
    if (await _isTutorialCompleted(_dashboardTutorialKey)) {
      debugPrint('ℹ️ Tutorial Dashboard déjà complété');
      return;
    }

    // Attendre que le build soit terminé
    await Future.delayed(const Duration(milliseconds: 500));

    // 🌟 ÉTAPE 0 : Afficher l'écran de bienvenue Coach Ryze
    final shouldContinue = await _showWelcomeScreen(
      context: context,
      languageCode: languageCode,
      pandaImagePath: pandaImagePath,
      userName: userName,
    );

    // Si l'utilisateur a skippé, marquer comme complété et sortir
    if (!shouldContinue) {
      await _markTutorialAsCompleted(_dashboardTutorialKey);
      debugPrint('⏭️ Tutorial Dashboard skippé depuis le Welcome Screen');
      return;
    }

    // Petit délai avant de lancer le tutorial principal
    await Future.delayed(const Duration(milliseconds: 300));

    final targets = <TargetFocus>[
      // 1. Bouton Ajouter aliment
      _createTarget(
        identify: 'add_food',
        keyTarget: addFoodKey,
        title: 'tutorial_dashboard_add_food_title'.tr(languageCode),
        description: 'tutorial_dashboard_add_food_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),

      // 2. Bouton Ajouter exercice
      _createTarget(
        identify: 'add_exercise',
        keyTarget: addExerciseKey,
        title: 'tutorial_dashboard_add_exercise_title'.tr(languageCode),
        description: 'tutorial_dashboard_add_exercise_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),

      // 3. Carte des calories
      _createTarget(
        identify: 'calories_card',
        keyTarget: caloriesCardKey,
        title: 'tutorial_dashboard_calories_title'.tr(languageCode),
        description: 'tutorial_dashboard_calories_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 20,
      ),

      // 4. Onglet Nutrition
      _createTarget(
        identify: 'nutrition_tab',
        keyTarget: nutritionTabKey,
        title: 'tutorial_dashboard_nutrition_tab_title'.tr(languageCode),
        description: 'tutorial_dashboard_nutrition_tab_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.Circle,
      ),

      // 5. Onglet Sport
      _createTarget(
        identify: 'sport_tab',
        keyTarget: sportTabKey,
        title: 'tutorial_dashboard_sport_tab_title'.tr(languageCode),
        description: 'tutorial_dashboard_sport_tab_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.Circle,
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 8,
      opacityShadow: 0.8,
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: 'skip'.tr(languageCode),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      // 🎯 TRANSITIONS FLUIDES : Pas de reset entre les steps
      pulseEnable: false, // Désactiver le pulse pour plus de fluidité

      onFinish: () {
        _markTutorialAsCompleted(_dashboardTutorialKey);
        debugPrint('✅ Tutorial Dashboard terminé');
      },
      onSkip: () {
        _markTutorialAsCompleted(_dashboardTutorialKey);
        debugPrint('⏭️ Tutorial Dashboard skippé');
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  /// Affiche le tutorial de la page Nutrition
  Future<void> showNutritionTutorial({
    required BuildContext context,
    required GlobalKey dashboardTabKey,
    required GlobalKey journalTabKey,
    required GlobalKey recipesTabKey,
    String languageCode = 'fr',
  }) async {
    // Vérifier si déjà complété
    if (await _isTutorialCompleted(_nutritionTutorialKey)) {
      debugPrint('ℹ️ Tutorial Nutrition déjà complété');
      return;
    }

    // Attendre que le build soit terminé
    await Future.delayed(const Duration(milliseconds: 500));

    final targets = <TargetFocus>[
      // 1. Onglet Tableau de bord
      _createTarget(
        identify: 'dashboard_tab',
        keyTarget: dashboardTabKey,
        title: 'tutorial_nutrition_dashboard_tab_title'.tr(languageCode),
        description: 'tutorial_nutrition_dashboard_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),

      // 2. Onglet Journal
      _createTarget(
        identify: 'journal_tab',
        keyTarget: journalTabKey,
        title: 'tutorial_nutrition_journal_tab_title'.tr(languageCode),
        description: 'tutorial_nutrition_journal_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),

      // 3. Onglet Recettes
      _createTarget(
        identify: 'recipes_tab',
        keyTarget: recipesTabKey,
        title: 'tutorial_nutrition_recipes_tab_title'.tr(languageCode),
        description: 'tutorial_nutrition_recipes_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 8,
      opacityShadow: 0.8,
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: 'skip'.tr(languageCode),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      // 🎯 TRANSITIONS FLUIDES
      pulseEnable: false,

      onFinish: () {
        _markTutorialAsCompleted(_nutritionTutorialKey);
        debugPrint('✅ Tutorial Nutrition terminé');
      },
      onSkip: () {
        _markTutorialAsCompleted(_nutritionTutorialKey);
        debugPrint('⏭️ Tutorial Nutrition skippé');
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  /// Affiche le tutorial de la page Sport
  Future<void> showSportTutorial({
    required BuildContext context,
    required GlobalKey startWorkoutKey,
    required GlobalKey addCardioKey,
    required GlobalKey workoutHistoryKey,
    String languageCode = 'fr',
  }) async {
    // Vérifier si déjà complété
    if (await _isTutorialCompleted(_sportTutorialKey)) {
      debugPrint('ℹ️ Tutorial Sport déjà complété');
      return;
    }

    // Attendre que le build soit terminé
    await Future.delayed(const Duration(milliseconds: 500));

    final targets = <TargetFocus>[
      // 1. Démarrer workout
      _createTarget(
        identify: 'start_workout',
        keyTarget: startWorkoutKey,
        title: 'tutorial_sport_start_workout_title'.tr(languageCode),
        description: 'tutorial_sport_start_workout_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),

      // 2. Ajouter cardio
      _createTarget(
        identify: 'add_cardio',
        keyTarget: addCardioKey,
        title: 'tutorial_sport_add_cardio_title'.tr(languageCode),
        description: 'tutorial_sport_add_cardio_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),

      // 3. Historique
      _createTarget(
        identify: 'workout_history',
        keyTarget: workoutHistoryKey,
        title: 'tutorial_sport_history_title'.tr(languageCode),
        description: 'tutorial_sport_history_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 8,
      opacityShadow: 0.8,
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: 'skip'.tr(languageCode),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      // 🎯 TRANSITIONS FLUIDES
      pulseEnable: false,

      onFinish: () {
        _markTutorialAsCompleted(_sportTutorialKey);
        debugPrint('✅ Tutorial Sport terminé');
      },
      onSkip: () {
        _markTutorialAsCompleted(_sportTutorialKey);
        debugPrint('⏭️ Tutorial Sport skippé');
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  /// Ferme le tutorial en cours
  void closeTutorial() {
    _tutorialCoachMark?.finish();
  }

  /// Affiche l'écran de bienvenue Coach Ryze
  /// Retourne true si l'utilisateur veut continuer le tutorial, false s'il skip
  Future<bool> _showWelcomeScreen({
    required BuildContext context,
    required String languageCode,
    String? pandaImagePath,
    String? userName,
  }) async {
    bool shouldContinue = false;

    // Vérifier que le context est monté
    if (!context.mounted) {
      print('⚠️ Context not mounted, cannot show welcome screen');
      return false;
    }

    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return TutorialWelcomeScreen(
            languageCode: languageCode,
            pandaImagePath: pandaImagePath,
            userName: userName,
            onStart: () {
              Navigator.of(context).pop(true);
            },
            onSkip: () {
              Navigator.of(context).pop(false);
            },
          );
        },
      ),
    );

    shouldContinue = result ?? false;
    return shouldContinue;
  }

  /// Fonction utilitaire pour s'assurer qu'un widget est visible à l'écran
  /// en défilant automatiquement jusqu'à lui si nécessaire
  /// Position le HAUT du bloc dans une zone visible (15% du haut de l'écran)
  Future<void> _ensureWidgetVisible(GlobalKey key, BuildContext context) async {
    try {
      // Attendre que le widget soit bien rendu
      await Future.delayed(const Duration(milliseconds: 100));

      final widgetContext = key.currentContext;
      if (widgetContext == null) {
        debugPrint('⚠️ Context introuvable pour la key');
        return;
      }

      // Utiliser Scrollable.ensureVisible avec un alignement fixe
      // 0.15 = positionne le haut du bloc à 15% du haut de l'écran
      // Cela garantit que le titre est toujours visible, quelle que soit la taille du contenu
      await Scrollable.ensureVisible(
        widgetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.15, // Le haut du bloc apparaît à 15% du haut de l'écran
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );

      // Petit délai après le scroll pour que l'animation se termine
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('✅ Widget scrollé et visible (haut du bloc à 15%)');
    } catch (e) {
      debugPrint('⚠️ Erreur lors du scroll automatique: $e');
    }
  }

  /// Tutorial complet du Dashboard Nutrition avec onglets + 4 éléments clés
  Future<void> showNutritionDashboardTutorial({
    required BuildContext context,
    required GlobalKey caloriesKey,
    required GlobalKey macrosKey,
    required GlobalKey hydrationMealsKey,
    required GlobalKey quickActionsKey,
    required GlobalKey dashboardTabKey,
    required GlobalKey journalTabKey,
    required GlobalKey recipesTabKey,
    String languageCode = 'fr',
  }) async {
    // Pas de vérification de completion ici - géré par le widget parent

    const nutritionAvatarPath = 'assets/images/coach_ryze_nutrition_avatar.png';

    final targets = <TargetFocus>[
      // 1. Onglet Tableau de bord → scroll vers Journal
      _createTarget(
        identify: 'nutrition_dashboard_tab',
        keyTarget: dashboardTabKey,
        title: 'tutorial_nutrition_dashboard_tab_title'.tr(languageCode),
        description: 'tutorial_nutrition_dashboard_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: nutritionAvatarPath,
        nextTargetKey: journalTabKey,
      ),

      // 2. Onglet Journal → scroll vers Recettes
      _createTarget(
        identify: 'nutrition_journal_tab',
        keyTarget: journalTabKey,
        title: 'tutorial_nutrition_journal_tab_title'.tr(languageCode),
        description: 'tutorial_nutrition_journal_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: nutritionAvatarPath,
        nextTargetKey: recipesTabKey,
      ),

      // 3. Onglet Recettes → scroll vers Calories
      _createTarget(
        identify: 'nutrition_recipes_tab',
        keyTarget: recipesTabKey,
        title: 'tutorial_nutrition_recipes_tab_title'.tr(languageCode),
        description: 'tutorial_nutrition_recipes_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: nutritionAvatarPath,
        nextTargetKey: caloriesKey,
      ),

      // 4. Carte des calories → scroll vers Macros
      _createTarget(
        identify: 'nutrition_calories_card',
        keyTarget: caloriesKey,
        title: 'tutorial_nutrition_calories_title'.tr(languageCode),
        description: 'tutorial_nutrition_calories_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: nutritionAvatarPath,
        nextTargetKey: macrosKey,
      ),

      // 5. Carte des macronutriments → scroll vers Hydration/Repas
      _createTarget(
        identify: 'nutrition_macros_card',
        keyTarget: macrosKey,
        title: 'tutorial_nutrition_macros_title'.tr(languageCode),
        description: 'tutorial_nutrition_macros_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: nutritionAvatarPath,
        nextTargetKey: hydrationMealsKey,
      ),

      // 6. Section hydratation + repas → scroll vers Actions rapides
      _createTarget(
        identify: 'nutrition_hydration_meals',
        keyTarget: hydrationMealsKey,
        title: 'tutorial_nutrition_hydration_meals_title'.tr(languageCode),
        description: 'tutorial_nutrition_hydration_meals_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: nutritionAvatarPath,
        nextTargetKey: quickActionsKey,
      ),

      // 7. Boutons d'action rapide → dernier step, pas de scroll suivant
      _createTarget(
        identify: 'nutrition_quick_actions',
        keyTarget: quickActionsKey,
        title: 'tutorial_nutrition_quick_actions_title'.tr(languageCode),
        description: 'tutorial_nutrition_quick_actions_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: nutritionAvatarPath,
        nextTargetKey: null, // Dernier step, pas de scroll
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 10,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: 'skip'.tr(languageCode),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      onSkip: () {
        debugPrint('⏭️ Tutorial Dashboard Nutrition skippé');
        return true;
      },
      onFinish: () {
        debugPrint('✅ Tutorial Dashboard Nutrition terminé');
      },
    );

    if (context.mounted) {
      _tutorialCoachMark?.show(context: context);
    }
  }

  /// Tutorial complet du Dashboard Sport avec onglets + 4 éléments clés
  Future<void> showSportDashboardTutorial({
    required BuildContext context,
    required GlobalKey caloriesKey,
    required GlobalKey sessionsKey,
    required GlobalKey splitKey,
    required GlobalKey quickActionsKey,
    required GlobalKey dashboardTabKey,
    required GlobalKey cardioTabKey,
    required GlobalKey musculationTabKey,
    String languageCode = 'fr',
  }) async {
    // Pas de vérification de completion ici - géré par le widget parent

    const sportAvatarPath = 'assets/images/coach_ryze_workout_avatar.png';

    final targets = <TargetFocus>[
      // 1. Onglet Tableau de bord → scroll vers Cardio
      _createTarget(
        identify: 'sport_dashboard_tab',
        keyTarget: dashboardTabKey,
        title: 'tutorial_sport_dashboard_tab_title'.tr(languageCode),
        description: 'tutorial_sport_dashboard_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: sportAvatarPath,
        nextTargetKey: cardioTabKey,
      ),

      // 2. Onglet Cardio → scroll vers Musculation
      _createTarget(
        identify: 'sport_cardio_tab',
        keyTarget: cardioTabKey,
        title: 'tutorial_sport_cardio_tab_title'.tr(languageCode),
        description: 'tutorial_sport_cardio_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: sportAvatarPath,
        nextTargetKey: musculationTabKey,
      ),

      // 3. Onglet Musculation → scroll vers Calories
      _createTarget(
        identify: 'sport_musculation_tab',
        keyTarget: musculationTabKey,
        title: 'tutorial_sport_musculation_tab_title'.tr(languageCode),
        description: 'tutorial_sport_musculation_tab_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: sportAvatarPath,
        nextTargetKey: caloriesKey,
      ),

      // 4. Carte des calories → scroll vers Sessions
      _createTarget(
        identify: 'sport_calories_card',
        keyTarget: caloriesKey,
        title: 'tutorial_sport_calories_title'.tr(languageCode),
        description: 'tutorial_sport_calories_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: sportAvatarPath,
        nextTargetKey: sessionsKey,
      ),

      // 5. Carte des séances → scroll vers Split
      _createTarget(
        identify: 'sport_sessions_card',
        keyTarget: sessionsKey,
        title: 'tutorial_sport_sessions_title'.tr(languageCode),
        description: 'tutorial_sport_sessions_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: sportAvatarPath,
        nextTargetKey: splitKey,
      ),

      // 6. Activités du jour → scroll vers Actions rapides
      _createTarget(
        identify: 'sport_split_card',
        keyTarget: splitKey,
        title: 'tutorial_sport_split_title'.tr(languageCode),
        description: 'tutorial_sport_split_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        avatarPath: sportAvatarPath,
        nextTargetKey: quickActionsKey,
      ),

      // 7. Boutons d'action rapide → dernier step, pas de scroll suivant
      _createTarget(
        identify: 'sport_quick_actions',
        keyTarget: quickActionsKey,
        title: 'tutorial_sport_actions_title'.tr(languageCode),
        description: 'tutorial_sport_actions_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: sportAvatarPath,
        nextTargetKey: null, // Dernier step, pas de scroll
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 10,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: 'skip'.tr(languageCode),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      onSkip: () {
        debugPrint('⏭️ Tutorial Dashboard Sport skippé');
        return true;
      },
      onFinish: () {
        debugPrint('✅ Tutorial Dashboard Sport terminé');
      },
    );

    if (context.mounted) {
      _tutorialCoachMark?.show(context: context);
    }
  }

  /// Tutorial pour la page Cardio
  Future<void> showCardioTutorial({
    required BuildContext context,
    required GlobalKey weeklyStatsKey,
    required GlobalKey activitySelectionKey,
    required GlobalKey lastSessionKey,
    required GlobalKey weekSessionsKey,
    required GlobalKey historyAccessKey,
    required String languageCode,
  }) async {
    final List<TargetFocus> targets = [
      // 1. Statistiques de la semaine
      _createTarget(
        identify: 'cardio_weekly_stats',
        keyTarget: weeklyStatsKey,
        title: 'tutorial_cardio_stats_title'.tr(languageCode),
        description: 'tutorial_cardio_stats_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: 'assets/images/coach_ryze_workout_avatar.png',
        nextTargetKey: activitySelectionKey,
      ),

      // 2. Choisir une activité
      _createTarget(
        identify: 'cardio_activity_selection',
        keyTarget: activitySelectionKey,
        title: 'tutorial_cardio_activities_title'.tr(languageCode),
        description: 'tutorial_cardio_activities_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: 'assets/images/coach_ryze_workout_avatar.png',
        nextTargetKey: lastSessionKey,
      ),

      // 3. Dernière séance
      _createTarget(
        identify: 'cardio_last_session',
        keyTarget: lastSessionKey,
        title: 'tutorial_cardio_last_session_title'.tr(languageCode),
        description: 'tutorial_cardio_last_session_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: 'assets/images/coach_ryze_workout_avatar.png',
        nextTargetKey: weekSessionsKey,
      ),

      // 4. Séances de la semaine
      _createTarget(
        identify: 'cardio_week_sessions',
        keyTarget: weekSessionsKey,
        title: 'tutorial_cardio_week_sessions_title'.tr(languageCode),
        description: 'tutorial_cardio_week_sessions_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: 'assets/images/coach_ryze_workout_avatar.png',
        nextTargetKey: historyAccessKey,
      ),

      // 5. Accès à l'historique
      _createTarget(
        identify: 'cardio_history_access',
        keyTarget: historyAccessKey,
        title: 'tutorial_cardio_history_title'.tr(languageCode),
        description: 'tutorial_cardio_history_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: 'assets/images/coach_ryze_workout_avatar.png',
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 10,
      opacityShadow: 0.8,
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: 'skip'.tr(languageCode),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      onSkip: () {
        debugPrint('⏭️ Tutorial Cardio sauté');
        return true;
      },
      onFinish: () {
        debugPrint('✅ Tutorial Cardio terminé');
      },
    );

    if (context.mounted) {
      _tutorialCoachMark?.show(context: context);
    }
  }

  /// Dispose les ressources
  void dispose() {
    _tutorialCoachMark = null;
  }
}
