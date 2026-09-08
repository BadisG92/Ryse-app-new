import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/ui/numeric_text_field.dart';
import '../design/design.dart';
import '../models/sport_models.dart';
import '../services/auth_service.dart';
import '../services/calorie_burn_service.dart';
import '../services/dashboard_service.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/sport_dashboard_service.dart';
import '../services/translations.dart';
import '../services/unit_service.dart';
import '../sport/session/sheets/exercise_picker_sheet.dart';

/// Corriger une séance déjà enregistrée.
///
/// On n'est plus en salle : le clavier a sa place ici, et chaque cellule est
/// un champ. Ce qui change par rapport à l'ancien écran, c'est le reste — la
/// même carte d'exercice que la séance en direct, la même feuille pour
/// ajouter un exercice (plus de dialogue « combien de séries ? »), les kcal
/// recalculées à chaque frappe, et l'annulation au lieu des snackbars.
///
/// Les écritures ne changent pas : on réécrit `workout_set_history` pour ce
/// `history_session_id` et on met à jour la ligne de
/// `workout_session_summaries`. Vider la séance de tous ses exercices la
/// supprime, comme avant.
class WorkoutEditScreen extends StatefulWidget {
  final String sessionId;
  final String historySessionId;
  final String sessionName;
  final List<WorkoutExercise> exercises;
  final int durationMinutes;
  final String? intensity;
  final String sessionDate;

  const WorkoutEditScreen({
    super.key,
    required this.sessionId,
    required this.historySessionId,
    required this.sessionName,
    required this.exercises,
    required this.durationMinutes,
    this.intensity,
    required this.sessionDate,
  });

  @override
  State<WorkoutEditScreen> createState() => _WorkoutEditScreenState();
}

class _WorkoutEditScreenState extends State<WorkoutEditScreen> {
  static const List<String> _dbIntensities = ['Faible', 'Modéré', 'Élevé'];

  late List<WorkoutExercise> _exercises;
  late int _minutes;
  late int _intensity;
  int _open = 0;
  bool _saving = false;
  ({int index, WorkoutExercise exercise})? _removed;

  @override
  void initState() {
    super.initState();
    _exercises = [
      for (final e in widget.exercises) WorkoutExercise(exercise: e.exercise, sets: [...e.sets], suggestedRepsMin: e.suggestedRepsMin, suggestedRepsMax: e.suggestedRepsMax),
    ];
    _minutes = widget.durationMinutes > 0 ? widget.durationMinutes : 45;
    final i = _dbIntensities.indexOf(widget.intensity ?? '');
    _intensity = i < 0 ? 1 : i;
  }

  double get _volumeKg => _exercises.fold<double>(0, (v, e) => v + e.sets.fold<double>(0, (s, set) => s + set.weight * set.reps));

  int get _doneSets => _exercises.fold<int>(0, (n, e) => n + e.sets.where((s) => s.reps > 0).length);

  int get _kcal => CalorieBurnService.calculateKcal(
        'musculation',
        AuthService().currentUser?.weight ?? 75.0,
        _minutes > 0 ? _minutes : 1,
        intensity: _dbIntensities[_intensity],
        totalWeightKg: _volumeKg,
      );

  // ------------------------------------------------------------- édition

  void _setValue(int ei, int si, {int? reps, double? weight}) {
    final old = _exercises[ei].sets[si];
    setState(() {
      _exercises[ei].sets[si] = ExerciseSet(
        reps: reps ?? old.reps,
        weight: weight ?? old.weight,
        isCompleted: old.isCompleted,
      );
    });
  }

  void _addSet(int ei) {
    RyzeFeedback.tap();
    final sets = _exercises[ei].sets;
    final last = sets.isEmpty ? null : sets.last;
    setState(() => sets.add(ExerciseSet(reps: last?.reps ?? 0, weight: last?.weight ?? 0, isCompleted: true)));
  }

  void _removeSet(int ei, int si) {
    if (_exercises[ei].sets.length <= 1) return;
    RyzeFeedback.removed();
    setState(() => _exercises[ei].sets.removeAt(si));
  }

