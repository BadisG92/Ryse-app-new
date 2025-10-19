import 'package:flutter/material.dart';

// Modèles pour les sessions cardio en temps réel
class CardioSessionData {
  final String activityType; // 'running', 'bike', 'walking'
  final String activityTitle;
  final String formatTitle;
  final DateTime startTime;
  DateTime? endTime;
  Duration duration;
  double distance; // en km
  double? targetDistance; // objectif de distance (optionnel)
  Duration? targetDuration; // objectif de durée (optionnel)
  bool isRunning;
  bool isPaused;
  List<LocationPoint> route; // Points GPS
  double averageSpeed; // km/h
  double currentSpeed; // km/h
  int steps; // nombre de pas (pour la marche)
  int calories; // estimation

  CardioSessionData({
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    required this.startTime,
    this.endTime,
    this.duration = Duration.zero,
    this.distance = 0.0,
    this.targetDistance,
    this.targetDuration,
    this.isRunning = false,
    this.isPaused = false,
    this.route = const [],
    this.averageSpeed = 0.0,
    this.currentSpeed = 0.0,
    this.steps = 0,
    this.calories = 0,
  });

  CardioSessionData copyWith({
    String? activityType,
    String? activityTitle,
    String? formatTitle,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    double? distance,
    double? targetDistance,
    Duration? targetDuration,
    bool? isRunning,
    bool? isPaused,
    List<LocationPoint>? route,
    double? averageSpeed,
    double? currentSpeed,
    int? steps,
    int? calories,
  }) {
    return CardioSessionData(
      activityType: activityType ?? this.activityType,
      activityTitle: activityTitle ?? this.activityTitle,
      formatTitle: formatTitle ?? this.formatTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      targetDistance: targetDistance ?? this.targetDistance,
      targetDuration: targetDuration ?? this.targetDuration,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      route: route ?? this.route,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
    );
  }

  // Calculer l'estimation des calories
  int calculateCalories() {
    double caloriesPerMinute;
    switch (activityType) {
      case 'running':
        caloriesPerMinute = 12.0; // ~720 cal/h
        break;
      case 'bike':
        caloriesPerMinute = 8.0; // ~480 cal/h
        break;
      case 'walking':
        caloriesPerMinute = 5.0; // ~300 cal/h
        break;
      default:
        caloriesPerMinute = 6.0;
    }
    return (duration.inMinutes * caloriesPerMinute).round();
  }

  // Calculer la vitesse moyenne
  double calculateAverageSpeed() {
    if (duration.inMinutes == 0) return 0.0;
    return distance / (duration.inMinutes / 60.0);
  }

  // Calculer les pas par minute (pour la marche)
  double calculateStepsPerMinute() {
    if (duration.inMinutes == 0) return 0.0;
    return steps / duration.inMinutes;
  }

  // Vérifier si l'objectif est atteint
  bool isTargetReached() {
    if (targetDistance != null && distance >= targetDistance!) {
      return true;
    }
    if (targetDuration != null && duration >= targetDuration!) {
      return true;
    }
    return false;
  }

  // Obtenir l'icône selon l'activité
  IconData getActivityIcon() {
    switch (activityType) {
      case 'running':
        return Icons.directions_run;
      case 'bike':
        return Icons.directions_bike;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.fitness_center;
    }
  }

  // Obtenir la couleur selon l'activité
  Color getActivityColor() {
    switch (activityType) {
      case 'running':
      case 'bike':
      case 'walking':
        return const Color(0xFF1C2951); // Bleu secondaire pour toutes les activités
      default:
        return const Color(0xFF64748B); // Gris du thème
    }
  }
}

// Point GPS pour tracer le parcours
class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
  });
}

// Configuration pour les objectifs
class CardioObjective {
  final String type; // 'distance' ou 'duration'
  final double? targetDistance; // en km
  final Duration? targetDuration;
  final String activityType;
  final String formatTitle;

  const CardioObjective({
    required this.type,
    this.targetDistance,
    this.targetDuration,
    required this.activityType,
    required this.formatTitle,
  });
}

// Données pour saisie manuelle
class ManualCardioEntry {
  final String activityType;
  final String activityTitle;
  final String formatTitle;
  final Duration duration;
  final double distance;
  final int steps; // nombre de pas (pour la marche)
  final DateTime date;
  final String? notes;
  final int intensity; // 1=Faible, 2=Modéré, 3=Élevé, 4=Très élevé

  const ManualCardioEntry({
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    required this.duration,
    required this.distance,
    this.steps = 0,
    required this.date,
    this.notes,
    this.intensity = 2, // Modéré par défaut
  });

