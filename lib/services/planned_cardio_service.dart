import 'package:flutter/foundation.dart';
import '../models/weekly_planner_models.dart';
import 'weekly_planner_service.dart';

/// Service partagé pour la création de cardio/HIIT planifiés
/// Utilisé par l'IA ET les écrans UI pour garantir la cohérence
class PlannedCardioService {
  // =====================================================
  // HIIT PRESETS
  // =====================================================

  /// Les presets HIIT disponibles (synchronisés avec la DB cardio_activity_formats)
  static const Map<String, HiitPreset> hiitPresets = {
    'tabata': HiitPreset(
      id: 'tabata',
      name: 'Tabata',
      nameFr: 'Tabata',
      workSeconds: 20,
      restSeconds: 10,
      rounds: 8,
      description: '4 min - 20s effort / 10s rest - 8 rounds',
      descriptionFr: '4 min - 20s effort / 10s repos - 8 rounds',
    ),
    'hiit_beginner': HiitPreset(
      id: 'hiit_beginner',
      name: 'Beginner HIIT',
      nameFr: 'HIIT Débutant',
      workSeconds: 30,
      restSeconds: 30,
      rounds: 15,
      description: '15 min - 30s effort / 30s rest - 15 rounds',
      descriptionFr: '15 min - 30s effort / 30s repos - 15 rounds',
    ),
    'hiit_intense': HiitPreset(
      id: 'hiit_intense',
      name: 'Intense HIIT',
      nameFr: 'HIIT Intense',
      workSeconds: 45,
      restSeconds: 15,
      rounds: 20,
      description: '20 min - 45s effort / 15s rest - 20 rounds',
      descriptionFr: '20 min - 45s effort / 15s repos - 20 rounds',
    ),
  };

  /// Types de cardio supportés (hors HIIT)
  static const List<String> cardioTypes = ['running', 'bike', 'walking'];

  // =====================================================
  // VALIDATION
  // =====================================================

  /// Valide et normalise un type HIIT
  /// Retourne le preset correspondant ou null si invalide
  static HiitPreset? validateHiitType(String? type) {
    if (type == null || type.isEmpty) return null;

    final normalized = type.toLowerCase().trim();

    // Correspondance directe
    if (hiitPresets.containsKey(normalized)) {
      return hiitPresets[normalized];
    }

    // Correspondance par alias
    if (normalized == 'beginner' || normalized == 'débutant' || normalized == 'debutant') {
      return hiitPresets['hiit_beginner'];
    }
    if (normalized == 'intense' || normalized == 'advanced' || normalized == 'avancé') {
      return hiitPresets['hiit_intense'];
    }

    return null;
  }

  /// Valide un type cardio (hors HIIT)
  static String? validateCardioType(String? type) {
    if (type == null || type.isEmpty) return null;

    final normalized = type.toLowerCase().trim();

    // Mapping des synonymes
    if (normalized == 'course' || normalized == 'courir' || normalized == 'run') {
      return 'running';
    }
    if (normalized == 'vélo' || normalized == 'velo' || normalized == 'cycling') {
      return 'bike';
    }
    if (normalized == 'marche' || normalized == 'walk') {
      return 'walking';
    }

    // Correspondance directe
    if (cardioTypes.contains(normalized)) {
      return normalized;
    }

    return null;
  }

  /// Détecte si un type demandé est un HIIT
  static bool isHiitType(String? type) {
    if (type == null) return false;
    final lower = type.toLowerCase().trim();
    return lower.contains('hiit') ||
           lower.contains('tabata') ||
           lower == 'hit' ||
           hiitPresets.containsKey(lower);
  }

  // =====================================================
  // CREATE HIIT
  // =====================================================

  /// Crée une séance HIIT planifiée
  /// Utilisée par l'IA et les écrans UI
  static Future<PlannedActivity?> createPlannedHiit({
    required DateTime date,
    required HiitPreset preset,
    String? customName,
  }) async {
    final hiitConfig = HiitConfig(
      workSeconds: preset.workSeconds,
      restSeconds: preset.restSeconds,
      rounds: preset.rounds,
      type: preset.id,
    );

    final activityData = {
      'activity_key': 'hiit',
      'activity_name': customName ?? preset.nameFr,
      'target_minutes': hiitConfig.totalMinutes,
      'hiit_config': hiitConfig.toJson(),
    };

    debugPrint('🏃 PlannedCardioService: Creating HIIT ${preset.id} for ${date.toIso8601String()}');
    debugPrint('   Config: ${hiitConfig.workSeconds}s work / ${hiitConfig.restSeconds}s rest × ${hiitConfig.rounds} rounds');

    final result = await WeeklyPlannerService.addPlannedActivity(
      plannedDate: date,
      activityType: PlannedActivityType.cardio,
      activityData: activityData,
      isAiGenerated: true,
    );

    if (result != null) {
      debugPrint('✅ PlannedCardioService: HIIT created successfully (id: ${result.id})');
    }

    return result;
  }

