import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/onboarding/onboarding_state.dart';

/// Le poids visé de l'onboarding.
///
/// Il valait 74 kg d'office, quel que soit le poids saisi : un homme de 95 kg
/// arrivait sur la règle avec 21 kg à perdre et « environ 35 semaines »
/// avant d'avoir rien touché. Il part maintenant du poids, d'un premier pas
/// raisonnable, et ne bouge plus une fois que la personne l'a choisi.
void main() {
  OnbAnswers answers(double kg, String goal, {bool metric = true}) => OnbAnswers()
    ..weightKg = kg
    ..goal = goal
    ..isMetric = metric;

  test('une perte part de 8 % du poids, sur la demi-graduation', () {
    final a = answers(95, 'lose')..suggestTarget();
    expect(a.targetKg, 87.5);
  });

  test('en livres, la cible tombe sur une livre entière', () {
    final a = answers(95, 'lose', metric: false)..suggestTarget();
    expect(OnbUnits.kgToLb(a.targetKg), 193);
    expect(a.targetKg, OnbUnits.lbToKg(193));
  });

  test('le pas reste entre 3 et 10 kg pour perdre, entre 2 et 6 kg pour prendre', () {
    expect((answers(150, 'lose')..suggestTarget()).targetKg, 140);
    expect((answers(36, 'lose')..suggestTarget()).targetKg, 35);
    expect((answers(82, 'gain')..suggestTarget()).targetKg, 86);
    expect((answers(130, 'gain')..suggestTarget()).targetKg, 136);
  });

  test('le choix de la personne survit à une reprise, un ancien brouillon garde sa cible', () {
    final a = answers(95, 'lose')
      ..targetKg = 80
      ..targetTouched = true;
    final back = OnbAnswers.fromJson(a.toJson());
    expect(back.targetTouched, isTrue);
    expect(back.targetKg, 80);

    final old = a.toJson()..remove('targetTouched');
    expect(OnbAnswers.fromJson(old).targetTouched, isTrue);
    expect(OnbAnswers().targetTouched, isFalse);
  });
}
