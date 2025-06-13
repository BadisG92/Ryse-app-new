import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/ui/recipe_models.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart' as nutrition_models;

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isFromDashboard;

  const RecipeDetailsScreen({
    super.key, 
    required this.recipe,
    this.isFromDashboard = false,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  double currentPortions = 1.0;
  bool isCustomized = false;
  bool showMacrosUpdatedMessage = false;
  Map<String, double> customizedIngredients = {};
  
  bool isIngredientsExpanded = false;
  bool isRecipeExpanded = false;

  @override
  void initState() {
    super.initState();
    currentPortions = widget.recipe.portions.toDouble();
  }

  // Calcul des calories par portion
  int get caloriesPerPortion => (widget.recipe.calories / widget.recipe.portions).round();
  
  // Calcul des macros par portion (approximatifs)
  double get proteinPerPortion => (caloriesPerPortion * 0.15 / 4); // 15% des calories
  double get carbsPerPortion => (caloriesPerPortion * 0.55 / 4); // 55% des calories
  double get fatPerPortion => (caloriesPerPortion * 0.30 / 9); // 30% des calories

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header fixe
          _buildHeader(),
          
          // Message des macros mises à jour
          if (showMacrosUpdatedMessage) _buildMacrosUpdatedMessage(),
          
          // Contenu principal scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRecipeImage(),
                  _buildRecipeTitle(),
                  _buildNutritionSummary(),
                  _buildIngredientSection(),
                  _buildRecipeSteps(),
                  const SizedBox(height: 100), // Espace pour le bouton du bas
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: Row(
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
                'Détails de la recette',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosUpdatedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF16A34A)),
      ),
      child: const Row(
        children: [
          Icon(
            LucideIcons.check,
            size: 16,
            color: Color(0xFF16A34A),
          ),
          SizedBox(width: 8),
          Text(
            'Macros mises à jour',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage() {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFFF8F9FA),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.chefHat,
              size: 48,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 8),
            Text(
              'Photo de la recette',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeTitle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              widget.recipe.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              isCustomized 
                ? 'Portion personnalisée • ${widget.recipe.time}'
                : '${currentPortions.toStringAsFixed(currentPortions.truncateToDouble() == currentPortions ? 0 : 1)} portion${currentPortions > 1 ? 's' : ''} • ${widget.recipe.time}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bilan nutritionnel (par portion)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            // Calories en premier (style mis en valeur)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  '${(caloriesPerPortion * currentPortions).round()} kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Protéines
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Protéines',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${(proteinPerPortion * currentPortions).toStringAsFixed(1)}g',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Glucides
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Glucides',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${(carbsPerPortion * currentPortions).toStringAsFixed(1)}g',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Lipides
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lipides',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${(fatPerPortion * currentPortions).toStringAsFixed(1)}g',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildExpandableSection(
        title: 'Ingrédients',
        isExpanded: isIngredientsExpanded,
        onTap: () => setState(() => isIngredientsExpanded = !isIngredientsExpanded),
        content: _buildIngredientsContent(),
        actions: isIngredientsExpanded ? _buildIngredientActions() : null,
      ),
    );
  }

  Widget _buildRecipeSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildExpandableSection(
        title: 'Étapes de préparation',
        isExpanded: isRecipeExpanded,
        onTap: () => setState(() => isRecipeExpanded = !isRecipeExpanded),
        content: _buildStepsContent(),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
    Widget? actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
            if (actions != null) ...[
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: actions,
              ),
            ],
          ] else ...[
            // Gradient pour suggérer qu'il y a plus de contenu
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  'Toucher pour voir plus...',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B).withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.recipe.ingredients.asMap().entries.map((entry) {
        final ingredient = entry.value;
        
        // Correction du parsing des ingrédients : "quantité - nom" devient "nom - quantité"
        final parts = ingredient.split(' - ');
        final quantity = parts[0]; // La quantité est maintenant en premier
        final name = parts.length > 1 ? parts[1] : ingredient; // Le nom en second
        
        final estimatedCalories = (caloriesPerPortion / widget.recipe.ingredients.length);
        
        // Utiliser la quantité personnalisée si elle existe, sinon la quantité proportionnelle
        final baseQuantity = double.tryParse(quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0;
        final currentQuantity = customizedIngredients.containsKey(ingredient)
          ? customizedIngredients[ingredient]!
          : baseQuantity;
        
        final adjustedQuantity = isCustomized && customizedIngredients.containsKey(ingredient)
          ? currentQuantity
          : currentQuantity * currentPortions;
        
        final adjustedCalories = isCustomized && customizedIngredients.containsKey(ingredient)
          ? (estimatedCalories * currentQuantity / baseQuantity)
          : estimatedCalories * currentPortions;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF64748B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Text(
                '${adjustedQuantity.toStringAsFixed(adjustedQuantity.truncateToDouble() == adjustedQuantity ? 0 : 1)}${_getQuantityUnit(quantity)} • ${adjustedCalories.round()} kcal',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIngredientActions() {
    return Column(
      children: [
        // Modifier la portion
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: _showPortionDialog,
            icon: const Icon(
              LucideIcons.settings,
              size: 16,
              color: Color(0xFF0B132B),
            ),
            label: const Text(
              'Modifier la portion',
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // Modifier les aliments
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _editIngredients,
            icon: const Icon(
              LucideIcons.pencil,
              size: 16,
              color: Color(0xFF0B132B),
            ),
            label: const Text(
              'Modifier les aliments',
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.recipe.steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomCTA() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleAddRecipeToMeal,
            icon: const Icon(
              LucideIcons.plus,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              'Ajouter à un repas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPortionDialog() {
    final portionController = TextEditingController(
      text: currentPortions.toStringAsFixed(currentPortions.truncateToDouble() == currentPortions ? 0 : 1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Modifier la portion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nombre de portions',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffix: Text('portion(s)'),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newPortions = double.tryParse(portionController.text);
              if (newPortions != null && newPortions > 0) {
                setState(() {
                  currentPortions = newPortions;
                  // Reset les ingrédients personnalisés si on change les portions
                  if (isCustomized) {
                    isCustomized = false;
                    customizedIngredients.clear();
                  }
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _editIngredients() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditIngredientsScreen(
          recipe: widget.recipe,
          currentPortions: currentPortions,
          customizedIngredients: customizedIngredients,
          onIngredientsUpdated: (updatedIngredients) {
            setState(() {
              customizedIngredients = updatedIngredients;
              isCustomized = true;
              showMacrosUpdatedMessage = true;
            });
            // Masquer le message après 3 secondes
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  showMacrosUpdatedMessage = false;
                });
              }
            });
          },
        ),
      ),
    );
  }

  void _handleAddRecipeToMeal() {
    // Créer un FoodItem basé sur la recette
    final totalCalories = (widget.recipe.calories * currentPortions / widget.recipe.portions).round();
    final foodItem = nutrition_models.FoodItem(
      name: widget.recipe.name,
      calories: totalCalories,
      portion: '${currentPortions.toStringAsFixed(currentPortions.truncateToDouble() == currentPortions ? 0 : 1)} portion(s)',
    );
    
    if (widget.isFromDashboard) {
      // Si on vient du dashboard, utiliser le système de sélection de repas
      _showMealSelectionBottomSheet(foodItem);
    } else {
      // Si on vient du journal, ajouter directement au repas contextuel
      // Fermer l'écran de détails ET l'écran de sélection de recettes
      Navigator.pop(context); // Ferme RecipeDetailsScreen
      Navigator.pop(context); // Ferme SelectRecipeScreen
      
      // Afficher le message de confirmation après fermeture
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${foodItem.name} ajouté au repas'),
              backgroundColor: const Color(0xFF0B132B),
            ),
          );
        }
      });
    }
  }

  void _showMealSelectionBottomSheet(nutrition_models.FoodItem foodItem) {
    // Simuler des repas existants
    final existingMeals = <nutrition_models.Meal>[
      nutrition_models.Meal(
        name: 'Petit-déjeuner',
        time: '08:30',
        items: [
          nutrition_models.FoodItem(
            name: 'Café',
            calories: 5,
            portion: '1 tasse',
          ),
        ],
      ),
      nutrition_models.Meal(
        name: 'Déjeuner',
        time: '12:45',
        items: [
          nutrition_models.FoodItem(
            name: 'Salade',
            calories: 150,
            portion: '200g',
          ),
        ],
      ),
    ];

    MealSelectionBottomSheet.show(
      context,
      foodName: foodItem.name,
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) {
        print('Ajouter ${foodItem.name} au repas ${meal.name}');
        
        // Fermer seulement RecipeDetailsScreen (retour à l'onglet d'origine)
        Navigator.pop(context);
        
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${foodItem.name} ajouté au ${meal.name}')),
            );
          }
        });
      },
      onCreateNewMeal: () {
        NewMealTypeBottomSheet.show(
          context,
          onMealTypeSelected: (mealType, time) {
            print('Créer un nouveau repas $mealType avec ${foodItem.name}');
            
            // Fermer seulement RecipeDetailsScreen (retour à l'onglet d'origine)
            Navigator.pop(context);
            
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${foodItem.name} ajouté au nouveau $mealType')),
                );
              }
            });
          },
        );
      },
    );
  }

  String _getQuantityUnit(String quantity) {
    if (quantity.contains('ml')) return 'ml';
    if (quantity.contains('g')) return 'g';
    if (quantity.contains('tasse')) return ' tasse(s)';
    if (quantity.contains('cuillère')) return ' cuillère(s)';
    return 'g'; // par défaut
  }
}

