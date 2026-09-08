import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/palette.dart';
import '../design/tokens.dart';

/// Le choix de palette de l'utilisateur, et sa mémoire.
///
/// Il n'y a rien de plus : la palette est un champ statique de `RyzeColors`,
/// donc changer d'habit se résume à lui affecter une autre valeur. Ce service
/// ne fait que deux choses de plus — la relire au lancement et la garder d'une
/// fois sur l'autre.
///
/// `ChangeNotifier` pour que l'application se redessine à la seconde du choix,
/// sans redémarrage : les jetons sont lus à chaque `build`, il suffit d'en
/// déclencher un depuis la racine.
class ThemeService extends ChangeNotifier {
  ThemeService._();

  static final ThemeService instance = ThemeService._();

  static const String _key = 'ryze_palette_v1';

  RyzePalette get palette => RyzeColors.palette;

  /// Au lancement, avant le premier rendu. Une clé inconnue — un réglage écrit
  /// par une version plus récente — retombe sur la palette d'origine plutôt
  /// que de laisser l'application sans couleurs.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      RyzeColors.palette = RyzePalettes.byKey(prefs.getString(_key));
    } catch (_) {
      // Le stockage peut manquer au tout premier lancement : la palette
      // d'origine est déjà en place, il n'y a rien à réparer.
    }
  }

  /// Le choix, appliqué tout de suite et gardé ensuite. L'écriture ne bloque
  /// pas le rendu : si elle échoue, l'habit tient jusqu'à la fermeture.
  Future<void> choose(RyzePalette palette) async {
    if (palette.key == RyzeColors.palette.key) return;
    RyzeColors.palette = palette;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, palette.key);
    } catch (_) {
      // rien à dire : l'écran a déjà changé de couleur
    }
  }
}
