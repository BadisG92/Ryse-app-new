import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/models/sport_models.dart';
import 'package:ryze_app/screens/ai_workout_generator_screen.dart';

/// Le nom d'une séance générée par Coach Ryze.
///
/// Les deux groupes les plus travaillés la nommaient quoi qu'il arrive : une
/// séance corps entier — un squat, un développé couché, un rowing, un développé
/// épaules, un curl — s'appelait donc « Legs & Chest », du nom de ses deux
/// premiers exercices. Le nom disait jambes et pectoraux, la séance faisait
/// tout le corps.
void main() {
  List<WorkoutExercise> workout(List<String> groups) => [
        for (final (i, g) in groups.indexed)
          WorkoutExercise(
            exercise: Exercise(id: '$i', name: 'ex$i', muscleGroup: g),
            sets: const [],
          ),
      ];

  test('un exercice par groupe, c’est un corps entier', () {
    expect(workoutNameFor(workout(['legs', 'chest', 'back', 'shoulders', 'arms']), 'fr'), 'Corps entier');
    expect(workoutNameFor(workout(['legs', 'chest', 'back', 'shoulders', 'arms']), 'en'), 'Full body');
  });

  test('deux groupes qui portent vraiment la séance la nomment', () {
    expect(
      workoutNameFor(workout(['chest', 'chest', 'chest', 'triceps', 'triceps', 'shoulders']), 'fr'),
      'Chest & Triceps',
    );
  });

  test('un seul groupe se dit seul', () {
    expect(workoutNameFor(workout(['back', 'back', 'back']), 'fr'), 'Back');
  });

  test('deux groupes exactement restent deux groupes', () {
    expect(workoutNameFor(workout(['legs', 'legs', 'glutes']), 'fr'), 'Legs & Glutes');
  });

  test('sans groupe connu, le nom générique', () {
    expect(workoutNameFor(workout(['', '  ']), 'fr'), 'Séance créée par Coach Ryze');
  });

  group('le nom que le modèle propose', () {
    final fullBody = workout(['legs', 'chest', 'back', 'shoulders', 'arms']);

    test('un nom sobre passe tel quel', () {
      expect(sessionNameFrom('Séance de foot', fullBody, 'fr'), 'Séance de foot');
    });

    test('les guillemets du modèle tombent', () {
      expect(sessionNameFrom('"Haut du corps"', fullBody, 'fr'), 'Haut du corps');
    });

    test('les emoji tombent', () {
      expect(sessionNameFrom('Corps entier 💪', fullBody, 'fr'), 'Corps entier');
    });

    test('un nom qui vend du rêve est écarté', () {
      expect(sessionNameFrom('🔥 ULTIMATE FULL BODY BEAST MODE BLAST!!!', fullBody, 'fr'), 'Corps entier');
    });

    test('rien, trop court, ou vide : le comptage reprend la main', () {
      expect(sessionNameFrom(null, fullBody, 'fr'), 'Corps entier');
      expect(sessionNameFrom('   ', fullBody, 'fr'), 'Corps entier');
      expect(sessionNameFrom('Go', fullBody, 'fr'), 'Corps entier');
    });
  });
}
