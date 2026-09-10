import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/services/ryze_links.dart';

/// Les adresses du site, dans les trois langues.
///
/// Quatre écrans construisaient leur lien légal à la main, aucun ne connaissait
/// l'allemand : un utilisateur allemand tombait sur la version anglaise. Ce
/// test fige la règle de nommage du site pour qu'un cinquième écran ne la
/// réinvente pas de travers.
void main() {
  group('Les conditions et la confidentialité', () {
    test('le français est la langue du site, donc sans suffixe', () {
      expect(RyzeLinks.terms('fr'), 'https://coach-ryze.com/terms.html');
      expect(RyzeLinks.privacy('fr'), 'https://coach-ryze.com/privacy.html');
    });

    test('l\'allemand a ses propres pages', () {
      expect(RyzeLinks.terms('de'), 'https://coach-ryze.com/terms_de.html');
      expect(RyzeLinks.privacy('de'), 'https://coach-ryze.com/privacy_de.html');
    });

    test('l\'anglais aussi', () {
      expect(RyzeLinks.terms('en'), 'https://coach-ryze.com/terms_en.html');
      expect(RyzeLinks.privacy('en'), 'https://coach-ryze.com/privacy_en.html');
    });

    test('une langue inconnue retombe sur l\'anglais, jamais sur rien', () {
      expect(RyzeLinks.terms('es'), 'https://coach-ryze.com/terms_en.html');
      expect(RyzeLinks.privacy(''), 'https://coach-ryze.com/privacy_en.html');
    });
  });

  group('L\'aide et le site', () {
    test('l\'aide suit la même règle', () {
      expect(RyzeLinks.support('fr'), 'https://coach-ryze.com/support.html');
      expect(RyzeLinks.support('de'), 'https://coach-ryze.com/support_de.html');
      expect(RyzeLinks.support('en'), 'https://coach-ryze.com/support_en.html');
    });

    test('la racine du site sert le français : le lien vise l\'index de la langue', () {
      expect(RyzeLinks.site('fr'), 'https://coach-ryze.com/index.html');
      expect(RyzeLinks.site('de'), 'https://coach-ryze.com/index_de.html');
      expect(RyzeLinks.site('en'), 'https://coach-ryze.com/index_en.html');
    });
  });

  test('aucune adresse ne se construit sans page', () {
    for (final lang in ['fr', 'en', 'de', 'xx']) {
      for (final url in [
        RyzeLinks.terms(lang),
        RyzeLinks.privacy(lang),
        RyzeLinks.support(lang),
        RyzeLinks.site(lang),
      ]) {
        expect(url, startsWith('https://coach-ryze.com/'));
        expect(url, endsWith('.html'));
        expect(url, isNot(contains('null')));
        expect(url.substring('https://'.length), isNot(contains('//')));
      }
    }
  });
}
