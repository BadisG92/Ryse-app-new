import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/services/ryze_dates.dart';

/// Un repas noté à 22 h reste un repas de 22 h, le jour où on l'a noté.
///
/// `consumed_at` reçoit l'heure murale du téléphone, écrite sans son décalage.
/// Postgres la relit comme du temps universel et la rend telle quelle : la
/// convertir en heure locale ajoutait le décalage une seconde fois. Un dîner
/// noté à 22 h 24 à Paris devenait 0 h 24 le lendemain, cochait le créneau du
/// jour suivant dans le planificateur, et s'affichait deux heures trop tard
/// dans le journal.
void main() {
  test('l’heure rendue est celle qui a été écrite', () {
    // Ce que la base a rendu ce soir-là, pour un repas noté à 22 h 24 à Paris.
    final at = RyzeDates.wall('2026-09-10 22:24:53.338483+00');

    expect(at, isNotNull);
    expect(at!.day, 10, reason: 'le repas appartient au jour où il a été noté');
    expect(at.hour, 22);
    expect(at.minute, 24);
  });

  test('un repas de midi ne bouge pas non plus', () {
    final at = RyzeDates.wall('2026-09-10 12:30:00+00');
    expect(at!.day, 10);
    expect(at.hour, 12);
  });

  test('la forme sans décalage se lit pareil', () {
    // Ce que l'application écrit avant que Postgres n'y touche.
    final at = RyzeDates.wall('2026-09-10T22:24:53.338');
    expect(at!.day, 10);
    expect(at.hour, 22);
  });

  test('rien à lire, rien à rendre', () {
    expect(RyzeDates.wall(null), isNull);
    expect(RyzeDates.wall(''), isNull);
    expect(RyzeDates.wall('pas une date'), isNull);
  });

  test('le résultat est une heure locale, jamais un instant universel', () {
    // Sans ça, un appelant qui referait `.toLocal()` retomberait dans le
    // décalage qu'on vient d'enlever.
    expect(RyzeDates.wall('2026-09-10 22:24:53+00')!.isUtc, isFalse);
  });
}
