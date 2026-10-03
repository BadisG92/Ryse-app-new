import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/onboarding/onboarding_strings.dart';
import 'package:ryze_app/onboarding/tone_test.dart';

/// L'écran du ton : une excuse, celle de la personne, et cinq répliques
/// écrites d'avance pour y répondre.
///
/// L'excuse vient de ce qu'elle a coché au chapitre 2, et chaque réplique
/// doit exister dans les trois langues. Sans prénom (un compte e-mail qui a
/// sauté la question), la réplique doit rester une phrase propre, sans
/// « bouger, , mais » ni « {n} » oublié.
void main() {
  const tones = ['friendly', 'strict', 'supportive', 'sassy', 'direct'];
  const langs = ['fr', 'en', 'de'];

  group('L’excuse', () {
    test('vient de la première raison cochée', () {
      expect(OnbToneScript.excuseKey(['obs_slow', 'obs_time']), 'slow');
      expect(OnbToneScript.excuseKey(['obs_motiv']), 'motiv');
    });

    test('sans raison cochée, la plus universelle', () {
      expect(OnbToneScript.excuseKey([]), 'none');
      expect(OnbToneScript.excuseKey(['obs_none']), 'none');
      expect(OnbToneScript.excuseKey(['autre_chose']), 'none');
    });

    test('prend les guillemets de la langue', () {
      expect(OnbToneScript.quoted('Il pleut, flemme.', 'fr'), '« Il pleut, flemme. »');
      expect(OnbToneScript.quoted('No time today.', 'en'), '“No time today.”');
      expect(OnbToneScript.quoted('Heute keine Zeit.', 'de'), '„Heute keine Zeit.“');
    });
  });

  group('Les répliques', () {
    test('chaque excuse et chaque réplique existent dans les trois langues', () {
      for (final e in OnbToneScript.excuses) {
        final keys = ['exc_$e', for (final t in tones) 'rep_${e}_$t'];
        for (final key in keys) {
          final fr = OnbStrings('fr').t(key);
          final en = OnbStrings('en').t(key);
          final de = OnbStrings('de').t(key);
          expect(en, isNot(key), reason: key);
          // t() retombe sur l'anglais : une traduction manquante se lirait en anglais
          expect(fr, isNot(en), reason: '$key fr');
          expect(de, isNot(en), reason: '$key de');
        }
      }
    });

    test('le prénom prend sa place', () {
      final line = OnbToneScript.withName(OnbStrings('fr').t('rep_motiv_sassy'), 'Alex');
      expect(line, 'Pas la force de bouger, Alex, mais celle de scroller ? 😏');
    });

    test('sans prénom, chaque réplique reste une phrase propre', () {
      for (final lang in langs) {
        for (final e in OnbToneScript.excuses) {
          for (final t in tones) {
            final line = OnbToneScript.withName(OnbStrings(lang).t('rep_${e}_$t'), null);
            final where = '$lang rep_${e}_$t : $line';
            expect(line, isNot(contains('{n}')), reason: where);
            expect(line, isNot(contains(' ,')), reason: where);
            expect(line, isNot(contains(',.')), reason: where);
            expect(line, isNot(contains(',?')), reason: where);
            expect(line, isNot(contains(', ?')), reason: where);
            expect(line, isNot(contains('  ')), reason: where);
          }
        }
      }
      expect(OnbToneScript.withName(OnbStrings('fr').t('rep_motiv_sassy'), ''), 'Pas la force de bouger, mais celle de scroller ? 😏');
    });

    test('aucun tiret cadratin ni demi-cadratin', () {
      for (final lang in langs) {
        for (final e in OnbToneScript.excuses) {
          for (final key in ['exc_$e', for (final t in tones) 'rep_${e}_$t']) {
            final text = OnbStrings(lang).t(key);
            expect(text.contains('—') || text.contains('–'), isFalse, reason: '$lang $key');
          }
        }
      }
    });
  });
}
