import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

class NewMealTypeBottomSheet {
  static void show(
    BuildContext context, {
    required Function(String mealType, String time) onMealTypeSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
              
              // Title
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'create_new_meal'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'choose_meal_type_to_create'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Options de repas - Ordre: Petit-déjeuner, Déjeuner, Collation, Dîner
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Column(
                  children: [
                    _buildMealOption(
                      context,
                      locService,
                      titleKey: 'breakfast',
                      descriptionKey: 'breakfast_description',
                      icon: LucideIcons.sunrise,
                      onTap: () {
                        Navigator.pop(context);
                        onMealTypeSelected('breakfast'.tr(locService.currentLanguageCode), '08:00');
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildMealOption(
                      context,
                      locService,
                      titleKey: 'lunch',
                      descriptionKey: 'lunch_description',
                      icon: LucideIcons.sun,
                      onTap: () {
                        Navigator.pop(context);
                        onMealTypeSelected('lunch'.tr(locService.currentLanguageCode), '12:30');
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildMealOption(
                      context,
                      locService,
                      titleKey: 'snack',
                      descriptionKey: 'snack_description',
                      icon: LucideIcons.milk,
                      onTap: () {
                        Navigator.pop(context);
                        onMealTypeSelected('snack'.tr(locService.currentLanguageCode), '16:00');
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildMealOption(
                      context,
                      locService,
                      titleKey: 'dinner',
                      descriptionKey: 'dinner_description',
                      icon: LucideIcons.sunset,
                      onTap: () {
                        Navigator.pop(context);
                        onMealTypeSelected('dinner'.tr(locService.currentLanguageCode), '19:30');
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMealOption(
    BuildContext context,
    LocalizationService locService, {
    required String titleKey,
    required String descriptionKey,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleKey.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descriptionKey.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
} 
