import 'package:flutter/material.dart';
import '../models/subscription_models.dart';
import '../screens/paywall_screen.dart';
import '../components/ui/coach_ryze_avatar.dart';
import 'subscription_service.dart';
import 'translations.dart';
import 'feature_trial_service.dart';

/// Contextes de paywall (pour analytics et personnalisation)
enum PaywallContext {
  // Contextes features Coach Ryze (principales)
  scanner,              // Scanner automatique (photo)
  barcodeScanner,       // Scanner de codes-barres
  chatInput,            // Déclarer repas au Coach Ryze (texte/voix)
  workoutGenerator,     // Coach Ryze - Générateur de workouts
  nutritionAnalysis,    // Bilan du Coach Ryze (quotidien)
  exerciseAnalysis,     // Analyse de progression par exercice
  planner,              // Planificateur hebdomadaire (repas + sport)

  // Contexte générique
  genericUpgrade,       // Upgrade générique (avatar sans tenue)
}

/// Service pour gérer l'affichage des paywalls
class PaywallService {
  static final PaywallService _instance = PaywallService._internal();
  factory PaywallService() => _instance;
  PaywallService._internal();

  static PaywallService get instance => _instance;

  final _subscriptionService = SubscriptionService.instance;
  final _trialService = FeatureTrialService.instance;

  /// Afficher un paywall en pleine page
  Future<bool> showPaywall({
    required BuildContext context,
    required PaywallContext paywallContext,
    String? customTitle,
    String? customMessage,
  }) async {
    // Si déjà Premium, ne pas afficher le paywall
    if (_subscriptionService.isPremium) {
      return true;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PaywallScreen(
          context: paywallContext,
          customTitle: customTitle,
          customMessage: customMessage,
        ),
      ),
    );

