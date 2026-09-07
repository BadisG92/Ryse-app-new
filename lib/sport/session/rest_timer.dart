import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../design/feedback.dart';

/// Le repos entre deux séries.
///
/// Il n'existait pas. Ici il compte sur l'heure murale : `endsAt` est fixé au
/// départ, et le temps restant est recalculé, pas décrémenté. Un téléphone
/// verrouillé pendant deux minutes revient donc sur « repos terminé », pas sur
/// un décompte figé à 1:12.
class RestState {
  const RestState({this.total = Duration.zero, this.endsAt, this.remaining = Duration.zero});

  final Duration total;
  final DateTime? endsAt;
  final Duration remaining;

  bool get running => endsAt != null && remaining > Duration.zero;

  /// Vrai pendant les deux secondes où la barre dit « Repos terminé ».
  bool get justEnded => endsAt != null && remaining <= Duration.zero;

  /// Part écoulée, de 0 à 1, pour la ligne ambre.
  double get progress {
    if (total <= Duration.zero) return 0;
    final done = total - remaining;
    return (done.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }
}

class RestTimer extends ValueNotifier<RestState> {
  RestTimer() : super(const RestState());

  Timer? _tick;
  Timer? _clear;
  bool _ended = false;

  /// Ce que le contrôleur fait quand le repos tombe à zéro : ouvrir
  /// l'exercice suivant, par exemple.
  VoidCallback? onEnd;

  /// Prévenir hors de l'app à la fin du repos, et annuler ce rappel. Les deux
  /// sont facultatifs : sans eux, l'haptique au retour reste le seul signal,
  /// ce qui suffit — d'où l'absence de tout `await` sur ces appels.
  void Function(DateTime endsAt)? onSchedule;
  VoidCallback? onCancelSchedule;

  void start(Duration d) {
    _ended = false;
    _clear?.cancel();
    final endsAt = DateTime.now().add(d);
    value = RestState(total: d, endsAt: endsAt, remaining: d);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _update());
    onSchedule?.call(endsAt);
  }

  /// Un brouillon repris en plein repos : on reprend là où il en était.
  void restore(DateTime endsAt, {Duration? total}) {
    final remaining = endsAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      value = const RestState();
      return;
    }
    _ended = false;
    value = RestState(total: total ?? remaining, endsAt: endsAt, remaining: remaining);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _update());
    onSchedule?.call(endsAt);
  }

  void skip() {
    _tick?.cancel();
    _clear?.cancel();
    _ended = true;
    value = const RestState();
    onCancelSchedule?.call();
  }

  void extend(Duration by) {
    final endsAt = value.endsAt;
    if (endsAt == null) return;
    final next = endsAt.add(by);
    final now = DateTime.now();
    if (!next.isAfter(now)) {
      skip();
      return;
    }
    value = RestState(total: value.total + by, endsAt: next, remaining: next.difference(now));
    onSchedule?.call(next);
  }

  /// Au retour de l'arrière-plan : recalculer, et signaler une fin manquée.
  void resync() {
    if (value.endsAt == null) return;
    _update();
  }

  void _update() {
    final endsAt = value.endsAt;
    if (endsAt == null) return;
    final remaining = endsAt.difference(DateTime.now());
    if (remaining > Duration.zero) {
      value = RestState(total: value.total, endsAt: endsAt, remaining: remaining);
      return;
    }
    _tick?.cancel();
    if (_ended) return;
    _ended = true;
    // Deux secondes de « Repos terminé », puis la barre redevient neutre.
    value = RestState(total: value.total, endsAt: endsAt, remaining: Duration.zero);
    RyzeFeedback.alert();
    onCancelSchedule?.call();
    onEnd?.call();
    _clear?.cancel();
    _clear = Timer(const Duration(seconds: 2), () {
      if (value.endsAt == endsAt) value = const RestState();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _clear?.cancel();
    onCancelSchedule?.call();
    super.dispose();
  }
}
