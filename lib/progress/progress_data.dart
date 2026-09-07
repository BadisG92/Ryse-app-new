import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../components/ui/global_progress_models.dart';
import '../services/progress_service_v2.dart';
import '../services/streak_service.dart';
import '../services/weight_service.dart';
import '../sport/sport_goal.dart';

/// Ce que la page Progression lit, en une fois.
///
/// Rien de neuf côté base : `WeightService`, `ProgressServiceV2` et
/// `StreakService` sont ceux que l'ancienne page utilisait déjà. Ce qui
/// change est ce qu'on en fait — et ce qu'on refuse d'afficher quand la
/// donnée ne le permet pas.
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.weight,
    required this.days,
    required this.streak,
    required this.sessions,
    required this.sportGoal,
    required this.calorieDays,
    required this.waterDays,
  });

  final WeightProgress? weight;
  final List<TrackingDay> days;
  final int streak;

  /// Séances faites cette semaine, et l'objectif **choisi** par
  /// l'utilisateur — nul s'il n'en a pas fixé. L'ancienne page comparait à
  /// `plannedSessions = 4` codé en dur ; personne n'avait demandé ce 4.
  final int sessions;
  final int? sportGoal;

  final int calorieDays;
  final int waterDays;

  static const empty = ProgressSnapshot(
    weight: null, days: [], streak: 0, sessions: 0, sportGoal: null, calorieDays: 0, waterDays: 0,
  );
}

class ProgressData {
  ProgressData._();

  static Future<ProgressSnapshot> load() async {
    final results = await Future.wait<Object?>([
      WeightService.getWeightProgress().then<WeightProgress?>((w) => w).catchError((_) => null),
      ProgressServiceV2.getWeeklyTracking().then<List<TrackingDay>>((d) => d).catchError((_) => <TrackingDay>[]),
      ProgressServiceV2.getWeeklyBalance().then<WeeklyBalance?>((b) => b).catchError((_) => null),
      StreakService.getCurrentStreak().then<int>((s) => s).catchError((_) => 0),
      SportGoal.load(),
    ]);

    final balance = results[2] as WeeklyBalance?;
    var calorieDays = 0, waterDays = 0, sessions = 0;
    for (final item in balance?.items ?? const <BalanceItem>[]) {
      // Reconnues à leur icône plutôt qu'à leur rang : le service peut en
      // ajouter une sans que cette page se mette à lire de travers.
      if (item.icon == LucideIcons.flame) {
        calorieDays = item.achieved;
      } else if (item.icon == LucideIcons.droplet) {
        waterDays = item.achieved;
      } else if (item.icon == LucideIcons.dumbbell) {
        sessions = item.achieved;
      }
    }

    return ProgressSnapshot(
      weight: results[0] as WeightProgress?,
      days: results[1] as List<TrackingDay>,
      streak: results[3] as int,
      sessions: sessions,
      sportGoal: results[4] as int?,
      calorieDays: calorieDays,
      waterDays: waterDays,
    );
  }
}

/// La projection vers le poids cible, à l'allure des dernières semaines.
///
/// Elle n'est calculée que si la donnée le permet : au moins quatre pesées
/// sur au moins deux semaines, une tendance qui va bien vers la cible, et
/// une échéance à moins de deux ans. Sinon elle n'est pas affichée — une
/// date inventée sur trois points serait pire que pas de date.
class WeightTrend {
  const WeightTrend({required this.kgPerWeek, required this.eta});

  /// Négatif quand on perd du poids.
  final double kgPerWeek;
  final DateTime eta;

  static WeightTrend? of(WeightProgress w) {
    final entries = [...w.entries]..sort((a, b) => a.date.compareTo(b.date));
    if (entries.length < 4) return null;
    final span = entries.last.date.difference(entries.first.date).inDays;
    if (span < 14) return null;

    // Régression linéaire des moindres carrés sur (jours, kg).
    final t0 = entries.first.date;
    var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
    for (final e in entries) {
      final x = e.date.difference(t0).inDays.toDouble();
      sx += x;
      sy += e.weight;
      sxx += x * x;
      sxy += x * e.weight;
    }
    final n = entries.length.toDouble();
    final denom = n * sxx - sx * sx;
    if (denom.abs() < 1e-6) return null;
    final slope = (n * sxy - sx * sy) / denom; // kg par jour
    if (slope.abs() < 0.001) return null; // à plat : pas d'échéance honnête

    final remaining = w.targetWeight - w.currentWeight;
    if (remaining.abs() < 0.2) return null; // déjà arrivé
    final days = remaining / slope;
    if (days <= 0 || days > 730) return null; // la tendance ne va pas vers la cible

    try {
      return WeightTrend(kgPerWeek: slope * 7, eta: DateTime.now().add(Duration(days: days.round())));
    } catch (e) {
      debugPrint('WeightTrend: $e');
      return null;
    }
  }
}
