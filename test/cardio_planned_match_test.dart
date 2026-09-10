import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/services/weekly_planner_service.dart';

/// Une course prévue et la course faite sont la même sortie.
///
/// Tout ce qui planifie un cardio écrit `activity_key` ; seule la
/// synchronisation d'une séance terminée pose `cardio_type`, et c'était la
/// seule clé que la recherche lisait. Une course prévue le matin restait donc
/// « à faire » le soir, avec la course faite affichée juste en dessous.
void main() {
  String? type(Map<String, dynamic>? data) => WeeklyPlannerService.cardioTypeOf(data);

  test('ce que le coach écrit quand il prévoit une course', () {
    // La forme exacte trouvée en base le 10 septembre 2026.
    expect(type({'target_km': 10, 'activity_key': 'running', 'activity_name': 'Course à pied'}), 'running');
  });

  test('ce que la séance terminée écrit', () {
    expect(
      type({'target_km': 9.99, 'cardio_type': 'running', 'activity_key': 'running', 'duration_minutes': 30}),
      'running',
    );
  });

  test('un vélo prévu ne répond pas pour une course', () {
    expect(type({'activity_key': 'bike'}), isNot('running'));
  });

  test('rien à dire quand il n’y a rien', () {
    expect(type(null), isNull);
    expect(type(const {}), isNull);
  });
}
