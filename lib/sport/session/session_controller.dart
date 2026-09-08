import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../design/feedback.dart';
import '../../models/sport_models.dart';
import '../../services/workout_session_store.dart';
import 'rest_timer.dart';
import 'session_history.dart';
import 'session_models.dart';

/// Quelle cellule est en train d'être saisie.
enum EditField { weight, reps }

/// Le seul état mutable d'une séance.
///
/// L'ancien écran tenait tout dans son `State` : 5 000 lignes reconstruites
/// chaque seconde par le chronomètre. Ici l'horloge est un `ValueNotifier`
/// que seule l'horloge écoute, et chaque geste sur une série finit par
/// [_touch], qui prévient les widgets et écrit le brouillon sur le téléphone.
/// Une app tuée par iOS retrouve donc la séance là où elle en était.
class SessionController extends ChangeNotifier {
  SessionController({required this.session, int current = 0, DateTime? restEndsAt}) : _current = current {
    _elapsedTick = Timer.periodic(const Duration(seconds: 1), (_) => _tickElapsed());
    _tickElapsed();
    rest.onEnd = _onRestEnd;
    if (restEndsAt != null) rest.restore(restEndsAt);
    for (final e in session.exercises) {
      unawaited(_loadGhosts(e));
    }
  }

  final LiveSession session;

  /// L'exercice ouvert. Un seul à la fois.
  int _current;
  int get current => _current;

  /// La série en saisie, et sa cellule.
  int? editingSet;
  EditField? editingField;

  /// Ce que le pavé est en train d'écrire, avant validation.
  String buffer = '';

  final ValueNotifier<Duration> elapsed = ValueNotifier<Duration>(Duration.zero);
  final RestTimer rest = RestTimer();

  /// Ce qu'on a fait la dernière fois, par exercice, pour les valeurs
  /// fantômes. Chargé en arrière-plan ; nul tant qu'on ne sait pas.
  final Map<String, List<LastSet>> ghosts = {};

  /// Le dernier exercice retiré, le temps d'une annulation.
  ({int index, LiveExercise exercise})? _removed;

  /// Vrai quand la dernière série d'un exercice vient d'être validée : à la
  /// fin du repos, on ouvre le suivant.
  bool _advanceAfterRest = false;

  Timer? _elapsedTick;
  Timer? _draftDebounce;

  // ------------------------------------------------------------ horloges

  void _tickElapsed() {
    elapsed.value = DateTime.now().difference(session.startedAt);
  }

  void _onRestEnd() {
    if (_advanceAfterRest) {
      _advanceAfterRest = false;
      final next = session.exercises.indexWhere((e) => !e.allDone, _current + 1);
      if (next >= 0) {
        _current = next;
        notifyListeners();
      }
    }
    _touch();
  }

  /// Au retour de l'arrière-plan.
  void onResumed() {
    _tickElapsed();
    rest.resync();
  }

  // -------------------------------------------------------------- lecture

  LiveExercise get currentExercise => session.exercises[_current];

  /// Ce qu'une série vaudrait si on la validait sans rien taper : la série
  /// précédente si elle est faite, sinon la même série de la dernière fois,
  /// sinon la fourchette du programme.
  ({double? weightKg, int? reps}) ghostFor(int exerciseIndex, int setIndex) {
    final e = session.exercises[exerciseIndex];
    if (setIndex > 0 && e.sets[setIndex - 1].done) {
      final p = e.sets[setIndex - 1];
      return (weightKg: p.weightKg, reps: p.reps);
    }
    final last = ghosts[_key(e.exercise)];
    if (last != null && last.isNotEmpty) {
      final g = setIndex < last.length ? last[setIndex] : last.last;
      return (weightKg: g.weightKg, reps: g.reps);
    }
    return (weightKg: null, reps: e.repsMin);
  }

  static String _key(Exercise e) => e.id.isNotEmpty ? e.id : e.name.toLowerCase();

