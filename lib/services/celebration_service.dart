import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/celebration_popup.dart';
import 'localization_service.dart';
import 'app_navigator.dart';
import 'unit_service.dart';

class CelebrationService {
  static final CelebrationService _instance = CelebrationService._internal();
  factory CelebrationService() => _instance;
  CelebrationService._internal();

  final Random _random = Random();

  // FRENCH - Workout celebration messages
  static const List<String> _workoutMessagesFr = [
    "Bravo ! 💪",
    "Excellent travail !",
    "Tu es un(e) champion(ne) !",
    "Continue comme ça !",
    "Incroyable performance !",
    "Tu progresses !",
    "Fier de toi !",
    "Machine de guerre !",
    "Rien ne t'arrête !",
    "Objectif atteint !",
    "Quelle séance ! 🔥",
    "Tu assures grave !",
    "Impressionnant !",
    "Tu déchires ! 💥",
    "Beast mode activé !",
    "Séance validée ! ✅",
    "Champion(ne) du jour !",
    "Tu donnes tout !",
    "Respect ! 👊",
    "Force et honneur !",
  ];

  static const List<String> _workoutSubtitlesFr = [
    "Une séance de plus vers ton objectif !",
    "Ton corps te remercie !",
    "Tu deviens plus fort(e) chaque jour !",
    "La régularité paye toujours !",
    "Continue sur cette lancée !",
    "Tu es sur la bonne voie !",
    "Chaque effort compte !",
    "Ta détermination est inspirante !",
    "Encore un pas vers la réussite !",
    "Tu repousses tes limites !",
    "La constance mène au succès !",
    "Ton futur toi te remercie !",
    "Chaque séance te rapproche du but !",
    "Tu construis ton corps idéal !",
  ];

  // ENGLISH - Workout celebration messages
  static const List<String> _workoutMessagesEn = [
    "Well done! 💪",
    "Excellent work!",
    "You're a champion!",
    "Keep it up!",
    "Amazing performance!",
    "You're progressing!",
    "Proud of you!",
    "Beast mode!",
    "Nothing stops you!",
    "Goal achieved!",
    "What a session! 🔥",
    "You're crushing it!",
    "Impressive!",
    "You're on fire! 💥",
    "Beast mode activated!",
    "Session completed! ✅",
    "Champion of the day!",
    "You gave it all!",
    "Respect! 👊",
    "Strength and honor!",
  ];

  static const List<String> _workoutSubtitlesEn = [
    "One more session towards your goal!",
    "Your body thanks you!",
    "You're getting stronger every day!",
    "Consistency always pays off!",
    "Keep up the momentum!",
    "You're on the right track!",
    "Every effort counts!",
    "Your determination is inspiring!",
    "Another step towards success!",
    "You're pushing your limits!",
    "Consistency leads to success!",
    "Your future self thanks you!",
    "Each session brings you closer!",
    "You're building your ideal body!",
  ];

  // GERMAN - Workout celebration messages
  static const List<String> _workoutMessagesDe = [
    "Gut gemacht! 💪",
    "Hervorragende Arbeit!",
    "Du bist ein Champion!",
    "Weiter so!",
    "Tolle Leistung!",
    "Du machst Fortschritte!",
    "Stolz auf dich!",
    "Beast Modus!",
    "Nichts hält dich auf!",
    "Ziel erreicht!",
    "Was für ein Training! 🔥",
    "Du gibst alles!",
    "Beeindruckend!",
    "Du bist on fire! 💥",
    "Beast Modus aktiviert!",
    "Training abgeschlossen! ✅",
    "Champion des Tages!",
    "Du hast alles gegeben!",
    "Respekt! 👊",
    "Kraft und Ehre!",
  ];

