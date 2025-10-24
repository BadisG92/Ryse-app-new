import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

class AddMealBottomSheet {
  static void show(
    BuildContext context,
    Function(String mealType) onMealTypeSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<LocalizationService>(
        builder: (context, locService, _) {
          final lang = locService.currentLanguageCode;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Titre
                  Text(
                    'add_meal'.tr(lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'choose_meal_type_to_create'.tr(lang),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Types de repas - Ordre: Petit-déjeuner, Déjeuner, Collation, Dîner
                  MealOptionWidget(
                    icon: LucideIcons.sunrise,
                    title: 'breakfast'.tr(lang),
                    subtitle: 'breakfast_description'.tr(lang),
                    onTap: () {
                      Navigator.pop(context);
                      onMealTypeSelected('breakfast'.tr(lang));
                    },
                  ),

                  const SizedBox(height: 12),

                  MealOptionWidget(
                    icon: LucideIcons.sun,
                    title: 'lunch'.tr(lang),
                    subtitle: 'lunch_description'.tr(lang),
                    onTap: () {
                      Navigator.pop(context);
                      onMealTypeSelected('lunch'.tr(lang));
                    },
                  ),

                  const SizedBox(height: 12),

                  MealOptionWidget(
                    icon: LucideIcons.milk,
                    title: 'snack'.tr(lang),
                    subtitle: 'snack_description'.tr(lang),
                    onTap: () {
                      Navigator.pop(context);
                      onMealTypeSelected('snack'.tr(lang));
                    },
                  ),

                  const SizedBox(height: 12),

                  MealOptionWidget(
                    icon: LucideIcons.sunset,
                    title: 'dinner'.tr(lang),
                    subtitle: 'dinner_description'.tr(lang),
                    onTap: () {
                      Navigator.pop(context);
                      onMealTypeSelected('dinner'.tr(lang));
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 
