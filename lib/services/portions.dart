/// Les portions qu'on propose, selon ce que l'aliment est.
///
/// Proposer « 30 g, 50 g, 100 g » pour du riz est juste ; proposer « 30 pièces,
/// 50 pièces » pour un œuf ne l'est pas, et c'est ce que faisait l'app parce
/// que la liste des portions était figée. Elle se calcule maintenant à partir
/// de l'unité et de la quantité de référence de l'aliment.
///
/// Une seule règle, partagée par la feuille de portion, le produit scanné et
/// la correction d'une quantité déjà enregistrée : ces trois écrans posaient la
/// même question et n'y répondaient pas pareil.
class RyzePortions {
  RyzePortions._();

  /// Les unités qui se pèsent ou se mesurent. Tout le reste se compte.
  static const _mass = {'g', 'gr', 'gramme', 'grammes', 'gram', 'grams', 'kg'};
  static const _volume = {'ml', 'cl', 'l', 'litre', 'litres', 'liter', 'liters'};

  /// Vrai quand l'aliment se compte : une pièce, une tranche, une cuillère.
  static bool isCount(String? unit) {
    final u = _normalise(unit);
    if (u.isEmpty) return false;
    return !_mass.contains(u) && !_volume.contains(u);
  }

  /// Ce qu'on propose sous le grand chiffre. Toujours six valeurs au plus,
  /// toujours plausibles pour cet aliment-là.
  static List<double> presets({String? unit, double reference = 100}) {
    final u = _normalise(unit);

    if (isCount(unit)) {
      // Un œuf, une tranche, une cuillère : on en prend un, deux, trois.
      // Si la référence est déjà un multiple, on part de là.
      final base = reference >= 1 ? reference.roundToDouble() : 1.0;
      return base == 1
          ? const [1, 2, 3, 4, 6, 8]
          : [base / 2, base, base * 1.5, base * 2, base * 3, base * 4]
              .where((v) => v >= 0.5)
              .map((v) => (v * 2).roundToDouble() / 2)
              .toSet()
              .toList();
    }

    if (_volume.contains(u)) {
      if (u == 'cl') return const [10, 15, 20, 25, 33, 50];
      if (u == 'l' || u.startsWith('lit')) return const [0.2, 0.25, 0.33, 0.5, 0.75, 1];
      return const [100, 150, 200, 250, 330, 500];
    }

    if (u == 'kg') return const [0.1, 0.15, 0.2, 0.25, 0.5, 1];

    // Au gramme. Un aliment dont la référence est minuscule — une épice, une
    // huile — n'a rien à faire avec une échelle qui commence à 30.
    if (reference > 0 && reference <= 25) return const [5, 10, 15, 20, 30, 50];
    return const [30, 50, 100, 150, 200, 250];
  }

  /// Le pas des deux boutons de part et d'autre du chiffre.
  static double step({String? unit, double reference = 100}) {
    if (isCount(unit)) return reference >= 2 ? 1 : 0.5;
    final u = _normalise(unit);
    if (u == 'kg' || u == 'l' || u.startsWith('lit')) return 0.05;
    if (u == 'cl') return 5;
    if (reference > 0 && reference <= 25) return 5;
    return 10;
  }

  /// « 150 g », « 2 pièces », « 1 tranche ». Le pluriel n'est appliqué qu'aux
  /// unités qui se comptent : « 2 gs » n'aurait aucun sens.
  static String label(double value, String? unit, String lang) {
    final u = (unit ?? 'g').trim();
    final n = format(value);
    if (u.isEmpty) return n;
    if (!isCount(u) || value < 2 || lang == 'de') return '$n $u';
    final last = u[u.length - 1].toLowerCase();
    if (last == 's' || last == 'x') return '$n $u';
    return '$n ${u}s';
  }

  /// Un nombre de portion : sans décimale quand il est rond.
  static String format(double value) =>
      value.truncateToDouble() == value ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  static String _normalise(String? unit) {
    var u = (unit ?? '').trim().toLowerCase();
    const accents = {'é': 'e', 'è': 'e', 'ê': 'e', 'à': 'a', 'ù': 'u', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ç': 'c'};
    accents.forEach((a, b) => u = u.replaceAll(a, b));
    return u.replaceAll('.', '');
  }
}
