import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../bottom_sheets/exercise_info_bottom_sheet.dart';
import '../design/design.dart';
import '../models/sport_models.dart';
import '../services/ai_workout_generation_service.dart';
import '../services/coach_preference_extractor.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../sport/session/session_screen.dart';
import '../sport/session/sheets/exercise_picker_sheet.dart';

/// Coach Ryze prépare une séance de musculation.
///
/// Deux temps, jamais mélangés : on demande, puis on regarde ce qui est
/// proposé et on le corrige. La demande est une phrase — les huit puces ne
/// sont qu'un raccourci pour l'écrire — plus trois réglages repliés, parce
/// que la plupart du temps la phrase suffit.
///
/// L'accès a déjà été vérifié par `SportStart.coach` avant que cet écran soit
/// poussé.
class AIWorkoutGeneratorScreen extends StatefulWidget {
  const AIWorkoutGeneratorScreen({super.key});

  @override
  State<AIWorkoutGeneratorScreen> createState() => _AIWorkoutGeneratorScreenState();
}

class _AIWorkoutGeneratorScreenState extends State<AIWorkoutGeneratorScreen> {
  static const List<String> _chipKeys = [
    'ai_workout_chip_upper',
    'ai_workout_chip_legs',
    'ai_workout_chip_full',
    'ai_workout_chip_push',
    'ai_workout_chip_pull',
    'ai_workout_chip_core',
    'ai_workout_chip_arms',
    'ai_workout_chip_circuit',
  ];
  static const List<int> _durations = [30, 45, 60, 90];
  static const List<String> _focusKeys = ['ai_workout_focus_strength', 'ai_workout_focus_hypertrophy', 'ai_workout_focus_endurance'];
  static const List<String> _focusValues = ['Force', 'Hypertrophie', 'Endurance'];
  static const List<double> _intensityValues = [0.2, 0.5, 0.85];

  final TextEditingController _prompt = TextEditingController();

  int? _chip;
  bool _params = false;
  int _duration = 1; // 45 min
  int _intensity = 1;
  int _focus = 1;

  bool _generating = false;
  List<WorkoutExercise>? _workout;
  String? _suggestions;
  String? _error;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _prompt.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  String get _lang => LocalizationService.instance.currentLanguageCode;

  bool get _canGenerate => _chip != null || _prompt.text.trim().isNotEmpty;

  Future<void> _generate() async {
    if (!_canGenerate || _generating) return;
    final lang = _lang;
    FocusScope.of(context).unfocus();
    RyzeFeedback.confirm();
    setState(() {
      _generating = true;
      _error = null;
      _workout = null;
    });

    try {
      final request = _prompt.text.trim().isNotEmpty ? _prompt.text.trim() : _chipKeys[_chip!].tr(lang);
      // Les blessures que le coach a retenues comptent aussi ici : l'écran
      // générait des séances sans jamais les regarder.
      final prefs = await CoachPreferenceExtractor.instance.getUserPreferences();
      final constraints = prefs?.fitnessConstraints ?? const <String>[];

      final result = await AIWorkoutGenerationService.generateWorkout(
        userRequest: request,
        constraints: constraints.isEmpty ? null : constraints,
        durationMinutes: _durations[_duration],
        intensity: _intensityValues[_intensity],
        focus: _focusValues[_focus],
        equipment: const ['Haltères', 'Barre'],
      );
      if (!mounted) return;
      if (result.success && result.exercises.isNotEmpty) {
        RyzeFeedback.success();
        setState(() {
          _workout = result.exercises;
          _suggestions = result.aiSuggestions;
          _name = sessionNameFrom(result.sessionName, result.exercises, lang);
        });
      } else {
        setState(() => _error = result.error ?? 'ai_workout_error_unknown'.tr(lang));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'ai_workout_error_unknown'.tr(lang));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _start() {
    final workout = _workout;
    if (workout == null || workout.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          sessionName: _name.isNotEmpty ? _name : 'ai_workout_generated_session'.tr(_lang),
          exercises: workout,
          isFromAI: true,
        ),
      ),
    );
  }

