import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

class AddFoodBottomSheet {
  static void show(
    BuildContext context, 
    Function showManualEntryBottomSheet, {
    String? mealName,
    String? mealId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
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
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  return Text(
                    'add_food'.tr(localizationService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  return Text(
                    'choose_how_to_add_food'.tr(localizationService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Options
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  return FoodOptionWidget(
                    icon: LucideIcons.pencil,
                    title: 'manual_entry_title'.tr(localizationService.currentLanguageCode),
                    subtitle: 'search_and_add_manually'.tr(localizationService.currentLanguageCode),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      // Ouvrir le second bottom sheet pour la saisie manuelle
                      Future.delayed(const Duration(milliseconds: 300), () {
                        showManualEntryBottomSheet();
                      });
                    },
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  return FoodOptionWidget(
                    icon: LucideIcons.camera,
                    title: 'ai_scanner_title'.tr(localizationService.currentLanguageCode),
                    subtitle: 'take_photo_of_dish'.tr(localizationService.currentLanguageCode),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      // Ouvrir la page scanner IA immédiatement
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIScannerScreen(
                            isFromDashboard: mealName == null && mealId == null,
                            mealName: mealName,
                            mealId: mealId,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  return FoodOptionWidget(
                    icon: LucideIcons.scan,
                    title: 'barcode'.tr(localizationService.currentLanguageCode),
                    subtitle: 'scan_product_barcode'.tr(localizationService.currentLanguageCode),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      // Ouvrir la page scanner code-barres immédiatement
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScannerScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  return FoodOptionWidget(
                    icon: LucideIcons.chefHat,
                    title: 'my_recipes'.tr(localizationService.currentLanguageCode),
                    subtitle: 'choose_from_saved_recipes'.tr(localizationService.currentLanguageCode),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      // Ouvrir la page sélection de recettes
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectRecipeScreen(),
                          ),
                        );
                      });
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 