  static const List<String> _workoutSubtitlesDe = [
    "Noch ein Training näher an deinem Ziel!",
    "Dein Körper dankt dir!",
    "Du wirst jeden Tag stärker!",
    "Beständigkeit zahlt sich immer aus!",
    "Bleib am Ball!",
    "Du bist auf dem richtigen Weg!",
    "Jede Anstrengung zählt!",
    "Deine Entschlossenheit ist inspirierend!",
    "Noch ein Schritt zum Erfolg!",
    "Du überwindest deine Grenzen!",
    "Kontinuität führt zum Erfolg!",
    "Dein zukünftiges Ich dankt dir!",
    "Jedes Training bringt dich näher!",
    "Du baust deinen idealen Körper auf!",
  ];

  // FRENCH - Nutrition celebration messages
  static const List<String> _nutritionMessagesFr = [
    "Super choix ! 🍎",
    "Bien joué !",
    "Nutrition au top !",
    "Continue sur cette lancée !",
    "Excellent suivi !",
    "Bravo pour ce suivi !",
    "Tu gères ton alimentation !",
    "Bon choix nutritionnel !",
    "Objectif nutrition en vue !",
    "Repas validé ! ✅",
    "Tu manges smart ! 🧠",
    "Choix de champion(ne) !",
    "Ta nutrition est on point ! 👌",
    "Bien vu pour ce repas !",
    "Tu nourris ton succès !",
    "Parfait pour tes objectifs !",
    "Alimentation de warrior ! 🥗",
    "Tu fais les bons choix !",
    "Bravo pour cette rigueur !",
  ];

  static const List<String> _nutritionSubtitlesFr = [
    "Chaque repas compte vers ton objectif !",
    "Bien manger c'est la clé !",
    "Ton corps te dit merci !",
    "La nutrition fait 70% du résultat !",
    "Tu nourris ton corps intelligemment !",
    "Un pas de plus vers tes objectifs !",
    "Ton alimentation est ton carburant !",
    "Tu construis ton physique à table !",
    "La discipline paie toujours !",
    "Chaque choix compte !",
    "Tu prends soin de toi !",
    "L'excellence commence dans l'assiette !",
  ];

  // ENGLISH - Nutrition celebration messages
  static const List<String> _nutritionMessagesEn = [
    "Great choice! 🍎",
    "Well done!",
    "Nutrition on point!",
    "Keep it up!",
    "Excellent tracking!",
    "Great job tracking!",
    "You're managing your diet!",
    "Smart nutritional choice!",
    "Nutrition goal in sight!",
    "Meal logged! ✅",
    "You eat smart! 🧠",
    "Champion's choice!",
    "Your nutrition is on point! 👌",
    "Good call for this meal!",
    "Fueling your success!",
    "Perfect for your goals!",
    "Warrior's diet! 🥗",
    "You make the right choices!",
    "Great discipline!",
  ];

  static const List<String> _nutritionSubtitlesEn = [
    "Every meal counts towards your goal!",
    "Eating well is the key!",
    "Your body says thank you!",
    "Nutrition is 70% of the result!",
    "You're feeding your body smartly!",
    "One more step towards your goals!",
    "Your diet is your fuel!",
    "You build your physique at the table!",
    "Discipline always pays off!",
    "Every choice matters!",
    "You're taking care of yourself!",
    "Excellence starts on the plate!",
  ];

  // GERMAN - Nutrition celebration messages
  static const List<String> _nutritionMessagesDe = [
    "Gute Wahl! 🍎",
    "Gut gemacht!",
    "Ernährung top!",
    "Weiter so!",
    "Tolles Tracking!",
    "Super Dokumentation!",
    "Du managst deine Ernährung!",
    "Kluge Wahl!",
    "Ernährungsziel in Sicht!",
    "Mahlzeit erfasst! ✅",
    "Du isst smart! 🧠",
    "Wahl eines Champions!",
    "Deine Ernährung ist perfekt! 👌",
    "Gute Entscheidung!",
    "Du tankt deinen Erfolg!",
    "Perfekt für deine Ziele!",
    "Krieger-Ernährung! 🥗",
    "Du triffst die richtigen Entscheidungen!",
    "Tolle Disziplin!",
  ];

