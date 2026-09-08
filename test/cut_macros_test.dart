import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/components/ui/onboarding_models.dart';

/// La répartition d'une sèche.
///
/// La règle qui compte : la protéine se calcule sur le poids du corps, pas sur
/// une part des calories. La part fixe se dégrade exactement là où la protéine
/// est la plus utile, c'est-à-dire dans un déficit franc.
void main() {
  UserProfile profile({
    String gender = 'Homme',
    String age = '30',
    String weight = '80',
    String height = '180',
    String activity = 'moderate',
    String goal = 'lose',
  }) =>
      UserProfile(
        gender: gender,
        age: age,
        weight: weight,
        height: height,
        activity: activity,
        goal: goal,
        obstacles: const [],
        restrictions: const [],
      );

  int kcalOf(Map<String, int> m) => m['protein']! * 4 + m['carbs']! * 4 + m['fat']! * 9;

  group('La protéine tient au poids, pas aux calories', () {
    test('deux grammes par kilo', () {
      final m = MetabolicCalculations.cutMacros(profile());
      expect(m['protein'], 160); // 80 kg × 2,0
    });

    test('elle ne fond pas quand les calories baissent', () {
      // Le reproche fait à la répartition ordinaire : à part fixe, un homme
      // de 80 kg tombe sous 1,7 g/kg dès que le budget descend.
      final leger = MetabolicCalculations.cutMacros(profile(activity: 'low'));
      final actif = MetabolicCalculations.cutMacros(profile(activity: 'high'));

      expect(leger['protein'], actif['protein']);
    });

    test('un gabarit plus lourd en reçoit plus', () {
      final petit = MetabolicCalculations.cutMacros(profile(weight: '60'));
      final grand = MetabolicCalculations.cutMacros(profile(weight: '95'));

      expect(petit['protein']! < grand['protein']!, isTrue);
    });
  });

  group('Les garde-fous', () {
    test('la protéine ne dépasse pas quarante pour cent des calories', () {
      // Un petit budget et un gros gabarit : sans plafond, il ne resterait
      // plus de quoi manger autre chose.
      final m = MetabolicCalculations.cutMacros(
        profile(weight: '120', gender: 'Femme', age: '55', height: '155', activity: 'low'),
      );
      final calories = MetabolicCalculations.calculateDailyGoal(
        profile(weight: '120', gender: 'Femme', age: '55', height: '155', activity: 'low'),
      );

      expect(m['protein']! * 4 <= calories * 0.41, isTrue);
    });

    test('le gras garde son minimum vital', () {
      final p = profile(weight: '80');
      final m = MetabolicCalculations.cutMacros(p);

      expect(m['fat']! >= (80 * MetabolicCalculations.cutMinFatPerKg).round() - 1, isTrue);
    });

    test('les glucides ne passent jamais sous zéro', () {
      final m = MetabolicCalculations.cutMacros(
        profile(weight: '140', gender: 'Femme', age: '60', height: '150', activity: 'low'),
      );
      expect(m['carbs']! >= 0, isTrue);
    });
  });

  group('La somme retombe juste', () {
    test('les macros valent le budget du jour', () {
      final p = profile();
      final calories = MetabolicCalculations.calculateDailyGoal(p);
      final m = MetabolicCalculations.cutMacros(p);

      // À l'arrondi près : trois nombres entiers ne tombent pas au kcal.
      expect((kcalOf(m) - calories).abs() <= 5, isTrue,
          reason: '${kcalOf(m)} contre $calories');
    });

    test('sur plusieurs gabarits', () {
      for (final poids in ['55', '70', '85', '100']) {
        final p = profile(weight: poids);
        final calories = MetabolicCalculations.calculateDailyGoal(p);
        final m = MetabolicCalculations.cutMacros(p);
        expect((kcalOf(m) - calories).abs() <= 5, isTrue, reason: 'à $poids kg');
      }
    });
  });

  group('Sans les données, on ne devine pas', () {
    test('un poids manquant retombe sur la répartition ordinaire', () {
      final sans = profile(weight: '');
      expect(MetabolicCalculations.cutMacros(sans),
          MetabolicCalculations.calculateMacros(sans));
    });
  });
}
