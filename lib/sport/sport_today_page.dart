import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../components/weekly_planner/cardio_recap_bottom_sheet.dart';
import '../components/weekly_planner/workout_recap_bottom_sheet.dart';
import '../design/design.dart';
import '../home/home_slots.dart';
import '../models/sport_models.dart';
import '../models/weekly_planner_models.dart';
import '../screens/planner_chat_screen.dart';
import '../services/database_service.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import '../services/weekly_planner_service.dart';
import '../services/workout_session_store.dart';
import 'sheets/goal_sheet.dart';
import 'sheets/session_recap_sheet.dart';
import 'sheets/start_session_sheet.dart';
import 'sport_data.dart';
import 'sport_goal.dart';
import 'sport_start.dart';
import 'widgets/pending_sync_line.dart';
import 'widgets/resume_session_card.dart';
import 'widgets/session_timeline.dart';
import 'widgets/week_rings.dart';

/// La journée sportive, lue comme une seule chose.
///
/// En haut, la semaine : combien de séances, sept anneaux, l'objectif si
/// l'utilisateur en a fixé un. Dessous, la séance du jour dans l'un de quatre
/// états — en cours, prévue, faite, rien — avec un seul bouton. Rien de plus :
/// les séances passées sont l'affaire de l'Historique, une position à droite.
class SportTodayPage extends StatefulWidget {
  const SportTodayPage({super.key});

  @override
  State<SportTodayPage> createState() => _SportTodayPageState();
}

class _SportTodayPageState extends State<SportTodayPage> with GlobalStateListener {
  SportWeek _week = SportWeek.empty;
  Map<String, Set<SportKind>> _kinds = const {};
  List<SportSessionRow> _today = const [];
  WeeklyPlannerData? _plan;
  SessionDraft? _draft;
  List<WorkoutProgram> _redo = const [];
  bool _loaded = false;

  /// Vrai des qu'il y a des chiffres a montrer : ceux gardes sur le telephone
  /// ou ceux du reseau. Faux, la semaine s'ecrit d'un tiret.
  bool _known = false;

  final ScrollController _scroll = ScrollController();

  /// Lundi → dimanche de cette semaine.
  List<DateTime> get _days {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
  }

  @override
  void initState() {
    super.initState();
    _restore();
    _load();
  }

