import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/cardio_session_models.dart';
import 'location_service.dart';
import 'unit_service.dart';

/// Service pour calculer les métriques cardio basées sur les données GPS et physiologiques
class CardioCalculator {
  // Constantes pour les calculs de calories
  static const double _baseMetabolicRate = 1.2; // Kcal/min au repos
  static const Map<String, double> _activityMETs = {
    'walking': 4.0,    // 4 METs pour marche modérée
    'running': 8.0,    // 8 METs pour course modérée  
    'bike': 6.0,       // 6 METs pour vélo modéré
    'hiking': 5.5,     // 5.5 METs pour randonnée
  };

  /// Calcule les calories brûlées basées sur l'activité, durée, et données utilisateur
  static int calculateCalories({
    required String activityType,
    required Duration duration,
    double? averageSpeed, // km/h
    double? distance, // km
    double userWeight = 70.0, // kg (poids par défaut)
    int userAge = 30, // âge par défaut
    String userGender = 'M', // M/F
  }) {
    // Obtenir les METs de base pour l'activité
    double baseMET = _activityMETs[activityType] ?? 6.0;
    
    // Ajuster les METs selon la vitesse si disponible
    double adjustedMET = _adjustMETForSpeed(activityType, averageSpeed, baseMET);
    
    // Ajuster selon les caractéristiques utilisateur
    adjustedMET = _adjustMETForUser(adjustedMET, userAge, userGender, userWeight);
    
    // Calcul des calories: MET × Poids(kg) × Temps(h)
    final durationHours = duration.inMinutes / 60.0;
    final calories = (adjustedMET * userWeight * durationHours).round();
    
    debugPrint('🔥 Calories calculées: $calories (MET: $adjustedMET, Durée: ${duration.inMinutes}min)');
    return calories;
  }

  /// Ajuste les METs selon la vitesse de l'activité
  static double _adjustMETForSpeed(String activityType, double? speed, double baseMET) {
    if (speed == null || speed <= 0) return baseMET;
    
    switch (activityType) {
      case 'walking':
        if (speed < 3.0) return 2.5;      // Marche très lente
        if (speed < 4.0) return 3.0;      // Marche lente
        if (speed < 5.0) return 3.5;      // Marche modérée
        if (speed < 6.0) return 4.5;      // Marche rapide
        return 5.0;                       // Marche très rapide
        
      case 'running':
        if (speed < 6.0) return 6.0;      // Jogging très lent
        if (speed < 8.0) return 8.1;      // Jogging lent
        if (speed < 10.0) return 10.1;    // Course modérée
        if (speed < 12.0) return 11.5;    // Course rapide
        if (speed < 14.0) return 12.8;    // Course très rapide
        return 14.0;                      // Sprint
        
      case 'bike':
        if (speed < 16.0) return 4.0;     // Vélo très lent
        if (speed < 19.0) return 6.8;     // Vélo modéré
        if (speed < 22.0) return 8.0;     // Vélo rapide
        if (speed < 25.0) return 10.0;    // Vélo très rapide
        return 12.0;                      // Vélo de course
        
      default:
        return baseMET;
    }
  }

  /// Ajuste les METs selon les caractéristiques de l'utilisateur
  static double _adjustMETForUser(double baseMET, int age, String gender, double weight) {
    double adjustedMET = baseMET;
    
    // Ajustement selon l'âge (métabolisme ralentit avec l'âge)
    if (age > 40) {
      adjustedMET *= 0.95;
    } else if (age > 60) {
      adjustedMET *= 0.90;
    }
    
    // Ajustement selon le genre (les hommes brûlent généralement plus)
    if (gender == 'F') {
      adjustedMET *= 0.95;
    }
    
    // Ajustement selon le poids (plus de poids = plus d'énergie)
    if (weight > 80) {
      adjustedMET *= 1.1;
    } else if (weight < 60) {
      adjustedMET *= 0.9;
    }
    
    return adjustedMET;
  }

