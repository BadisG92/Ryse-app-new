/// Ce que l'utilisateur vient d'ajouter, le temps de le lui montrer.
///
/// L'accueil rejouait l'animation de son grand chiffre à chaque visite : il
/// roulait pareil qu'on vienne de noter un repas ou qu'on revienne des
/// réglages. C'était du mouvement, pas une récompense — rien dedans ne disait
/// « ça, c'est ce que tu viens de faire ».
///
/// Ici, un aliment écrit dépose ce qu'il pèse. L'accueil le ramasse à sa
/// prochaine lecture, l'affiche une fois, et l'oublie. Le dépôt est volatil et
/// vide au bout de quelques secondes : personne ne doit voir « +546 » en
/// rouvrant l'app une heure plus tard.
class RyzeGain {
  RyzeGain._();

  /// Au-delà, ce n'est plus « ce que tu viens de faire ».
  static const Duration life = Duration(seconds: 12);

  static int _kcal = 0;
  static DateTime? _at;

  /// Un aliment vient d'être écrit sur aujourd'hui.
  ///
  /// Les ajouts qui se suivent s'additionnent — une photo pose souvent quatre
  /// aliments d'un coup, et c'est le repas entier qu'on veut voir arriver, pas
  /// le dernier ingrédient.
  static void add(int kcal) {
    if (kcal <= 0) return;
    final now = DateTime.now();
    final since = _at;
    _kcal = (since != null && now.difference(since) < life) ? _kcal + kcal : kcal;
    _at = now;
  }

  /// Ce qu'il y a à montrer, une seule fois. Zéro si rien n'a été ajouté, ou
  /// si c'est trop vieux pour être « à l'instant ».
  static int take() {
    final since = _at;
    final fresh = since != null && DateTime.now().difference(since) < life;
    final value = fresh ? _kcal : 0;
    _kcal = 0;
    _at = null;
    return value;
  }

  /// Un écran qui n'a pas vocation à l'afficher n'a pas à le consommer.
  static void clear() {
    _kcal = 0;
    _at = null;
  }
}