// Écran pour modifier les ingrédients individuellement
class EditIngredientsScreen extends StatefulWidget {
  final Recipe recipe;
  final double currentPortions;
  final Map<String, double> customizedIngredients;
  final Function(Map<String, double>) onIngredientsUpdated;

  const EditIngredientsScreen({
    super.key,
    required this.recipe,
    required this.currentPortions,
    required this.customizedIngredients,
    required this.onIngredientsUpdated,
  });

  @override
  State<EditIngredientsScreen> createState() => _EditIngredientsScreenState();
}

class _EditIngredientsScreenState extends State<EditIngredientsScreen> {
  late Map<String, double> tempCustomizedIngredients;

  @override
  void initState() {
    super.initState();
    tempCustomizedIngredients = Map.from(widget.customizedIngredients);
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
          'Modifier les aliments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              widget.onIngredientsUpdated(tempCustomizedIngredients);
              Navigator.pop(context);
            },
            child: const Text(
              'Terminer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B132B),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.recipe.ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = widget.recipe.ingredients[index];
          final parts = ingredient.split(' - ');
          final quantity = parts[0]; // Quantité en premier
          final name = parts.length > 1 ? parts[1] : ingredient; // Nom en second
          final estimatedCalories = (widget.recipe.calories / widget.recipe.portions / widget.recipe.ingredients.length).round();
          
          final baseQuantity = double.tryParse(quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0;
          final currentQuantity = tempCustomizedIngredients.containsKey(ingredient)
            ? tempCustomizedIngredients[ingredient]!
            : baseQuantity * widget.currentPortions;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIngredientCard(ingredient, name, estimatedCalories, quantity, currentQuantity),
          );
        },
      ),
    );
  }

  Widget _buildIngredientCard(String ingredient, String name, int baseCalories, String originalQuantity, double currentQuantity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${baseCalories} kcal • ${currentQuantity.toStringAsFixed(currentQuantity.truncateToDouble() == currentQuantity ? 0 : 1)}${_getQuantityUnit(originalQuantity)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _editIngredient(ingredient, name, baseCalories, originalQuantity, currentQuantity),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              child: const Icon(
                LucideIcons.pencil,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editIngredient(String ingredient, String name, int baseCalories, String originalQuantity, double currentQuantity) {
    final originalQty = double.tryParse(originalQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0;
    final calories = (baseCalories * currentQuantity / originalQty).round();
    
    // Calcul des macronutriments (valeurs approximatives basées sur les calories)
    final protein = (calories * 0.15 / 4); // 15% des calories en protéines
    final carbs = (calories * 0.55 / 4); // 55% des calories en glucides  
    final fat = (calories * 0.30 / 9); // 30% des calories en lipides

    EditableFoodDetailsBottomSheet.show(
      context,
      name: name,
      calories: calories,
      proteins: protein,
      glucides: carbs,
      lipides: fat,
      quantity: currentQuantity,
      isModified: false,
      // Utiliser onFoodSaved pour juste enregistrer les modifications sans ajouter au repas
      onFoodSaved: (foodItem) {
        setState(() {
          tempCustomizedIngredients[ingredient] = double.parse(foodItem.portion.replaceAll('g', ''));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name enregistré'),
            backgroundColor: const Color(0xFF0B132B),
          ),
        );
      },
    );
  }

  String _getQuantityUnit(String quantity) {
    if (quantity.contains('ml')) return 'ml';
    if (quantity.contains('g')) return 'g';
    if (quantity.contains('tasse')) return ' tasse(s)';
    if (quantity.contains('cuillère')) return ' cuillère(s)';
    return 'g'; // par défaut
  }
} 
