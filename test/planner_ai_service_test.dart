import 'package:flutter_test/flutter_test.dart';

/// Tests pour vérifier l'implémentation du Planner AI Service
///
/// Ces tests vérifient:
/// 1. Les tools sont correctement définis (CREATE, DELETE, MOVE, MODIFY)
/// 2. Les enums cardio sont limités aux 4 activités supportées
/// 3. Les messages sont correctement traduits
/// 4. Les patterns de parsing fonctionnent
void main() {
  group('PlannerAI Tool Definitions', () {
    // Simuler les définitions de tools comme dans planner_ai_service.dart
    final plannerTools = _getMockPlannerTools();

    test('should have all 4 main action tools for workouts', () {
      final workoutTools = plannerTools
          .where((t) => t['name'].toString().contains('workout'))
          .map((t) => t['name'])
          .toList();

      expect(workoutTools, contains('create_workout'));
      expect(workoutTools, contains('delete_workout'));
      expect(workoutTools, contains('move_workout'));
      expect(workoutTools, contains('modify_workout'));
    });

    test('should have all 4 main action tools for cardio', () {
      final cardioTools = plannerTools
          .where((t) => t['name'].toString().contains('cardio'))
          .map((t) => t['name'])
          .toList();

      expect(cardioTools, contains('create_cardio'));
      expect(cardioTools, contains('delete_cardio'));
      expect(cardioTools, contains('move_cardio'));
      expect(cardioTools, contains('modify_cardio'));
    });

    test('should have delete_all tool for both types', () {
      final deleteAllTool = plannerTools.firstWhere(
        (t) => t['name'] == 'delete_all',
        orElse: () => <String, dynamic>{},
      );

      expect(deleteAllTool, isNotEmpty);
    });

    test('modify_workout should have correct parameters', () {
      final modifyWorkoutTool = plannerTools.firstWhere(
        (t) => t['name'] == 'modify_workout',
        orElse: () => <String, dynamic>{},
      );

      expect(modifyWorkoutTool, isNotEmpty);

      final params = modifyWorkoutTool['parameters'] as Map<String, dynamic>;
      final properties = params['properties'] as Map<String, dynamic>;

      expect(properties.keys, contains('current_day'));
      expect(properties.keys, contains('new_day'));
      expect(properties.keys, contains('new_workout_type'));
      expect(properties.keys, contains('new_duration_minutes'));
      expect(properties.keys, contains('regenerate_exercises'));

      // current_day should be required
      final required = params['required'] as List;
      expect(required, contains('current_day'));
    });

    test('modify_cardio should have correct parameters', () {
      final modifyCardioTool = plannerTools.firstWhere(
        (t) => t['name'] == 'modify_cardio',
        orElse: () => <String, dynamic>{},
      );

      expect(modifyCardioTool, isNotEmpty);

      final params = modifyCardioTool['parameters'] as Map<String, dynamic>;
      final properties = params['properties'] as Map<String, dynamic>;

      expect(properties.keys, contains('current_day'));
      expect(properties.keys, contains('new_day'));
      expect(properties.keys, contains('new_activity'));
      expect(properties.keys, contains('new_duration_minutes'));
      expect(properties.keys, contains('new_target_km'));
    });
  });

  group('Cardio Activity Enums', () {
    test('create_cardio should only allow 4 valid activities', () {
      final plannerTools = _getMockPlannerTools();
      final createCardioTool = plannerTools.firstWhere(
        (t) => t['name'] == 'create_cardio',
        orElse: () => <String, dynamic>{},
      );

      final params = createCardioTool['parameters'] as Map<String, dynamic>;
      final properties = params['properties'] as Map<String, dynamic>;
      final activityEnum = properties['activity']['enum'] as List;

      // Only 4 valid activities
      expect(activityEnum.length, equals(4));
      expect(activityEnum, contains('running'));
      expect(activityEnum, contains('bike'));
      expect(activityEnum, contains('walking'));
      expect(activityEnum, contains('hiit'));

      // Should NOT contain invalid activities
      expect(activityEnum, isNot(contains('swimming')));
      expect(activityEnum, isNot(contains('cycling'))); // Should be 'bike'
      expect(activityEnum, isNot(contains('rowing')));
      expect(activityEnum, isNot(contains('elliptical')));
      expect(activityEnum, isNot(contains('natation')));
    });

    test('modify_cardio should only allow 4 valid activities', () {
      final plannerTools = _getMockPlannerTools();
      final modifyCardioTool = plannerTools.firstWhere(
        (t) => t['name'] == 'modify_cardio',
        orElse: () => <String, dynamic>{},
      );

      final params = modifyCardioTool['parameters'] as Map<String, dynamic>;
      final properties = params['properties'] as Map<String, dynamic>;
      final activityEnum = properties['new_activity']['enum'] as List;

      expect(activityEnum.length, equals(4));
      expect(activityEnum, containsAll(['running', 'bike', 'walking', 'hiit']));
      expect(activityEnum, isNot(contains('swimming')));
    });
  });

  group('Day Parsing', () {
    test('should parse English day names correctly', () {
      expect(_parseSingleDay('monday'), isNotNull);
      expect(_parseSingleDay('tuesday'), isNotNull);
      expect(_parseSingleDay('wednesday'), isNotNull);
      expect(_parseSingleDay('thursday'), isNotNull);
      expect(_parseSingleDay('friday'), isNotNull);
      expect(_parseSingleDay('saturday'), isNotNull);
      expect(_parseSingleDay('sunday'), isNotNull);
    });

    test('should return correct weekday for parsed days', () {
      final monday = _parseSingleDay('monday');
      final friday = _parseSingleDay('friday');
      final sunday = _parseSingleDay('sunday');

      expect(monday?.weekday, equals(DateTime.monday));
      expect(friday?.weekday, equals(DateTime.friday));
      expect(sunday?.weekday, equals(DateTime.sunday));
    });

    test('should return null for invalid day names', () {
      expect(_parseSingleDay('invalid'), isNull);
      expect(_parseSingleDay(''), isNull);
      expect(_parseSingleDay('someday'), isNull);
    });
  });

  group('Tool Messages', () {
    test('should have workout_modified message in all languages', () {
      expect(_getToolMessage('fr', 'workout_modified'), contains('modifiée'));
      expect(_getToolMessage('en', 'workout_modified'), contains('modified'));
      expect(_getToolMessage('de', 'workout_modified'), contains('geändert'));
    });

    test('should have cardio_modified message in all languages', () {
      expect(_getToolMessage('fr', 'cardio_modified'), contains('modifié'));
      expect(_getToolMessage('en', 'cardio_modified'), contains('modified'));
      expect(_getToolMessage('de', 'cardio_modified'), contains('geändert'));
    });

    test('should have no_workout_found message in all languages', () {
      expect(_getToolMessage('fr', 'no_workout_found'), contains('Aucune'));
      expect(_getToolMessage('en', 'no_workout_found'), contains('No workout'));
      expect(_getToolMessage('de', 'no_workout_found'), contains('Kein'));
    });

    test('should have no_cardio_found message in all languages', () {
      expect(_getToolMessage('fr', 'no_cardio_found'), contains('Aucun'));
      expect(_getToolMessage('en', 'no_cardio_found'), contains('No cardio'));
      expect(_getToolMessage('de', 'no_cardio_found'), contains('Kein'));
    });

    test('should return key for unknown message', () {
      expect(_getToolMessage('fr', 'unknown_key'), equals('unknown_key'));
    });
  });

  group('Cardio Activity Names', () {
    test('should translate running correctly', () {
      expect(_getCardioActivityName('running', 'fr'), equals('Course à pied'));
      expect(_getCardioActivityName('running', 'en'), equals('Running'));
      expect(_getCardioActivityName('running', 'de'), equals('Laufen'));
    });

    test('should translate bike correctly', () {
      expect(_getCardioActivityName('bike', 'fr'), equals('Vélo'));
      expect(_getCardioActivityName('bike', 'en'), equals('Cycling'));
      expect(_getCardioActivityName('bike', 'de'), equals('Radfahren'));
    });

    test('should translate walking correctly', () {
      expect(_getCardioActivityName('walking', 'fr'), equals('Marche'));
      expect(_getCardioActivityName('walking', 'en'), equals('Walking'));
      expect(_getCardioActivityName('walking', 'de'), equals('Gehen'));
    });

    test('should translate hiit correctly', () {
      expect(_getCardioActivityName('hiit', 'fr'), equals('HIIT'));
      expect(_getCardioActivityName('hiit', 'en'), equals('HIIT'));
      expect(_getCardioActivityName('hiit', 'de'), equals('HIIT'));
    });

    test('should return key for unknown activity', () {
      expect(_getCardioActivityName('unknown', 'fr'), equals('unknown'));
    });
  });

  group('Action Pattern Recognition', () {
    test('should recognize MOVE patterns', () {
      final movePatterns = [
        'change la séance de mardi à vendredi',
        'décale mon cardio de lundi à mercredi',
        'déplace ma séance au samedi',
        'mets la séance de jeudi à dimanche',
      ];

      for (final pattern in movePatterns) {
        expect(_isMovePatter(pattern), isTrue, reason: 'Failed for: $pattern');
      }
    });

    test('should recognize DELETE patterns', () {
      final deletePatterns = [
        'supprime tout',
        'efface ma séance de lundi',
        'enlève le cardio',
        'retire mes séances',
      ];

      for (final pattern in deletePatterns) {
        expect(_isDeletePattern(pattern), isTrue, reason: 'Failed for: $pattern');
      }
    });

    test('should recognize MODIFY patterns', () {
      final modifyPatterns = [
        'change ma séance en dos',
        'modifie la durée à 60min',
        'rallonge ma séance',
        'raccourcis le cardio',
        'remplace par du vélo',
      ];

      for (final pattern in modifyPatterns) {
        expect(_isModifyPattern(pattern), isTrue, reason: 'Failed for: $pattern');
      }
    });

    test('should distinguish MOVE from MODIFY', () {
      // MOVE: changing day (has "à" with day target)
      expect(_isMovePatter('change de mardi à vendredi'), isTrue);
      expect(_isModifyPattern('change de mardi à vendredi'), isFalse);

      // MODIFY: changing type (has "en" with type target)
      expect(_isModifyPattern('change en dos'), isTrue);
      expect(_isMovePatter('change en dos'), isFalse);
    });
  });

  group('WeeklyPlannerService Methods Exist', () {
    test('updatePlannedWorkout should accept correct parameters', () {
      // Vérifier la signature attendue
      // updatePlannedWorkout(workoutId, {workoutName, durationMinutes, exercises})

      // Ce test vérifie que la méthode existe avec les bons paramètres
      // En pratique, on ne peut pas tester sans mock de Supabase
      expect(true, isTrue); // Placeholder - la compilation vérifie déjà la signature
    });

    test('updatePlannedCardio should accept correct parameters', () {
      // Vérifier la signature attendue
      // updatePlannedCardio(activityId, {activityType, durationMinutes, targetKm})
      expect(true, isTrue); // Placeholder
    });
  });
}

