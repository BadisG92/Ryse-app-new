import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../widgets/nutrition/option_widgets.dart';

class FoodInputMethodBottomSheet {
  static void show(
    BuildContext context, {
    required String mealType,
    required String time,
    required Function() onManualSelected,
    required Function() onAIPhotoSelected,
    required Function() onBarcodeSelected,
    required Function() onRecipeSelected,
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
                  'add_food_to_meal_simple'.tr(locService.currentLanguageCode),
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
                  'choose_input_method'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Input method options
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Column(
                  children: [
                    // Manual food entry
                    FoodOptionWidget(
                      icon: LucideIcons.pencil,
                      title: 'manual_food_entry'.tr(locService.currentLanguageCode),
                      subtitle: 'manual_food_entry_description'.tr(locService.currentLanguageCode),
                      onTap: () {
                        Navigator.pop(context);
                        onManualSelected();
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // AI Photo
                    FoodOptionWidget(
                      icon: LucideIcons.camera,
                      title: 'ai_photo_scan'.tr(locService.currentLanguageCode),
                      subtitle: 'ai_photo_scan_description'.tr(locService.currentLanguageCode),
                      onTap: () {
                        Navigator.pop(context);
                        onAIPhotoSelected();
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Barcode scanner
                    FoodOptionWidget(
                      icon: LucideIcons.scan,
                      title: 'barcode_scanner'.tr(locService.currentLanguageCode),
                      subtitle: 'barcode_scanner_description'.tr(locService.currentLanguageCode),
                      onTap: () {
                        Navigator.pop(context);
                        onBarcodeSelected();
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Recipe selection
                    FoodOptionWidget(
                      icon: LucideIcons.bookOpen,
                      title: 'recipe_selection'.tr(locService.currentLanguageCode),
                      subtitle: 'recipe_selection_description'.tr(locService.currentLanguageCode),
                      onTap: () {
                        Navigator.pop(context);
                        onRecipeSelected();
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
}