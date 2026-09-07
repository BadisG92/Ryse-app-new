import 'package:intl/intl.dart';

import '../components/weekly_planner/week_strip.dart';
import '../services/translations.dart';

/// What the coach's one button does.
enum HomeAction { logBreakfast, logLunch, logSnack, logDinner, logMeal, drinkWater, startWorkout, viewDay, analyseDay, analyseYesterday }

/// The coach's line for right now, and the one action that follows from it.
///
/// The hour sets the frame, the day's state picks inside it: an unlogged meal
/// at its hour comes first, then water when the bottle is untouched, then a
/// session still waiting, then whatever is left of the calorie goal. There is
/// always exactly one sentence and one button, and the button always does
/// something: no hour of the day leaves the coach with nothing to offer.
class HomeSuggestion {
  const HomeSuggestion({required this.line, required this.cta, required this.action, required this.sport});

  /// One sentence. The greeting is the caller's business: the home says it
  /// once a day, not on top of every line.
  final String line;

  /// The button's label.
  final String cta;
  final HomeAction action;

  /// Which coach is talking: the sport coach for a session, the nutrition
  /// coach for everything else.
  final bool sport;

  static HomeSuggestion build({
    required String lang,
    required String name,
    required DaySlots today,
    required double waterL,
    required double waterGoalL,
    required int calories,
    required int calorieGoal,

    /// Vrai quand la journée a assez servi pour être lue par le coach.
    bool analysisOffered = false,

    /// Vrai quand elle a déjà été produite : le coach propose alors de la
    /// voir, pas de la relancer.
    bool analysisReady = false,

    /// Minuit est passé et la journée qui vient de finir vaut d'être lue.
    /// L'accueil le calcule sur les calories d'hier, que l'état global n'a
    /// plus : il a basculé de jour en même temps que l'horloge.
    bool nightReview = false,
    DateTime? now,
  }) {
    final h = (now ?? DateTime.now()).hour;
    final numbers = NumberFormat.decimalPattern(lang);

    bool done(WeekSlot s) => today.state(s) == SlotState.done;
    bool planned(WeekSlot s) => today.state(s) == SlotState.planned;

    HomeSuggestion say(String lineKey, String ctaKey, HomeAction action, {bool sport = false, Map<String, String> args = const {}}) {
      var line = lineKey.tr(lang);
      args.forEach((k, v) => line = line.replaceAll('{$k}', v));
      return HomeSuggestion(line: line, cta: ctaKey.tr(lang), action: action, sport: sport);
    }

    HomeSuggestion meal(WeekSlot s) => switch (s) {
          WeekSlot.breakfast => say('home_line_breakfast', 'cta_log_breakfast', HomeAction.logBreakfast),
          WeekSlot.lunch => say('home_line_lunch', 'cta_log_lunch', HomeAction.logLunch),
          WeekSlot.snack => say('home_line_snack', 'cta_log_snack', HomeAction.logSnack),
          _ => say('home_line_dinner', 'cta_log_dinner', HomeAction.logDinner),
        };

    /// La séance du jour n'est proposée que tant qu'elle n'est pas faite, donc
    /// le bouton la lance. Il disait « Voir ma séance » et ouvrait un récap où
    /// il fallait retrouver « Commencer » : deux taps pour ce que le coach
    /// vient d'annoncer. Regarder ce qu'il y a dedans reste possible d'un tap
    /// sur la pastille de la rangée du jour.
    HomeSuggestion workout() {
      final label = today.labels[WeekSlot.sport];
      return label == null || label.isEmpty
          ? say('home_line_workout_generic', 'cta_start_workout', HomeAction.startWorkout, sport: true)
          : say('home_line_workout', 'cta_start_workout', HomeAction.startWorkout, sport: true, args: {'name': label});
    }

    HomeSuggestion water() => say('home_line_water', 'cta_drink', HomeAction.drinkWater);

    /// La lecture de la journée, en fin de soirée. C'est le coach qui la
    /// porte, et lui seul : elle vivait avant dans un second bouton du
    /// journal, ce qui faisait deux coachs pour une seule voix.
    HomeSuggestion analysis() => analysisReady
        ? say('home_line_analysis_ready', 'cta_see_analysis', HomeAction.analyseDay)
        : say('home_line_analysis', 'cta_analyse_day', HomeAction.analyseDay);

    /// What is left of the goal, the goal met, or the goal passed. Three
    /// distinct states: the coach and the instrument above it must never say
    /// opposite things about the same number.
    HomeSuggestion rest() {
      final remaining = calorieGoal - calories;
      if (remaining > 0) {
        return say('home_line_remaining', 'cta_log_meal', HomeAction.logMeal, args: {'n': numbers.format(remaining)});
      }
      if (remaining == 0) return say('home_line_goal_done', 'cta_view_day', HomeAction.viewDay);
      return say('home_line_over', 'cta_view_day', HomeAction.viewDay, args: {'n': numbers.format(-remaining)});
    }

    final waterLow = waterGoalL > 0 && waterL / waterGoalL < 0.25;
    final waterUnfinished = waterGoalL > 0 && waterL < waterGoalL;
    final sessionWaiting = planned(WeekSlot.sport);

    if (h >= 5 && h < 11) {
      if (!done(WeekSlot.breakfast)) return meal(WeekSlot.breakfast);
      if (waterLow) return water();
      if (sessionWaiting) return workout();
      return rest();
    }
    if (h >= 11 && h < 14) {
      if (!done(WeekSlot.lunch)) return meal(WeekSlot.lunch);
      if (waterLow) return water();
      if (sessionWaiting) return workout();
      return rest();
    }
    if (h >= 14 && h < 18) {
      if (sessionWaiting) return workout();
      if (planned(WeekSlot.snack)) return meal(WeekSlot.snack);
      if (waterLow) return water();
      return rest();
    }
    if (h >= 18 && h < 22) {
      if (!done(WeekSlot.dinner)) return meal(WeekSlot.dinner);
      if (sessionWaiting) return workout();
      // the evening is the last chance to close the bottle, so it is checked
      // against the whole goal and not just against a quarter of it
      if (waterUnfinished) return water();
      if (analysisOffered) return analysis();
      return rest();
    }

    // 22 h – minuit. La journée finit, mais un dîner mangé et pas noté est
    // exactement ce qui arrive à cette heure : le coach le propose encore
    // plutôt que de rendre un cul-de-sac.
    if (h >= 22) {
      if (!done(WeekSlot.dinner)) return meal(WeekSlot.dinner);
      if (analysisOffered) return analysis();
      if (waterUnfinished) return water();
      return say('home_line_night', 'cta_view_day', HomeAction.viewDay);
    }

    // Minuit passé. L'application bascule de journée sur l'horloge locale :
    // à 0 h 30, « today » est un jour vieux de trente minutes, dont rien ne
    // peut être en retard. Le coach proposait pourtant d'enregistrer son
    // dîner — un dîner à vingt heures de là.
    //
    // À cette heure, la seule journée dont on puisse parler est celle qui
    // vient de finir. Si elle a de quoi être lue, le coach la lit ; sinon il
    // souhaite bonne nuit, et c'est tout ce qu'il y a d'honnête à dire.
    if (nightReview) return say('home_line_analysis_night', 'cta_analyse_yesterday', HomeAction.analyseYesterday);
    return say('home_line_night', 'cta_view_day', HomeAction.viewDay);
  }
}
