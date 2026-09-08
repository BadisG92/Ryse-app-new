import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/models/coach_chat_models.dart';
import 'package:ryze_app/services/coach_preference_extractor.dart';

/// Ce que Ryze retient de l'utilisateur, et ce qu'il ne doit pas perdre.
///
/// L'onboarding écrit dans la même colonne que l'extraction automatique, sous
/// une septième clé. Les deux fonctions qui sauvaient les préférences
/// reconstruisaient le document à partir des six listes qu'elles connaissent :
/// la première extraction effaçait donc définitivement ce que l'utilisateur
/// avait raconté pendant l'inscription.
void main() {
  group('La fusion du document de préférences', () {
    test('conserve une clé que le code ne connaît pas', () {
      final existing = {
        'allergies': ['noix'],
        'onboarding_insights': '- Motivation : se sentir mieux\n- Blocage : le soir',
      };
      final update = {
        'allergies': ['noix', 'lactose'],
        'dietary_restrictions': <String>[],
      };

      final merged = UserCoachPreferences.mergePreferencesJson(existing, update);

      expect(merged['onboarding_insights'], existing['onboarding_insights']);
      expect(merged['allergies'], ['noix', 'lactose']);
    });

    test('accepte un document vide', () {
      final merged = UserCoachPreferences.mergePreferencesJson(null, {'allergies': <String>[]});
      expect(merged['allergies'], isEmpty);
    });

    test('la sérialisation du modèle porte les insights', () {
      final prefs = UserCoachPreferences(
        id: '1',
        userId: 'u1',
        allergies: const ['noix'],
        onboardingInsights: '- Objectif : 5 kg',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = prefs.toPreferencesJson();

      expect(json['onboarding_insights'], '- Objectif : 5 kg');
      expect(json['allergies'], ['noix']);
    });

    test('copyWith garde les insights quand on ne les touche pas', () {
      final prefs = UserCoachPreferences(
        id: '1',
        userId: 'u1',
        onboardingInsights: '- Objectif : 5 kg',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = prefs.copyWith(allergies: const ['gluten']);

      expect(updated.onboardingInsights, '- Objectif : 5 kg');
      expect(updated.allergies, ['gluten']);
    });
  });

  group('Le dédoublonnage de ce qui est retenu', () {
    test('ne garde pas deux fois le même fait écrit autrement', () {
      final merged = CoachPreferenceExtractor.mergeList(
        ['Sans gluten'],
        ['sans gluten,', 'lactose'],
      );

      expect(merged.length, 2);
      // La première formulation est celle qui reste.
      expect(merged.first, 'Sans gluten');
      expect(merged, contains('lactose'));
    });

    test('ignore les accents et la casse', () {
      final merged = CoachPreferenceExtractor.mergeList(
        ['Blessure au genou'],
        ['blessure au génou'],
      );

      expect(merged.length, 1);
    });

    test('écarte les entrées vides', () {
      final merged = CoachPreferenceExtractor.mergeList(['noix'], ['', '   ']);
      expect(merged, ['noix']);
    });

    test('accepte des listes nulles', () {
      expect(CoachPreferenceExtractor.mergeList(null, null), isEmpty);
      expect(CoachPreferenceExtractor.mergeList(null, ['noix']), ['noix']);
    });
  });
}
