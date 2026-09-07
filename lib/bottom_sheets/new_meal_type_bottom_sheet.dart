import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

/// Quel repas créer, quand aucun n'est encore ouvert.
///
/// Les quatre repas de la journée, dans l'ordre où on les prend, chacun avec
/// son heure par défaut. C'est la même feuille que partout ailleurs depuis la
/// refonte : le repas est une rangée, pas une carte à ombre.
class NewMealTypeBottomSheet {
  NewMealTypeBottomSheet._();

  static const List<(String, IconData, String)> _meals = [
    ('breakfast', LucideIcons.sunrise, '08:00'),
    ('lunch', LucideIcons.sun, '12:30'),
    ('snack', LucideIcons.milk, '16:00'),
    ('dinner', LucideIcons.sunset, '19:30'),
  ];

  static void show(
    BuildContext context, {
    required Function(String mealType, String time) onMealTypeSelected,
  }) {
    final lang = LocalizationService.instance.currentLanguageCode;
    showRyzeSheet<void>(
      context,
      title: 'create_new_meal'.tr(lang),
      subtitle: 'choose_meal_type_to_create'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          for (final meal in _meals)
            RyzeSheetRow(
              first: meal == _meals.first,
              icon: meal.$2,
              label: meal.$1.tr(lang),
              hint: meal.$3,
              onTap: () {
                Navigator.pop(sheet);
                onMealTypeSelected(meal.$1.tr(lang), meal.$3);
              },
            ),
        ],
      ),
    );
  }
}
