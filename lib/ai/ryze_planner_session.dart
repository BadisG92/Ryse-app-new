import 'package:flutter/foundation.dart';

import '../models/weekly_planner_models.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/planner_ai_service.dart';
import '../services/translations.dart';
import 'prompts/persona_strings.dart';
import 'ryze_agent.dart';
import 'ryze_context.dart';
import 'ryze_context_source.dart';
import 'ryze_events.dart';
import 'ryze_persona.dart';
import 'ryze_tools/ryze_tools.dart';

/// Le planificateur, sur le même moteur que la conversation.
///
/// Il avait le sien : un prompt de deux cents lignes par mode, son propre
/// client HTTP sans délai d'expiration, ses vingt-trois outils, et surtout
/// aucune personnalité — le ton choisi par l'utilisateur n'existait pas de ce
/// côté, et le journal non plus.
///
/// Ce qui reste à lui, c'est sa mise en scène : la bande des jours, les cartes
/// feuilletées par jour, les boutons de validation. Ce qui devient commun,
/// c'est tout le reste. Les deux surfaces ne se distinguent plus par ce
/// qu'elles savent faire, mais par ce qu'elles montrent.
class RyzePlannerSession {
  RyzePlannerSession({required this.mode, required this.weekStart}) {
    PlannerAIService.setPlanningWindow(weekStart);
    _agent = RyzeAgent(config: RyzeGenerationConfig.planner)
      ..systemInstructionBuilder = _buildSystemInstruction
      ..tools = ryzeTools.declarationsFor(RyzeSurface.planner);
  }

  /// `meals` ou `workouts` : de quoi on parle sur cet écran.
  final String mode;

  /// Le premier des sept jours affichés.
  final DateTime weekStart;

  late final RyzeAgent _agent;

  String get _lang => LocalizationService.instance.currentLanguageCode;

  void dispose() {
    _agent.dispose();
    PlannerAIService.setPlanningWindow(null);
  }

  /// Une note pour le modèle après une validation, sans aller-retour.
  void note(String text) => _agent.note(text);

  // ---------------------------------------------------------------- envoi