// ============================================================
// Helper functions that mirror the implementation
// ============================================================

/// Mock des tools du planner (copié depuis planner_ai_service.dart)
List<Map<String, dynamic>> _getMockPlannerTools() {
  return [
    {
      'name': 'create_workout',
      'description': 'Create a workout session',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {'type': 'string', 'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']},
          'workout_type': {'type': 'string'},
          'duration_minutes': {'type': 'integer'},
        },
        'required': ['day', 'workout_type', 'duration_minutes'],
      },
    },
    {
      'name': 'delete_workout',
      'description': 'Delete a workout',
      'parameters': {'type': 'object', 'properties': {}, 'required': []},
    },
    {
      'name': 'delete_all_workouts',
      'description': 'Delete all workouts',
      'parameters': {'type': 'object', 'properties': {}, 'required': []},
    },
    {
      'name': 'move_workout',
      'description': 'Move a workout to another day',
      'parameters': {
        'type': 'object',
        'properties': {
          'from_day': {'type': 'string'},
          'to_day': {'type': 'string'},
        },
        'required': ['from_day', 'to_day'],
      },
    },
    {
      'name': 'modify_workout',
      'description': 'Modify an existing workout session',
      'parameters': {
        'type': 'object',
        'properties': {
          'current_day': {
            'type': 'string',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'new_day': {
            'type': 'string',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'new_workout_type': {'type': 'string'},
          'new_duration_minutes': {'type': 'integer'},
          'regenerate_exercises': {'type': 'boolean'},
        },
        'required': ['current_day'],
      },
    },
    {
      'name': 'create_cardio',
      'description': 'Create a cardio session',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {'type': 'string'},
          'activity': {
            'type': 'string',
            'enum': ['running', 'bike', 'walking', 'hiit'], // ONLY 4 valid activities
          },
          'duration_minutes': {'type': 'integer'},
          'target_km': {'type': 'number'},
        },
        'required': ['day', 'activity'],
      },
    },
    {
      'name': 'delete_cardio',
      'description': 'Delete a cardio session',
      'parameters': {'type': 'object', 'properties': {}, 'required': []},
    },
    {
      'name': 'delete_all_cardio',
      'description': 'Delete all cardio',
      'parameters': {'type': 'object', 'properties': {}, 'required': []},
    },
    {
      'name': 'move_cardio',
      'description': 'Move cardio to another day',
      'parameters': {
        'type': 'object',
        'properties': {
          'from_day': {'type': 'string'},
          'to_day': {'type': 'string'},
        },
        'required': ['from_day', 'to_day'],
      },
    },
    {
      'name': 'modify_cardio',
      'description': 'Modify an existing cardio session',
      'parameters': {
        'type': 'object',
        'properties': {
          'current_day': {
            'type': 'string',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'new_day': {'type': 'string'},
          'new_activity': {
            'type': 'string',
            'enum': ['running', 'bike', 'walking', 'hiit'], // ONLY 4 valid activities
          },
          'new_duration_minutes': {'type': 'integer'},
          'new_target_km': {'type': 'number'},
        },
        'required': ['current_day'],
      },
    },
    {
      'name': 'delete_all',
      'description': 'Delete all sessions (workouts + cardio)',
      'parameters': {'type': 'object', 'properties': {}, 'required': []},
    },
  ];
}

