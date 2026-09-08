import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/weekly_planner/week_strip.dart';
import '../config/supabase_config.dart';
import '../design/glass_row.dart';
import '../design/tokens.dart';
import '../home/home_slots.dart';
import '../home/home_suggestion.dart';
import 'global_state_manager.dart';
import 'localization_service.dart';
import 'translations.dart';
import 'weekly_planner_service.dart';

/// What the widgets show, written by the app and read by iOS and Android.
///
/// One JSON under `widget_meal_data`: in the App Group on iOS, in
/// home_widget's preferences on Android. The app decides everything that
/// needs a rule or a language — which slot is done, what the coach says at
/// each hour, every word — and the native side only lays values out.
///
/// Contract, version 2:
/// ```
/// v, day (yyyy-MM-dd, local), lang
/// kcal    { eaten, goal }
/// water   { ml, goalMl, glassMl }
/// slots   [{ slot, state, label, word, kind? }]   state: free | planned | done
/// lines   [{ from, text }]        the coach's line from that hour on
/// strings { … }                   every word, in the app's language
/// theme   { key, ink, ink2, acc, accInk }   the palette the user chose
/// ```
/// Numbers travel raw and the widget formats them for `lang`, so a glass
/// added from the widget itself can be redrawn without waking the app. The
/// day travels as a string and is compared as one: the widget never parses a
/// date. Slots come from [HomeSlots] and the lines from [HomeSuggestion], the
/// same two readings the home makes, so the widget and the home cannot
/// disagree about the same day.
class MealWidgetDataProvider {
  MealWidgetDataProvider._();

  static const String appGroupId = 'group.com.ryze.app';
  static const String dataKey = 'widget_meal_data';
  static const int contractVersion = 2;

  /// Keys the iOS water intent leaves for the app (see AddWaterIntent.swift).
  static const String pendingFlagKey = 'widget_pending_water_add';
  static const String pendingAmountKey = 'widget_pending_water_amount';
  static const String pendingStampKey = 'widget_pending_water_timestamp';

  static const MethodChannel channel = MethodChannel('com.ryze.widget/data');

  static const List<String> _androidWidgets = ['RyseMealWidget', 'RyseWaterWidget'];

  /// The hours at which the coach's frame changes, as in [HomeSuggestion].
  static const List<int> _bands = [0, 5, 11, 14, 18, 22];

  static Future<void>? _inFlight;
  static bool _queued = false;

  /// Rebuilds and writes the widgets' data.
  ///
  /// Calls that arrive while a write is running collapse into one more write
  /// after it, so a burst of entries costs two syncs rather than ten, and the
  /// last one always sees the final state.
  static Future<void> updateWidgetData() {
    final running = _inFlight;
    if (running != null) {
      _queued = true;
      return running;
    }
    final run = _sync().whenComplete(() {
      _inFlight = null;
      if (_queued) {
        _queued = false;
        updateWidgetData();
      }
    });
    _inFlight = run;
    return run;
  }

  /// After a sign-in or at launch: make sure the goals are loaded first.
  static Future<void> forceWidgetUpdate() async {
    try {
      await GlobalStateManager.instance.initialize();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Widget: state not ready before sync: $e');
    }
    await updateWidgetData();
  }

