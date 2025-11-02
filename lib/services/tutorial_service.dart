import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'translations.dart';
import '../components/ui/tutorial_welcome_screen.dart';

/// Service de gestion des tutoriels interactifs (Feature Discovery)
/// Utilise tutorial_coach_mark pour afficher des overlays explicatifs
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  // Mode debug - Force l'affichage du tutorial à chaque fois
  static const bool _debugMode = false; // Mode production : tutoriels une seule fois

  // Clés SharedPreferences pour sauvegarder l'état
  static const String _dashboardTutorialKey = 'tutorial_dashboard_completed';
  static const String _nutritionTutorialKey = 'tutorial_nutrition_completed';
  static const String _sportTutorialKey = 'tutorial_sport_completed';
  static const String _cardioTutorialKey = 'tutorial_cardio_completed';
  static const String _musculationTutorialKey = 'tutorial_musculation_completed';
  static const String _progressionTutorialKey = 'tutorial_progression_completed';

  TutorialCoachMark? _tutorialCoachMark;

  /// Vérifie si un tutorial a déjà été complété
  /// Vérifie d'abord dans Supabase (source de vérité), puis SharedPreferences en fallback
  Future<bool> _isTutorialCompleted(String key) async {
    if (_debugMode) return false; // En mode debug, toujours afficher

    final prefs = await SharedPreferences.getInstance();
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        // Vérifier dans Supabase (source de vérité)
        final response = await supabase
            .from('users')
            .select(key)
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 3));

        final isCompleted = response[key] as bool? ?? false;

        // Synchroniser avec SharedPreferences pour accès offline
        await prefs.setBool(key, isCompleted);

        return isCompleted;
      } catch (e) {
        debugPrint('⚠️ Erreur lecture tutorial depuis Supabase: $e');
        // Fallback vers SharedPreferences
        return prefs.getBool(key) ?? false;
      }
    }

    // Pas d'utilisateur connecté, utiliser SharedPreferences
    return prefs.getBool(key) ?? false;
  }

  /// Fonction pour obtenir la position d'un widget
  void _logWidgetPosition(GlobalKey key, String identify) {
    final context = key.currentContext;
    if (context == null) {
      debugPrint('🔴 [$identify] Context NULL!');
      return;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('🔴 [$identify] RenderBox NULL!');
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    debugPrint('📍 [$identify] Position: x=${position.dx.toStringAsFixed(1)}, y=${position.dy.toStringAsFixed(1)}, size: ${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}');
  }

  /// Marque un tutorial comme complété
  /// Sauvegarde dans Supabase ET SharedPreferences pour persister l'état
  Future<void> _markTutorialAsCompleted(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        // Sauvegarder dans Supabase pour persister entre les sessions
        await supabase.from('users').update({
          key: true,
        }).eq('id', user.id);

        debugPrint('✅ Tutorial marqué comme complété dans Supabase: $key');
      } catch (e) {
        debugPrint('❌ Erreur sauvegarde tutorial dans Supabase: $e');
        // Continue quand même, l'utilisateur a les SharedPreferences
      }
    }

    debugPrint('✅ Tutorial marqué comme complété localement: $key');
  }

  /// Réinitialise tous les tutoriels (utile pour debug)
  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dashboardTutorialKey);
    await prefs.remove(_nutritionTutorialKey);
    await prefs.remove(_sportTutorialKey);
    await prefs.remove(_cardioTutorialKey);
    await prefs.remove(_musculationTutorialKey);
    await prefs.remove(_progressionTutorialKey);
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
    double scrollAlignment = 0.3, // Alignment du scroll (0.3 par défaut = box plus haut)
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
                      onPressed: () async {
                        // Logger la position actuelle AVANT le scroll
                        debugPrint('📍 AVANT SCROLL pour: $identify');
                        _logWidgetPosition(keyTarget, identify);
                        if (nextTargetKey != null) {
                          _logWidgetPosition(nextTargetKey, 'Next target');
                        }

                        // Passer au prochain step immédiatement (fait disparaître l'overlay)
                        controller.next();

                        // 🎯 SCROLL vers le prochain target APRÈS que l'overlay soit disparu
                        if (nextTargetKey != null) {
                          // Attendre un TOUT PETIT délai pour que controller.next() soit enregistré
                          await Future.delayed(const Duration(milliseconds: 50));

                          // Vérifier que le widget est toujours monté avant d'utiliser context
                          if (context.mounted) {
                            // Scroller IMMÉDIATEMENT avant que le nouveau target apparaisse
                            await _ensureWidgetVisible(nextTargetKey, context, alignment: scrollAlignment);

                            // Logger la position APRÈS le scroll
                            debugPrint('📍 APRÈS SCROLL');
                            _logWidgetPosition(nextTargetKey, 'After scroll');
                          }
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
    required GlobalKey addWaterKey,
    required GlobalKey caloriesCardKey,
    required GlobalKey nutritionTabKey,
    required GlobalKey sportTabKey,
    required GlobalKey progressTabKey,
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

      // 3. Bouton Ajouter eau
      _createTarget(
        identify: 'add_water',
        keyTarget: addWaterKey,
        title: 'tutorial_dashboard_add_water_title'.tr(languageCode),
        description: 'tutorial_dashboard_add_water_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
      ),

      // 4. Carte des calories
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

      // 6. Onglet Progression
      _createTarget(
        identify: 'progress_tab',
        keyTarget: progressTabKey,
        title: 'tutorial_dashboard_progress_tab_title'.tr(languageCode),
        description: 'tutorial_dashboard_progress_tab_desc'.tr(languageCode),
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
  /// Version ROBUSTE qui positionne la box EN BAS de l'écran pour que le texte soit visible
  Future<void> _ensureWidgetVisible(GlobalKey key, BuildContext context, {double alignment = 0.3}) async {
    try {
      // Attendre que le prochain frame soit rendu (plus fiable que délais hardcodés)
      await Future.delayed(Duration.zero);

      // Vérifier que le context est toujours monté après le délai
      if (!context.mounted) {
        debugPrint('⚠️ Context démonté, annulation du scroll');
        return;
      }

      final widgetContext = key.currentContext;
      if (widgetContext == null) {
        debugPrint('⚠️ Context introuvable pour la key');
        return;
      }

      // Logger la position du scroll AVANT
      final scrollableState = Scrollable.maybeOf(widgetContext);
      if (scrollableState != null) {
        debugPrint('📐 Scroll position AVANT: ${scrollableState.position.pixels.toStringAsFixed(1)}');
      }

      // Utiliser Scrollable.ensureVisible avec un alignement EN BAS
      // 0.75 = positionne le haut du bloc à 75% du haut de l'écran
      // Résultat : la box est EN BAS avec le texte du tooltip VISIBLE AU-DESSUS
      // Cette méthode gère automatiquement :
      // - Les nested scrollables
      // - Les SliverAppBar qui se collapse
      // - Les calculs de position complexes
      await Scrollable.ensureVisible(
        widgetContext,
        duration: const Duration(milliseconds: 400), // Animation smooth
        curve: Curves.easeInOut,
        alignment: alignment, // Position configurable selon le widget
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );

      // Attendre la fin complète de l'animation + marge de sécurité
      await Future.delayed(const Duration(milliseconds: 450));

      // Logger la position du scroll APRÈS
      if (scrollableState != null) {
        debugPrint('📐 Scroll position APRÈS: ${scrollableState.position.pixels.toStringAsFixed(1)}, alignment: $alignment');
      }

      debugPrint('✅ Widget scrollé avec succès');
    } catch (e) {
      debugPrint('⚠️ Erreur lors du scroll automatique: $e');
    }
  }

  /// Tutorial du Dashboard Nutrition (SANS les onglets, déjà expliqués avant)
  /// Montre uniquement les 4 éléments clés du dashboard
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
      // 1. Carte des calories → scroll vers Macros
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

    debugPrint('🚀 === DÉBUT TUTORIAL SPORT DASHBOARD ===');
    debugPrint('📍 État initial des widgets:');
    _logWidgetPosition(dashboardTabKey, 'Dashboard Tab');
    _logWidgetPosition(cardioTabKey, 'Cardio Tab');
    _logWidgetPosition(musculationTabKey, 'Musculation Tab');
    _logWidgetPosition(caloriesKey, 'Calories Card');
    _logWidgetPosition(sessionsKey, 'Sessions Card');
    _logWidgetPosition(splitKey, 'Split Card');
    _logWidgetPosition(quickActionsKey, 'Quick Actions');

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
        scrollAlignment: 0.1, // Onglets en haut
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
        scrollAlignment: 0.1, // Onglets en haut
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
        scrollAlignment: 0.3, // Carte Calories en haut
      ),

      // 4. Carte des calories → PAS de scroll, Progression déjà visible
      _createTarget(
        identify: 'sport_calories_card',
        keyTarget: caloriesKey,
        title: 'tutorial_sport_calories_title'.tr(languageCode),
        description: 'tutorial_sport_calories_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: sportAvatarPath,
        nextTargetKey: null, // Pas de scroll, Progression déjà visible
      ),

      // 5. Carte des séances (Progression) → scroll vers Split
      _createTarget(
        identify: 'sport_sessions_card',
        keyTarget: sessionsKey,
        title: 'tutorial_sport_sessions_title'.tr(languageCode),
        description: 'tutorial_sport_sessions_desc'.tr(languageCode),
        align: ContentAlign.top, // Texte au-dessus
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: sportAvatarPath,
        nextTargetKey: splitKey,
        scrollAlignment: 0.6, // Carte Split plus bas pour être bien visible
      ),

      // 6. Activités du jour → scroll vers Actions rapides
      _createTarget(
        identify: 'sport_split_card',
        keyTarget: splitKey,
        title: 'tutorial_sport_split_title'.tr(languageCode),
        description: 'tutorial_sport_split_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        avatarPath: sportAvatarPath,
        nextTargetKey: quickActionsKey,
        scrollAlignment: 0.7, // Actions mieux ajusté après scroll
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
    // Vérifier si le tutoriel a déjà été complété
    final isCompleted = await _isTutorialCompleted(_cardioTutorialKey);
    if (isCompleted) {
      debugPrint('⏭️ Tutorial Cardio déjà complété, ignoré');
      return;
    }
    final List<TargetFocus> targets = [
      // 1. Statistiques de la semaine → scroll vers Activités
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
        scrollAlignment: 0.8, // Positionne le bas de la boîte au-dessus de la navigation
      ),

      // 2. Choisir une activité → scroll vers Dernière séance
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
        scrollAlignment: 0.8, // Positionne le bas de la boîte au-dessus de la navigation
      ),

      // 3. Dernière séance → scroll vers Séances de la semaine
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
        scrollAlignment: 0.8, // Positionne le bas de la boîte au-dessus de la navigation
      ),

      // 4. Séances de la semaine → scroll vers Accès historique
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
        scrollAlignment: 0.8, // Positionne le bas de la boîte au-dessus de la navigation
      ),

      // 5. Accès à l'historique → dernière cible
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
        _markTutorialAsCompleted(_cardioTutorialKey);
        debugPrint('⏭️ Tutorial Cardio sauté');
        return true;
      },
      onFinish: () {
        _markTutorialAsCompleted(_cardioTutorialKey);
        debugPrint('✅ Tutorial Cardio terminé');
      },
    );

    if (context.mounted) {
      _tutorialCoachMark?.show(context: context);
    }
  }

  /// Tutorial pour la page Musculation
  Future<void> showMusculationTutorial({
    required BuildContext context,
    required GlobalKey weeklyStatsKey,
    required GlobalKey sessionTypesBlockKey,
    required GlobalKey manualButtonKey,
    required GlobalKey guidedButtonKey,
    required GlobalKey coachRyzeButtonKey,
    required GlobalKey weekHistoryKey,
    required GlobalKey viewJournalKey,
    required GlobalKey progressKey,
    String languageCode = 'fr',
  }) async {
    // Vérifier si le tutoriel a déjà été complété
    final isCompleted = await _isTutorialCompleted(_musculationTutorialKey);
    if (isCompleted) {
      debugPrint('⏭️ Tutorial Musculation déjà complété, ignoré');
      return;
    }
    const workoutAvatarPath = 'assets/images/coach_ryze_workout_avatar.png';

    final targets = <TargetFocus>[
      // 1. Statistiques de la semaine → PAS de scroll (les 3 boutons sont déjà visibles)
      _createTarget(
        identify: 'musculation_weekly_stats',
        keyTarget: weeklyStatsKey,
        title: 'tutorial_musculation_stats_title'.tr(languageCode),
        description: 'tutorial_musculation_stats_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: workoutAvatarPath,
        nextTargetKey: null, // Pas de scroll, les boutons sont déjà visibles
      ),

      // 2. Bouton séance manuelle → PAS de scroll (déjà visible)
      _createTarget(
        identify: 'musculation_manual_button',
        keyTarget: manualButtonKey,
        title: 'tutorial_musculation_manual_title'.tr(languageCode),
        description: 'tutorial_musculation_manual_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: workoutAvatarPath,
        nextTargetKey: null,
      ),

      // 3. Bouton séance guidée → PAS de scroll (déjà visible)
      _createTarget(
        identify: 'musculation_guided_button',
        keyTarget: guidedButtonKey,
        title: 'tutorial_musculation_guided_title'.tr(languageCode),
        description: 'tutorial_musculation_guided_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: workoutAvatarPath,
        nextTargetKey: null,
      ),

      // 4. Bouton Coach Ryze → scroll UNE SEULE FOIS vers le bas pour montrer Historique, Journal et Progression
      _createTarget(
        identify: 'musculation_coach_button',
        keyTarget: coachRyzeButtonKey,
        title: 'tutorial_musculation_coach_title'.tr(languageCode),
        description: 'tutorial_musculation_coach_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        avatarPath: workoutAvatarPath,
        nextTargetKey: progressKey, // Scroll directement vers Progression (le plus bas)
        scrollAlignment: 0.8, // Positionne Progression plus bas pour que Historique soit bien visible en haut
      ),

      // 5. Historique de la semaine → PAS de scroll (déjà visible)
      _createTarget(
        identify: 'musculation_week_history',
        keyTarget: weekHistoryKey,
        title: 'tutorial_musculation_history_title'.tr(languageCode),
        description: 'tutorial_musculation_history_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: workoutAvatarPath,
        nextTargetKey: null, // Pas de scroll
      ),

      // 6. Bouton "Voir tout mon journal" → PAS de scroll (déjà visible)
      _createTarget(
        identify: 'musculation_view_journal',
        keyTarget: viewJournalKey,
        title: 'tutorial_musculation_journal_title'.tr(languageCode),
        description: 'tutorial_musculation_journal_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        avatarPath: workoutAvatarPath,
        nextTargetKey: null, // Pas de scroll
      ),

      // 7. Progression par exercice → dernier step, PAS de scroll
      _createTarget(
        identify: 'musculation_progress',
        keyTarget: progressKey,
        title: 'tutorial_musculation_progress_title'.tr(languageCode),
        description: 'tutorial_musculation_progress_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: workoutAvatarPath,
        nextTargetKey: null, // Dernier target
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
        _markTutorialAsCompleted(_musculationTutorialKey);
        debugPrint('⏭️ Tutorial Musculation sauté');
        return true;
      },
      onFinish: () {
        _markTutorialAsCompleted(_musculationTutorialKey);
        debugPrint('✅ Tutorial Musculation terminé');
      },
    );

    if (context.mounted) {
      _tutorialCoachMark?.show(context: context);
    }
  }

  /// Tutorial pour la page Progression Globale
  Future<void> showGlobalProgressTutorial({
    required BuildContext context,
    required GlobalKey settingsIconKey,
    required GlobalKey weightSectionKey,
    required GlobalKey balanceSectionKey,
    required GlobalKey trackingSectionKey,
    required String languageCode,
  }) async {
    // Vérifier si le tutoriel a déjà été complété
    final isCompleted = await _isTutorialCompleted(_progressionTutorialKey);
    if (isCompleted) {
      debugPrint('⏭️ Tutorial Progression déjà complété, ignoré');
      return;
    }
    const progressAvatarPath = 'assets/images/coach_ryze_avatar.png';

    final List<TargetFocus> targets = [
      // 1. Icône Settings → pas de scroll (en haut de la page)
      _createTarget(
        identify: 'progress_settings_icon',
        keyTarget: settingsIconKey,
        title: 'tutorial_global_progress_settings_title'.tr(languageCode),
        description: 'tutorial_global_progress_settings_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
        avatarPath: progressAvatarPath,
        nextTargetKey: weightSectionKey,
        scrollAlignment: 0.1,
      ),

      // 2. Section Poids → pas de scroll (en haut de la page)
      _createTarget(
        identify: 'progress_weight_section',
        keyTarget: weightSectionKey,
        title: 'tutorial_global_progress_weight_title'.tr(languageCode),
        description: 'tutorial_global_progress_weight_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: progressAvatarPath,
        nextTargetKey: balanceSectionKey,
        scrollAlignment: 0.3,
      ),

      // 3. Section Bilan hebdomadaire → scroll vers le bas
      _createTarget(
        identify: 'progress_balance_section',
        keyTarget: balanceSectionKey,
        title: 'tutorial_global_progress_balance_title'.tr(languageCode),
        description: 'tutorial_global_progress_balance_desc'.tr(languageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: progressAvatarPath,
        nextTargetKey: trackingSectionKey,
        scrollAlignment: 0.8,
      ),

      // 4. Section Tracking → dernière cible
      _createTarget(
        identify: 'progress_tracking_section',
        keyTarget: trackingSectionKey,
        title: 'tutorial_global_progress_tracking_title'.tr(languageCode),
        description: 'tutorial_global_progress_tracking_desc'.tr(languageCode),
        align: ContentAlign.top,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        avatarPath: progressAvatarPath,
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
        _markTutorialAsCompleted(_progressionTutorialKey);
        debugPrint('⏭️ Tutorial Progression Globale skippé');
        return true;
      },
      onFinish: () {
        _markTutorialAsCompleted(_progressionTutorialKey);
        debugPrint('✅ Tutorial Progression Globale terminé');
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