  /// Ce que le telephone sait deja, sans reseau : la semaine de la derniere
  /// lecture et le brouillon de seance. La page s'ouvre pleine, puis se
  /// corrige quand le reseau repond.
  Future<void> _restore() async {
    final snap = await SportData.lastKnown();
    if (!mounted || snap == null || _loaded) return;
    setState(() {
      _week = snap.week;
      _kinds = snap.kinds;
      _known = true;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    switch (event.type) {
      case ChangeType.workout:
      case ChangeType.sport:
      case ChangeType.planner:
      case ChangeType.dayReset:
      case ChangeType.batch:
        _load();
      default:
        break;
    }
  }

  /// Ce qui dessine la page. Les programmes en sont sortis : ils ne servent
  /// qu'aux puces « Refaire » de la feuille de depart, et leurs six secondes
  /// d'attente etaient dans le chemin de la premiere image.
  Future<void> _load() async {
    final now = DateTime.now();
    final days = _days;
    unawaited(_loadRedo());
    final results = await Future.wait<Object?>([
      SportData.week(),
      SportData.kinds(from: days.first, to: days.last),
      SportData.onDay(now),
      WorkoutSessionStore.instance.loadDraft(),
      WeeklyPlannerService.getWeekData().then<WeeklyPlannerData?>((w) => w).catchError((_) => null),
    ]);
    if (!mounted) return;
    final week = results[0] as SportWeek;
    final kinds = results[1] as Map<String, Set<SportKind>>;
    setState(() {
      _week = week;
      _kinds = kinds;
      _today = results[2] as List<SportSessionRow>;
      _draft = results[3] as SessionDraft?;
      _plan = results[4] as WeeklyPlannerData?;
      _loaded = true;
      _known = true;
    });
    unawaited(SportData.remember(week, kinds));
  }

  /// Les programmes de l'utilisateur, pour « Refaire ». Sans eux la feuille
  /// de depart s'ouvre quand meme, avec les facons de commencer.
  Future<void> _loadRedo() async {
    try {
      final all = await DatabaseService.getWorkoutTemplates(
        language: LocalizationService.instance.currentLanguageCode,
        includePublic: false,
      ).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      setState(() => _redo = all.where((p) => p.isCustom).take(3).toList());
    } catch (e) {
      debugPrint('SportTodayPage._loadRedo: $e');
    }
  }

  String get _lang => LocalizationService.instance.currentLanguageCode;

  // --------------------------------------------------------------- actions

  Future<void> _start() async {
    final choice = await StartSessionSheet.show(context, lang: _lang, redo: _redo);
    if (choice == null || !mounted) return;
    switch (choice.kind) {
      case StartKind.free:
        await SportStart.free(context);
      case StartKind.program:
        await SportStart.pickProgram(context);
      case StartKind.redo:
        await SportStart.program(context, choice.program!);
      case StartKind.coach:
        await SportStart.coach(context);
      case StartKind.cardio:
        await SportStart.cardio(context);
      case StartKind.hiit:
        await SportStart.hiit(context);
      case StartKind.declare:
        await SportStart.cardio(context, declare: true);
    }
    _load();
  }

  Future<void> _resume() async {
    final draft = _draft;
    if (draft == null) return;
    await SportStart.resume(context, draft);
    _load();
  }

  Future<void> _discardDraft() async {
    await WorkoutSessionStore.instance.clearDraft();
    _load();
  }

  Future<void> _startPlanned(HomeSession s) async {
    if (s.workout != null) {
      await SportStart.plannedWorkout(context, s.workout!);
    } else if (s.cardio != null) {
      await SportStart.plannedCardio(context, s.cardio!);
    }
    _load();
  }

  /// Voir ce qu'il y a dans la séance prévue avant de la lancer : le récap,
  /// le même que l'accueil ouvre.
  Future<void> _showPlanned(HomeSession s) async {
    if (s.workout != null) {
      await WorkoutRecapBottomSheet.show(context, workout: s.workout!);
    } else if (s.cardio != null) {
      await CardioRecapBottomSheet.show(context, activity: s.cardio!);
    }
    _load();
  }

  Future<void> _openPlanner() async {
    final week = _plan ?? await WeeklyPlannerService.getWeekData();
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlannerChatScreen(initialMode: 'workouts', weekData: week),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: RyzeDurations.enter,
        reverseTransitionDuration: RyzeDurations.enter,
      ),
    );
    _load();
  }

  Future<void> _goal() async {
    final picked = await GoalSheet.show(context, lang: _lang, current: _week.goal);
    if (picked == null || !mounted) return;
    await SportGoal.save(picked == 0 ? null : picked);
    RyzeFeedback.select();
    _load();
  }

