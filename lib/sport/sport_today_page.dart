import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../home/home_slots.dart';
import '../models/sport_models.dart';
import '../models/weekly_planner_models.dart';
import '../services/database_service.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/weekly_planner_service.dart';
import '../services/workout_session_store.dart';
import 'sheets/session_recap_sheet.dart';
import 'sheets/start_session_sheet.dart';
import 'sport_data.dart';
import 'sport_start.dart';
import 'widgets/pending_sync_line.dart';
import 'widgets/resume_session_card.dart';
import 'widgets/session_timeline.dart';

/// La journée sportive, lue comme une seule chose.
///
/// L'instrument dit où en est la semaine face à l'objectif de l'onboarding ;
/// la carte du jour est dans l'un de quatre états (en cours, prévue, faite,
/// rien) ; la feuille de départ ramène les huit façons de commencer à une ;
/// les dernières séances sont sur le rail. Quand l'instrument sort de
/// l'écran, la barre collante le ramène.
class SportTodayPage extends StatefulWidget {
  const SportTodayPage({super.key});

  @override
  State<SportTodayPage> createState() => _SportTodayPageState();
}

class _SportTodayPageState extends State<SportTodayPage> with GlobalStateListener {
  SportWeek _week = SportWeek.empty;
  List<SportSessionRow> _recent = const [];
  List<SportSessionRow> _today = const [];
  DayPlanData? _plan;
  SessionDraft? _draft;
  List<WorkoutProgram> _redo = const [];
  bool _shown = false;