    return result ?? false;
  }

  /// Vérifier si l'utilisateur peut accéder à une feature
  /// Affiche un paywall si nécessaire
  Future<bool> canAccessFeature({
    required BuildContext context,
    required String featureName,
    required PaywallContext paywallContext,
  }) async {
    if (_subscriptionService.canAccessFeature(featureName)) {
      return true;
    }

    // Afficher le paywall
    return await showPaywall(
      context: context,
      paywallContext: paywallContext,
    );
  }

  /// Vérifier limite quotidienne et afficher paywall si dépassée
  Future<bool> checkDailyLimit({
    required BuildContext context,
    required String featureName,
    required int limit,
    required PaywallContext paywallContext,
  }) async {
    if (await _subscriptionService.canUseDailyLimitedFeature(featureName, limit)) {
      // Incrémenter le compteur
      await _subscriptionService.incrementDailyUsage(featureName);
      return true;
    }

    // Limite atteinte, afficher paywall
    return await showPaywall(
      context: context,
      paywallContext: paywallContext,
    );
  }

  /// Obtenir l'avatar Coach Ryze selon le contexte
  static CoachRyzeAvatarType getContextAvatar(PaywallContext context) {
    switch (context) {
      case PaywallContext.scanner:
      case PaywallContext.barcodeScanner:
      case PaywallContext.chatInput:
      case PaywallContext.nutritionAnalysis:
        return CoachRyzeAvatarType.nutrition;

      case PaywallContext.workoutGenerator:
      case PaywallContext.exerciseAnalysis:
        return CoachRyzeAvatarType.workout;

      case PaywallContext.planner:
        return CoachRyzeAvatarType.workout; // Avatar sport pour le planificateur

      case PaywallContext.genericUpgrade:
        return CoachRyzeAvatarType.workout; // Avatar sans tenue spéciale
    }
  }

  /// Obtenir la clé de traduction du titre selon le contexte
  static String getContextTitleKey(PaywallContext context) {
    switch (context) {
      case PaywallContext.scanner:
        return 'paywall_title_scanner';
      case PaywallContext.barcodeScanner:
        return 'paywall_title_barcode';
      case PaywallContext.chatInput:
        return 'paywall_title_chat';
      case PaywallContext.workoutGenerator:
        return 'paywall_title_workout';
      case PaywallContext.nutritionAnalysis:
        return 'paywall_title_nutrition_analysis';
      case PaywallContext.exerciseAnalysis:
        return 'paywall_title_exercise_analysis';
      case PaywallContext.planner:
        return 'paywall_title_planner';
      case PaywallContext.genericUpgrade:
        return 'paywall_title_generic';
    }
  }

  /// Obtenir le titre accrocheur émotionnel selon le contexte
  static String getContextTitle(PaywallContext context, String languageCode) {
    final key = getContextTitleKey(context);
    return AppTranslations.get(key, languageCode);
  }

  /// Obtenir les benefices emotionnels selon le contexte
  static List<Map<String, String>> getContextBenefits(
    PaywallContext context,
    String languageCode,
  ) {
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    switch (context) {
      case PaywallContext.scanner:
        return [
          {
            'icon': '⚡',
            'text': isGerman
                ? 'Mach ein Foto, erhalte Kalorien in 2 Sekunden'
                : isFrench
                    ? 'Prends une photo, obtiens les calories en 2 secondes'
                    : 'Take a photo, get calories in 2 seconds',
          },
          {
            'icon': '🎯',
            'text': isGerman
                ? 'Schluss mit ungenauen Schaetzungen, die deinen Fortschritt ruinieren'
                : isFrench
                    ? 'Fini les estimations approximatives qui ruinent tes progrès'
                    : 'No more rough estimates ruining your progress',
          },
          {
            'icon': '🔥',
            'text': isGerman
                ? 'Scanne deine 3 taeglichen Mahlzeiten in unter 30 Sekunden'
                : isFrench
                    ? 'Scanne tes 3 repas quotidiens en moins de 30 secondes'
                    : 'Scan your 3 daily meals in under 30 seconds',
          },
          {
            'icon': '📊',
            'text': isGerman
                ? 'Sieh genau, was du isst (Makros + Mikros)'
                : isFrench
                    ? 'Vois exactement ce que tu manges (macros + micros)'
                    : 'See exactly what you\'re eating (macros + micros)',
          },
          {
            'icon': '💪',
            'text': isGerman
                ? 'Erreiche deine Ziele 3x schneller mit praezisem Tracking'
                : isFrench
                    ? 'Atteins tes objectifs 3x plus vite avec un tracking précis'
                    : 'Reach your goals 3x faster with precise tracking',
          },
          {
            'icon': '✨',
            'text': isGerman
                ? 'Ueber 10.000 Athleten scannen bereits ihre Mahlzeiten'
                : isFrench
                    ? 'Plus de 10 000 athlètes scannent déjà leurs repas'
                    : 'Over 10,000 athletes already scan their meals',
          },
        ];

      case PaywallContext.barcodeScanner:
        return [
          {
            'icon': '📱',
            'text': isGerman
                ? 'Scanne den Barcode, erhalte die echten Naehrwerte'
                : isFrench
                    ? 'Scanne le code-barre, obtiens les vraies valeurs nutritionnelles'
                    : 'Scan the barcode, get the real nutritional values',
          },
          {
            'icon': '✅',
            'text': isGerman
                ? 'Kalorien, Protein, Kohlenhydrate, Fette 100% genau'
                : isFrench
                    ? 'Calories, protéines, glucides, lipides 100% précis'
                    : '100% accurate calories, protein, carbs, fats',
          },
          {
            'icon': '⚡',
            'text': isGerman
                ? 'Tracke dein Essen in 2 Sekunden'
                : isFrench
                    ? 'Tracke tes aliments en 2 secondes chrono'
                    : 'Track your food in 2 seconds flat',
          },
          {
            'icon': '🎯',
            'text': isGerman
                ? 'Schluss mit Schaetzfehlern, die deine Ergebnisse verfaelschen'
                : isFrench
                    ? 'Fini les erreurs d\'estimation qui faussent tes résultats'
                    : 'No more estimation errors messing up your results',
          },
          {
            'icon': '📊',
            'text': isGerman
                ? 'Weltweite Datenbank mit Millionen von Produkten'
                : isFrench
                    ? 'Base de données mondiale de millions de produits'
                    : 'Global database of millions of products',
          },
          {
            'icon': '💪',
            'text': isGerman
                ? 'Erreiche deine Ziele mit ultra-praezisem Tracking'
                : isFrench
                    ? 'Atteins tes objectifs avec un tracking ultra-précis'
                    : 'Reach your goals with ultra-precise tracking',
          },
        ];

      case PaywallContext.chatInput:
        return [
          {
            'icon': '🗣️',
            'text': isGerman
                ? 'Sag einfach "Ich habe Pizza gegessen" und es ist getrackt'
                : isFrench
                    ? 'Dis juste "j\'ai mangé une pizza" et c\'est tracké'
                    : 'Just say "I ate a pizza" and it\'s tracked',
          },
          {
            'icon': '⚡',
            'text': isGerman
                ? 'Die SCHNELLSTE Art zu tracken (3 Sekunden)'
                : isFrench
                    ? 'Le moyen le PLUS rapide de tracker (3 secondes chrono)'
                    : 'The FASTEST way to track (3 seconds flat)',
          },
          {
            'icon': '🎤',
            'text': isGerman
                ? 'Melde Mahlzeiten per Sprache waehrend du isst'
                : isFrench
                    ? 'Déclare tes repas en vocal pendant que tu manges'
                    : 'Declare meals by voice while you eat',
          },
          {
            'icon': '🧠',
            'text': isGerman
                ? 'Coach Ryze versteht "2 Eier + Buttertoast"'
                : isFrench
                    ? 'Le Coach Ryze comprend "2 œufs + tartines beurre"'
                    : 'Coach Ryze understands "2 eggs + buttered toast"',
          },
          {
            'icon': '💪',
            'text': isGerman
                ? 'Bleib konstant beim Tracken = garantierte Ergebnisse'
                : isFrench
                    ? 'Reste constant dans ton tracking = résultats garantis'
                    : 'Stay consistent with tracking = guaranteed results',
          },
          {
            'icon': '📲',
            'text': isGerman
                ? 'Perfekt wenn du mit Freunden im Restaurant bist'
                : isFrench
                    ? 'Parfait quand t\'es au resto avec des potes'
                    : 'Perfect when you\'re at a restaurant with friends',
          },
        ];

      case PaywallContext.workoutGenerator:
        return [
          {
            'icon': '🤖',
            'text': isGerman
                ? 'Dein Coach erstellt Einheiten angepasst an DEIN Level'
                : isFrench
                    ? 'Ton Coach crée des séances adaptées à TON niveau'
                    : 'Your Coach creates sessions adapted to YOUR level',
          },
          {
            'icon': '📈',
            'text': isGerman
                ? 'Automatische Progression basierend auf deiner Leistung'
                : isFrench
                    ? 'Progression automatique basée sur tes performances'
                    : 'Automatic progression based on your performance',
          },
          {
            'icon': '⚡',
            'text': isGerman
                ? 'Generiere ein komplettes Workout in 10 Sekunden'
                : isFrench
                    ? 'Génère un workout complet en 10 secondes'
                    : 'Generate a complete workout in 10 seconds',
          },
          {
            'icon': '💪',
            'text': isGerman
                ? 'Nie wieder stagnieren: Coach erhoeht die Intensitaet'
                : isFrench
                    ? 'Ne stagne plus jamais : le Coach augmente l\'intensité'
                    : 'Never plateau again: Coach increases intensity',
          },
          {
            'icon': '🎯',
            'text': isGerman
                ? 'Intelligente Balance aller Muskelgruppen'
                : isFrench
                    ? 'Équilibrage intelligent de tous les groupes musculaires'
                    : 'Smart balancing of all muscle groups',
          },
          {
            'icon': '🔥',
            'text': isGerman
                ? 'Erreiche deine koerperlichen Ziele 2x schneller'
                : isFrench
                    ? 'Atteins tes objectifs physiques 2x plus vite'
                    : 'Reach your physical goals 2x faster',
          },
        ];

      case PaywallContext.nutritionAnalysis:
        return [
          {
            'icon': '📊',
            'text': isGerman
                ? 'Personalisierter Tagesbericht deines Tages'
                : isFrench
                    ? 'Bilan quotidien personnalisé de ta journée'
                    : 'Personalized daily report of your day',
          },
          {
            'icon': '💡',
            'text': isGerman
                ? 'Wisse GENAU, was du anpassen musst, um Fortschritte zu machen'
                : isFrench
                    ? 'Sais EXACTEMENT quoi ajuster pour progresser'
                    : 'Know EXACTLY what to adjust to progress',
          },
          {
            'icon': '🎯',
            'text': isGerman
                ? 'Tipps angepasst an dein Ziel (Abnehmen, Aufbauen...)'
                : isFrench
                    ? 'Conseils adaptés à ton objectif (sèche, prise de masse...)'
                    : 'Advice adapted to your goal (cut, bulk...)',
          },
          {
            'icon': '📈',
            'text': isGerman
                ? 'Visualisiere deinen Fortschritt Woche fuer Woche'
                : isFrench
                    ? 'Visualise ta progression semaine après semaine'
                    : 'Visualize your progress week after week',
          },
          {
            'icon': '🔥',
            'text': isGerman
                ? 'Verstehe, warum du an manchen Tagen stagnierst'
                : isFrench
                    ? 'Comprends pourquoi certains jours tu stagnes'
                    : 'Understand why some days you plateau',
          },
          {
            'icon': '✨',
            'text': isGerman
                ? 'Erhalte taeglich personalisierte Ermutigung'
                : isFrench
                    ? 'Reçois des encouragements personnalisés chaque jour'
                    : 'Receive personalized encouragement every day',
          },
        ];

      case PaywallContext.exerciseAnalysis:
        return [
          {
            'icon': '💪',
            'text': isGerman
                ? 'Analyse deiner Leistung Uebung fuer Uebung'
                : isFrench
                    ? 'Analyse de tes perfs exercice par exercice'
                    : 'Analysis of your performance exercise by exercise',
          },
          {
            'icon': '📈',
            'text': isGerman
                ? 'Sieh deine Schwachstellen und wie du sie behebst'
                : isFrench
                    ? 'Vois tes points faibles et comment les corriger'
                    : 'See your weak points and how to fix them',
          },
          {
            'icon': '🎯',
            'text': isGerman
                ? 'Empfehlungen, um 5-10kg bei jeder Bewegung zuzulegen'
                : isFrench
                    ? 'Recommandations pour ajouter 5-10kg sur chaque mouvement'
                    : 'Recommendations to add 5-10kg on each movement',
          },
          {
            'icon': '⚡',
            'text': isGerman
                ? 'Erkennt automatisch, wann du steigern solltest'
                : isFrench
                    ? 'Détecte automatiquement quand tu dois progresser'
                    : 'Automatically detects when you should progress',
          },
          {
            'icon': '🔥',
            'text': isGerman
                ? 'Vergleiche deine Leistung mit Athleten deines Levels'
                : isFrench
                    ? 'Compare tes perfs avec des athlètes de ton niveau'
                    : 'Compare your performance with athletes at your level',
          },
          {
            'icon': '💡',
            'text': isGerman
                ? 'Sofortiges Feedback nach jeder Einheit'
                : isFrench
                    ? 'Feedback immédiat après chaque séance'
                    : 'Immediate feedback after each session',
          },
        ];

      case PaywallContext.planner:
        return [
          {
            'icon': '📅',
            'text': isGerman
                ? 'Plane deine ganze Woche in 30 Sekunden mit KI'
                : isFrench
                    ? 'Planifie ta semaine entière en 30 secondes avec l\'IA'
                    : 'Plan your entire week in 30 seconds with AI',
          },
          {
            'icon': '🍽️',
            'text': isGerman
                ? 'Mahlzeiten + Workouts automatisch auf deine Ziele abgestimmt'
                : isFrench
                    ? 'Repas + entraînements automatiquement adaptés à tes objectifs'
                    : 'Meals + workouts automatically tailored to your goals',
          },
          {
            'icon': '🧠',
            'text': isGerman
                ? 'Sag einfach "Plane mein Training" und Ryze erledigt den Rest'
                : isFrench
                    ? 'Dis juste "planifie mon entraînement" et Ryze fait le reste'
                    : 'Just say "plan my training" and Ryze does the rest',
          },
          {
            'icon': '⚡',
            'text': isGerman
                ? 'Nie wieder Zeit verschwenden mit der Frage "Was esse ich heute?"'
                : isFrench
                    ? 'Plus jamais de temps perdu à réfléchir "qu\'est-ce que je mange ?"'
                    : 'Never waste time wondering "what should I eat?" again',
          },
          {
            'icon': '🎯',
            'text': isGerman
                ? 'Bleib auf Kurs mit einem klaren Wochenplan'
                : isFrench
                    ? 'Reste sur la bonne voie avec un plan de semaine clair'
                    : 'Stay on track with a clear weekly plan',
          },
          {
            'icon': '💪',
            'text': isGerman
                ? 'Die Athleten, die planen, erreichen ihre Ziele 2x schneller'
                : isFrench
                    ? 'Les athlètes qui planifient atteignent leurs objectifs 2x plus vite'
                    : 'Athletes who plan reach their goals 2x faster',
          },
        ];

      default:
        // Benefices generiques (5 points)
        return [
          {
            'icon': '🎯',
            'text': isGerman
                ? 'Erreiche deine Ziele 2x schneller mit einem persönlichen KI-Coach'
                : isFrench
                    ? 'Atteins tes objectifs 2x plus vite avec un coach IA dédié'
                    : 'Reach your goals 2x faster with a dedicated AI coach',
          },
          {
            'icon': '📸',
            'text': isGerman
                ? 'Scanne jedes Gericht in 2 Sekunden — Kalorien und Makros sofort'
                : isFrench
                    ? 'Scanne n\'importe quel plat en 2 secondes — calories et macros instantanés'
                    : 'Scan any meal in 2 seconds — instant calories and macros',
          },
          {
            'icon': '🍽️',
            'text': isGerman
                ? 'Iss, was du liebst, und mache trotzdem Fortschritte'
                : isFrench
                    ? 'Mange ce que tu aimes tout en progressant'
                    : 'Eat what you love while still making progress',
          },
          {
            'icon': '💪',
            'text': isGerman
                ? 'Workouts, die jede Woche an DEIN Level angepasst sind'
                : isFrench
                    ? 'Entraînements adaptés à TON niveau chaque semaine'
                    : 'Workouts adapted to YOUR level every week',
          },
          {
            'icon': '📊',
            'text': isGerman
                ? 'Visualisiere deine Fortschritte und bleib motiviert'
                : isFrench
                    ? 'Visualise tes progrès et reste motivé'
                    : 'Visualize your progress and stay motivated',
          },
        ];
    }
  }

  /// Obtenir la clé de traduction de la bulle du Coach selon le contexte
  static String getCoachBubbleTextKey(PaywallContext context) {
    switch (context) {
      case PaywallContext.scanner:
        return 'paywall_bubble_scanner';
      case PaywallContext.barcodeScanner:
        return 'paywall_bubble_barcode';
      case PaywallContext.chatInput:
        return 'paywall_bubble_chat';
      case PaywallContext.workoutGenerator:
        return 'paywall_bubble_workout';
      case PaywallContext.nutritionAnalysis:
        return 'paywall_bubble_nutrition_analysis';
      case PaywallContext.exerciseAnalysis:
        return 'paywall_bubble_exercise_analysis';
      case PaywallContext.planner:
        return 'paywall_bubble_planner';
      case PaywallContext.genericUpgrade:
        return 'paywall_bubble_generic';
    }
  }

  /// Obtenir le texte de la bulle du Coach Ryze selon le contexte
  static String getCoachBubbleText(PaywallContext context, String languageCode) {
    final key = getCoachBubbleTextKey(context);
    return AppTranslations.get(key, languageCode);
  }

  /// Obtenir le message personnalise selon le contexte
  static Map<String, String> getPaywallContent(
    PaywallContext context,
    String languageCode,
  ) {
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    switch (context) {
      // === FEATURES COACH RYZE (NOUVELLES) ===

      case PaywallContext.scanner:
        return {
          'title': isGerman
              ? '📸 Auto-Scanner - Premium'
              : isFrench
                  ? '📸 Scanner automatique - Premium'
                  : '📸 Auto Scanner - Premium',
          'message': isGerman
              ? 'Der Auto-Scanner ist Premium-Mitgliedern vorbehalten.\n\n✨ Coach Ryze erkennt dein Essen sofort\n📊 Kalorien automatisch berechnet\n⚡ Schneller als manuelle Eingabe'
              : isFrench
                  ? 'Le scanner automatique est réservé aux membres Premium.\n\n✨ Le Coach Ryze reconnaît tes aliments instantanément\n📊 Calories calculées automatiquement\n⚡ Plus rapide que l\'entrée manuelle'
                  : 'Auto scanner is reserved for Premium members.\n\n✨ Coach Ryze recognizes your food instantly\n📊 Calories calculated automatically\n⚡ Faster than manual entry',
        };

      case PaywallContext.barcodeScanner:
        return {
          'title': isGerman
              ? '📱 Barcode-Scanner - Premium'
              : isFrench
                  ? '📱 Scanner codes-barres - Premium'
                  : '📱 Barcode Scanner - Premium',
          'message': isGerman
              ? 'Der Barcode-Scanner ist Premium-Mitgliedern vorbehalten.\n\n✨ Scanne Supermarktprodukte\n📊 Komplette Naehrwerte automatisch\n⚡ Enorme Zeitersparnis'
              : isFrench
                  ? 'Le scanner de codes-barres est réservé aux membres Premium.\n\n✨ Scanne les produits du supermarché\n📊 Nutritions complètes automatiquement\n⚡ Gain de temps énorme'
                  : 'Barcode scanner is reserved for Premium members.\n\n✨ Scan supermarket products\n📊 Complete nutrition automatically\n⚡ Huge time saver',
        };

      case PaywallContext.chatInput:
        return {
          'title': isGerman
              ? '💬 Coach Ryze mitteilen - Premium'
              : isFrench
                  ? '💬 Déclarer au Coach Ryze - Premium'
                  : '💬 Tell Coach Ryze - Premium',
          'message': isGerman
              ? 'Coach Ryze deine Mahlzeiten mitzuteilen ist Premium-Mitgliedern vorbehalten.\n\n🗣️ Sag einfach, was du gegessen hast\n✨ Coach Ryze versteht und berechnet alles\n⚡ Sprache oder Text, ultraschnell'
              : isFrench
                  ? 'Déclarer tes repas au Coach Ryze est réservé aux membres Premium.\n\n🗣️ Dis simplement ce que tu as mangé\n✨ Le Coach Ryze comprend et calcule tout\n⚡ Vocal ou texte, ultra rapide'
                  : 'Telling Coach Ryze your meals is reserved for Premium members.\n\n🗣️ Simply say what you ate\n✨ Coach Ryze understands and calculates everything\n⚡ Voice or text, ultra fast',
        };

      case PaywallContext.workoutGenerator:
        return {
          'title': isGerman
              ? '🤖 Coach Ryze - Premium'
              : isFrench
                  ? '🤖 Coach Ryze - Premium'
                  : '🤖 Coach Ryze - Premium',
          'message': isGerman
              ? 'Der personalisierte Workout-Generator ist Premium-Mitgliedern vorbehalten.\n\n✨ Coach Ryze analysiert deinen Verlauf\n💪 Erstellt Workouts angepasst an dein Level\n📈 Schlaegt automatisch die richtigen Gewichte vor'
              : isFrench
                  ? 'Le générateur de séances personnalisées est réservé aux membres Premium.\n\n✨ Le Coach Ryze analyse ton historique\n💪 Crée des workouts adaptés à ton niveau\n📈 Suggère les bons poids automatiquement'
                  : 'Personalized workout generator is reserved for Premium members.\n\n✨ Coach Ryze analyzes your history\n💪 Creates workouts adapted to your level\n📈 Suggests the right weights automatically',
        };

      case PaywallContext.nutritionAnalysis:
        return {
          'title': isGerman
              ? '📊 Coach Ryze Bericht - Premium'
              : isFrench
                  ? '📊 Bilan du Coach Ryze - Premium'
                  : '📊 Coach Ryze Report - Premium',
          'message': isGerman
              ? 'Der personalisierte Tagesbericht ist Premium-Mitgliedern vorbehalten.\n\n✨ Coach Ryze analysiert deinen Tag\n💡 Personalisierte Tipps basierend auf deinen Zielen\n📈 Verfolge deinen Fortschritt'
              : isFrench
                  ? 'Le bilan quotidien personnalisé est réservé aux membres Premium.\n\n✨ Le Coach Ryze analyse ta journée\n💡 Conseils personnalisés selon tes objectifs\n📈 Suivi de ta progression'
                  : 'Personalized daily report is reserved for Premium members.\n\n✨ Coach Ryze analyzes your day\n💡 Personalized advice based on your goals\n📈 Track your progress',
        };

      case PaywallContext.exerciseAnalysis:
        return {
          'title': isGerman
              ? '💪 Fortschrittsanalyse - Premium'
              : isFrench
                  ? '💪 Analyse de progression - Premium'
                  : '💪 Progress Analysis - Premium',
          'message': isGerman
              ? 'Die Fortschrittsanalyse ist Premium-Mitgliedern vorbehalten.\n\n✨ Coach Ryze analysiert deine Leistung\n💡 Empfehlungen zur Verbesserung\n📈 Personalisiertes Feedback'
              : isFrench
                  ? 'L\'analyse de progression est réservée aux membres Premium.\n\n✨ Le Coach Ryze analyse tes performances\n💡 Recommandations pour progresser\n📈 Feedback personnalisé'
                  : 'Progress analysis is reserved for Premium members.\n\n✨ Coach Ryze analyzes your performance\n💡 Recommendations to improve\n📈 Personalized feedback',
        };

      case PaywallContext.planner:
        return {
          'title': isGerman
              ? '📅 Wochenplaner - Premium'
              : isFrench
                  ? '📅 Planificateur - Premium'
                  : '📅 Weekly Planner - Premium',
          'message': isGerman
              ? 'Der KI-Planer ist Premium-Mitgliedern vorbehalten.\n\n✨ Plane Mahlzeiten + Workouts mit KI\n📅 Deine ganze Woche in 30 Sekunden\n🎯 Automatisch auf deine Ziele abgestimmt'
              : isFrench
                  ? 'Le planificateur IA est réservé aux membres Premium.\n\n✨ Planifie repas + entraînements avec l\'IA\n📅 Ta semaine entière en 30 secondes\n🎯 Automatiquement adapté à tes objectifs'
                  : 'The AI planner is reserved for Premium members.\n\n✨ Plan meals + workouts with AI\n📅 Your entire week in 30 seconds\n🎯 Automatically tailored to your goals',
        };

      case PaywallContext.genericUpgrade:
        return {
          'title': isGerman
              ? '💎 Werde Premium'
              : isFrench
                  ? '💎 Passe Premium'
                  : '💎 Upgrade to Premium',
          'message': isGerman
              ? 'Schalte alle Premium-Funktionen frei und erreiche deine Ziele schneller.'
              : isFrench
                  ? 'Débloque toutes les fonctionnalités Premium et atteins tes objectifs plus rapidement.'
                  : 'Unlock all Premium features and reach your goals faster.',
        };
    }
  }

  // ═══════════════════════════════════════════════════════
  // SYSTÈME D'ESSAIS GRATUITS
  // ═══════════════════════════════════════════════════════

  /// Mapper PaywallContext vers clé de feature trial
  static String getFeatureTrialKey(PaywallContext context) {
    switch (context) {
      case PaywallContext.scanner:
        return FeatureTrialService.keyScanner;
      case PaywallContext.barcodeScanner:
        return FeatureTrialService.keyBarcode;
      case PaywallContext.chatInput:
        return FeatureTrialService.keyChat;
      case PaywallContext.workoutGenerator:
        return FeatureTrialService.keyWorkout;
      case PaywallContext.nutritionAnalysis:
        return FeatureTrialService.keyNutritionAnalysis;
      case PaywallContext.exerciseAnalysis:
        return FeatureTrialService.keyExerciseAnalysis;
      case PaywallContext.planner:
        return FeatureTrialService.keyPlanner;
      case PaywallContext.genericUpgrade:
        return ''; // Pas de trial pour générique
    }
  }

  /// Vérifier si l'utilisateur peut utiliser la feature (Premium ou 1er essai gratuit)
  ///
  /// Retourne `true` si l'utilisateur peut accéder à la feature :
  /// - Si Premium : accès illimité
  /// - Si non-Premium et 1er essai : accès gratuit (et marque comme utilisé si `markAsUsed = true`)
  /// - Si non-Premium et essai déjà utilisé : affiche le paywall et retourne `false`
  ///
  /// Paramètres :
  /// - `context` : BuildContext pour afficher le paywall si nécessaire
  /// - `paywallContext` : Contexte de la feature (scanner, barcode, chat, etc.)
  /// - `markAsUsed` : Si `true`, marque l'essai gratuit comme utilisé (par défaut `true`)
  ///
  /// Exemple :
  /// ```dart
  /// final canUse = await PaywallService.instance.canUseFeature(
  ///   context: context,
  ///   paywallContext: PaywallContext.scanner,
  /// );
  ///
  /// if (canUse) {
  ///   // Ouvrir le scanner
  ///   Navigator.push(...);
  /// }
  /// // Sinon, le paywall s'est affiché automatiquement
  /// ```
  Future<bool> canUseFeature({
    required BuildContext context,
    required PaywallContext paywallContext,
    bool markAsUsed = true,
  }) async {
    // Si Premium, accès illimité
    if (_subscriptionService.isPremium) {
      print('✅ PaywallService: User is Premium, granting access to ${paywallContext.name}');
      return true;
    }

    // Vérifier le trial gratuit
    final trialKey = getFeatureTrialKey(paywallContext);
    if (trialKey.isEmpty) {
      print('⚠️ PaywallService: No trial key for ${paywallContext.name}, showing paywall');
      await showPaywall(
        context: context,
        paywallContext: paywallContext,
      );
      return false;
    }

    final hasUsed = await _trialService.hasUsedFreeTrial(trialKey);

    if (!hasUsed) {
      // 1er essai gratuit
      print('🎁 PaywallService: First free trial for ${paywallContext.name}');

      if (markAsUsed) {
        await _trialService.markFeatureAsUsed(trialKey);
        print('✅ PaywallService: Marked ${paywallContext.name} trial as used');
      }

      return true;
    }

    // A déjà utilisé son essai, montrer le paywall
    print('🚫 PaywallService: Trial already used for ${paywallContext.name}, showing paywall');
    await showPaywall(
      context: context,
      paywallContext: paywallContext,
    );

    return false;
  }

  /// Vérifier si la feature est verrouillée (badge Premium à afficher)
  ///
  /// Retourne `true` si l'utilisateur doit voir un badge "Premium" :
  /// - Non-Premium ET a déjà utilisé son essai gratuit
  ///
  /// Retourne `false` si :
  /// - Premium (accès illimité)
  /// - Non-Premium mais n'a pas encore utilisé son essai
  ///
  /// Utile pour griser les boutons et afficher le badge "PRO"
  Future<bool> isFeatureLocked(PaywallContext paywallContext) async {
    // Si Premium, jamais verrouillé
    if (_subscriptionService.isPremium) {
      return false;
    }

    // Vérifier si l'essai a été utilisé
    final trialKey = getFeatureTrialKey(paywallContext);
    if (trialKey.isEmpty) {
      return true; // Pas de trial = toujours verrouillé pour non-Premium
    }

    final hasUsed = await _trialService.hasUsedFreeTrial(trialKey);
    return hasUsed; // Verrouillé si l'essai a déjà été utilisé
  }
}