  static Future<void> _sync() async {
    try {
      final payload = await buildPayload();
      if (payload == null) return;
      await _write(jsonEncode(payload));
      if (kDebugMode) {
        final kcal = payload['kcal'] as Map<String, dynamic>;
        final water = payload['water'] as Map<String, dynamic>;
        debugPrint('📱 Widget: ${kcal['eaten']}/${kcal['goal']} kcal · ${water['ml']}/${water['goalMl']} ml · ${(payload['slots'] as List).length} slots');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Widget sync failed: $e');
    }
  }

  /// The contract, as a map. Null when there is nothing honest to write: no
  /// user, or the demo mode that invents figures for screenshots.
  static Future<Map<String, dynamic>?> buildPayload({DateTime? now}) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return null;
    if (WeeklyPlannerService.isDemoMode) return null;

    final date = now ?? DateTime.now();
    final localization = LocalizationService.instance;
    if (!localization.isInitialized) await localization.initialize();
    final lang = localization.currentLanguageCode;

    final state = GlobalStateManager.instance;
    if (state.calorieGoal == 0 || state.waterGoalL == 0) await state.initialize();

    final week = await WeeklyPlannerService.getWeekData(forceRefresh: true);
    final day = week.getDayPlan(date);
    final today = HomeSlots.ofDay(day);
    final session = HomeSlots.session(day);

    final eaten = state.currentCalories.round();
    final goal = state.calorieGoal.round();
    final goalMl = (state.waterGoalL * 1000).round();
    // a glass tapped on the widget while the app was closed is already on
    // the widget; it must not vanish until the app has written it
    final waterMl = (state.currentWaterL * 1000).round() + await _pendingWaterMl();

    final slots = <Map<String, dynamic>>[
      for (final slot in WeekSlot.values)
        {
          'slot': slot.name,
          'state': _stateName(today.state(slot)),
          'label': 'slot_${slot.name}'.tr(lang),
          'word': _wordKey(today.state(slot)).tr(lang),
          if (slot == WeekSlot.sport && session != null) 'kind': session.workout != null ? 'strength' : 'cardio',
        },
    ];

    final lines = <Map<String, dynamic>>[
      for (final hour in _bands)
        () {
          final suggestion = HomeSuggestion.build(
            lang: lang,
            name: '',
            today: today,
            waterL: waterMl / 1000,
            waterGoalL: goalMl / 1000,
            calories: eaten,
            calorieGoal: goal,
            now: DateTime(date.year, date.month, date.day, hour),
          );
          return {
            'from': hour,
            'text': suggestion.line,
            // a line that only restates what is left of the goal says nothing
            // the figure above it does not; the lock screen shows the water
            // instead of the same number twice
            'restates': suggestion.action == HomeAction.logMeal || suggestion.action == HomeAction.viewDay,
          };
        }(),
    ];

    return {
      'v': contractVersion,
      'day': DateFormat('yyyy-MM-dd').format(date),
      'lang': lang,
      'kcal': {'eaten': eaten, 'goal': goal},
      'water': {'ml': waterMl, 'goalMl': goalMl, 'glassMl': (GlassRow.glassLitres * 1000).round()},
      'slots': slots,
      'lines': lines,
      'strings': strings(lang),
      'theme': theme(),
      // for a human reading the JSON; nothing parses it
      'updatedAt': date.toIso8601String(),
    };
  }

  /// The edition in force, whole: an edition owns its ground — paper, card,
  /// greys, text — and not only its mark, so a widget on Volt is black with
  /// volt writing, not volt writing on the widget's own white. Every colour
  /// the tokens derive from the palette travels; the native side derives
  /// the edges the same way the tokens do.
  static Map<String, dynamic> theme() {
    final p = RyzeColors.palette;
    return {
      'key': p.key,
      'dark': p.dark,
      'paper0': _hex(p.paper0),
      'paper': _hex(p.paper),
      'paper2': _hex(p.paper2),
      'surf': _hex(p.surf),
      'text': _hex(p.text),
      'mute': _hex(p.mute),
      'mute2': _hex(p.mute2),
      'idle': _hex(p.idle),
      'ink': _hex(p.ink),
      'ink2': _hex(p.ink2),
      'acc': _hex(p.acc),
      'accInk': _hex(p.accInk),
    };
  }

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Every word the widgets show. The keys are the widget's, the values the
  /// app's, from the same dictionary as every screen.
  static Map<String, String> strings(String lang) => {
        'title_water': 'widget_water_title'.tr(lang),
        'desc_water': 'widget_water_description'.tr(lang),
        'title_meals': 'widget_meals_title'.tr(lang),
        'desc_meals': 'widget_meals_description'.tr(lang),
        'title_today': 'widget_today_title'.tr(lang),
        'desc_today': 'widget_today_description'.tr(lang),
        'lead_remaining': 'home_remaining'.tr(lang),
        'lead_over': 'home_over_by'.tr(lang),
        'lead_reached': 'home_goal_reached'.tr(lang),
        'lead_loading': 'home_loading'.tr(lang),
        'unit': 'home_remaining_unit'.tr(lang),
        'eaten_tpl': 'home_eaten'.tr(lang),
        'goal_tpl': 'home_goal'.tr(lang),
        'left_short': 'widget_left_short'.tr(lang),
        'over_short': 'widget_over_short'.tr(lang),
        'reached_short': 'widget_reached_short'.tr(lang),
        'water': 'nutri_water'.tr(lang),
        'water_goal_tpl': 'widget_water_goal'.tr(lang),
        'glasses_of_tpl': 'widget_glasses_of'.tr(lang),
        'glass_one': 'widget_glass_one'.tr(lang),
        'glass_two': 'widget_glass_two'.tr(lang),
        'open_app': 'widget_open_app'.tr(lang),
        // the word of a free slot, for the widget to reset a stale day itself
        'free_word': 'slot_free'.tr(lang),
      };

