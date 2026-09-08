import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'meal_widget_data_provider.dart';
import 'water_service.dart';

/// Water added from the iOS widget while the app was closed.
///
/// The widget's buttons run an App Intent in the widget's own process: it
/// redraws the glasses at once and leaves the amount in the App Group for
/// the app. That amount can only have been left while the app was not in
/// front, so it is read exactly when the app comes back to the front, and
/// once at launch. Polling the native side twice a second for the whole life
/// of the app, which is what this did before, bought nothing.
class WidgetWaterHandler with WidgetsBindingObserver {
  WidgetWaterHandler._();

  static final WidgetWaterHandler instance = WidgetWaterHandler._();
  static const MethodChannel _channel = MealWidgetDataProvider.channel;

  bool _busy = false;

  /// Reads once now, then on every return to the foreground.
  static void startChecking() {
    if (!Platform.isIOS) return;
    WidgetsBinding.instance.addObserver(instance);
    instance._process();
  }

  static void stopChecking() {
    WidgetsBinding.instance.removeObserver(instance);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _process();
  }

  Future<void> _process() async {
    if (_busy) return;
    _busy = true;
    try {
      final pending = await _channel.invokeMethod<bool>('getBool', {'key': MealWidgetDataProvider.pendingFlagKey});
      if (pending != true) return;

      final amount = await _channel.invokeMethod<int>('getInt', {'key': MealWidgetDataProvider.pendingAmountKey}) ?? 0;
      final stamp = await _channel.invokeMethod<double>('getDouble', {'key': MealWidgetDataProvider.pendingStampKey});

      // taken off the shelf before the write, so a second pass cannot add it twice
      await _clear();

      if (amount <= 0) return;
      if (stamp != null) {
        final left = DateTime.fromMillisecondsSinceEpoch((stamp * 1000).round());
        // a glass tapped yesterday belongs to yesterday, which the widget
        // has already reset; writing it today would be a lie
        if (!_sameDay(left, DateTime.now())) {
          if (kDebugMode) debugPrint('💧 Widget: $amount ml left on another day, dropped');
          await MealWidgetDataProvider.updateWidgetData();
          return;
        }
      }

      if (kDebugMode) debugPrint('💧 Widget: writing $amount ml added from the widget');
      final ok = await WaterService.addWaterEntry(
        amount: amount,
        sourceType: amount == 250 ? 'glass' : 'manual',
      );
      if (!ok) {
        // offline, most likely: back on the shelf for the next return
        await _restore(amount);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Widget: pending water failed: $e');
    } finally {
      _busy = false;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static Future<void> _clear() async {
    for (final key in [
      MealWidgetDataProvider.pendingFlagKey,
      MealWidgetDataProvider.pendingAmountKey,
      MealWidgetDataProvider.pendingStampKey,
    ]) {
      await _channel.invokeMethod('remove', {'key': key});
    }
  }

  static Future<void> _restore(int amount) async {
    try {
      final already = await _channel.invokeMethod<bool>('getBool', {'key': MealWidgetDataProvider.pendingFlagKey}) == true
          ? (await _channel.invokeMethod<int>('getInt', {'key': MealWidgetDataProvider.pendingAmountKey}) ?? 0)
          : 0;
      await _channel.invokeMethod('setBool', {'key': MealWidgetDataProvider.pendingFlagKey, 'value': true});
      await _channel.invokeMethod('setInt', {'key': MealWidgetDataProvider.pendingAmountKey, 'value': already + amount});
      await _channel.invokeMethod('setDouble', {
        'key': MealWidgetDataProvider.pendingStampKey,
        'value': DateTime.now().millisecondsSinceEpoch / 1000,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Widget: could not keep $amount ml for later: $e');
    }
  }
}