  Stream<CoachEvent> send(String text) async* {
    final meals = <PendingMeal>[];
    final sessions = <PendingSession>[];

    try {
      await for (final event in _agent.send(text)) {
        switch (event) {
          case RyzeTextDelta(:final text):
            yield CoachText(text);

          case RyzeToolCall():
            yield* _runTool(event, meals, sessions);

          case RyzeError(:final messageKey):
            yield CoachFailure(messageKey.tr(_lang));
            return;

          case RyzeDone():
            break;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzePlannerSession : $e');
      yield CoachFailure('coach_error_generic'.tr(_lang));
      return;
    }

    // Les propositions arrivent groupées : l'écran les feuillette par jour, il
    // lui faut la fournée entière.
    if (meals.isNotEmpty || sessions.isNotEmpty) {
      yield CoachProposals(meals: meals, sessions: sessions);
    }
  }

  Stream<CoachEvent> _runTool(
    RyzeToolCall call,
    List<PendingMeal> meals,
    List<PendingSession> sessions,
  ) async* {
    final tool = ryzeTools.byName(call.name);
    if (tool == null) {
      _agent.addToolResults([
        (name: call.name, response: {'ok': false, 'error': 'unknown tool'})
      ]);
      return;
    }

    // Une création se montre dans les pages de l'écran, pas en carte : c'est
    // là toute la différence entre les deux surfaces. Rien n'est écrit ici —
    // l'exécuteur bâtit l'objet, la validation viendra du bouton.
    if (call.name.startsWith('plan.create')) {
      final result = await tool.execute(call.args);
      final payload = result.payload;
      if (payload is PendingMeal) meals.add(payload);
      if (payload is PendingSession) sessions.add(payload);

      _agent.addToolResults([(name: call.name, response: result.toResponse())]);
      return;
    }

    if (tool.needsConfirmation(call.args) && tool.preview != null) {
      final pending = await tool.preview!(call.args);
      _agent.addToolResults([
        (name: call.name, response: {'ok': false, 'status': 'awaiting_user_validation'})
      ]);
      yield CoachAsk(pending);
      return;
    }

    final result = await tool.execute(call.args);
    _agent.addToolResults([(name: call.name, response: result.toResponse())]);
    yield CoachAction(result.summary, ok: result.ok, toolName: call.name);
  }

  // ------------------------------------------------------- l'instruction

  Future<String> _buildSystemInstruction() async {
    final strings = RyzePersona.of(_lang);

    final context = await RyzeContextSource.instance.build(strings);
    final window = await _window(strings);

    return RyzePersona.build(
      lang: _lang,
      surface: RyzeSurface.planner,
      userName: GlobalStateManager.instance.userName,
      context: [context, window].where((s) => s.trim().isNotEmpty).join('\n\n'),
      surfaceRules: _rules(strings),
    );
  }

  /// Les règles propres à l'écran, courtes.
  ///
  /// L'ancien prompt en faisait deux cents lignes par mode : listes de
  /// mots-clés par langue, exemples avant-après, et des consignes qui
  /// répétaient ce que les descriptions d'outils disent déjà. Tout cela
  /// repartait à chaque tour.
  String _rules(PersonaStrings s) {
    final planningMeals = mode == 'meals';
    return '''
## ${planningMeals ? 'PLANNING MEALS' : 'PLANNING TRAINING'}
You are on the planning screen. The user came here to fill days ahead, not to log what already happened.

${planningMeals ? '''
- Spread the day's calories using the table below, and let daily totals vary naturally: a training day carries more, a rest day slightly less.
- Vary the dishes. The same meal twice in a week is a plan nobody follows.
- Use realistic quantities: 100 g, 2 eggs, one chicken breast. Never 127.3 g.
- When the user names a food, that exact food goes in the dish. Never substitute it.
- Asked for several days, plan every available day: breakfast, lunch and dinner for each.''' : '''
- Ask for the muscle group and the length when they are missing; choose the days yourself when the user does not care.
- Space the same muscle group by at least one day.
- Only running, cycling, walking and HIIT exist as cardio. Anything else, say so and offer the closest.'''}
- Only the available days below. The past cannot be planned.''';
  }

  /// Ce qu'il reste à remplir, et les cibles par repas.
  Future<String> _window(PersonaStrings s) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const names = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final available = <String>[];
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (!DateTime(day.year, day.month, day.day).isBefore(today)) {
        available.add(names[day.weekday - 1]);
      }
    }

    final lines = <String>['AVAILABLE DAYS: ${available.join(', ')}'];

    if (mode == 'meals') {
      final targets = GlobalStateManager.instance;
      final kcal = targets.calorieGoal.round();
      final protein = targets.proteinGoal;
      final carbs = targets.carbsGoal;
      final fats = targets.fatGoal;

      // Une seule répartition, celle du service : la prose et le tableau se
      // contredisaient dans la même requête.
      lines.add('DAILY TARGET: $kcal kcal · P ${protein}g · C ${carbs}g · F ${fats}g');
      lines.add('PER MEAL, aim for these shares of the day:');
      for (final entry in PlannerAIService.mealSplit.entries) {
        final part = entry.value;
        lines.add('  ${entry.key}: ${(kcal * part).round()} kcal · '
            'P ${(protein * part).round()}g · C ${(carbs * part).round()}g · F ${(fats * part).round()}g');
      }
      lines.add('These are targets, not exact values. Prefer an honest recipe over a perfect number.');
    }

    return '## ${s.label('section_planner_window')}\n${lines.join('\n')}';
  }

  /// Le contexte de l'écran est refait quand la semaine bouge.
  static void invalidate() =>
      RyzeContext.instance.invalidate({RyzeBlock.weekPlan, RyzeBlock.plannerWindow, RyzeBlock.today});
}
