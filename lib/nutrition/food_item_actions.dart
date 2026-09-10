import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/design.dart';
import '../models/nutrition_models.dart' as nutrition;
import '../services/food_entries_service.dart';
import '../services/portions.dart';
import '../services/translations.dart';

/// Les deux gestes d'un aliment noté : refixer ce qu'il pesait, ou l'enlever.
///
/// Ils vivaient en double, à l'identique, dans la journée et l'historique de
/// Nutrition, et nulle part ailleurs : un repas ouvert depuis l'accueil ou
/// depuis le planificateur se lisait sans pouvoir se corriger, alors que c'est
/// la même feuille. Ils vivent ici, et les trois surfaces les appellent.
///
/// Chacun rend vrai quand quelque chose a changé : à l'appelant de se
/// recharger.
class FoodItemActions {
  FoodItemActions._();

  /// Refixer la portion. La feuille propose les quantités plausibles pour
  /// l'unité de l'aliment, plus celle qui est enregistrée : on doit toujours
  /// pouvoir revenir en arrière.
  static Future<bool> editPortion(
    BuildContext context, {
    required nutrition.FoodItem item,
    required String lang,
  }) async {
    if (item.id == null) return false;

    // `portion` porte la quantité telle qu'elle a été saisie : « 120 g ».
    final parts = item.portion.trim().split(RegExp(r'\s+'));
    final current = double.tryParse(parts.first.replaceAll(',', '.')) ?? 100;
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : 'g';
    final steps = <double>{...RyzePortions.presets(unit: unit, reference: current), current}.toList()..sort();

    final chosen = await showRyzeSheet<double>(
      context,
      title: item.name,
      subtitle: 'nutri_fix_portion'.tr(lang),
      builder: (sheet) => Wrap(
        spacing: sheet.vw(2),
        runSpacing: sheet.vw(2),
        children: [
          for (final value in steps)
            _PortionChip(
              label: RyzePortions.label(value, unit, lang),
              selected: (value - current).abs() < 0.05,
              onTap: () => Navigator.pop(sheet, value),
            ),
        ],
      ),
    );
    if (chosen == null || !context.mounted || (chosen - current).abs() < 0.05) return false;

    final ok = await FoodEntriesService.updateFoodEntryQuantity(item.id!, chosen);
    if (!context.mounted) return ok;
    if (ok) {
      RyzeFeedback.confirm();
    } else {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(lang));
    }
    return ok;
  }

  /// Enlever l'aliment, avec la barre d'annulation qui le remet où il était.
  ///
  /// [onUndone] est appelé quand l'aliment est revenu : l'écran qui l'affichait
  /// doit se recharger une seconde fois.
  static Future<bool> remove(
    BuildContext context, {
    required nutrition.FoodItem item,
    required WeekSlot slot,
    required DateTime day,
    required String lang,
    VoidCallback? onUndone,
  }) async {
    if (item.id == null) return false;
    RyzeFeedback.removed();
    final ok = await FoodEntriesService.removeFoodEntry(item.id!);
    if (!context.mounted) return ok;
    if (!ok) {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(lang));
      return false;
    }
    RyzeUndo.show(
      context,
      message: 'undo_item_removed'.tr(lang).replaceAll('{name}', item.name),
      undoLabel: 'undo'.tr(lang),
      onUndo: () async {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;
        await FoodEntriesService.addFoodEntry(
          userId: userId,
          mealName: 'meal_name_${slot.name}'.tr(lang),
          foodItem: item,
          consumedAt: day,
        );
        onUndone?.call();
      },
    );
    return true;
  }
}

class _PortionChip extends StatelessWidget {
  const _PortionChip({required this.label, required this.onTap, this.selected = false});

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.pill),
          border: Border.all(color: RyzeColors.ink, width: 1.5),
        ),
        child: Text(
          label,
          style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: selected ? RyzeColors.surf : RyzeColors.ink),
        ),
      ),
    );
  }
}