  final ScrollController _scroll = ScrollController();
  bool _stuck = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _shown = true);
      });
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

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final past = _scroll.offset > context.vw(26);
    if (past != _stuck) setState(() => _stuck = past);
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final results = await Future.wait<Object?>([
      SportData.week(),
      SportData.recent(limit: 3),
      SportData.onDay(now),
      WorkoutSessionStore.instance.loadDraft(),
      WeeklyPlannerService.getWeekData().then<WeeklyPlannerData?>((w) => w).catchError((_) => null),
      DatabaseService.getWorkoutTemplates(language: LocalizationService.instance.currentLanguageCode, includePublic: false)
          .timeout(const Duration(seconds: 6))
          .then<List<WorkoutProgram>>((l) => l)
          .catchError((_) => <WorkoutProgram>[]),
    ]);
    if (!mounted) return;
    final week = results[4] as WeeklyPlannerData?;
    final programs = (results[5] as List<WorkoutProgram>).where((p) => p.isCustom).take(3).toList();
    setState(() {
      _week = results[0] as SportWeek;
      _recent = results[1] as List<SportSessionRow>;
      _today = results[2] as List<SportSessionRow>;
      _draft = results[3] as SessionDraft?;
      _plan = week?.getDayPlan(now);
      _redo = programs;
    });
  }

  // --------------------------------------------------------------- actions

  Future<void> _start() async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final choice = await StartSessionSheet.show(context, lang: lang, redo: _redo);
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

  Future<void> _open(SportSessionRow row) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final action = await SessionRecapSheet.show(context, lang: lang, row: row);
    if (!mounted) return;
    if (action == RecapAction.delete) {
      setState(() {
        _recent = _recent.where((r) => r.id != row.id).toList();
        _today = _today.where((r) => r.id != row.id).toList();
      });
      SessionDeletion.schedule(context, lang: lang, row: row, onRestore: _load, onDeleted: _load);
    } else if (action == RecapAction.edited) {
      _load();
    }
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final numbers = NumberFormat.decimalPattern(lang);
    final gutter = context.vw(5.1);
    final w = _week;
    final remaining = w.goal - w.sessions;
    final lead = remaining < 0 ? 'sport_over_week'.tr(lang) : (remaining == 0 ? 'sport_week_met'.tr(lang) : 'sport_left_week'.tr(lang));
    final time = w.minutes >= 60 ? '${w.minutes ~/ 60} h ${(w.minutes % 60).toString().padLeft(2, '0')}' : '${w.minutes} min';

    return Stack(
      children: [
        ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(gutter, context.vw(2), gutter, 132),
          children: [
            PopIn(
              delay: const Duration(milliseconds: 60),
              dy: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DayInstrument(
                    lead: lead,
                    unit: 'sport_sessions_unit'.tr(lang),
                    eatenLabel: 'sport_done_n'.tr(lang).replaceAll('{n}', '${w.sessions}'),
                    goalLabel: 'sport_goal_n'.tr(lang).replaceAll('{n}', '${w.goal}'),
                    calories: w.sessions,
                    calorieGoal: w.goal,
                    shown: _shown,
                  ),
                  SizedBox(height: context.vw(2.1)),
                  Text(
                    [
                      'sport_week_line'.tr(lang).replaceAll('{time}', time).replaceAll('{kcal}', numbers.format(w.kcal)),
                      if (w.streak > 1) 'sport_week_streak'.tr(lang).replaceAll('{n}', '${w.streak}'),
                    ].join(' · '),
                    style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  PendingSyncLine(lang: lang, compact: false),
                ],
              ),
            ),
            SizedBox(height: context.vw(7)),
            PopIn(
              delay: const Duration(milliseconds: 320),
              dy: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BlockHeader(title: 'sport_today_block'.tr(lang)),
                  SizedBox(height: context.vw(2.6)),
                  _todayCard(context, lang),
                ],
              ),
            ),
            SizedBox(height: context.vw(7)),
            PopIn(
              delay: const Duration(milliseconds: 500),
              dy: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BlockHeader(title: 'sport_last_sessions'.tr(lang)),
                  SizedBox(height: context.vw(1)),
                  if (_recent.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.vw(4), horizontal: context.vw(2)),
                      child: Text('sport_no_sessions_yet'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
                    )
                  else
                    SessionTimeline(lang: lang, rows: _recent, onTap: _open),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: StickyTotal(
            shown: _stuck,
            lead: lead,
            value: '${remaining.abs()}',
            unit: 'sport_sessions_unit'.tr(lang),
            fraction: w.goal > 0 ? w.sessions / w.goal : 0,
          ),
        ),
      ],
    );
  }

  /// La carte du jour : en cours, prévue, faite, ou rien.
  Widget _todayCard(BuildContext context, String lang) {
    final draft = _draft;
    if (draft != null) {
      return ResumeSessionCard(lang: lang, draft: draft, onResume: _resume, onDiscard: _discardDraft);
    }
    final planned = HomeSlots.session(_plan);
    if (planned != null && planned.status != PlannedStatus.completed) {
      final w = planned.workout;
      final hint = w != null
          ? 'sport_exercises_n_min'.tr(lang).replaceAll('{n}', '${w.exercises.length}').replaceAll('{min}', '${w.durationMinutes ?? 0}')
          : (planned.cardio?.cardioData?.targetMinutes != null ? 'sport_objective_min'.tr(lang).replaceAll('{n}', '${planned.cardio!.cardioData!.targetMinutes}') : 'sport_kind_cardio'.tr(lang));
      return _TodayCard(
        ring: SessionRing(kind: w != null ? SportKind.strength : SportKind.cardio),
        title: planned.label,
        hint: hint,
        action: 'sport_planned_start'.tr(lang),
        onTap: () => _startPlanned(planned),
        secondary: 'sport_start_session'.tr(lang),
        onSecondary: _start,
      );
    }
    // Le jour a déjà ses séances : elles sont la carte, et on peut en ajouter.
    if (_today.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in _today) SessionRow(lang: lang, row: row, onTap: () => _open(row), showDate: false),
          _GhostButton(label: 'sport_start_session'.tr(lang), onTap: _start),
        ],
      );
    }
    return _TodayCard(
      ring: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: RyzeColors.idle, shape: BoxShape.circle, border: Border.all(color: RyzeColors.idle)),
      ),
      title: 'sport_nothing_planned'.tr(lang),
      hint: null,
      action: 'sport_start_session'.tr(lang),
      onTap: _start,
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.ring, required this.title, required this.hint, required this.action, required this.onTap, this.secondary, this.onSecondary});

  final Widget ring;
  final String title;
  final String? hint;
  final String action;
  final VoidCallback onTap;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(context.vw(4.1)),
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ring,
                  SizedBox(width: context.vw(3.1)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                        if (hint != null) ...[
                          SizedBox(height: context.vw(0.5)),
                          Text(hint!, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.vw(3.6)),
              Pressable(
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
                      Text(action, style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (secondary != null) _GhostButton(label: secondary!, onTap: onSecondary!),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.vw(2.1)),
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: context.vw(11.3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RyzeRadius.sm),
            border: Border.all(color: RyzeColors.idle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.ink),
              SizedBox(width: context.vw(1.5)),
              Text(label, style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: RyzeText.body(context, 3.9, weight: FontWeight.w600));
  }
}