  /// Calcule la vitesse instantanée lissée sur plusieurs points GPS
  static double calculateSmoothedSpeed(List<LocationPoint> recentPoints) {
    if (recentPoints.length < 2) return 0.0;
    
    // Utiliser maximum 5 points pour lisser
    final pointsToUse = recentPoints.length > 5 ? 5 : recentPoints.length;
    final points = recentPoints.sublist(recentPoints.length - pointsToUse);
    
    double totalDistance = 0.0;
    Duration totalTime = Duration.zero;
    
    for (int i = 1; i < points.length; i++) {
      final distance = LocationService.calculateDistanceBetweenPoints(
        points[i - 1], 
        points[i]
      );
      final timeDiff = points[i].timestamp.difference(points[i - 1].timestamp);
      
      totalDistance += distance; // en mètres
      totalTime += timeDiff;
    }
    
    if (totalTime.inSeconds == 0) return 0.0;
    
    final speedMs = totalDistance / totalTime.inSeconds; // m/s
    return speedMs * 3.6; // convertir en km/h
  }

  /// Calcule l'allure (pace) formatée en min:sec par km
  static String calculateFormattedPace(double averageSpeed) {
    if (averageSpeed <= 0) return '--:--';
    
    final paceMinutesPerKm = 60.0 / averageSpeed; // minutes par km
    final minutes = paceMinutesPerKm.floor();
    final seconds = ((paceMinutesPerKm - minutes) * 60).round();
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calcule le pourcentage de progression vers un objectif
  static double calculateObjectiveProgress({
    required CardioObjective objective,
    double? currentDistance,
    Duration? currentDuration,
  }) {
    if (objective.type == 'distance' && objective.targetDistance != null && currentDistance != null) {
      return (currentDistance / objective.targetDistance!).clamp(0.0, 1.0);
    } else if (objective.type == 'duration' && objective.targetDuration != null && currentDuration != null) {
      return (currentDuration.inSeconds / objective.targetDuration!.inSeconds).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Estime les calories par minute selon l'activité et l'intensité
  static double estimateCaloriesPerMinute({
    required String activityType,
    double userWeight = 70.0,
    String intensity = 'moderate', // 'light', 'moderate', 'intense'
  }) {
    double baseMET = _activityMETs[activityType] ?? 6.0;
    
    // Ajuster selon l'intensité
    switch (intensity) {
      case 'light':
        baseMET *= 0.7;
        break;
      case 'intense':
        baseMET *= 1.4;
        break;
      case 'moderate':
      default:
        // Pas de changement
        break;
    }
    
    // Calories par minute = (MET × Poids × 3.5) / 200
    return (baseMET * userWeight * 3.5) / 200;
  }

  /// Calcule la zone de fréquence cardiaque cible
  static Map<String, int> calculateHeartRateZones(int age) {
    final maxHR = 220 - age;
    
    return {
      'recovery': (maxHR * 0.5).round(),      // 50% - Zone récupération
      'aerobic': (maxHR * 0.6).round(),       // 60% - Zone aérobique  
      'anaerobic': (maxHR * 0.7).round(),     // 70% - Zone anaérobique
      'vo2max': (maxHR * 0.8).round(),        // 80% - Zone VO2 max
      'neuromuscular': (maxHR * 0.9).round(), // 90% - Zone neuromusculaire
      'maximum': maxHR,                       // 100% - Fréquence maximale
    };
  }

  /// Calcule l'efficacité de la séance basée sur les métriques
  static Map<String, dynamic> calculateSessionEfficiency({
    required Duration duration,
    required double distance,
    required double averageSpeed,
    required int calories,
    String activityType = 'running',
  }) {
    // Calculs d'efficacité
    final caloriesPerMinute = calories / duration.inMinutes;
    final speedConsistency = _calculateSpeedConsistency(averageSpeed);
    final distanceEfficiency = distance / duration.inMinutes; // km par minute
    
    // Score global (0-100)
    double overallScore = 0.0;
    
    // Score de calories (0-25 points)
    final expectedCaloriesPerMin = estimateCaloriesPerMinute(activityType: activityType);
    final calorieScore = ((caloriesPerMinute / expectedCaloriesPerMin) * 25).clamp(0, 25);
    
    // Score de vitesse (0-25 points)  
    final expectedSpeed = _getExpectedSpeed(activityType);
    final speedScore = ((averageSpeed / expectedSpeed) * 25).clamp(0, 25);
    
    // Score de consistance (0-25 points)
    final consistencyScore = speedConsistency * 25;
    
    // Score de durée (0-25 points)
    final durationScore = _calculateDurationScore(duration, activityType);
    
    overallScore = calorieScore + speedScore + consistencyScore + durationScore;
    
    return {
      'overall_score': overallScore.clamp(0, 100).round(),
      'calories_per_minute': caloriesPerMinute.toStringAsFixed(1),
      'distance_efficiency': UnitService.instance.formatSpeed(distanceEfficiency * 60),
      'speed_consistency': '${(speedConsistency * 100).toStringAsFixed(0)}%',
      'recommendations': _generateRecommendations(overallScore, activityType),
    };
  }

  /// Calcule la consistance de vitesse (0.0 = très variable, 1.0 = très constant)
  static double _calculateSpeedConsistency(double averageSpeed) {
    // Pour l'instant, retourner une valeur par défaut
    // En production, on analyserait les variations de vitesse
    return 0.8; // 80% de consistance par défaut
  }

  /// Obtient la vitesse attendue selon l'activité
  static double _getExpectedSpeed(String activityType) {
    switch (activityType) {
      case 'walking': return 5.0; // km/h
      case 'running': return 10.0; // km/h
      case 'bike': return 20.0; // km/h
      default: return 8.0; // km/h
    }
  }

  /// Calcule le score de durée selon l'activité
  static double _calculateDurationScore(Duration duration, String activityType) {
    // Durées optimales recommandées
    final optimalMinutes = {
      'walking': 30,
      'running': 45, 
      'bike': 60,
    };
    
    final optimal = optimalMinutes[activityType] ?? 45;
    final actual = duration.inMinutes;
    
    // Score maximal si durée = optimal, décroit selon l'écart
    final ratio = actual / optimal;
    if (ratio >= 0.8 && ratio <= 1.2) {
      return 25.0; // Score maximal dans la fourchette 80%-120%
    } else {
      return (25.0 * (1.0 - (ratio - 1.0).abs())).clamp(0, 25);
    }
  }

  /// Génère des recommandations selon le score
  static List<String> _generateRecommendations(double score, String activityType) {
    final recommendations = <String>[];
    
    if (score < 50) {
      recommendations.add('Essayez d\'augmenter l\'intensité de votre entraînement');
      recommendations.add('Travaillez sur la régularité de votre rythme');
    } else if (score < 75) {
      recommendations.add('Bon travail ! Vous pouvez encore améliorer votre vitesse moyenne');
      recommendations.add('Essayez d\'allonger progressivement la durée');
    } else {
      recommendations.add('Excellente performance ! Continuez ainsi');
      recommendations.add('Vous pouvez tenter des objectifs plus ambitieux');
    }
    
    return recommendations;
  }

  /// Calcule les statistiques de dénivelé
  static Map<String, double> calculateElevationStats(List<LocationPoint> route) {
    if (route.length < 2) {
      return {'gain': 0.0, 'loss': 0.0, 'max': 0.0, 'min': 0.0};
    }
    
    double gain = 0.0;
    double loss = 0.0;
    double maxAlt = route.first.altitude ?? 0.0;
    double minAlt = route.first.altitude ?? 0.0;
    
    for (int i = 1; i < route.length; i++) {
      final current = route[i].altitude;
      final previous = route[i - 1].altitude;
      
      if (current != null && previous != null) {
        final diff = current - previous;
        if (diff > 0) {
          gain += diff;
        } else {
          loss += diff.abs();
        }
        
        maxAlt = max(maxAlt, current);
        minAlt = min(minAlt, current);
      }
    }
    
    return {
      'gain': gain,           // dénivelé positif en mètres
      'loss': loss,           // dénivelé négatif en mètres  
      'max': maxAlt,          // altitude maximale en mètres
      'min': minAlt,          // altitude minimale en mètres
    };
  }
}