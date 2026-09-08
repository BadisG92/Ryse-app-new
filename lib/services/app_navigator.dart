import 'package:flutter/material.dart';

/// Service singleton pour accéder au Navigator global de l'app
/// Cela permet d'afficher des dialogs/popups depuis n'importe où dans l'app
class AppNavigator {
  static final AppNavigator _instance = AppNavigator._internal();
  factory AppNavigator() => _instance;
  AppNavigator._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  /// L'onglet qu'une source extérieure à la barre — un widget, un lien —
  /// demande à voir. La barre l'écoute et le remet à null une fois passé ;
  /// s'il est demandé avant qu'elle existe, elle le lit en arrivant.
  final ValueNotifier<String?> requestedTab = ValueNotifier<String?>(null);

  void requestTab(String tab) {
    requestedTab.value = tab;
  }

  /// L'animation d'ouverture est finie. L'app principale est construite
  /// sous elle pendant qu'elle joue, ce qui suffit pour la préparer mais pas
  /// pour poser une feuille dessus : une feuille ouverte sur le logo qui
  /// s'écrit est une feuille ouverte sur rien.
  final ValueNotifier<bool> introDone = ValueNotifier<bool>(false);

  /// La barre des onglets est montée : un utilisateur connecté, une page
  /// d'accueil, un endroit où une feuille a un sens.
  final ValueNotifier<bool> mainReady = ValueNotifier<bool>(false);

  bool get isReady => introDone.value && mainReady.value;

  /// Attend que l'app soit prête à recevoir un geste venu de l'extérieur.
  /// Faux si elle ne l'est pas dans le délai : l'écran de connexion, par
  /// exemple, ne monte jamais la barre.
  Future<bool> whenReady({Duration timeout = const Duration(seconds: 20)}) async {
    final end = DateTime.now().add(timeout);
    while (!isReady) {
      if (DateTime.now().isAfter(end)) return false;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // une image de plus, pour que l'accueil ait posé son premier rendu
    await Future.delayed(const Duration(milliseconds: 250));
    return true;
  }

  /// Initialiser avec le navigatorKey de l'app
  void initialize(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  NavigatorState? get navigatorState => _navigatorKey?.currentState;

  /// Obtenir le context du Navigator
  BuildContext? get context => _navigatorKey?.currentContext;

  /// Obtenir le context de l'overlay (utile pour showDialog global)
  BuildContext? get overlayContext => navigatorState?.overlay?.context;

  /// Obtenir le meilleur context disponible pour les overlays
  BuildContext? get safestContext => overlayContext ?? navigatorState?.context ?? context;

  /// Vérifier si le context est disponible
  bool get hasContext => context != null;
}
