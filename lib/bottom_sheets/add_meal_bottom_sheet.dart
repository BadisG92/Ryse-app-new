import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/nutrition/option_widgets.dart';

class AddMealBottomSheet {
  static void show(BuildContext context, Function showAddFoodBottomSheet) {
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
              
              // Titre
              const Text(
                'Ajouter un repas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Quel type de repas souhaitez-vous ajouter ?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Types de repas
              MealOptionWidget(
                icon: LucideIcons.sunrise,
                title: 'Petit-déjeuner',
                subtitle: 'Commencez bien votre journée',
                onTap: () {
                  Navigator.pop(context);
                  // Ouvrir le bottom sheet d'ajout d'aliment après sélection du repas
                  Future.delayed(const Duration(milliseconds: 300), () {
                    showAddFoodBottomSheet();
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              MealOptionWidget(
                icon: LucideIcons.sun,
                title: 'Déjeuner',
                subtitle: 'Votre repas principal de midi',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    showAddFoodBottomSheet();
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              MealOptionWidget(
                icon: LucideIcons.sunset,
                title: 'Dîner',
                subtitle: 'Terminez la journée en beauté',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    showAddFoodBottomSheet();
                  });
                },
              ),
              
              const SizedBox(width: 12),
              
              MealOptionWidget(
                icon: LucideIcons.milk,
                title: 'Collation',
                subtitle: 'Une petite pause gourmande',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    showAddFoodBottomSheet();
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