  Future<void> _rename() async {
    final lang = _lang;
    final controller = TextEditingController(text: _name);
    final name = await showRyzeSheet<String>(
      context,
      title: 'ai_workout_rename'.tr(lang),
      keyboard: true,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              border: Border.all(color: RyzeColors.line),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: RyzeText.body(context, 3.9),
              cursorColor: RyzeColors.ink,
              onSubmitted: (v) => Navigator.pop(sheet, v.trim()),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
              ),
            ),
          ),
          SizedBox(height: context.vw(3.1)),
          OnbButton(label: 'save'.tr(lang), onPressed: () => Navigator.pop(sheet, controller.text.trim())),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && mounted) setState(() => _name = name);
  }

  Future<void> _addExercise() async {
    final picked = await ExercisePickerSheet.show(context, lang: _lang);
    if (picked == null || !mounted) return;
    setState(() {
      _workout = [
        ...?_workout,
        WorkoutExercise(
          exercise: picked,
          sets: List.generate(3, (_) => const ExerciseSet(reps: 0, weight: 0)),
          suggestedRepsMin: 8,
          suggestedRepsMax: 12,
        ),
      ];
    });
  }

  void _move(int index, int by) {
    final list = _workout;
    if (list == null) return;
    final to = index + by;
    if (to < 0 || to >= list.length) return;
    RyzeFeedback.tap();
    setState(() {
      final e = list.removeAt(index);
      list.insert(to, e);
    });
  }

  void _remove(int index) {
    final list = _workout;
    if (list == null || index >= list.length) return;
    final lang = _lang;
    final gone = list[index];
    RyzeFeedback.removed();
    setState(() => list.removeAt(index));
    RyzeUndo.show(
      context,
      message: 'session_exercise_removed'.tr(lang).replaceAll('{name}', gone.exercise.name),
      undoLabel: 'undo'.tr(lang),
      onUndo: () => setState(() => list.insert(index.clamp(0, list.length), gone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final workout = _workout;

    return Scaffold(
      backgroundColor: RyzeColors.paper,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const OnbBackground(scene: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, context.vw(2.6)),
                  child: Row(
                    children: [
                      Pressable(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: context.vw(9.7),
                          height: context.vw(9.7),
                          decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
                          child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.ink),
                        ),
                      ),
                      SizedBox(width: context.vw(3.1)),
                      Expanded(child: Text('ai_workout_title'.tr(lang), style: RyzeText.body(context, 4.1, weight: FontWeight.w600))),
                    ],
                  ),
                ),
                Expanded(
                  child: workout == null
                      ? _ask(context, lang, gutter)
                      : _preview(context, lang, gutter, workout),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ demander

  Widget _ask(BuildContext context, String lang, double gutter) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(6)),
            children: [
              Text('ai_workout_ask'.tr(lang), style: RyzeText.display(context, 6.7, weight: FontWeight.w600)),
              SizedBox(height: context.vw(3.6)),
              Container(
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.md),
                  border: Border.all(color: RyzeColors.line),
                ),
                child: TextField(
                  controller: _prompt,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: RyzeText.body(context, 3.9, height: 1.4),
                  cursorColor: RyzeColors.ink,
                  decoration: InputDecoration(
                    hintText: 'ai_workout_hint'.tr(lang),
                    hintStyle: RyzeText.body(context, 3.9, color: RyzeColors.mute2),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(context.vw(4.1)),
                  ),
                ),
              ),
              SizedBox(height: context.vw(3.1)),
              Wrap(
                spacing: context.vw(2.1),
                runSpacing: context.vw(2.1),
                children: [
                  for (var i = 0; i < _chipKeys.length; i++)
                    OnbChip(
                      label: _chipKeys[i].tr(lang),
                      selected: _chip == i,
                      index: i,
                      onTap: () => setState(() => _chip = _chip == i ? null : i),
                    ),
                ],
              ),
              SizedBox(height: context.vw(4.1)),
              Pressable(
                onTap: () {
                  RyzeFeedback.tap();
                  setState(() => _params = !_params);
                },
                child: Row(
                  children: [
                    Text('ai_workout_params'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.mute)),
                    SizedBox(width: context.vw(1.5)),
                    Icon(_params ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: context.vw(4.1), color: RyzeColors.mute2),
                  ],
                ),
              ),
              AnimatedSize(
                duration: RyzeDurations.enter,
                curve: RyzeCurves.out,
                alignment: Alignment.topCenter,
                child: !_params
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.only(top: context.vw(2.6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('workout_duration'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
                            SizedBox(height: context.vw(1.5)),
                            RyzeSegmented(
                              labels: [for (final d in _durations) '$d'],
                              index: _duration,
                              onChanged: (i) => setState(() => _duration = i),
                            ),
                            SizedBox(height: context.vw(3.6)),
                            Text('workout_intensity'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
                            SizedBox(height: context.vw(1.5)),
                            RyzeSegmented(
                              labels: [
                                'workout_intensity_low'.tr(lang),
                                'workout_intensity_moderate'.tr(lang),
                                'workout_intensity_high'.tr(lang),
                              ],
                              index: _intensity,
                              onChanged: (i) => setState(() => _intensity = i),
                            ),
                            SizedBox(height: context.vw(3.6)),
                            Text('ai_workout_focus'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
                            SizedBox(height: context.vw(1.5)),
                            RyzeSegmented(
                              labels: [for (final k in _focusKeys) k.tr(lang)],
                              index: _focus,
                              onChanged: (i) => setState(() => _focus = i),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_error != null) ...[
                SizedBox(height: context.vw(4.1)),
                Text(_error!, style: RyzeText.body(context, 3.4, color: RyzeColors.danger, height: 1.4)),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, context.vw(2.1)),
            child: Pressable(
              onTap: _canGenerate && !_generating ? _generate : null,
              child: AnimatedContainer(
                duration: RyzeDurations.tap,
                height: context.vw(13.3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _canGenerate && !_generating ? RyzeColors.ink : RyzeColors.idle,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  boxShadow: _canGenerate && !_generating ? RyzeShadow.soft : null,
                ),
                child: _generating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: context.vw(4.1),
                            height: context.vw(4.1),
                            child: CircularProgressIndicator(color: RyzeColors.mute, strokeWidth: 2),
                          ),
                          SizedBox(width: context.vw(2.6)),
                          Flexible(
                            child: Text(
                              'ai_workout_generating'.tr(lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.mute),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RyzeMark(size: context.vw(5), color: _canGenerate ? RyzeColors.surf : RyzeColors.mute),
                          SizedBox(width: context.vw(2.1)),
                          Text(
                            'ai_workout_generate'.tr(lang),
                            style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: _canGenerate ? RyzeColors.surf : RyzeColors.mute),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- relire

  Widget _preview(BuildContext context, String lang, double gutter, List<WorkoutExercise> workout) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(6)),
            children: [
              Pressable(
                onTap: _rename,
                child: Row(
                  children: [
                    Flexible(child: Text(_name, style: RyzeText.display(context, 6.2, weight: FontWeight.w600))),
                    SizedBox(width: context.vw(2.1)),
                    Icon(LucideIcons.pencil, size: context.vw(4.1), color: RyzeColors.mute2),
                  ],
                ),
              ),
              SizedBox(height: context.vw(0.5)),
              Text(
                'sport_program_exercises'.tr(lang).replaceAll('{n}', '${workout.length}'),
                style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
              ),
              SizedBox(height: context.vw(4.1)),
              for (var i = 0; i < workout.length; i++) _exerciseCard(context, lang, workout, i),
              Pressable(
                onTap: _addExercise,
                child: Container(
                  height: context.vw(12.3),
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
                      Text('workout_add_exercise'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              if (_suggestions != null && _suggestions!.trim().isNotEmpty) ...[
                SizedBox(height: context.vw(5.1)),
                Container(
                  padding: EdgeInsets.all(context.vw(4.1)),
                  decoration: BoxDecoration(
                    color: RyzeColors.surf,
                    borderRadius: BorderRadius.circular(RyzeRadius.md),
                    border: Border.all(color: RyzeColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CoachAvatar(RyzeAssets.sportAvatar, sizeVw: 7.7),
                          SizedBox(width: context.vw(2.6)),
                          Text('ai_workout_suggestions'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: context.vw(2.1)),
                      Text(_suggestions!, style: RyzeText.body(context, 3.4, color: RyzeColors.mute, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, context.vw(2.1)),
            child: Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: _generating ? null : _generate,
                    child: Container(
                      height: context.vw(13.3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RyzeColors.surf,
                        borderRadius: BorderRadius.circular(RyzeRadius.sm),
                        border: Border.all(color: RyzeColors.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.refreshCw, size: context.vw(4.1), color: RyzeColors.ink),
                          SizedBox(width: context.vw(1.5)),
                          Flexible(
                            child: Text(
                              'ai_workout_regenerate'.tr(lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.vw(3.1)),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: _start,
                    child: Container(
                      height: context.vw(13.3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RyzeColors.ink,
                        borderRadius: BorderRadius.circular(RyzeRadius.sm),
                        boxShadow: RyzeShadow.soft,
                      ),
                      child: Text('ai_workout_start'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _exerciseCard(BuildContext context, String lang, List<WorkoutExercise> workout, int i) {
    final we = workout[i];
    final min = we.suggestedRepsMin, max = we.suggestedRepsMax;
    final sets = (min != null && max != null)
        ? 'sport_sets_reps'.tr(lang).replaceAll('{sets}', '${we.sets.length}').replaceAll('{min}', '$min').replaceAll('{max}', '$max')
        : 'sport_sets_only'.tr(lang).replaceAll('{sets}', '${we.sets.length}');

    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.1)),
      child: Container(
        padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.1), context.vw(2.1), context.vw(3.1)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Pressable(
                onTap: () => ExerciseInfoBottomSheet.show(context, exerciseId: we.exercise.id, exerciseName: we.exercise.name),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(we.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                        ),
                        SizedBox(width: context.vw(1.5)),
                        Icon(LucideIcons.info, size: context.vw(3.6), color: RyzeColors.mute2),
                      ],
                    ),
                    Text(
                      [if (we.exercise.muscleGroup.isNotEmpty) we.exercise.muscleGroup, sets].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                    ),
                  ],
                ),
              ),
            ),
            _Icon(icon: LucideIcons.chevronUp, tooltip: 'ai_workout_move_up'.tr(lang), onTap: i == 0 ? null : () => _move(i, -1)),
            _Icon(icon: LucideIcons.chevronDown, tooltip: 'ai_workout_move_down'.tr(lang), onTap: i == workout.length - 1 ? null : () => _move(i, 1)),
            _Icon(icon: LucideIcons.trash2, tooltip: 'sport_delete'.tr(lang), onTap: () => _remove(i)),
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: context.vw(9.2),
          height: context.vw(9.2),
          child: Icon(icon, size: context.vw(4.1), color: onTap == null ? RyzeColors.idle : RyzeColors.mute),
        ),
      ),
    );
  }
}


/// Le nom vient des groupes musculaires que la séance travaille le plus.
/// Ils arrivent déjà traduits de Supabase, donc pas de table par langue.
///
/// Les deux premiers étaient pris quoi qu'il arrive. Une séance corps
/// entier — un squat, un développé couché, un rowing, un développé
/// épaules, un curl, un exercice par groupe — s'appelait donc
/// « Legs & Chest », du nom de ses deux premiers exercices. Le nom disait
/// jambes et pectoraux, la séance faisait tout le corps, et on ne pouvait
/// plus s'y retrouver dans l'historique.
///
/// Deux groupes ne nomment la séance que s'ils la portent vraiment : au
/// moins soixante-dix pour cent des exercices. En dessous, c'est un corps
/// entier, et ça se dit.
@visibleForTesting
String workoutNameFor(List<WorkoutExercise> exercises, String lang) {
  final counts = <String, int>{};
  for (final e in exercises) {
    final g = e.exercise.muscleGroup.trim();
    if (g.isEmpty) continue;
    counts[g] = (counts[g] ?? 0) + 1;
  }
  if (counts.isEmpty) return 'ai_workout_generated_session'.tr(lang);

  final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final total = counts.values.fold<int>(0, (s, n) => s + n);
  final lead = top.take(2).fold<int>(0, (s, e) => s + e.value);
  if (top.length > 2 && lead < total * 0.7) return 'ai_workout_full_body'.tr(lang);

  final parts = top.take(2).map((e) => e.key[0].toUpperCase() + e.key.substring(1)).toList();
  return parts.join(' & ');
}

/// Le nom d'une séance générée : celui du modèle s'il tient debout, sinon
/// celui que ses groupes musculaires dictent.
///
/// Le modèle sait ce qui a été demandé — « une séance de foot », « du full
/// body » — et le comptage des groupes, non. Mais il sait aussi vendre du
/// rêve : un nom trop long, criard ou décoré passe à la trappe et le
/// comptage reprend la main.
@visibleForTesting
String sessionNameFrom(String? proposed, List<WorkoutExercise> exercises, String lang) {
  final clean = _tidy(proposed);
  if (clean != null) return clean;
  return workoutNameFor(exercises, lang);
}

/// Ce qui reste du nom proposé une fois nettoyé, ou nul s'il n'en reste rien
/// d'utilisable.
String? _tidy(String? raw) {
  if (raw == null) return null;
  var name = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  // les guillemets que le modèle ajoute parfois autour de sa réponse
  name = name.replaceAll(RegExp(r'''^["“”'']+|["“”'']+$'''), '').trim();
  // emoji et symboles : le système n'en met nulle part ailleurs
  name = name.replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]', unicode: true), '').trim();
  name = name.replaceAll(RegExp(r'[!]+'), '').trim();
  if (name.length < 3 || name.length > 28) return null;
  return name;
}
