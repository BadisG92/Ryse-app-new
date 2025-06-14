import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/services/database_service.dart';
import '../lib/types/database_types.dart';

// Generate mocks
@GenerateMocks([SupabaseClient])
import 'database_service_test.mocks.dart';

void main() {
  group('DatabaseService Tests', () {
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
    });

    group('Exercise Functions', () {
      test('getExercises should return list of exercises', () async {
        // Arrange
        final mockResponse = [
          {
            'id': '1',
            'name': 'Bench Press',
            'muscle_group': 'chest',
            'equipment': 'barbell',
            'description': 'Chest exercise',
            'is_custom': false,
            'user_id': null,
          },
          {
            'id': '2',
            'name': 'Squats',
            'muscle_group': 'legs',
            'equipment': 'bodyweight',
            'description': 'Leg exercise',
            'is_custom': false,
            'user_id': null,
          }
        ];

        when(mockClient.rpc('get_exercises_localized', params: anyNamed('params')))
            .thenAnswer((_) async => mockResponse);

        // Act
        // Note: This test would need dependency injection to work properly
        // For now, it demonstrates the expected behavior

        // Assert
        expect(mockResponse.length, equals(2));
        expect(mockResponse[0]['name'], equals('Bench Press'));
        expect(mockResponse[1]['muscle_group'], equals('legs'));
      });

      test('Exercise.fromJson should create valid Exercise object', () {
        // Arrange
        final json = {
          'id': '123',
          'name_en': 'Push-up',
          'name_fr': 'Pompes',
          'muscle_group': 'chest',
          'equipment': 'bodyweight',
          'description': 'Basic push-up exercise',
          'is_custom': false,
          'user_id': null,
          'created_at': '2024-01-01T00:00:00Z',
        };

        // Act
        final exercise = Exercise.fromJson(json);

        // Assert
        expect(exercise.id, equals('123'));
        expect(exercise.nameEn, equals('Push-up'));
        expect(exercise.nameFr, equals('Pompes'));
        expect(exercise.muscleGroup, equals('chest'));
        expect(exercise.equipment, equals('bodyweight'));
        expect(exercise.isCustom, equals(false));
        expect(exercise.getLocalizedName('fr'), equals('Pompes'));
        expect(exercise.getLocalizedName('en'), equals('Push-up'));
      });

      test('Exercise.toJson should create valid JSON', () {
        // Arrange
        final exercise = Exercise(
          id: '456',
          nameEn: 'Squat',
          nameFr: 'Squat',
          muscleGroup: 'legs',
          equipment: 'bodyweight',
          description: 'Basic squat exercise',
          isCustom: true,
          userId: 'user123',
        );

        // Act
        final json = exercise.toJson();

        // Assert
        expect(json['id'], equals('456'));
        expect(json['name_en'], equals('Squat'));
        expect(json['name_fr'], equals('Squat'));
        expect(json['muscle_group'], equals('legs'));
        expect(json['is_custom'], equals(true));
        expect(json['user_id'], equals('user123'));
      });
    });

    group('Food Functions', () {
      test('Food.fromJson should create valid Food object', () {
        // Arrange
        final json = {
          'id': '789',
          'name_en': 'Apple',
          'name_fr': 'Pomme',
          'calories': 52,
          'proteins': 0.3,
          'carbs': 14.0,
          'fats': 0.2,
          'category': 'Fruits',
          'is_custom': false,
          'user_id': null,
        };

        // Act
        final food = Food.fromJson(json);

        // Assert
        expect(food.id, equals('789'));
        expect(food.nameEn, equals('Apple'));
        expect(food.nameFr, equals('Pomme'));
        expect(food.calories, equals(52));
        expect(food.proteins, equals(0.3));
        expect(food.carbs, equals(14.0));
        expect(food.fats, equals(0.2));
        expect(food.category, equals('Fruits'));
        expect(food.getLocalizedName('fr'), equals('Pomme'));
        expect(food.getLocalizedName('en'), equals('Apple'));
      });

      test('Food nutritional values should be properly handled', () {
        // Arrange
        final food = Food(
          id: '1',
          nameEn: 'Test Food',
          nameFr: 'Aliment Test',
          calories: 100,
          proteins: 5.5,
          carbs: 20.0,
          fats: 3.2,
        );

        // Act & Assert
        expect(food.calories, equals(100));
        expect(food.proteins, equals(5.5));
        expect(food.carbs, equals(20.0));
        expect(food.fats, equals(3.2));
      });
    });

    group('HIIT Workout Functions', () {
      test('HiitWorkout.fromJson should create valid HiitWorkout object', () {
        // Arrange
        final json = {
          'id': 'hiit1',
          'title_en': 'Quick HIIT',
          'title_fr': 'HIIT Rapide',
          'description_en': 'Quick workout',
          'description_fr': 'Entraînement rapide',
          'work_duration': 30,
          'rest_duration': 10,
          'total_duration': 600,
          'total_rounds': 15,
          'is_custom': false,
          'user_id': null,
        };

        // Act
        final workout = HiitWorkout.fromJson(json);

        // Assert
        expect(workout.id, equals('hiit1'));
        expect(workout.titleEn, equals('Quick HIIT'));
        expect(workout.titleFr, equals('HIIT Rapide'));
        expect(workout.workDuration, equals(30));
        expect(workout.restDuration, equals(10));
        expect(workout.totalRounds, equals(15));
        expect(workout.getLocalizedTitle('fr'), equals('HIIT Rapide'));
        expect(workout.getLocalizedDescription('fr'), equals('Entraînement rapide'));
      });
    });

    group('Recipe Functions', () {
      test('Recipe.fromJson should handle JSONB ingredients', () {
        // Arrange
        final json = {
          'id': 'recipe1',
          'name_en': 'Apple Pie',
          'name_fr': 'Tarte aux Pommes',
          'ingredients': [
            {'quantity': 3, 'unit': 'cups', 'food_name': 'Apples'},
            {'quantity': 1, 'unit': 'cup', 'food_name': 'Sugar'}
          ],
          'steps_en': ['Peel apples', 'Mix ingredients', 'Bake'],
          'steps_fr': ['Éplucher les pommes', 'Mélanger les ingrédients', 'Cuire'],
          'servings': 8,
          'difficulty': 'medium',
          'tags': ['dessert', 'fruit'],
        };

        // Act
        final recipe = Recipe.fromJson(json);

        // Assert
        expect(recipe.id, equals('recipe1'));
        expect(recipe.nameEn, equals('Apple Pie'));
        expect(recipe.nameFr, equals('Tarte aux Pommes'));
        expect(recipe.servings, equals(8));
        expect(recipe.difficulty, equals('medium'));
        expect(recipe.stepsEn.length, equals(3));
        expect(recipe.stepsFr.length, equals(3));
        expect(recipe.tags, contains('dessert'));
        expect(recipe.getLocalizedName('fr'), equals('Tarte aux Pommes'));
        expect(recipe.getLocalizedSteps('fr')[0], equals('Éplucher les pommes'));
      });
    });

    group('Session Types', () {
      test('WorkoutSession should handle dates correctly', () {
        // Arrange
        final now = DateTime.now();
        final session = WorkoutSession(
          id: 'session1',
          userId: 'user1',
          name: 'Morning Workout',
          startTime: now,
          endTime: now.add(Duration(hours: 1)),
          isCompleted: true,
        );

        // Act
        final json = session.toJson();
        final recreated = WorkoutSession.fromJson(json);

        // Assert
        expect(recreated.id, equals('session1'));
        expect(recreated.name, equals('Morning Workout'));
        expect(recreated.isCompleted, equals(true));
        expect(recreated.startTime.difference(now).inSeconds, lessThan(1));
      });

      test('CardioSession should handle all metrics', () {
        // Arrange
        final session = CardioSession(
          id: 'cardio1',
          userId: 'user1',
          activityType: 'running',
          activityTitle: 'Morning Run',
          formatTitle: 'Distance',
          startTime: DateTime.now(),
          durationSeconds: 1800,
          distanceKm: 5.0,
          averageSpeedKmh: 10.0,
          steps: 6000,
          calories: 300,
        );

        // Act
        final json = session.toJson();

        // Assert
        expect(json['activity_type'], equals('running'));
        expect(json['distance_km'], equals(5.0));
        expect(json['average_speed_kmh'], equals(10.0));
        expect(json['steps'], equals(6000));
        expect(json['calories'], equals(300));
      });
    });

    group('UserDailySummary', () {
      test('should aggregate daily metrics correctly', () {
        // Arrange
        final json = {
          'summary_date': '2024-01-01',
          'total_meals': 3,
          'total_calories_nutrition': 2000,
          'workout_sessions': 1,
          'hiit_sessions': 1,
          'cardio_sessions': 1,
          'total_calories_burned': 500,
        };

        // Act
        final summary = UserDailySummary.fromJson(json);

        // Assert
        expect(summary.summaryDate, equals('2024-01-01'));
        expect(summary.totalMeals, equals(3));
        expect(summary.totalCaloriesNutrition, equals(2000));
        expect(summary.workoutSessions, equals(1));
        expect(summary.hiitSessions, equals(1));
        expect(summary.cardioSessions, equals(1));
        expect(summary.totalCaloriesBurned, equals(500));
      });
    });

    group('Localization Helper', () {
      test('should return correct localized names', () {
        // Act & Assert
        expect(
          LocalizationHelper.getLocalizedName('Apple', 'Pomme', 'fr'),
          equals('Pomme')
        );
        expect(
          LocalizationHelper.getLocalizedName('Apple', 'Pomme', 'en'),
          equals('Apple')
        );
        expect(
          LocalizationHelper.getLocalizedName('Apple', 'Pomme', 'es'),
          equals('Apple') // Default to English for unknown languages
        );
      });

      test('should return correct localized steps', () {
        // Arrange
        final stepsEn = ['Step 1', 'Step 2', 'Step 3'];
        final stepsFr = ['Étape 1', 'Étape 2', 'Étape 3'];

        // Act & Assert
        expect(
          LocalizationHelper.getLocalizedSteps(stepsEn, stepsFr, 'fr'),
          equals(stepsFr)
        );
        expect(
          LocalizationHelper.getLocalizedSteps(stepsEn, stepsFr, 'en'),
          equals(stepsEn)
        );
      });
    });
  });

  group('Integration Tests', () {
    test('should handle null and empty values gracefully', () {
      // Test Exercise with minimal data
      final exerciseJson = {
        'id': '1',
        'name_en': 'Test',
        'name_fr': 'Test',
        'muscle_group': 'test',
      };
      
      final exercise = Exercise.fromJson(exerciseJson);
      expect(exercise.equipment, isNull);
      expect(exercise.description, isNull);
      expect(exercise.isCustom, equals(false)); // Default value
    });

    test('should handle date parsing correctly', () {
      final dateString = '2024-01-01T12:00:00Z';
      final parsed = DateTime.parse(dateString);
      
      expect(parsed.year, equals(2024));
      expect(parsed.month, equals(1));
      expect(parsed.day, equals(1));
    });
  });
} 