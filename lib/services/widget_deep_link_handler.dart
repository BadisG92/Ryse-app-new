import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/weekly_planner/week_strip.dart';
import '../config/supabase_config.dart';
import '../design/feedback.dart';
import '../design/undo_bar.dart';
import '../home/home_slots.dart';
import '../models/nutrition_models.dart';
import '../nutrition/add_food_sheet.dart';
import 'app_navigator.dart';
import 'food_add_flow.dart';
import 'localization_service.dart';
import 'translations.dart';
import 'water_service.dart';

/// What a tap on a widget opens.
///
/// The widgets speak `ryse://` — the scheme predates the spelling of the
/// brand and cannot change without orphaning every widget already placed:
/// - `ryse://add-food?meal=breakfast|lunch|snack|dinner[&mode=…]`
/// - `ryse://add-water?amount=250`
/// - `ryse://sport`, `ryse://nutrition`, `ryse://progress`, `ryse://dashboard`
///
/// Every destination is the one the home opens for the same gesture: the
/// add sheet of that meal, the journal's own write path for a glass, a tab.
/// The widget is a remote control for the app, never a second app.
///
/// Three rules make a tap from a closed app feel like one tap:
/// - the same link delivered twice within a few seconds is one tap — the
///   plugin hands the launch link to both the initial-link call and the
///   stream, and iOS can deliver it more than once on top;
/// - nothing opens before the app is ready — the intro finished and the tab
///   bar mounted — because the app is built under the intro while it plays,
///   and a sheet over the logo being written is a sheet over nothing;
/// - one gesture at a time: a second tap while a sheet from the first is
///   open closes that sheet and opens its own.
class WidgetDeepLinkHandler {
  WidgetDeepLinkHandler._();

  static GlobalKey<NavigatorState>? navigatorKey;

  static void initialize(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// How long the same link stays "the same tap".
  static const Duration _sameTap = Duration(seconds: 5);

  static Uri? _lastUri;
  static DateTime? _lastAt;
  static bool _dispatching = false;
  static bool _sheetOpen = false;

  static Future<void> handleDeepLink(Uri uri) async {
    if (uri.scheme != 'ryse') return;

    final now = DateTime.now();
    final last = _lastAt;
    if (_lastUri == uri && last != null && now.difference(last) < _sameTap) {
      if (kDebugMode) debugPrint('🔗 Widget link repeated, ignored: $uri');
      return;
    }
    _lastUri = uri;
    _lastAt = now;

    if (_dispatching) {
      if (kDebugMode) debugPrint('🔗 Widget link while another is being opened, ignored: $uri');
      return;
    }
    _dispatching = true;
    if (kDebugMode) debugPrint('🔗 Widget link: $uri');

    try {
      final ready = await AppNavigator().whenReady();
      if (!ready) {
        if (kDebugMode) debugPrint('🔗 Widget link dropped: the app is not ready (signed out?)');
        return;
      }

      switch (uri.host) {
        case 'add-food':
          await _addFood(uri.queryParameters['meal'], uri.queryParameters['mode']);
        case 'add-water':
          await _addWater(int.tryParse(uri.queryParameters['amount'] ?? ''));
        case 'sport':
        case 'nutrition':
        case 'progress':
          _closeOurSheet();
          AppNavigator().requestTab(uri.host);
        case 'dashboard':
        case 'home':
          _closeOurSheet();
          AppNavigator().requestTab('home');
        default:
          if (kDebugMode) debugPrint('⚠️ Widget link not understood: $uri');
      }
    } finally {
      _dispatching = false;
    }
  }

  static bool get _signedIn => SupabaseConfig.client.auth.currentUser != null;

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  static BuildContext? get _context {
    final c = AppNavigator().safestContext;
    return c != null && c.mounted ? c : null;
  }

  /// A sheet this handler opened and the user has not closed: a new tap
  /// replaces it rather than stacking a second one on top.
  static void _closeOurSheet() {
    if (!_sheetOpen) return;
    AppNavigator().navigatorState?.maybePop();
    _sheetOpen = false;
  }

  /// A meal from the widget: the same sheet the home opens for that slot, or
  /// one tool of it straight away when the link names one.
  static Future<void> _addFood(String? meal, String? mode) async {
    final slot = _slotOf(meal);
    final tool = _toolOf(mode);
    final context = _context;
    if (context == null || !_signedIn) return;

    if (slot == null || slot == WeekSlot.sport) {
      _closeOurSheet();
      AppNavigator().requestTab('nutrition');
      return;
    }

    final lang = _lang;
    final mealName = 'meal_name_${slot.name}'.tr(lang);

    void logged(FoodItem item) {
      RyzeFeedback.success();
      final c = _context;
      if (c != null) {
        RyzeUndo.note(c, message: 'home_meal_logged'.tr(lang).replaceAll('{m}', mealName));
      }
    }

    _closeOurSheet();
    // the sheet is a modal: the handler is free again as soon as it is up,
    // so the next tap can replace it instead of waiting for it to close
    _sheetOpen = true;
    final shown = tool != null
        ? FoodAddFlow.open(context, tool, mealName: mealName, onWritten: logged)
        : AddFoodSheet.show(context, mealName: mealName, title: mealName, onAdded: logged);
    shown.whenComplete(() => _sheetOpen = false);
  }

  /// Water from the widget writes at once, through the journal's own path,
  /// and answers with the home's own bar. Without an amount the link only
  /// brings the home up, where the tile is.
  static Future<void> _addWater(int? millilitres) async {
    if (millilitres == null || millilitres <= 0) {
      _closeOurSheet();
      AppNavigator().requestTab('home');
      return;
    }
    final context = _context;
    if (context == null) return;
    final lang = _lang;
    if (!_signedIn) {
      RyzeUndo.failed(context, message: 'must_be_connected'.tr(lang));
      return;
    }

    RyzeFeedback.tap();
    final ok = await WaterService.addWaterEntry(
      amount: millilitres,
      sourceType: millilitres == 250 ? 'glass' : 'manual',
    );
    final c = _context ?? context;
    if (!c.mounted) return;
    if (ok) {
      RyzeUndo.note(c, message: millilitres == 250 ? 'home_glass_added'.tr(lang) : '$millilitres ${'water_added'.tr(lang)}');
    } else {
      RyzeUndo.failed(c, message: 'water_add_error'.tr(lang));
    }
  }

  /// The slot a link names. The new widgets send the slot's own name; the
  /// French types of the first widget are still understood.
  static WeekSlot? _slotOf(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase().trim();
    if (lower == 'dejeuner') return WeekSlot.lunch;
    final type = HomeSlots.normalizeMealType(lower);
    for (final slot in WeekSlot.values) {
      if (slot.name == type) return slot;
    }
    return null;
  }

  static FoodTool? _toolOf(String? mode) => switch (mode?.toLowerCase()) {
        'manual' || 'search' => FoodTool.search,
        'camera' || 'scanner' || 'photo' => FoodTool.photo,
        'barcode' => FoodTool.barcode,
        'recipe' || 'recipes' => FoodTool.recipe,
        'chat' || 'coach' => FoodTool.coach,
        _ => null,
      };
}
