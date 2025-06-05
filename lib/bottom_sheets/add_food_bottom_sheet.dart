import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';

class AddFoodBottomSheet {
  static void show(BuildContext context, Function showManualEntryBottomSheet) {
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
              const Text(
                'Ajouter un aliment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Choisissez comment vous souhaitez ajouter votre aliment',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Options
              FoodOptionWidget(
                icon: LucideIcons.edit3,
                title: 'Saisie manuelle',
                subtitle: 'Rechercher et ajouter manuellement',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  // Ouvrir le second bottom sheet pour la saisie manuelle
                  Future.delayed(const Duration(milliseconds: 300), () {
                    showManualEntryBottomSheet();
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.camera,
                title: 'Scanner avec l\'IA',
                subtitle: 'Prenez une photo de votre plat',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  // Ouvrir la page scanner IA immédiatement
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIScannerScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.scan,
                title: 'Code-barres',
                subtitle: 'Scanner le code-barres du produit',
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
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.chefHat,
                title: 'Mes recettes',
                subtitle: 'Choisir parmi vos recettes sauvegardées',
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
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 