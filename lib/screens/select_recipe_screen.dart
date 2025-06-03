import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'recipe_details_screen.dart';

class SelectRecipeScreen extends StatefulWidget {
  const SelectRecipeScreen({super.key});

  @override
  State<SelectRecipeScreen> createState() => _SelectRecipeScreenState();
}

class _SelectRecipeScreenState extends State<SelectRecipeScreen> {
  String searchQuery = '';

  final List<Recipe> recipes = [
    Recipe(
      name: 'Salade de quinoa aux légumes',
      calories: 320,
      time: '15 min',
      portions: 2,
      difficulty: 'Facile',
      ingredients: [
        'Quinoa - 80g',
        'Tomates cerises - 100g',
        'Concombre - 50g',
        'Avocat - 60g',
        'Huile d\'olive - 10ml',
      ],
    ),
    Recipe(
      name: 'Saumon grillé aux brocolis',
      calories: 450,
      time: '25 min',
      portions: 1,
      difficulty: 'Moyen',
      ingredients: [
        'Filet de saumon - 150g',
        'Brocolis - 200g',
        'Citron - 30g',
        'Huile d\'olive - 5ml',
        'Ail - 5g',
      ],
    ),
    Recipe(
      name: 'Bowl petit-déjeuner aux fruits',
      calories: 280,
      time: '10 min',
      portions: 1,
      difficulty: 'Facile',
      ingredients: [
        'Yaourt grec - 150g',
        'Flocons d\'avoine - 30g',
        'Banane - 80g',
        'Myrtilles - 50g',
        'Miel - 10g',
      ],
    ),
    Recipe(
      name: 'Smoothie protéiné',
      calories: 195,
      time: '5 min',
      portions: 1,
      difficulty: 'Facile',
      ingredients: [
        'Lait d\'amande - 200ml',
        'Banane - 100g',
        'Poudre de protéine - 25g',
        'Épinards - 30g',
        'Graines de chia - 10g',
      ],
    ),
    Recipe(
      name: 'Curry de lentilles',
      calories: 380,
      time: '30 min',
      portions: 3,
      difficulty: 'Moyen',
      ingredients: [
        'Lentilles corail - 100g',
        'Lait de coco - 200ml',
        'Tomates - 150g',
        'Oignon - 80g',
        'Épices curry - 5g',
      ],
    ),
  ];

  List<Recipe> get filteredRecipes {
    if (searchQuery.isEmpty) return recipes;
    return recipes.where((recipe) =>
        recipe.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
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
        title: const Text(
          'Choisir une recette',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
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
                  hintText: 'Rechercher une recette...',
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
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),
          
          // Liste des recettes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRecipeCard(recipe),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.chefHat,
                size: 32,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et difficulté
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: recipe.difficulty == 'Facile'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        recipe.difficulty,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: recipe.difficulty == 'Facile'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCA8A04),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Infos principales
                Row(
                  children: [
                    _buildInfoChip(
                      LucideIcons.flame,
                      '${recipe.calories} kcal',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      LucideIcons.clock,
                      recipe.time,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      LucideIcons.users,
                      '${recipe.portions} portion${recipe.portions > 1 ? 's' : ''}',
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Ingrédients (aperçu)
                const Text(
                  'Ingrédients principaux :',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.ingredients.take(3).map((ing) => ing.split(' - ')[0]).join(', '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Bouton d'ajout
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openRecipeDetails(recipe),
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Ajouter au repas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  void _openRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(recipe: recipe),
      ),
    );
  }
}

class Recipe {
  final String name;
  final int calories;
  final String time;
  final int portions;
  final String difficulty;
  final List<String> ingredients;

  Recipe({
    required this.name,
    required this.calories,
    required this.time,
    required this.portions,
    required this.difficulty,
    required this.ingredients,
  });
} 