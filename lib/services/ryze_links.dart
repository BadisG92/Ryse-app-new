/// Les adresses du site, en un seul endroit.
///
/// Quatre écrans construisaient leur lien légal à la main, chacun avec son
/// propre `lang == 'fr' ? … : …` : les conditions, la confidentialité, le
/// paywall d'onboarding, le paywall des fonctions et les écrans de compte.
/// Aucun ne connaissait l'allemand, donc un utilisateur allemand tombait sur
/// la version anglaise — et le jour où les pages allemandes ont été publiées,
/// il aurait fallu penser aux quatre.
///
/// Le site nomme ses pages `page.html` en français, `page_en.html` en anglais
/// et `page_de.html` en allemand. La racine, elle, sert toujours la version
/// française : le lien « Site web » vise donc l'index de la langue.
class RyzeLinks {
  RyzeLinks._();

  static const String host = 'https://coach-ryze.com';
  static const String supportEmail = 'support@coach-ryze.com';

  /// Le suffixe de fichier pour une langue. Vide en français, langue du site.
  static String _suffix(String lang) => switch (lang) {
        'fr' => '',
        'de' => '_de',
        _ => '_en',
      };

  static String _page(String name, String lang) => '$host/$name${_suffix(lang)}.html';

  /// Les conditions d'utilisation. App Review les attend sur tout écran
  /// d'abonnement, et sur la création de compte.
  static String terms(String lang) => _page('terms', lang);

  /// La politique de confidentialité.
  static String privacy(String lang) => _page('privacy', lang);

  /// La page d'aide.
  static String support(String lang) => _page('support', lang);

  /// L'accueil du site, dans la langue de l'utilisateur.
  static String site(String lang) => lang == 'fr' ? '$host/index.html' : _page('index', lang);
}