  /// Calcule les calories brûlées selon l'intensité et le type d'activité
  /// Utilise les valeurs MET (Metabolic Equivalent of Task)
  /// Formule: Calories = MET × Poids (kg) × Durée (heures)
  /// Note: On utilise un poids moyen de 70kg pour l'estimation
  ///
  /// PRIORITÉ: Si distance fournie, on calcule le MET basé sur la vitesse réelle
  /// Sinon, on utilise l'intensité du slider
  int calculateCalories({double userWeight = 70.0}) {
    double met;

    // Si distance fournie ET durée > 0, calculer MET basé sur la vitesse réelle
    if (distance > 0 && duration.inMinutes > 0) {
      final double speed = calculateAverageSpeed(); // km/h
      met = _getMETFromSpeed(speed);
    } else {
      // Sinon utiliser l'intensité du slider
      met = _getMETFromIntensity();
    }

    final double hours = duration.inMinutes / 60.0;
    final double calories = met * userWeight * hours;
    return calories.round();
  }

  /// Retourne la valeur MET basée sur la vitesse réelle (plus précis)
  double _getMETFromSpeed(double speedKmh) {
    switch (activityType) {
      case 'running':
        // Course à pied - MET basé sur la vitesse
        if (speedKmh < 6.4) return 6.0;   // < 6.4 km/h (marche rapide/jogging très léger)
        if (speedKmh < 8.0) return 8.3;   // 6.4-8 km/h (jogging léger)
        if (speedKmh < 9.7) return 9.0;   // 8-9.7 km/h (jogging)
        if (speedKmh < 10.8) return 10.5; // 9.7-10.8 km/h (course modérée)
        if (speedKmh < 12.1) return 11.0; // 10.8-12.1 km/h (course)
        if (speedKmh < 13.8) return 11.5; // 12.1-13.8 km/h (course rapide)
        if (speedKmh < 16.0) return 12.8; // 13.8-16 km/h (course très rapide)
        return 16.0; // > 16 km/h (sprint)

      case 'bike':
        // Vélo - MET basé sur la vitesse
        if (speedKmh < 16.0) return 4.0;  // < 16 km/h (balade)
        if (speedKmh < 19.3) return 6.8;  // 16-19.3 km/h (modéré)
        if (speedKmh < 22.4) return 8.0;  // 19.3-22.4 km/h (intense)
        if (speedKmh < 25.6) return 10.0; // 22.4-25.6 km/h (très intense)
        if (speedKmh < 30.6) return 12.0; // 25.6-30.6 km/h (course)
        return 15.8; // > 30.6 km/h (compétition)

      case 'walking':
        // Marche - MET basé sur la vitesse
        if (speedKmh < 3.2) return 2.0;   // < 3.2 km/h (très lent)
        if (speedKmh < 4.0) return 2.5;   // 3.2-4 km/h (lent)
        if (speedKmh < 4.8) return 3.0;   // 4-4.8 km/h (normal lent)
        if (speedKmh < 5.6) return 3.5;   // 4.8-5.6 km/h (normal)
        if (speedKmh < 6.4) return 4.3;   // 5.6-6.4 km/h (rapide)
        if (speedKmh < 7.2) return 5.0;   // 6.4-7.2 km/h (très rapide)
        return 7.0; // > 7.2 km/h (marche athlétique)

      default:
        // Activité générique - estimation linéaire
        return 3.0 + (speedKmh * 0.3);
    }
  }

  /// Retourne la valeur MET selon l'activité et l'intensité du slider
  double _getMETFromIntensity() {
    switch (activityType) {
      case 'running':
        // Course à pied
        switch (intensity) {
          case 1: return 6.0;  // Jogging léger (~8 km/h)
          case 2: return 9.8;  // Course modérée (~10 km/h)
          case 3: return 11.8; // Course rapide (~12 km/h)
          case 4: return 14.5; // Sprint (~14+ km/h)
          default: return 9.8;
        }
      case 'bike':
        // Vélo
        switch (intensity) {
          case 1: return 4.0;  // Balade tranquille (< 16 km/h)
          case 2: return 6.8;  // Vélo modéré (16-19 km/h)
          case 3: return 8.0;  // Vélo intense (19-22 km/h)
          case 4: return 10.0; // Vélo très intense (22-25 km/h)
          default: return 6.8;
        }
      case 'walking':
        // Marche
        switch (intensity) {
          case 1: return 2.5;  // Marche lente (3-4 km/h)
          case 2: return 3.5;  // Marche normale (5 km/h)
          case 3: return 5.0;  // Marche rapide (6 km/h)
          case 4: return 6.5;  // Marche très rapide (7 km/h)
          default: return 3.5;
        }
      default:
        // Activité générique
        switch (intensity) {
          case 1: return 3.0;
          case 2: return 5.0;
          case 3: return 7.0;
          case 4: return 9.0;
          default: return 5.0;
        }
    }
  }

  double calculateAverageSpeed() {
    if (duration.inMinutes == 0) return 0.0;
    return distance / (duration.inMinutes / 60.0);
  }
} 
