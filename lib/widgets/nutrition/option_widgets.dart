import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FoodOptionWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FoodOptionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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

class MealOptionWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MealOptionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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

class FoodSuggestionWidget extends StatelessWidget {
  final String name;
  final int calories;
  final String per;
  final VoidCallback onTap;
  final bool isCustom;
  final String? origin; // 'manual', 'barcode', ou null
  final bool hasModifiedMacros; // Macronutriments modifiés
  final bool isRecipe; // Est-ce une recette

  const FoodSuggestionWidget({
    super.key,
    required this.name,
    required this.calories,
    required this.per,
    required this.onTap,
    this.isCustom = false,
    this.origin,
    this.hasModifiedMacros = false,
    this.isRecipe = false,
  });

  // Méthode pour déterminer l'icône selon les nouvelles règles
  IconData _getIconBasedOnRules() {
    // Règle 1: Aliment custom_foods avec origin = 'barcode' → icône code-barres
    if (isCustom && origin?.toLowerCase().trim() == 'barcode') {
      return LucideIcons.scan;
    }
    
    // Règle 2: Aliment custom_foods avec origin = 'manual' → icône bonhomme
    if (isCustom && origin?.toLowerCase().trim() == 'manual') {
      return LucideIcons.user;
    }
    
    // Règle 3: Aliment de base avec macronutriments modifiés → icône bonhomme
    if (!isCustom && hasModifiedMacros) {
      return LucideIcons.user;
    }
    
    // Règle 4: Recette avec aliment modifié → icône bonhomme
    if (isRecipe && hasModifiedMacros) {
      return LucideIcons.user;
    }
    
    // Règle 5: Aliment custom par défaut → icône bonhomme
    if (isCustom) {
      return LucideIcons.user;
    }
    
    // Par défaut: pas d'icône (aliment de base non modifié)
    return LucideIcons.user; // Fallback, ne devrait pas être affiché
  }
  
  // Méthode pour déterminer le texte selon les nouvelles règles
  String _getTextBasedOnRules() {
    // Règle 1: Aliment custom_foods avec origin = 'barcode' → "Scanné"
    if (isCustom && origin?.toLowerCase().trim() == 'barcode') {
      return 'Scanné';
    }
    
    // Règle 2: Aliment custom_foods avec origin = 'manual' → "Personnalisé"
    if (isCustom && origin?.toLowerCase().trim() == 'manual') {
      return 'Personnalisé';
    }
    
    // Règle 3: Aliment de base avec macronutriments modifiés → "Modifié"
    if (!isCustom && hasModifiedMacros) {
      return 'Modifié';
    }
    
    // Règle 4: Recette avec aliment modifié → "Modifié"
    if (isRecipe && hasModifiedMacros) {
      return 'Modifié';
    }
    
    // Règle 5: Aliment custom par défaut → "Personnalisé"
    if (isCustom) {
      return 'Personnalisé';
    }
    
    // Par défaut
    return 'Personnalisé';
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Vérifier les paramètres reçus et la logique (focus sur Nutella)
    if (name.toLowerCase().contains('nutella')) {
      print('🎨 DEBUG FoodSuggestionWidget - NUTELLA:');
      print('   - isCustom: $isCustom');
      print('   - origin: "$origin"');
      print('   - hasModifiedMacros: $hasModifiedMacros');
      print('   - isRecipe: $isRecipe');
      print('   - Icône sélectionnée: ${_getIconBasedOnRules()}');
      print('   - Texte sélectionné: ${_getTextBasedOnRules()}');
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Indicateur pour aliment personnalisé, modifié ou scanné
            if (isCustom || hasModifiedMacros || isRecipe) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getIconBasedOnRules(),
                  size: 14,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (isCustom || hasModifiedMacros || isRecipe) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getTextBasedOnRules(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$calories kcal / $per',
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
