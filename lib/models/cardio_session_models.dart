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

  const ManualCardioEntry({
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    required this.duration,
    required this.distance,
    this.steps = 0,
    required this.date,
    this.notes,
  });

  int calculateCalories() {
    double caloriesPerMinute;
    switch (activityType) {
      case 'running':
        caloriesPerMinute = 12.0;
        break;
      case 'bike':
        caloriesPerMinute = 8.0;
        break;
      case 'walking':
        caloriesPerMinute = 5.0;
        break;
      default:
        caloriesPerMinute = 6.0;
    }
    return (duration.inMinutes * caloriesPerMinute).round();
  }

  double calculateAverageSpeed() {
    if (duration.inMinutes == 0) return 0.0;
    return distance / (duration.inMinutes / 60.0);
  }
} 
