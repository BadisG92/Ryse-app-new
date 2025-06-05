import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../screens/manual_food_entry_screen.dart';

class ManualEntryBottomSheet {
  static void show(BuildContext context, Function showFoodDetailsBottomSheet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
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
                
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.transparent,
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Rechercher un aliment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Champ de recherche
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un aliment...',
                      hintStyle: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: Implémenter la recherche avec suggestions
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bouton "Ajouter manuellement"
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final parentContext = context;
                      Navigator.pop(context);
                      // TODO: Ouvrir l'écran d'ajout manuel
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.push(
                          parentContext,
                          MaterialPageRoute(
                            builder: (context) => const ManualFoodEntryScreen(),
                          ),
                        );
                      });
                    },
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: Color(0xFF0B132B),
                    ),
                    label: const Text(
                      'Ajouter un aliment manuellement',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFF0B132B),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                // Liste des suggestions
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      // Suggestions d'aliments (mockées pour l'instant)
                      FoodSuggestionWidget(
                        name: 'Pomme rouge',
                        calories: 52,
                        per: '100g',
                        onTap: () => showFoodDetailsBottomSheet('Pomme rouge', 52, 100),
                      ),
                      FoodSuggestionWidget(
                        name: 'Banane',
                        calories: 89,
                        per: '100g',
                        onTap: () => showFoodDetailsBottomSheet('Banane', 89, 100),
                      ),
                      FoodSuggestionWidget(
                        name: 'Riz blanc cuit',
                        calories: 130,
                        per: '100g',
                        onTap: () => showFoodDetailsBottomSheet('Riz blanc cuit', 130, 100),
                      ),
                      FoodSuggestionWidget(
                        name: 'Poulet grillé',
                        calories: 165,
                        per: '100g',
                        onTap: () => showFoodDetailsBottomSheet('Poulet grillé', 165, 100),
                      ),
                      FoodSuggestionWidget(
                        name: 'Brocolis cuits',
                        calories: 35,
                        per: '100g',
                        onTap: () => showFoodDetailsBottomSheet('Brocolis cuits', 35, 100),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 