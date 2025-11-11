import 'package:flutter/material.dart';

/// Service singleton pour accéder au Navigator global de l'app
/// Cela permet d'afficher des dialogs/popups depuis n'importe où dans l'app
class AppNavigator {
  static final AppNavigator _instance = AppNavigator._internal();
  factory AppNavigator() => _instance;
  AppNavigator._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

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
