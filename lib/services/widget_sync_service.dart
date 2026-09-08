import 'dart:async';

import 'package:flutter/foundation.dart';

import 'global_state_manager.dart';
import 'meal_widget_data_provider.dart';
import 'theme_service.dart';

/// Keeps the widgets in step with the app.
///
/// Food and water write to the widget from their own services. What changes
/// the day's slots without touching either — a meal or a session planned, a
/// workout finished, the day turning at midnight, the goals edited — reaches
/// the widget through the global state's events, listened to here. So does
/// the palette: a widget wears the colours the user chose, the second they
/// choose them. The provider collapses bursts, so listening broadly costs
/// nothing.
class WidgetSyncService {
  WidgetSyncService._();

  static StreamSubscription<StateChangeEvent>? _events;
  static bool _listeningToTheme = false;

  static void start() {
    _events ??= GlobalStateManager.instance.events.listen((event) {
      switch (event.type) {
        case ChangeType.planner:
        case ChangeType.workout:
        case ChangeType.sport:
        case ChangeType.dayReset:
        case ChangeType.batch:
        case ChangeType.goals:
        case ChangeType.streak:
          MealWidgetDataProvider.updateWidgetData();
        default:
          break;
      }
    });
    if (!_listeningToTheme) {
      ThemeService.instance.addListener(_onTheme);
      _listeningToTheme = true;
    }
  }

  static void _onTheme() {
    MealWidgetDataProvider.updateWidgetData();
  }

  static Future<void> stop() async {
    await _events?.cancel();
    _events = null;
    if (_listeningToTheme) {
      ThemeService.instance.removeListener(_onTheme);
      _listeningToTheme = false;
    }
  }

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
