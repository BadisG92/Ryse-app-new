import 'dart:math' as math;

class CalorieBurnService {
  static const Map<String, double> _metModerateByType = {
    'musculation': 5.0,
    'course': 8.5,
    'velo': 7.5,
    'marche': 3.5,
    'hiit': 8.0,
  };

  static const Map<String, double> _intensityMultiplier = {
    'Faible': 0.85,
    'Modéré': 1.00,
    'Élevé': 1.15,
  };

  /// Calculate calories burned using MET model with optional adjustments.
  /// - type: one of 'musculation', 'course', 'velo', 'marche', 'hiit'
  /// - weightKg: user body weight in kilograms
  /// - durationMinutes: session duration in minutes
  /// - intensity: 'Faible' | 'Modéré' | 'Élevé'
  /// - totalWeightKg: for musculation, total lifted volume (sum of weight*reps across sets) in kilograms
  static int calculateKcal(
    String type,
    double weightKg,
    int durationMinutes, {
    String intensity = 'Modéré',
    double? totalWeightKg,
  }) {
    if (durationMinutes <= 0 || weightKg <= 0) return 0;

    final baseMet = _metModerateByType[type.toLowerCase()] ?? 5.0;
    final mult = _intensityMultiplier[intensity] ?? 1.0;
    final effectiveMet = baseMet * mult;

    double kcalBase = effectiveMet * 0.0175 * weightKg * durationMinutes;

    if (type.toLowerCase() == 'musculation' && (totalWeightKg != null) && totalWeightKg > 0) {
      final adjustment = totalWeightKg * 0.005; // volume-based tweak
      final capped = math.min(adjustment, kcalBase * 0.30); // cap at +30%
      kcalBase += capped;
    }

    return kcalBase.round();
  }
}


