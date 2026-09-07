import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/design.dart';
import '../models/nutrition_models.dart';
import '../services/food_add_flow.dart';
import '../services/food_entries_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

/// How a food gets into a meal, in one sheet.
///
/// The meal is already chosen, because the sheet is always opened from a meal:
/// the app never asks twice. What the user eats again comes first, as chips
/// that log in one tap; the five ways to describe something new come after.
///
/// The recents are filtered by meal type, so the sheet never offers chicken at
/// breakfast. Everything written here goes through [FoodAddFlow], which is the
/// journal's own write path.
class AddFoodSheet {
  AddFoodSheet._();

  /// [mealName] is the journal's own name for the meal, the one
  /// `FoodEntriesService` recognises. [onAdded] fires once something was
  /// written, so the page can refresh and offer to undo.
  static Future<void> show(
    BuildContext context, {
    required String mealName,
    required String title,
    DateTime? date,
    required void Function(FoodItem item) onAdded,
  }) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final recents = userId == null
        ? <FoodItem>[]
        : await FoodEntriesService.getRecentFoodsForMealType(userId, mealName);
    if (!context.mounted) return;

    await showRyzeSheet<void>(
      context,
      title: title,
      subtitle: 'nutri_how_add'.tr(lang),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recents.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: sheet.vw(2.3)),
              child: Text(
                'way_recent'.tr(lang),
                style: RyzeText.body(sheet, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
              ),
            ),
            SizedBox(
              height: sheet.vw(11),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: recents.length,
                separatorBuilder: (_, __) => SizedBox(width: sheet.vw(2.1)),
                itemBuilder: (_, i) => _RecentChip(
                  item: recents[i],
                  lang: lang,
                  onTap: () async {
                    RyzeFeedback.confirm();
                    Navigator.pop(sheet);
                    final ok = await FoodAddFlow.write(recents[i], mealName: mealName, date: date);
                    if (ok) onAdded(recents[i]);
                  },
                ),
              ),
            ),
            SizedBox(height: sheet.vw(4.1)),
          ],
          RyzeSheetGroup(
            children: [
              for (final way in AddFoodSheet._ways)
                RyzeSheetRow(
                  first: way == AddFoodSheet._ways.first,
                  icon: way.icon,
                  label: way.label.tr(lang),
                  hint: way.hint.tr(lang),
                  onTap: () {
                    Navigator.pop(sheet);
                    FoodAddFlow.open(
                      context,
                      way.tool,
                      mealName: mealName,
                      date: date,
                      onWritten: onAdded,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Les deux façons où Ryze fait le travail viennent d'abord — la photo,
  /// puis la phrase. C'est ce que l'app sait faire que personne d'autre ne
  /// fait ; chercher un aliment dans une liste, tout le monde sait. Le reste
  /// suit dans l'ordre de l'effort demandé à l'utilisateur.
  static const List<_Way> _ways = [
    _Way(FoodTool.photo, LucideIcons.camera, 'way_photo', 'way_photo_hint'),
    _Way(FoodTool.coach, LucideIcons.messageCircle, 'way_coach', 'way_coach_hint'),
    _Way(FoodTool.barcode, LucideIcons.scanLine, 'way_barcode', 'way_barcode_hint'),
    _Way(FoodTool.search, LucideIcons.search, 'way_search', 'way_search_hint'),
    _Way(FoodTool.recipe, LucideIcons.chefHat, 'way_recipe', 'way_recipe_hint'),
  ];
}

class _Way {
  const _Way(this.tool, this.icon, this.label, this.hint);

  final FoodTool tool;
  final IconData icon;
  final String label;
  final String hint;
}

/// A dish already eaten at this meal: its name, its calories, one tap.
class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.item, required this.lang, required this.onTap});

  final FoodItem item;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RyzeColors.paper,
          borderRadius: BorderRadius.circular(RyzeRadius.pill),
          border: Border.all(color: RyzeColors.idle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.vw(36)),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RyzeText.body(context, 3.4, weight: FontWeight.w600),
              ),
            ),
            SizedBox(width: context.vw(1.8)),
            Text(
              '${item.calories} ${'nutri_kcal'.tr(lang)}',
              style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
            ),
          ],
        ),
      ),
    );
  }
}
