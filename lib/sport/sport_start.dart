import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../models/cardio_session_models.dart';
import '../models/hiit_models.dart';
import '../models/sport_models.dart';
import '../models/weekly_planner_models.dart';
import '../screens/ai_workout_generator_screen.dart';
import '../services/cardio_service.dart';
import '../services/localization_service.dart';
import '../services/paywall_service.dart';
import '../services/translations.dart';
import '../services/workout_session_store.dart';
import 'cardio/cardio_live_screen.dart';
import 'cardio/hiit_live_screen.dart';
import 'cardio/hiit_setup_sheet.dart';
import 'cardio/manual_cardio_sheet.dart';
import 'session/session_screen.dart';
import 'sport_programs_page.dart';

/// Les façons de commencer une séance, ramenées à une classe.
///
/// L'ancien onglet en avait huit, dans cinq fichiers, chacune avec ses
/// modales. Ici chaque chemin est une méthode qui pousse l'écran qui va bien
/// et rend la main quand il revient ; les feuilles intermédiaires (activité,
/// format, objectif, direct ou déclaré) sont des `showRyzeSheet`. Tout ce
/// qui touche au réseau reste dans les écrans eux-mêmes.
class SportStart {
  SportStart._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  static Future<T?> _push<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  /// Une séance de musculation vide, nommée par le jour.
  static Future<void> free(BuildContext context) {
    final now = DateTime.now();
    final name = 'workout_default_session_name'.tr(_lang).replaceAll('{day}', '${now.day}').replaceAll('{month}', '${now.month}');
    return _push(context, WorkoutSessionScreen(sessionName: name, exercises: const []));
  }

  /// Un programme, le tien ou celui de Ryze.
  static Future<void> program(BuildContext context, WorkoutProgram program) {
    final exercises = [
      for (final p in program.exercises)
        WorkoutExercise(
          exercise: p.exercise,
          sets: List.generate(p.sets, (_) => const ExerciseSet(reps: 0, weight: 0)),
          suggestedRepsMin: p.suggestedRepsMin,
          suggestedRepsMax: p.suggestedRepsMax,
        ),
    ];
    return _push(
      context,
      WorkoutSessionScreen(sessionName: program.name, exercises: exercises, isFromProgram: true, guidedTemplateId: program.id),
    );
  }

  /// Choisir un programme dans la bibliothèque, puis le lancer.
  static Future<void> pickProgram(BuildContext context) async {
    final picked = await SportProgramsPage.pick(context);
    if (picked == null || !context.mounted) return;
    await program(context, picked);
  }

  /// La séance de musculation prévue ce jour dans le planificateur.
  static Future<void> plannedWorkout(BuildContext context, PlannedWorkout w) {
    return _push(
      context,
      WorkoutSessionScreen(
        sessionName: w.workoutName,
        exercises: w.exercises,
        isFromAI: w.isAiGenerated,
        plannedWorkoutId: w.id,
      ),
    );
  }

  /// Reprendre une séance interrompue.
  static Future<void> resume(BuildContext context, SessionDraft draft) {
    return _push(context, WorkoutSessionScreen(sessionName: '', exercises: const [], draft: draft));
  }