  Future<void> _loadGhosts(LiveExercise e) async {
    final key = _key(e.exercise);
    if (ghosts.containsKey(key)) return;
    final last = await LastSets.load(e.exercise);
    if (last != null) {
      ghosts[key] = last;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------- mutations

  void open(int index) {
    if (index == _current) return;
    _current = index.clamp(0, session.exercises.length - 1);
    _closePad();
    RyzeFeedback.select();
    _touch();
  }

  /// Ouvre le pavé sur une cellule. Le tampon part vide : ce qu'on tape
  /// remplace, ce qu'on ne tape pas garde la valeur ou le fantôme.
  void edit(int setIndex, EditField field) {
    editingSet = setIndex;
    editingField = field;
    buffer = '';
    RyzeFeedback.select();
    notifyListeners();
  }

  void _closePad() {
    editingSet = null;
    editingField = null;
    buffer = '';
  }

  void closePad() {
    _closePad();
    notifyListeners();
  }

  /// Une touche du pavé.
  void type(String key) {
    if (editingField == null) return;
    if (key == '⌫') {
      buffer = buffer.isEmpty ? '' : buffer.substring(0, buffer.length - 1);
    } else if (key == '.' || key == ',') {
      if (editingField == EditField.reps || buffer.contains('.')) return;
      buffer = '${buffer.isEmpty ? '0' : buffer}.';
    } else {
      if (buffer.length >= 6) return;
      buffer += key;
    }
    RyzeFeedback.tap();
    notifyListeners();
  }

  /// Ce que la cellule en saisie vaut maintenant : le tampon s'il y en a un,
  /// sinon la valeur enregistrée, sinon le fantôme.
  double? _committedWeight(int setIndex) {
    final s = currentExercise.sets[setIndex];
    if (s.weightKg > 0) return s.weightKg;
    return ghostFor(_current, setIndex).weightKg;
  }

  int? _committedReps(int setIndex) {
    final s = currentExercise.sets[setIndex];
    if (s.reps > 0) return s.reps;
    return ghostFor(_current, setIndex).reps;
  }

  /// Une puce ± du pavé : appliquée à la valeur courante ou au fantôme, puis
  /// écrite tout de suite dans la série.
  void bump(double delta) {
    final i = editingSet;
    final f = editingField;
    if (i == null || f == null) return;
    final s = currentExercise.sets[i];
    if (f == EditField.weight) {
      final base = buffer.isNotEmpty ? double.tryParse(buffer) ?? 0 : (_committedWeight(i) ?? 0);
      s.weightKg = (base + delta).clamp(0, 999).toDouble();
      s.weightKg = (s.weightKg * 4).round() / 4;
    } else {
      final base = buffer.isNotEmpty ? int.tryParse(buffer) ?? 0 : (_committedReps(i) ?? 0);
      s.reps = (base + delta.round()).clamp(0, 999);
    }
    buffer = '';
    RyzeFeedback.tap();
    _touch();
  }

  /// « Suivant » sur le poids : on garde ce qui est tapé et on passe aux reps.
  void next() {
    final i = editingSet;
    if (i == null) return;
    _commitBuffer(i);
    editingField = EditField.reps;
    buffer = '';
    RyzeFeedback.select();
    _touch();
  }

  void _commitBuffer(int i) {
    if (buffer.isEmpty) return;
    final s = currentExercise.sets[i];
    if (editingField == EditField.weight) {
      s.weightKg = (double.tryParse(buffer) ?? s.weightKg).clamp(0, 999).toDouble();
    } else {
      s.reps = (int.tryParse(buffer) ?? s.reps).clamp(0, 999);
    }
    buffer = '';
  }

  /// Le geste qui compte. Prend le fantôme si rien n'a été tapé, marque la
  /// série faite, lance le repos, prépare la suivante, ferme le pavé.
  void completeSet(int setIndex) {
    final e = currentExercise;
    final s = e.sets[setIndex];
    if (editingSet == setIndex) _commitBuffer(setIndex);
    final ghost = ghostFor(_current, setIndex);
    if (s.weightKg <= 0 && ghost.weightKg != null) s.weightKg = ghost.weightKg!;
    if (s.reps <= 0 && ghost.reps != null) s.reps = ghost.reps!;
    if (s.reps <= 0) {
      // rien à valider : on ouvre les reps pour le dire
      edit(setIndex, EditField.reps);
      return;
    }
    s.done = true;

    // Un record, c'est plus lourd que tout ce qu'on a de la dernière fois sur
    // cet exercice. Sans dernière fois, il n'y a rien à battre : la première
    // séance ne s'auto-félicite pas.
    final previous = ghosts[_key(e.exercise)];
    final best = previous == null || previous.isEmpty
        ? 0.0
        : previous.map((p) => p.weightKg).reduce((a, b) => a > b ? a : b);
    s.record = best > 0 && s.weightKg > best;
    if (setIndex + 1 < e.sets.length) {
      final n = e.sets[setIndex + 1];
      if (!n.done && n.isEmpty) {
        n.weightKg = s.weightKg;
        n.reps = s.reps;
      }
    } else {
      _advanceAfterRest = session.exercises.skip(_current + 1).any((x) => !x.allDone);
    }
    _closePad();
    if (s.record) {
      RyzeFeedback.alert();
    } else {
      RyzeFeedback.success();
    }
    rest.start(Duration(seconds: session.restSeconds));
    _touch();
  }

  void uncompleteSet(int setIndex) {
    currentExercise.sets[setIndex].done = false;
    RyzeFeedback.removed();
    _touch();
  }

  void addSet() {
    final e = currentExercise;
    final prev = e.sets.isEmpty ? null : e.sets.last;
    e.sets.add(LiveSet(weightKg: prev?.weightKg ?? 0, reps: prev?.reps ?? 0));
    RyzeFeedback.tap();
    _touch();
  }

  void removeSet(int setIndex) {
    final e = currentExercise;
    if (e.sets.length <= 1) return;
    e.sets.removeAt(setIndex);
    _closePad();
    RyzeFeedback.removed();
    _touch();
  }

  void addExercise(Exercise exercise, {int sets = 3}) {
    session.exercises.add(LiveExercise(exercise: exercise, sets: List.generate(sets, (_) => LiveSet())));
    _current = session.exercises.length - 1;
    _closePad();
    unawaited(_loadGhosts(session.exercises.last));
    RyzeFeedback.success();
    _touch();
  }

  void replaceExercise(int index, Exercise exercise) {
    final e = session.exercises[index];
    e.exercise = exercise;
    for (final s in e.sets) {
      s.weightKg = 0;
      s.reps = 0;
      s.done = false;
    }
    _closePad();
    unawaited(_loadGhosts(e));
    RyzeFeedback.select();
    _touch();
  }

  /// Retire un exercice et le garde de côté, le temps d'une annulation.
  void removeExercise(int index) {
    _removed = (index: index, exercise: session.exercises.removeAt(index));
    if (session.exercises.isEmpty) {
      _current = 0;
    } else if (_current >= session.exercises.length) {
      _current = session.exercises.length - 1;
    }
    _closePad();
    RyzeFeedback.removed();
    _touch();
  }

  void restoreExercise() {
    final r = _removed;
    if (r == null) return;
    _removed = null;
    final at = r.index.clamp(0, session.exercises.length);
    session.exercises.insert(at, r.exercise);
    _current = at;
    _touch();
  }

  void setRest(int seconds) {
    session.restSeconds = seconds;
    _touch();
  }

  // ---------------------------------------------------------- brouillon

  void _touch() {
    notifyListeners();
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 400), () => unawaited(flushDraft()));
  }

  /// Écrit le brouillon tout de suite. Appelé au passage en arrière-plan.
  Future<void> flushDraft() async {
    _draftDebounce?.cancel();
    await WorkoutSessionStore.instance.saveDraft(session.toJson(), current: _current, restEndsAt: rest.value.endsAt);
  }

  // ---------------------------------------------------------------- fin

  /// Ce que la feuille de fin montre avant qu'on confirme.
  int get durationMinutes {
    final m = elapsed.value.inMinutes;
    return m < 1 ? 1 : m;
  }

  static String newId() => const Uuid().v4();

  @override
  void dispose() {
    _elapsedTick?.cancel();
    _draftDebounce?.cancel();
    elapsed.dispose();
    rest.dispose();
    super.dispose();
  }
}
