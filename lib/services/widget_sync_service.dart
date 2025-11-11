import 'package:flutter/foundation.dart';

import 'meal_widget_data_provider.dart';

/// Helper pour synchroniser les widgets iOS quand une donnée globale change
class WidgetSyncService {
  /// Rafraîchir les données du widget repas.
  static Future<void> refreshMealWidget({bool force = false}) async {
    try {
      if (force) {
        await MealWidgetDataProvider.forceWidgetUpdate();
      } else {
        await MealWidgetDataProvider.updateWidgetData();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Impossible de rafraîchir le widget repas: $e');
      }
    }
  }
}
