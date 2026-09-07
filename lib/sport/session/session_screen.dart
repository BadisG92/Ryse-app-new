import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bottom_sheets/exercise_info_bottom_sheet.dart';
import '../../design/design.dart';
import '../../models/sport_models.dart';
import '../../services/auth_service.dart';
import '../../services/calorie_burn_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/workout_session_store.dart';
import '../../widgets/exercise/exercise_detail_page.dart';
import 'session_controller.dart';
import 'session_history.dart';
import 'session_models.dart';
import 'session_voice.dart';
import 'sheets/exercise_menu_sheet.dart';
import 'sheets/exercise_picker_sheet.dart';
import 'sheets/finish_sheet.dart';
import 'sheets/leave_sheet.dart';
import 'widgets/exercise_card.dart';
import 'widgets/session_bottom_bar.dart';
import 'widgets/session_header.dart';

/// La séance de musculation, en direct.
///
/// Même nom et même constructeur que l'ancien écran (moins ses six
/// paramètres d'édition, jamais passés), plus `draft` pour reprendre une
/// séance interrompue. L'écran ne possède rien : l'état vit dans
/// `SessionController`, le brouillon dans `WorkoutSessionStore`, et chaque
/// mutation est déjà sur le téléphone avant qu'on ait fini de la regarder.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.sessionName,
    required this.exercises,
    this.isFromProgram = false,
    this.guidedTemplateId,
    this.isFromAI = false,
    this.plannedWorkoutId,
    this.onProgramSaved,
    this.onSessionCompleted,
    this.draft,
  });

  final String sessionName;
  final List<WorkoutExercise> exercises;
  final bool isFromProgram;
  final String? guidedTemplateId;
  final bool isFromAI;
  final String? plannedWorkoutId;

  /// Gardé pour ses deux appelants de l'ancien onglet, qui disparaissent avec
  /// lui : l'enregistrement comme programme passe désormais par le store
  /// (`saveUserWorkoutTemplate` au rejeu), pas par ce rappel.
  final Function(WorkoutProgram)? onProgramSaved;
  final Function(WorkoutSession)? onSessionCompleted;

  /// Une séance interrompue à reprendre ; les autres paramètres sont ignorés.
  final SessionDraft? draft;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> with WidgetsBindingObserver {
  late final SessionController _c;
  late final SessionVoice _voice;
  final ScrollController _scroll = ScrollController();
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final draft = widget.draft;
    if (draft != null) {
      _c = SessionController(
        session: LiveSession.fromJson(draft.session),
        current: draft.current,
        restEndsAt: draft.restEndsAt,
      );
    } else {
      _c = SessionController(
        session: LiveSession(
          id: SessionController.newId(),
          name: widget.sessionName,
          startedAt: DateTime.now(),
          exercises: [for (final e in widget.exercises) LiveExercise.fromWorkout(e)],
          isFromProgram: widget.isFromProgram,
          isFromAI: widget.isFromAI,
          guidedTemplateId: widget.guidedTemplateId,
          plannedWorkoutId: widget.plannedWorkoutId,
        ),
      );
    }
    _voice = SessionVoice(onFilled: _onVoiceFilled);
    _c.addListener(_onChanged);
    _voice.addListener(_onChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_onChanged);
    _voice.removeListener(_onChanged);
    _voice.dispose();
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _c.onResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _c.flushDraft();
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String get _lang => LocalizationService.instance.currentLanguageCode;

  // ------------------------------------------------------------- exercices

  Future<void> _openExercise(int i) async {
    _c.open(i);
    await Future<void>.delayed(RyzeDurations.enter);
    if (!mounted || !_scroll.hasClients) return;
    // La carte ouverte remonte en vue, sans bousculer si elle y est déjà.
    final key = _keys[i];
    final ctx = key?.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx, alignment: 0.05, duration: RyzeDurations.enter, curve: RyzeCurves.out);
    }
  }

  final Map<int, GlobalKey> _keys = {};
  GlobalKey _keyFor(int i) => _keys.putIfAbsent(i, GlobalKey.new);

  Future<void> _addExercise() async {
    _c.closePad();
    final picked = await ExercisePickerSheet.show(context, lang: _lang);
    if (picked == null || !mounted) return;
    _c.addExercise(picked);
    _openExercise(_c.session.exercises.length - 1);
  }

  Future<void> _menu(int i) async {
    final lang = _lang;
    final ex = _c.session.exercises[i];
    final choice = await ExerciseMenuSheet.show(
      context,
      lang: lang,
      exercise: ex,
      restSeconds: _c.session.restSeconds,
      onRestChanged: _c.setRest,
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case ExerciseMenuChoice.progression:
        _progression(ex);
      case ExerciseMenuChoice.info:
        ExerciseInfoBottomSheet.show(context, exerciseId: ex.exercise.id, exerciseName: ex.exercise.name);
      case ExerciseMenuChoice.replace:
        final picked = await ExercisePickerSheet.show(context, lang: lang, replacing: ex.exercise);
        if (picked == null || !mounted) return;
        _c.replaceExercise(i, picked);
      case ExerciseMenuChoice.remove:
        _c.removeExercise(i);
        RyzeFeedback.removed();
        RyzeUndo.show(
          context,
          message: 'session_exercise_removed'.tr(lang).replaceAll('{name}', ex.exercise.name),
          undoLabel: 'undo'.tr(lang),
          onUndo: _c.restoreExercise,
        );
    }
  }

  void _progression(LiveExercise ex) {
    _c.flushDraft();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExerciseDetailPage(exerciseName: ex.exercise.name)),
    );
  }

  // ------------------------------------------------------------------ voix

  Future<void> _mic() async {
    final i = _c.editingSet;
    if (i == null) return;
    if (_voice.listening) {
      await _voice.stop();
      return;
    }
    final ok = await _voice.start(i);
    if (!ok && mounted) {
      RyzeUndo.failed(context, message: 'session_mic_unavailable'.tr(_lang));
    }
  }

  void _onVoiceFilled(int setIndex, int? reps, double? weightKg) {
    final ex = _c.currentExercise;
    if (setIndex < 0 || setIndex >= ex.sets.length) return;
    final set = ex.sets[setIndex];
    if (weightKg != null && weightKg > 0) set.weightKg = weightKg;
    if (reps != null && reps > 0) set.reps = reps;
    _c.closePad();
    if (set.reps > 0) _c.completeSet(setIndex);
  }

  // ---------------------------------------------------------------- sortie

  Future<void> _onClose() async {
    _c.closePad();
    final choice = await LeaveSheet.show(context, lang: _lang, doneSets: _c.session.doneSets);
    if (!mounted) return;
    switch (choice) {
      case LeaveChoice.stay:
        return;
      case LeaveChoice.pause:
        await _c.flushDraft();
        if (mounted) Navigator.of(context).pop();
      case LeaveChoice.finish:
        _finish();
      case LeaveChoice.abandon:
        await WorkoutSessionStore.instance.clearDraft();
        _c.rest.skip();
        if (mounted) Navigator.of(context).pop();
    }
  }

  int _kcalFor(String intensity, int minutes) {
    final weight = AuthService().currentUser?.weight ?? 75.0;
    return CalorieBurnService.calculateKcal(
      'musculation',
      weight,
      minutes,
      intensity: intensity,
      totalWeightKg: _c.session.volumeKg,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _c.closePad();
    final lang = _lang;
    final choice = await FinishSheet.show(
      context,
      lang: lang,
      session: _c.session,
      elapsedMinutes: _c.durationMinutes,
      kcalFor: _kcalFor,
    );
    if (choice == null || !mounted) return;
    _finishing = true;
    _c.rest.skip();
    RyzeFeedback.success();

    final live = _c.session;
    final now = DateTime.now();
    final session = live.toWorkoutSession(now);
    final source = await WorkoutSessionStore.resolveSource(
      isFromAI: live.isFromAI,
      isFromProgram: live.isFromProgram,
      guidedTemplateId: live.guidedTemplateId,
    );
    final outcome = await WorkoutSessionStore.instance.finish(
      session: session,
      sessionSource: source.source,
      guidedTemplateId: source.templateId,
      plannedWorkoutId: live.plannedWorkoutId,
      intensity: choice.intensity,
      durationMinutes: choice.minutes,
      caloriesBurned: _kcalFor(choice.intensity, choice.minutes),
      saveAsProgram: choice.saveAsProgram,
      isFromAI: live.isFromAI,
      historySessionId: live.id,
    );
    await LastSets.remember(session);
    widget.onSessionCompleted?.call(session);
    if (!mounted) return;

    final nav = Navigator.of(context);
    nav.pop();
    // Une séance Coach Ryze lancée depuis le générateur revient à l'onglet,
    // pas au générateur (sauf si elle venait du planificateur).
    if (live.isFromAI && live.plannedWorkoutId == null && nav.canPop()) nav.pop();

    final ack = outcome == FinishOutcome.queued
        ? 'session_queued_ack'.tr(lang)
        : 'session_saved_ack'.tr(lang).replaceAll('{min}', '${choice.minutes}').replaceAll('{sets}', '${live.doneSets}');
    RyzeUndo.note(context, message: ack);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    context.watch<LocalizationService>();
    final lang = _lang;
    final s = _c.session;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onClose();
      },
      child: Scaffold(
        backgroundColor: RyzeColors.paper,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const OnbBackground(scene: false),
            SafeArea(
            bottom: false,
            child: Column(
              children: [
                SessionHeader(
                  lang: lang,
                  name: s.name,
                  done: s.doneSets,
                  total: s.totalSets,
                  elapsed: _c.elapsed,
                  onClose: _onClose,
                ),
                Expanded(
                  child: s.exercises.isEmpty
                      ? _Empty(lang: lang, onAdd: _addExercise)
                      : ListView.builder(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(2.1), context.vw(5.1), context.vw(40)),
                          itemCount: s.exercises.length,
                          itemBuilder: (context, i) => KeyedSubtree(
                            key: _keyFor(i),
                            child: ExerciseCard(
                              index: i,
                              exercise: s.exercises[i],
                              open: _c.current == i,
                              lang: lang,
                              controller: _c,
                              onOpen: () => _openExercise(i),
                              onMenu: () => _menu(i),
                              onTitle: () => _progression(s.exercises[i]),
                            ),
                          ),
                        ),
                ),
                if (_voice.listening)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.vw(2.1)),
                    child: Text(
                      _voice.heard.isEmpty ? 'session_listening'.tr(lang) : _voice.heard,
                      style: RyzeText.body(context, 3.4, color: RyzeColors.accInk),
                    ),
                  ),
                SessionBottomBar(
                  lang: lang,
                  controller: _c,
                  onAddExercise: _addExercise,
                  onFinish: _finish,
                  onMic: _mic,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

/// Une séance libre commence vide : la première chose à faire est d'ajouter
/// un exercice, alors c'est la seule chose à l'écran.
class _Empty extends StatelessWidget {
  const _Empty({required this.lang, required this.onAdd});

  final String lang;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.vw(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'session_empty'.tr(lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 3.9, color: RyzeColors.mute),
            ),
            SizedBox(height: context.vw(4.1)),
            Pressable(
              onTap: onAdd,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.vw(6.2), vertical: context.vw(3.1)),
                decoration: BoxDecoration(
                  color: RyzeColors.ink,
                  borderRadius: BorderRadius.circular(RyzeRadius.pill),
                  boxShadow: RyzeShadow.soft,
                ),
                child: Text('session_add_exercise'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.surf)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