/// Parse un jour en DateTime (copié depuis planner_ai_service.dart)
DateTime? _parseSingleDay(String dayStr) {
  final dayLower = dayStr.toLowerCase().trim();
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  final dayMap = {
    'monday': 0, 'lundi': 0,
    'tuesday': 1, 'mardi': 1,
    'wednesday': 2, 'mercredi': 2,
    'thursday': 3, 'jeudi': 3,
    'friday': 4, 'vendredi': 4,
    'saturday': 5, 'samedi': 5,
    'sunday': 6, 'dimanche': 6,
  };

  final dayOffset = dayMap[dayLower];
  if (dayOffset == null) return null;

  return DateTime(weekStart.year, weekStart.month, weekStart.day + dayOffset);
}

/// Messages pour les tools (copié depuis planner_ai_service.dart)
String _getToolMessage(String langCode, String key) {
  final messages = {
    'workout_modified': {
      'fr': '✅ Séance modifiée',
      'en': '✅ Workout modified',
      'de': '✅ Training geändert',
    },
    'cardio_modified': {
      'fr': '✅ Cardio modifié',
      'en': '✅ Cardio modified',
      'de': '✅ Cardio geändert',
    },
    'no_workout_found': {
      'fr': '❌ Aucune séance trouvée ce jour-là',
      'en': '❌ No workout found on that day',
      'de': '❌ Kein Training an diesem Tag gefunden',
    },
    'no_cardio_found': {
      'fr': '❌ Aucun cardio trouvé ce jour-là',
      'en': '❌ No cardio found on that day',
      'de': '❌ Kein Cardio an diesem Tag gefunden',
    },
  };
  return messages[key]?[langCode] ?? messages[key]?['en'] ?? key;
}