  static const List<String> _nutritionSubtitlesDe = [
    "Jede Mahlzeit zählt für dein Ziel!",
    "Gut essen ist der Schlüssel!",
    "Dein Körper sagt danke!",
    "Ernährung macht 70% des Ergebnisses aus!",
    "Du ernährst deinen Körper klug!",
    "Noch ein Schritt zu deinen Zielen!",
    "Deine Ernährung ist dein Treibstoff!",
    "Du baust deinen Körper am Tisch auf!",
    "Disziplin zahlt sich immer aus!",
    "Jede Wahl zählt!",
    "Du kümmerst dich um dich selbst!",
    "Exzellenz beginnt auf dem Teller!",
  ];

  /// Show celebration popup after completing a workout
  void celebrateWorkoutCompletion(
    BuildContext context, {
    String? customMessage,
    String? customSubtitle,
    String? actionDescription,
    String? sessionName,
    String? workoutType,
    int? exerciseCount,
  }) {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = langCode == 'de' ? _workoutMessagesDe : (langCode == 'en' ? _workoutMessagesEn : _workoutMessagesFr);
    final subtitles = langCode == 'de' ? _workoutSubtitlesDe : (langCode == 'en' ? _workoutSubtitlesEn : _workoutSubtitlesFr);

    final message = customMessage ?? messages[_random.nextInt(messages.length)];
    final subtitle = customSubtitle ?? subtitles[_random.nextInt(subtitles.length)];
    final actionText = actionDescription ?? _buildWorkoutActionDescription(
      langCode: langCode,
      sessionName: sessionName,
      workoutType: workoutType,
      exerciseCount: exerciseCount,
    );

    CelebrationPopup.show(
      context,
      message: message,
      subtitle: subtitle,
      celebrationType: 'workout',
      actionDescription: actionText,
    );
  }

