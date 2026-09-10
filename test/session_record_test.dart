import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/sport/session/session_controller.dart';

/// À qui appartient la pastille de record, dans une séance.
///
/// La règle ne regardait que la dernière fois : chaque série plus lourde que
/// l'historique décrochait sa pastille. Trente-cinq puis quarante en portaient
/// donc deux, alors que le record de trente-cinq avait déjà été battu dans la
/// même séance — et la séance en cours ne comptait pas dans ce qu'il fallait
/// battre.
void main() {
  test('le record se déplace sur la plus lourde, il ne se multiplie pas', () {
    expect(recordHolder(30, [30, 35, 40]), 2);
  });

  test('la série qui égale l’ancien record ne le bat pas', () {
    expect(recordHolder(30, [30]), -1);
  });

  test('une série plus légère après le record ne le vole pas', () {
    expect(recordHolder(30, [35, 32]), 0);
  });

  test('à poids égal, la première garde la pastille', () {
    expect(recordHolder(30, [40, 40]), 0);
  });

  test('sans dernière fois, personne ne s’auto-félicite', () {
    expect(recordHolder(0, [30, 40, 50]), -1);
  });

  test('une série non validée ne porte rien', () {
    // les séries non faites arrivent à zéro
    expect(recordHolder(30, [0, 45, 0]), 1);
  });
}
