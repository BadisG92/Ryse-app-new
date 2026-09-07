import 'package:flutter/material.dart';

import '../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../screens/ai_chat_input_screen.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import 'auth_service.dart';
import 'food_entries_service.dart';
import 'paywall_service.dart';

/// The five ways to put a food into a meal, and the one way it is written.
///
/// This is the flow `NutritionQuickActionsSection` has always run, lifted out
/// of the widget so any surface can use it: the redesigned Nutrition tab, the
/// home, the journal, the iOS widget. The screens, the paywall gates and the
/// write are unchanged; what changes is that the meal is decided by the caller
/// instead of being asked for again inside a chain of bottom sheets.
///
/// Every path ends at `FoodEntriesService.addFoodEntry`, which is the only
/// place that touches Supabase. That call also updates the day's totals, the
/// macros, the meal count, the planner and the meal reminders, so a surface
/// that goes through here stays connected to the rest of the app.
enum FoodTool {
  /// Describe the meal to the coach. Writes itself.
  coach,

  /// Photograph the dish. Writes itself.
  photo,

  /// Scan a barcode. Hands back a food, we write it.
  barcode,

  /// Search the database. Hands back a food, we write it.
  search,

  /// Pick one of the user's recipes. Hands back a food, we write it.
  recipe,
}

class FoodAddFlow {
  FoodAddFlow._();

  /// The meal being filled, so two tools opened in a row land in the same meal
  /// instead of creating two. Cleared once the meal is written.
  static String? _pendingId;
  static String? _pendingMeal;

  /// Which gate each tool sits behind. Search and recipes are open.
  static PaywallContext? _gate(FoodTool tool) => switch (tool) {
        FoodTool.coach => PaywallContext.chatInput,
        FoodTool.photo => PaywallContext.scanner,
        FoodTool.barcode => PaywallContext.barcodeScanner,
        FoodTool.search || FoodTool.recipe => null,
      };

  /// The id the meal's entries share. Reused while the same meal is open.
  static Future<String?> mealId(String mealName, {DateTime? date}) async {
    final user = AuthService().currentUser;
    if (user == null) return null;

    if (_pendingId != null && _pendingMeal?.toLowerCase() == mealName.toLowerCase()) {
      return _pendingId;
    }

    final id = await FoodEntriesService.generateMealId(
      userId: user.id,
      mealName: mealName,
      forDate: date ?? DateTime.now(),
    );
    if (id != null) {
      _pendingId = id;
      _pendingMeal = mealName;
    }
    return id;
  }

  /// Forget the meal being filled, so the next add starts a new one.
  static void reset() {
    _pendingId = null;
    _pendingMeal = null;
  }

  /// Opens one tool for [mealName]. [onWritten] fires after the tools that
  /// hand a food back; the two that write themselves report through the
  /// app's own refresh, as they always have.
  ///
  /// [date] decides the day the entry lands on for the three tools we write
  /// ourselves. The coach and the photo scanner write from inside their own
  /// screen and always land on today.
  static Future<void> open(
    BuildContext context,
    FoodTool tool, {
    required String mealName,
    DateTime? date,
    void Function(FoodItem item)? onWritten,
  }) async {
    final gate = _gate(tool);
    if (gate != null) {
      final allowed = await PaywallService.instance.canUseFeature(
        context: context,
        paywallContext: gate,
      );
      if (!allowed) return;
    }
    if (!context.mounted) return;

    final id = await mealId(mealName, date: date);
    if (id == null || !context.mounted) return;

    Future<void> take(FoodItem item) async {
      final ok = await write(item, mealName: mealName, mealId: id, date: date);
      if (ok) onWritten?.call(item);
    }

    switch (tool) {
      case FoodTool.coach:
        AIChatInputScreen.showAsBottomSheet(
          context,
          isFromDashboard: true,
          mealName: mealName,
          mealId: id,
        );
      case FoodTool.photo:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIScannerScreen(isFromDashboard: true, mealName: mealName, mealId: id),
          ),
        );
      case FoodTool.barcode:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BarcodeScannerScreen(isFromDashboard: true, onFoodScanned: take),
          ),
        );
      case FoodTool.search:
        ManualFoodSearchBottomSheet.show(context, isFromDashboard: true, onFoodCreated: take);
      case FoodTool.recipe:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectRecipeScreen(isFromDashboard: true, onRecipeSelected: take),
          ),
        );
    }
  }

  /// Writes one food into one meal. The single write path, used by the tools
  /// above and by the recents of the add sheet.
  static Future<bool> write(
    FoodItem item, {
    required String mealName,
    String? mealId,
    DateTime? date,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return false;

    final at = date == null ? DateTime.now() : _sameTimeOfDay(date);
    final id = mealId ??
        await FoodEntriesService.generateMealId(userId: user.id, mealName: mealName, forDate: at);
    if (id == null) return false;

    final writing = FoodEntriesService.addFoodEntry(
      userId: user.id,
      mealName: mealName,
      foodItem: item,
      consumedAt: at,
      mealId: id,
    );

    final ok = await writing;
    if (ok) reset();
    return ok;
  }

  /// A past day is logged at the current hour of that day, so the entry keeps
  /// a plausible time instead of landing at midnight.
  static DateTime _sameTimeOfDay(DateTime day) {
    final now = DateTime.now();
    if (day.year == now.year && day.month == now.month && day.day == now.day) return now;
    return DateTime(day.year, day.month, day.day, now.hour, now.minute);
  }
}