  static String _stateName(SlotState s) => switch (s) {
        SlotState.done => 'done',
        SlotState.planned || SlotState.incoming => 'planned',
        SlotState.empty => 'free',
      };

  static String _wordKey(SlotState s) => switch (s) {
        SlotState.done => 'slot_done',
        SlotState.planned || SlotState.incoming => 'slot_planned',
        SlotState.empty => 'slot_free',
      };

  /// Water the iOS widget added while the app was closed, not yet written.
  static Future<int> _pendingWaterMl() async {
    if (!Platform.isIOS) return 0;
    try {
      final pending = await channel.invokeMethod<bool>('getBool', {'key': pendingFlagKey});
      if (pending != true) return 0;
      final amount = await channel.invokeMethod<int>('getInt', {'key': pendingAmountKey});
      return (amount ?? 0).clamp(0, 10000);
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _write(String encoded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dataKey, encoded);

    if (Platform.isIOS) {
      try {
        await channel.invokeMethod('setString', {'key': dataKey, 'value': encoded});
        await channel.invokeMethod('reloadWidgetTimelines');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Widget: App Group write failed: $e');
      }
    }

    if (Platform.isAndroid) {
      try {
        await HomeWidget.saveWidgetData<String>(dataKey, encoded);
        await _updateAndroidWidgets();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Widget: Android write failed: $e');
      }
    }
  }

  static Future<void> _updateAndroidWidgets() async {
    for (final name in _androidWidgets) {
      await HomeWidget.updateWidget(
        name: name,
        androidName: name,
        qualifiedAndroidName: 'com.ryze.app.widget.$name',
      );
    }
  }

  /// The data as the widgets see it, for a debug screen.
  static Future<Map<String, dynamic>?> getWidgetData() async {
    try {
      String? encoded;
      if (Platform.isIOS) {
        try {
          encoded = await channel.invokeMethod<String>('getString', {'key': dataKey});
        } catch (_) {}
      }
      encoded ??= (await SharedPreferences.getInstance()).getString(dataKey);
      if (encoded == null) return null;
      return jsonDecode(encoded) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Widget: read failed: $e');
      return null;
    }
  }

  /// On sign-out: the widgets go back to their empty state.
  static Future<void> clearWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(dataKey);

      if (Platform.isIOS) {
        try {
          for (final key in [dataKey, pendingFlagKey, pendingAmountKey, pendingStampKey]) {
            await channel.invokeMethod('remove', {'key': key});
          }
          await channel.invokeMethod('reloadWidgetTimelines');
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Widget: App Group clear failed: $e');
        }
      }

      if (Platform.isAndroid) {
        try {
          await HomeWidget.saveWidgetData<String?>(dataKey, null);
          await _updateAndroidWidgets();
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Widget: Android clear failed: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Widget: clear failed: $e');
    }
  }
}