  /// Crée une séance HIIT avec paramètres custom
  static Future<PlannedActivity?> createCustomHiit({
    required DateTime date,
    required int workSeconds,
    required int restSeconds,
    required int rounds,
    String? customName,
  }) async {
    final hiitConfig = HiitConfig(
      workSeconds: workSeconds,
      restSeconds: restSeconds,
      rounds: rounds,
      type: 'custom',
    );

    final activityData = {
      'activity_key': 'hiit',
      'activity_name': customName ?? 'HIIT Custom',
      'target_minutes': hiitConfig.totalMinutes,
      'hiit_config': hiitConfig.toJson(),
    };

    debugPrint('🏃 PlannedCardioService: Creating custom HIIT for ${date.toIso8601String()}');
    debugPrint('   Config: ${workSeconds}s work / ${restSeconds}s rest × $rounds rounds');

    return await WeeklyPlannerService.addPlannedActivity(
      plannedDate: date,
      activityType: PlannedActivityType.cardio,
      activityData: activityData,
      isAiGenerated: true,
    );
  }

  // =====================================================
  // CREATE CARDIO (non-HIIT)
  // =====================================================

  /// Crée une séance cardio planifiée (course, vélo, marche)
  static Future<PlannedActivity?> createPlannedCardio({
    required DateTime date,
    required String activityType,
    int? durationMinutes,
    double? targetKm,
    String? customName,
  }) async {
    // Valider le type
    final validatedType = validateCardioType(activityType);
    if (validatedType == null) {
      debugPrint('❌ PlannedCardioService: Invalid cardio type: $activityType');
      return null;
    }

    // Générer le nom selon le type
    final activityName = customName ?? _getCardioName(validatedType);

    final activityData = {
      'activity_key': validatedType,
      'activity_name': activityName,
      if (durationMinutes != null) 'target_minutes': durationMinutes,
      if (targetKm != null) 'target_km': targetKm,
    };

    debugPrint('🏃 PlannedCardioService: Creating cardio $validatedType for ${date.toIso8601String()}');
    if (durationMinutes != null) debugPrint('   Duration: $durationMinutes min');
    if (targetKm != null) debugPrint('   Target: $targetKm km');

    return await WeeklyPlannerService.addPlannedActivity(
      plannedDate: date,
      activityType: PlannedActivityType.cardio,
      activityData: activityData,
      isAiGenerated: true,
    );
  }

  // =====================================================
  // HELPERS
  // =====================================================

  static String _getCardioName(String type) {
    switch (type) {
      case 'running':
        return 'Course à pied';
      case 'bike':
        return 'Vélo';
      case 'walking':
        return 'Marche';
      default:
        return type;
    }
  }

  /// Obtient la liste des presets HIIT pour l'affichage (UI ou IA)
  static List<HiitPreset> getHiitPresetsList() {
    return hiitPresets.values.toList();
  }

  /// Obtient le message de proposition des presets HIIT
  static String getHiitPresetsMessage(String langCode) {
    if (langCode == 'fr') {
      return '''Quel type de HIIT tu veux ?
• **Tabata** - 4 min (20s effort / 10s repos × 8)
• **Débutant** - 15 min (30s effort / 30s repos × 15)
• **Intense** - 20 min (45s effort / 15s repos × 20)
• **Custom** - Tu choisis tes paramètres''';
    }
    return '''What type of HIIT do you want?
• **Tabata** - 4 min (20s work / 10s rest × 8)
• **Beginner** - 15 min (30s work / 30s rest × 15)
• **Intense** - 20 min (45s work / 15s rest × 20)
• **Custom** - Choose your own parameters''';
  }
}

/// Modèle pour un preset HIIT
class HiitPreset {
  final String id;
  final String name;
  final String nameFr;
  final int workSeconds;
  final int restSeconds;
  final int rounds;
  final String description;
  final String descriptionFr;

  const HiitPreset({
    required this.id,
    required this.name,
    required this.nameFr,
    required this.workSeconds,
    required this.restSeconds,
    required this.rounds,
    required this.description,
    required this.descriptionFr,
  });

  int get totalMinutes => ((workSeconds + restSeconds) * rounds / 60).ceil();

  String getLocalizedName(String langCode) => langCode == 'fr' ? nameFr : name;
  String getLocalizedDescription(String langCode) => langCode == 'fr' ? descriptionFr : description;
}