  Future<void> _addExercise() async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final picked = await ExercisePickerSheet.show(context, lang: lang);
    if (picked == null || !mounted) return;
    setState(() {
      _exercises.add(WorkoutExercise(
        exercise: picked,
        sets: List.generate(3, (_) => const ExerciseSet(reps: 0, weight: 0, isCompleted: true)),
      ));
      _open = _exercises.length - 1;
    });
  }

  void _removeExercise(int index) {
    final lang = LocalizationService.instance.currentLanguageCode;
    final gone = _exercises[index];
    setState(() {
      _removed = (index: index, exercise: gone);
      _exercises.removeAt(index);
      if (_open >= _exercises.length) _open = _exercises.length - 1;
    });
    RyzeFeedback.removed();
    RyzeUndo.show(
      context,
      message: 'session_exercise_removed'.tr(lang).replaceAll('{name}', gone.exercise.name),
      undoLabel: 'undo'.tr(lang),
      onUndo: () {
        final r = _removed;
        if (r == null) return;
        setState(() => _exercises.insert(r.index.clamp(0, _exercises.length), r.exercise));
      },
    );
  }

  // ----------------------------------------------------------- écriture

  Future<void> _save() async {
    if (_saving) return;
    final lang = LocalizationService.instance.currentLanguageCode;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    final client = Supabase.instance.client;
    try {
      // Vider la séance de tous ses exercices, c'est la supprimer.
      if (_exercises.isEmpty) {
        await client.from('workout_set_history').delete().eq('history_session_id', widget.historySessionId);
        await client.from('workout_session_summaries').delete().eq('id', widget.sessionId);
        await _refresh();
        if (!mounted) return;
        Navigator.pop(context, true);
        RyzeUndo.note(context, message: 'sport_session_deleted'.tr(lang));
        return;
      }

      await client.from('workout_set_history').delete().eq('history_session_id', widget.historySessionId);

      final rows = <Map<String, dynamic>>[];
      var order = 1;
      for (final we in _exercises) {
        for (final set in we.sets.where((s) => s.reps > 0)) {
          rows.add({
            'user_id': userId,
            'history_session_id': widget.historySessionId,
            'exercise_name': we.exercise.name,
            'set_order': order,
            'reps': set.reps,
            'weight': set.weight,
            'performed_at': widget.sessionDate,
            'session_name': widget.sessionName,
          });
          order++;
        }
      }
      if (rows.isNotEmpty) await client.from('workout_set_history').insert(rows);

      await client.from('workout_session_summaries').update({
        'session_name': widget.sessionName,
        'duration_minutes': _minutes,
        'calories_burned': _kcal,
        'intensity': _dbIntensities[_intensity],
        'total_volume_kg': _volumeKg.round(),
        'num_exercises': _exercises.length,
      }).eq('id', widget.sessionId);

      await _refresh();
      if (!mounted) return;
      RyzeFeedback.success();
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      RyzeUndo.failed(context, message: 'workout_save_failed'.tr(lang));
    }
  }

  Future<void> _refresh() async {
    SportDashboardService.forceInvalidateAllCaches();
    DashboardService.invalidateAndRefreshAfterWorkout();
    try {
      await GlobalStateManager.instance.refreshSportData();
    } catch (_) {}
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final units = UnitService.instance;

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.sessionName, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 4.1, weight: FontWeight.w600)),
                            Text('sport_edit'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(6)),
                    children: [
                      for (var i = 0; i < _exercises.length; i++) _exerciseCard(context, lang, units, i),
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
                      SizedBox(height: context.vw(5.1)),
                      _settings(context, lang, units),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, context.vw(2.1)),
                    child: Pressable(
                      onTap: _saving ? null : _save,
                      child: AnimatedContainer(
                        duration: RyzeDurations.tap,
                        height: context.vw(13.3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _saving ? RyzeColors.idle : RyzeColors.ink,
                          borderRadius: BorderRadius.circular(RyzeRadius.sm),
                          boxShadow: _saving ? null : RyzeShadow.soft,
                        ),
                        child: _saving
                            ? SizedBox(
                                width: context.vw(4.6),
                                height: context.vw(4.6),
                                child: CircularProgressIndicator(color: RyzeColors.mute, strokeWidth: 2),
                              )
                            : Text('save'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(BuildContext context, String lang, UnitService units, int i) {
    final we = _exercises[i];
    final open = _open == i;
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.1)),
      child: AnimatedContainer(
        duration: RyzeDurations.fill,
        curve: RyzeCurves.out,
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: open ? RyzeColors.ink : RyzeColors.line, width: open ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              onTap: () {
                RyzeFeedback.tap();
                setState(() => _open = open ? -1 : i);
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.1), context.vw(2.6), context.vw(3.1)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(we.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                          Text(
                            'sport_sets_only'.tr(lang).replaceAll('{sets}', '${we.sets.length}'),
                            style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                          ),
                        ],
                      ),
                    ),
                    Pressable(
                      onTap: () => _removeExercise(i),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(LucideIcons.trash2, size: context.vw(4.1), color: RyzeColors.mute2),
                      ),
                    ),
                    Icon(open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: context.vw(4.6), color: RyzeColors.mute2),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: RyzeDurations.enter,
              curve: RyzeCurves.out,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.fromLTRB(context.vw(2.6), 0, context.vw(2.6), context.vw(2.6)),
                      child: Column(
                        children: [
                          for (var s = 0; s < we.sets.length; s++) _setRow(context, lang, units, i, s),
                          Pressable(
                            onTap: () => _addSet(i),
                            child: Container(
                              height: context.vw(10.3),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                                border: Border.all(color: RyzeColors.idle),
                              ),
                              child: Text('session_add_set'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setRow(BuildContext context, String lang, UnitService units, int ei, int si) {
    final set = _exercises[ei].sets[si];
    final shownWeight = units.displayWeight(set.weight);
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(1.8)),
      child: Row(
        children: [
          SizedBox(
            width: context.vw(5.6),
            child: Text('${si + 1}', style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: RyzeColors.mute2)),
          ),
          Expanded(
            child: _Field(
              value: shownWeight <= 0 ? '' : (shownWeight % 1 == 0 ? shownWeight.toStringAsFixed(0) : shownWeight.toStringAsFixed(1)),
              unit: units.weightUnit,
              decimals: true,
              onChanged: (v) {
                final shown = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                // Le champ est dans l'unité de l'utilisateur, la base en kilos.
                _setValue(ei, si, weight: units.isMetric ? shown : shown / 2.2046226218);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.vw(1.5)),
            child: Text('×', style: RyzeText.body(context, 3.9, color: RyzeColors.mute2)),
          ),
          Expanded(
            child: _Field(
              value: set.reps <= 0 ? '' : '${set.reps}',
              unit: null,
              decimals: false,
              onChanged: (v) => _setValue(ei, si, reps: int.tryParse(v) ?? 0),
            ),
          ),
          SizedBox(width: context.vw(1.5)),
          Pressable(
            onTap: _exercises[ei].sets.length > 1 ? () => _removeSet(ei, si) : null,
            child: SizedBox(
              width: context.vw(9.2),
              height: context.vw(9.2),
              child: Icon(
                LucideIcons.minus,
                size: context.vw(4.1),
                color: _exercises[ei].sets.length > 1 ? RyzeColors.mute : RyzeColors.idle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settings(BuildContext context, String lang, UnitService units) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('workout_duration'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(1.5)),
        Row(
          children: [
            _Step(icon: LucideIcons.minus, onTap: _minutes > 5 ? () => setState(() => _minutes -= 5) : null),
            Expanded(
              child: Center(
                child: RollingNumber('$_minutes ${'minutes'.tr(lang)}', style: RyzeText.display(context, 6.2, weight: FontWeight.w600)),
              ),
            ),
            _Step(icon: LucideIcons.plus, onTap: _minutes < 600 ? () => setState(() => _minutes += 5) : null),
          ],
        ),
        SizedBox(height: context.vw(4.1)),
        Text('workout_intensity'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        RyzeSegmented(
          labels: [
            'workout_intensity_low'.tr(lang),
            'workout_intensity_moderate'.tr(lang),
            'workout_intensity_high'.tr(lang),
          ],
          index: _intensity,
          onChanged: (i) => setState(() => _intensity = i),
        ),
        SizedBox(height: context.vw(4.1)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Row(
            children: [
              Expanded(child: _Small(value: '$_doneSets', label: 'session_sets_done'.tr(lang))),
              Expanded(child: _Small(value: units.displayWeight(_volumeKg).round().toString(), label: '${'session_volume'.tr(lang)} · ${units.weightUnit}')),
              Expanded(child: _Small(value: '$_kcal', label: 'session_kcal_estimated'.tr(lang), amber: true)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Une cellule de valeur : le champ est le seul endroit qui se corrige.
class _Field extends StatefulWidget {
  const _Field({required this.value, required this.unit, required this.decimals, required this.onChanged});

  final String value;
  final String? unit;
  final bool decimals;
  final ValueChanged<String> onChanged;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final TextEditingController _c = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RyzeColors.paper,
        borderRadius: BorderRadius.circular(RyzeRadius.xs),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: NumericTextField(
              controller: _c,
              hintText: '—',
              textAlign: TextAlign.center,
              allowDecimals: widget.decimals,
              minValue: 0,
              maxValue: widget.decimals ? 1000 : 200,
              onChanged: widget.onChanged,
              style: RyzeText.display(context, 4.6, weight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintStyle: RyzeText.display(context, 4.6, weight: FontWeight.w600).copyWith(color: RyzeColors.mute2),
                contentPadding: EdgeInsets.symmetric(vertical: context.vw(2.6), horizontal: context.vw(1)),
                isDense: true,
              ),
            ),
          ),
          if (widget.unit != null)
            Padding(
              padding: EdgeInsets.only(right: context.vw(2.1)),
              child: Text(widget.unit!, style: RyzeText.body(context, 2.9, color: RyzeColors.mute2)),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              RyzeFeedback.tap();
              onTap!();
            },
      child: Container(
        width: context.vw(11.3),
        height: context.vw(11.3),
        decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
        child: Icon(icon, size: context.vw(4.6), color: onTap == null ? RyzeColors.mute2 : RyzeColors.ink),
      ),
    );
  }
}

class _Small extends StatelessWidget {
  const _Small({required this.value, required this.label, this.amber = false});

  final String value;
  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          style: RyzeText.display(context, 5.6, weight: FontWeight.w600).copyWith(
            color: amber ? RyzeColors.accInk : RyzeColors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: RyzeText.body(context, 2.6, color: RyzeColors.mute)),
      ],
    );
  }
}