  void celebrateWorkoutCompletionGlobal({
    String? customMessage,
    String? customSubtitle,
    String? actionDescription,
    String? sessionName,
    String? workoutType,
    int? exerciseCount,
  }) {
    final appNavigator = AppNavigator();
    final navigatorState = appNavigator.navigatorState;
    final targetContext = appNavigator.safestContext;

    if (navigatorState == null || targetContext == null) {
      debugPrint('❌ Impossible d\'afficher le popup workout: navigator indisponible');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigatorState.mounted) {
        debugPrint('❌ Navigator non monté, popup workout annulé');
        return;
      }
      celebrateWorkoutCompletion(
        targetContext,
        customMessage: customMessage,
        customSubtitle: customSubtitle,
        actionDescription: actionDescription,
        sessionName: sessionName,
        workoutType: workoutType,
        exerciseCount: exerciseCount,
      );
    });
  }

  /// Show celebration popup after adding a food entry
  void celebrateFoodEntry(
    BuildContext context, {
    String? customMessage,
    String? customSubtitle,
    String? actionDescription,
    String? foodName,
    String? mealName,
  }) {
    debugPrint('🎊 CelebrationService.celebrateFoodEntry - START');
    debugPrint('   Context: $context');

    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = langCode == 'de' ? _nutritionMessagesDe : (langCode == 'en' ? _nutritionMessagesEn : _nutritionMessagesFr);
    final subtitles = langCode == 'de' ? _nutritionSubtitlesDe : (langCode == 'en' ? _nutritionSubtitlesEn : _nutritionSubtitlesFr);

    final message = customMessage ?? messages[_random.nextInt(messages.length)];
    final subtitle = customSubtitle ?? subtitles[_random.nextInt(subtitles.length)];
    final actionText = actionDescription ?? _buildFoodActionDescription(
      langCode: langCode,
      foodName: foodName,
      mealName: mealName,
    );

    debugPrint('   Message: $message');
    debugPrint('   Subtitle: $subtitle');
    debugPrint('   Calling CelebrationPopup.show...');

    CelebrationPopup.show(
      context,
      message: message,
      subtitle: subtitle,
      celebrationType: 'nutrition',
      actionDescription: actionText,
    );

    debugPrint('🎊 CelebrationService.celebrateFoodEntry - END');
  }

  void celebrateFoodEntryGlobal({
    String? customMessage,
    String? customSubtitle,
    String? actionDescription,
    String? foodName,
    String? mealName,
  }) {
    final appNavigator = AppNavigator();
    final navigatorState = appNavigator.navigatorState;
    final targetContext = appNavigator.safestContext;

    if (navigatorState == null || targetContext == null) {
      debugPrint('❌ Impossible d\'afficher le popup nutrition: navigator indisponible');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigatorState.mounted) {
        debugPrint('❌ Navigator non monté, popup nutrition annulé');
        return;
      }
      celebrateFoodEntry(
        targetContext,
        customMessage: customMessage,
        customSubtitle: customSubtitle,
        actionDescription: actionDescription,
        foodName: foodName,
        mealName: mealName,
      );
    });
  }

  /// Show celebration popup after completing a cardio session
  void celebrateCardioCompletion(
    BuildContext context, {
    String? customMessage,
    String? customSubtitle,
    String? actionDescription,
    String? activityTitle,
    Duration? duration,
    double? distanceKm,
  }) {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = langCode == 'de' ? _workoutMessagesDe : (langCode == 'en' ? _workoutMessagesEn : _workoutMessagesFr);
    final subtitles = langCode == 'de' ? _workoutSubtitlesDe : (langCode == 'en' ? _workoutSubtitlesEn : _workoutSubtitlesFr);

    final message = customMessage ?? messages[_random.nextInt(messages.length)];
    final subtitle = customSubtitle ?? subtitles[_random.nextInt(subtitles.length)];
    final actionText = actionDescription ?? _buildCardioActionDescription(
      langCode: langCode,
      activityTitle: activityTitle,
      duration: duration,
      distanceKm: distanceKm,
    );

    CelebrationPopup.show(
      context,
      message: message,
      subtitle: subtitle,
      celebrationType: 'workout',
      actionDescription: actionText,
    );
  }

  void celebrateCardioCompletionGlobal({
    String? customMessage,
    String? customSubtitle,
    String? actionDescription,
    String? activityTitle,
    Duration? duration,
    double? distanceKm,
  }) {
    final appNavigator = AppNavigator();
    final navigatorState = appNavigator.navigatorState;
    final targetContext = appNavigator.safestContext;

    if (navigatorState == null || targetContext == null) {
      debugPrint('❌ Impossible d\'afficher le popup cardio: navigator indisponible');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigatorState.mounted) {
        debugPrint('❌ Navigator non monté, popup cardio annulé');
        return;
      }
      celebrateCardioCompletion(
        targetContext,
        customMessage: customMessage,
        customSubtitle: customSubtitle,
        actionDescription: actionDescription,
        activityTitle: activityTitle,
        duration: duration,
        distanceKm: distanceKm,
      );
    });
  }

  /// Show celebration popup after completing a HIIT session
  void celebrateHiitCompletion(BuildContext context, {String? customMessage}) {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final messages = langCode == 'de' ? _workoutMessagesDe : (langCode == 'en' ? _workoutMessagesEn : _workoutMessagesFr);
    final subtitles = langCode == 'de' ? _workoutSubtitlesDe : (langCode == 'en' ? _workoutSubtitlesEn : _workoutSubtitlesFr);

    final message = customMessage ?? messages[_random.nextInt(messages.length)];
    final subtitle = subtitles[_random.nextInt(subtitles.length)];

    CelebrationPopup.show(
      context,
      message: message,
      subtitle: subtitle,
      celebrationType: 'workout',
    );
  }

  /// Show custom celebration popup
  void celebrateCustom(
    BuildContext context, {
    required String message,
    String? subtitle,
    String celebrationType = 'workout',
    String? actionDescription,
  }) {
    CelebrationPopup.show(
      context,
      message: message,
      subtitle: subtitle,
      celebrationType: celebrationType,
      actionDescription: actionDescription,
    );
  }

  String? _buildFoodActionDescription({
    required String langCode,
    String? foodName,
    String? mealName,
  }) {
    if (foodName != null && mealName != null) {
      if (langCode == 'de') return '$foodName zu $mealName hinzugefügt';
      if (langCode == 'en') return '$foodName added to $mealName';
      return '$foodName a été ajouté au repas $mealName';
    }

    if (foodName != null) {
      if (langCode == 'de') return '$foodName in deinem Journal gespeichert';
      if (langCode == 'en') return '$foodName saved to your journal';
      return '$foodName a été enregistré dans ton journal';
    }

    if (mealName != null) {
      if (langCode == 'de') return 'Eintrag zu $mealName hinzugefügt';
      if (langCode == 'en') return 'Entry added to $mealName';
      return 'Entrée ajoutée au repas $mealName';
    }

    if (langCode == 'de') return 'Ernährungseintrag gespeichert';
    if (langCode == 'en') return 'Nutrition entry saved';
    return 'Entrée nutrition enregistrée';
  }

  String? _buildCardioActionDescription({
    required String langCode,
    String? activityTitle,
    Duration? duration,
    double? distanceKm,
  }) {
    final buffer = StringBuffer();

    if (activityTitle != null) {
      if (langCode == 'de') {
        buffer.write('$activityTitle Training erfasst');
      } else if (langCode == 'en') {
        buffer.write('$activityTitle session logged');
      } else {
        buffer.write('Séance $activityTitle validée');
      }
    }

    if (duration != null && duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final durationText = minutes >= 60
          ? '${(minutes / 60).floor()}h${minutes % 60}min'
          : '$minutes min';
      buffer.write(buffer.isEmpty ? durationText : ' · $durationText');
    }

    if (distanceKm != null && distanceKm > 0) {
      // Utiliser UnitService pour afficher la distance dans la bonne unité
      final distanceText = UnitService.instance.formatDistance(distanceKm, decimals: distanceKm >= 10 ? 1 : 2);
      buffer.write(buffer.isEmpty ? distanceText : ' · $distanceText');
    }

    if (buffer.isEmpty) {
      if (langCode == 'de') return 'Cardio-Training abgeschlossen';
      if (langCode == 'en') return 'Cardio session completed';
      return 'Séance cardio complétée';
    }

    return buffer.toString();
  }

  String? _buildWorkoutActionDescription({
    required String langCode,
    String? sessionName,
    String? workoutType,
    int? exerciseCount,
  }) {
    final parts = <String>[];

    if (sessionName != null && sessionName.trim().isNotEmpty) {
      if (langCode == 'de') {
        parts.add('Training "$sessionName"');
      } else if (langCode == 'en') {
        parts.add('Session "$sessionName"');
      } else {
        parts.add('Séance "$sessionName"');
      }
    }

    if (workoutType != null) {
      String? typeText;
      switch (workoutType) {
        case 'guided':
          typeText = langCode == 'de' ? 'Geführtes Programm' : (langCode == 'en' ? 'Guided program' : 'Programme guidé');
          break;
        case 'coach':
          typeText = langCode == 'de' ? 'Coach Ryze Training' : (langCode == 'en' ? 'Coach Ryze session' : 'Séance Coach Ryze');
          break;
        case 'manual':
          typeText = langCode == 'de' ? 'Manuelles Training' : (langCode == 'en' ? 'Manual workout' : 'Séance manuelle');
          break;
      }
      if (typeText != null) parts.add(typeText);
    }

    if (exerciseCount != null && exerciseCount > 0) {
      String label;
      if (langCode == 'de') {
        label = '$exerciseCount Übung${exerciseCount > 1 ? 'en' : ''}';
      } else if (langCode == 'en') {
        label = '$exerciseCount exercise${exerciseCount > 1 ? 's' : ''}';
      } else {
        label = '$exerciseCount exercice${exerciseCount > 1 ? 's' : ''}';
      }
      parts.add(label);
    }

    if (parts.isEmpty) {
      if (langCode == 'de') return 'Training erfasst';
      if (langCode == 'en') return 'Workout logged';
      return 'Séance enregistrée';
    }

    return parts.join(' · ');
  }
}