  /// Un jour de la semaine qui a une séance : la seule, ou le choix.
  Future<void> _openDay(DateTime day) async {
    final rows = await SportData.onDay(day);
    if (!mounted || rows.isEmpty) return;
    if (rows.length == 1) return _open(rows.first);
    final lang = _lang;
    final picked = await showRyzeSheet<SportSessionRow>(
      context,
      title: RyzeDates.full(day, lang),
      subtitle: 'sport_sessions_n'.tr(lang).replaceAll('{n}', '${rows.length}'),
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final r in rows) SessionRow(lang: lang, row: r, onTap: () => Navigator.pop(sheet, r), showDate: false)],
      ),
    );
    if (picked != null && mounted) await _open(picked);
  }

  Future<void> _open(SportSessionRow row) async {
    final lang = _lang;
    final action = await SessionRecapSheet.show(context, lang: lang, row: row);
    if (!mounted) return;
    if (action == RecapAction.delete) {
      setState(() => _today = _today.where((r) => r.id != row.id).toList());
      SessionDeletion.schedule(context, lang: lang, row: row, onRestore: _load, onDeleted: _load);
    } else if (action == RecapAction.edited) {
      _load();
    }
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final w = _week;
    final goal = w.goal;

    return Stack(
      children: [
        ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(gutter, context.vw(2), gutter, 132),
          children: [
            PopIn(
              delay: const Duration(milliseconds: 60),
              dy: 8,
              child: _todayBlock(context, lang),
            ),
            SizedBox(height: context.vw(7)),
            PopIn(
              delay: const Duration(milliseconds: 320),
              dy: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WeekBlock(
                    lang: lang,
                    days: _days,
                    kinds: _kinds,
                    sessions: w.sessions,
                    minutes: w.minutes,
                    kcal: w.kcal,
                    streak: w.streak,
                    goal: goal,
                    loaded: _known,
                    onDay: _openDay,
                    onGoal: _goal,
                    onPlan: _openPlanner,
                  ),
                  PendingSyncLine(lang: lang, compact: false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// La séance du jour : en cours, prévue, faite, ou rien. Un seul bouton
  /// dans chaque état ; le « + » du titre sert à commencer autre chose.
  Widget _todayBlock(BuildContext context, String lang) {
    final draft = _draft;
    final planned = HomeSlots.session(_plan?.getDayPlan(DateTime.now()));
    final waiting = planned != null && planned.status != PlannedStatus.completed;
    final showPlus = draft == null && (waiting || _today.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('sport_session_of_day'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600))),
            if (showPlus)
              Semantics(
                label: 'sport_another_session'.tr(lang),
                button: true,
                child: Pressable(
                  onTap: _start,
                  child: Container(
                    width: context.vw(8.7),
                    height: context.vw(8.7),
                    decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
                    child: Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.ink),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.vw(2.6)),
        if (draft != null)
          ResumeSessionCard(lang: lang, draft: draft, onResume: _resume, onDiscard: _discardDraft)
        else if (waiting)
          _PlannedCard(
            lang: lang,
            session: planned,
            onOpen: () => _showPlanned(planned),
            onStart: () => _startPlanned(planned),
          )
        else if (_today.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final row in _today) SessionRow(lang: lang, row: row, onTap: () => _open(row), showDate: false)],
          )
        else if (!_loaded)
          // Tant qu'on n'a pas lu, on ne dit rien. La carte « rien de prevu »
          // s'affichait pendant la lecture puis cedait la place a la vraie
          // seance : l'application annoncait une absence qu'elle n'avait pas
          // encore verifiee.
          const _PendingCard()
        else
          _EmptyCard(lang: lang, onStart: _start),
      ],
    );
  }
}

/// La séance prévue : le nom, ce qu'elle contient, *Commencer*. La carte se
/// presse pour voir les exercices avant de partir.
class _PlannedCard extends StatelessWidget {
  const _PlannedCard({required this.lang, required this.session, required this.onOpen, required this.onStart});

  final String lang;
  final HomeSession session;
  final VoidCallback onOpen;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final w = session.workout;
    final kind = w != null ? SportKind.strength : SportKind.cardio;
    final String hint;
    if (w != null) {
      hint = 'sport_exercises_n_min'.tr(lang).replaceAll('{n}', '${w.exercises.length}').replaceAll('{min}', '${w.durationMinutes ?? 0}');
    } else {
      final m = session.cardio?.cardioData?.targetMinutes;
      hint = m != null ? 'sport_objective_min'.tr(lang).replaceAll('{n}', '$m') : 'sport_kind_cardio'.tr(lang);
    }

    return Container(
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: onOpen,
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.6), context.vw(2.6), context.vw(1)),
              child: Row(
                children: [
                  SessionRing(kind: kind, size: 16),
                  SizedBox(width: context.vw(3.1)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                        SizedBox(height: context.vw(0.5)),
                        Text(
                          '${'home_session_planned'.tr(lang)} · $hint',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: context.vw(4.6), color: RyzeColors.mute2),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(2.1), context.vw(4.1), context.vw(4.1)),
            child: _InkButton(label: 'sport_planned_start'.tr(lang), onTap: onStart),
          ),
        ],
      ),
    );
  }
}

/// Rien de prévu : démarrer, ou laisser Ryze planifier la semaine.
/// La place de la carte, le temps de la lecture. Elle en a la hauteur, pour
/// que rien ne saute quand la vraie arrive.
class _PendingCard extends StatelessWidget {
  const _PendingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.vw(31),
      decoration: BoxDecoration(
        color: RyzeColors.surf.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.lang, required this.onStart});

  final String lang;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.vw(4.1)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('sport_nothing_planned'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
          SizedBox(height: context.vw(3.6)),
          _InkButton(label: 'sport_start_session'.tr(lang), onTap: onStart),
        ],
      ),
    );
  }
}

class _InkButton extends StatelessWidget {
  const _InkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: context.vw(12.3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RyzeColors.ink,
          borderRadius: BorderRadius.circular(RyzeRadius.sm),
          boxShadow: RyzeShadow.soft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.play, size: context.vw(4.1), color: RyzeColors.surf),
            SizedBox(width: context.vw(2.1)),
            Text(label, style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
          ],
        ),
      ),
    );
  }
}