  /// Coach Ryze, derrière son paywall (premier essai offert).
  static Future<void> coach(BuildContext context) async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.workoutGenerator,
      markAsUsed: false,
    );
    if (!canUse || !context.mounted) return;
    await _push(context, const AIWorkoutGeneratorScreen());
  }

  /// Le cardio prévu ce jour : on saute le choix de l'activité.
  static Future<void> plannedCardio(BuildContext context, PlannedActivity a) async {
    final data = a.cardioData;
    if (data == null) return cardio(context);
    if (data.isHiit) {
      final c = data.hiitConfig!;
      final total = ((c.workSeconds + c.restSeconds) * c.rounds / 60).ceil();
      return _push(
        context,
        HiitLiveScreen(
          workout: HiitWorkout(
            id: 'planned_${a.id}',
            title: data.activityName,
            description: '',
            workDuration: c.workSeconds,
            restDuration: c.restSeconds,
            totalDuration: total,
            totalRounds: c.rounds,
          ),
        ),
      );
    }
    CardioObjective? objective;
    if (data.targetKm != null && data.targetKm! > 0) {
      objective = CardioObjective(type: 'distance', targetDistance: data.targetKm, activityType: data.activityKey, formatTitle: data.activityName);
    } else if (data.targetMinutes != null && data.targetMinutes! > 0) {
      objective = CardioObjective(type: 'duration', targetDuration: Duration(minutes: data.targetMinutes!), activityType: data.activityKey, formatTitle: data.activityName);
    }
    final live = await _trackOrDeclare(context, trackable: true);
    if (live == null || !context.mounted) return;
    if (live) {
      await _push(context, CardioLiveScreen(activityType: data.activityKey, activityTitle: data.activityName, formatTitle: data.activityName, objective: objective));
    } else {
      await ManualCardioSheet.show(context, lang: _lang, activityType: data.activityKey, activityTitle: data.activityName, formatTitle: data.activityName, objective: objective);
    }
  }

  /// HIIT : le réglage, puis la séance.
  static Future<void> hiit(BuildContext context) async {
    final workout = await HiitSetupSheet.show(context, lang: _lang);
    if (workout == null || !context.mounted) return;
    await _push(context, HiitLiveScreen(workout: workout));
  }

  /// Cardio : activité → format → objectif → en direct ou déclaré.
  /// `declare` saute la question du direct : c'est « déclarer une séance ».
  static Future<void> cardio(BuildContext context, {bool declare = false}) async {
    final lang = _lang;
    List<CardioActivityType> activities;
    try {
      activities = await CardioService.getCardioActivities();
    } catch (_) {
      activities = const [];
    }
    if (!context.mounted) return;
    if (activities.isEmpty) {
      RyzeUndo.failed(context, message: 'cardio_no_activities_available'.tr(lang));
      return;
    }
    if (!declare) activities = activities.where((a) => a.activityKey != 'hiit').toList();

    final activity = await showRyzeSheet<CardioActivityType>(
      context,
      title: 'sport_choose_activity'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          for (var i = 0; i < activities.length; i++)
            RyzeSheetRow(
              first: i == 0,
              icon: _icon(activities[i].activityKey),
              label: activities[i].name,
              hint: activities[i].description,
              onTap: () => Navigator.pop(sheet, activities[i]),
            ),
        ],
      ),
    );
    if (activity == null || !context.mounted) return;

    if (activity.activityKey == 'hiit') return hiit(context);

    final formats = activity.formats;
    CardioActivityFormat? format;
    if (formats.length == 1) {
      format = formats.first;
    } else if (formats.isNotEmpty) {
      format = await showRyzeSheet<CardioActivityFormat>(
        context,
        title: activity.name,
        subtitle: 'sport_choose_format'.tr(lang),
        builder: (sheet) => RyzeSheetGroup(
          children: [
            for (var i = 0; i < formats.length; i++)
              RyzeSheetRow(
                first: i == 0,
                icon: formats[i].isTrackable ? LucideIcons.navigation : LucideIcons.pencilLine,
                label: formats[i].name,
                hint: formats[i].description,
                onTap: () => Navigator.pop(sheet, formats[i]),
              ),
          ],
        ),
      );
      if (format == null || !context.mounted) return;
    }
    final formatTitle = format?.name ?? activity.name;

    CardioObjective? objective;
    if (format != null && format.isConfigurable && (format.configType == 'distance' || format.configType == 'duration')) {
      objective = await _objective(context, activity: activity, format: format);
      if (!context.mounted) return;
    }

    bool? live;
    if (declare) {
      live = false;
    } else {
      live = await _trackOrDeclare(context, trackable: format?.isTrackable ?? true);
      if (live == null || !context.mounted) return;
    }
    if (live) {
      await _push(context, CardioLiveScreen(activityType: activity.activityKey, activityTitle: activity.name, formatTitle: formatTitle, objective: objective));
    } else {
      await ManualCardioSheet.show(context, lang: lang, activityType: activity.activityKey, activityTitle: activity.name, formatTitle: formatTitle, objective: objective);
    }
  }

  /// L'objectif d'un format qui en prend un : quelques valeurs, dont celle
  /// du format, et « sans objectif ».
  static Future<CardioObjective?> _objective(BuildContext context, {required CardioActivityType activity, required CardioActivityFormat format}) async {
    final lang = _lang;
    final distance = format.configType == 'distance';
    final values = distance
        ? {3.0, 5.0, 10.0, if (format.defaultDistanceKm != null) format.defaultDistanceKm!}.toList()
        : {15.0, 20.0, 30.0, 45.0, if (format.defaultDurationMinutes != null) format.defaultDurationMinutes!.toDouble()}.toList();
    values.sort();
    final key = distance ? 'sport_objective_km' : 'sport_objective_min';
    final picked = await showRyzeSheet<double>(
      context,
      title: 'sport_choose_objective'.tr(lang),
      subtitle: format.name,
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(first: true, icon: LucideIcons.minus, label: 'sport_objective_free'.tr(lang), onTap: () => Navigator.pop(sheet, -1.0)),
          for (final v in values)
            RyzeSheetRow(
              icon: distance ? LucideIcons.route : LucideIcons.timer,
              label: key.tr(lang).replaceAll('{n}', v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1)),
              onTap: () => Navigator.pop(sheet, v),
            ),
        ],
      ),
    );
    if (picked == null || picked < 0) return null;
    return distance
        ? CardioObjective(type: 'distance', targetDistance: picked, activityType: activity.activityKey, formatTitle: format.name)
        : CardioObjective(type: 'duration', targetDuration: Duration(minutes: picked.round()), activityType: activity.activityKey, formatTitle: format.name);
  }

  /// En direct (chrono, GPS) ou déclaré. Un format qui ne se suit pas ne
  /// pose pas la question.
  static Future<bool?> _trackOrDeclare(BuildContext context, {required bool trackable}) {
    if (!trackable) return Future.value(false);
    final lang = _lang;
    return showRyzeSheet<bool>(
      context,
      title: 'sport_track_or_declare'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(first: true, icon: LucideIcons.navigation, label: 'sport_track_session'.tr(lang), hint: 'sport_track_hint'.tr(lang), onTap: () => Navigator.pop(sheet, true)),
          RyzeSheetRow(icon: LucideIcons.pencilLine, label: 'sport_declare_session'.tr(lang), hint: 'sport_declare_hint'.tr(lang), onTap: () => Navigator.pop(sheet, false)),
        ],
      ),
    );
  }

  static IconData _icon(String key) {
    switch (key) {
      case 'running':
      case 'run':
        return LucideIcons.footprints;
      case 'bike':
      case 'cycling':
        return LucideIcons.bike;
      case 'walking':
      case 'walk':
        return LucideIcons.footprints;
      case 'swimming':
        return LucideIcons.waves;
      case 'hiit':
        return LucideIcons.zap;
      default:
        return LucideIcons.activity;
    }
  }
}