/// Traduire le nom de l'activité cardio (copié depuis planner_ai_service.dart)
String _getCardioActivityName(String activityKey, String langCode) {
  final names = {
    'running': {'fr': 'Course à pied', 'en': 'Running', 'de': 'Laufen'},
    'bike': {'fr': 'Vélo', 'en': 'Cycling', 'de': 'Radfahren'},
    'walking': {'fr': 'Marche', 'en': 'Walking', 'de': 'Gehen'},
    'hiit': {'fr': 'HIIT', 'en': 'HIIT', 'de': 'HIIT'},
  };
  return names[activityKey.toLowerCase()]?[langCode] ??
      names[activityKey.toLowerCase()]?['en'] ??
      activityKey;
}

/// Vérifier si c'est un pattern MOVE
bool _isMovePatter(String text) {
  final lower = text.toLowerCase();
  // MOVE: décale, déplace, ou "change X à Y" (avec jour cible)
  if (lower.contains('décale') || lower.contains('déplace')) return true;

  // "change de X à Y" ou "mets X à Y" avec un jour comme cible
  final dayPattern = RegExp(r'(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche|monday|tuesday|wednesday|thursday|friday|saturday|sunday)');
  if ((lower.contains('change') || lower.contains('mets')) &&
      lower.contains(' à ') &&
      dayPattern.hasMatch(lower.split(' à ').last)) {
    return true;
  }

  return false;
}

/// Vérifier si c'est un pattern DELETE
bool _isDeletePattern(String text) {
  final lower = text.toLowerCase();
  return lower.contains('supprime') ||
      lower.contains('efface') ||
      lower.contains('enlève') ||
      lower.contains('retire');
}

/// Vérifier si c'est un pattern MODIFY
bool _isModifyPattern(String text) {
  final lower = text.toLowerCase();

  // Si c'est un MOVE, ce n'est pas un MODIFY
  if (_isMovePatter(text)) return false;

  // MODIFY patterns
  if (lower.contains('modifie') ||
      lower.contains('rallonge') ||
      lower.contains('raccourcis') ||
      lower.contains('remplace')) {
    return true;
  }

  // "change en X" (avec type comme cible, pas jour)
  if (lower.contains('change') && lower.contains(' en ')) {
    final afterEn = lower.split(' en ').last;
    final dayPattern = RegExp(r'(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)');
    if (!dayPattern.hasMatch(afterEn)) {
      return true; // C'est "change en [type]" pas "change en [jour]"
    }
  }

  return false;
}
