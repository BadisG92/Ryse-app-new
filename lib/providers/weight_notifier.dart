import 'package:flutter/foundation.dart';

class WeightNotifier extends ChangeNotifier {
  static final WeightNotifier _instance = WeightNotifier._internal();
  factory WeightNotifier() => _instance;
  WeightNotifier._internal();

  static WeightNotifier get instance => _instance;

  /// Notifie tous les widgets qui écoutent que les données de poids ont changé
  void notifyWeightChanged() {
    debugPrint('🔄 WeightNotifier: Notifying weight changed');
    notifyListeners();
  }

  /// Force le rafraîchissement des données de poids dans tous les écrans
  void forceRefresh() {
    notifyWeightChanged();
  }
}