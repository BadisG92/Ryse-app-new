import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'select_recipe_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailsScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  double currentPortions = 1.0;
  bool isCustomized = false;
  bool showMacrosUpdatedMessage = false;
  Map<String, double> customizedIngredients = {};

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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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
            
            // Message des macros mises à jour
            if (showMacrosUpdatedMessage)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.check,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Macros mises à jour',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo de la recette
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
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
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Nom de la recette
                      Text(
                        widget.recipe.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Portions actuelles
                      Text(
                        isCustomized 
                          ? 'Portion personnalisée • ${widget.recipe.time}'
                          : '${currentPortions.toStringAsFixed(currentPortions.truncateToDouble() == currentPortions ? 0 : 1)} portion${currentPortions > 1 ? 's' : ''} • ${widget.recipe.time}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Bilan calorique pour une portion
                      Container(
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
                      
                      const SizedBox(height: 20),
                      
                      // Liste des ingrédients
                      const Text(
                        'Ingrédients',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Liste des ingrédients en format liste
                      ...widget.recipe.ingredients.asMap().entries.map((entry) {
                        final index = entry.key;
                        final ingredient = entry.value;
                        final parts = ingredient.split(' - ');
                        final name = parts[0];
                        final originalQuantity = parts.length > 1 ? parts[1] : '100g';
                        final estimatedCalories = (caloriesPerPortion / widget.recipe.ingredients.length);
                        
                        // Utiliser la quantité personnalisée si elle existe, sinon la quantité proportionnelle
                        final currentQuantity = customizedIngredients.containsKey(ingredient)
                          ? customizedIngredients[ingredient]!
                          : double.tryParse(originalQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0;
                        
                        final adjustedQuantity = isCustomized && customizedIngredients.containsKey(ingredient)
                          ? currentQuantity
                          : currentQuantity * currentPortions;
                        
                        final adjustedCalories = isCustomized && customizedIngredients.containsKey(ingredient)
                          ? (estimatedCalories * currentQuantity / (double.tryParse(originalQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0))
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
                                '${adjustedQuantity.toStringAsFixed(adjustedQuantity.truncateToDouble() == adjustedQuantity ? 0 : 1)}${_getQuantityUnit(originalQuantity)} • ${adjustedCalories.round()} kcal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Boutons d'action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Modifier la portion
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: _showPortionDialog,
                      icon: const Icon(
                        LucideIcons.sliders,
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
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: _editIngredients,
                      icon: const Icon(
                        LucideIcons.edit,
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
                  
                  // Ajouter au repas
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Retour à la liste des recettes
                        Navigator.pop(context); // Retour au journal
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Recette "${widget.recipe.name}" ajoutée au repas'),
                            backgroundColor: const Color(0xFF0B132B),
                          ),
                        );
                      },
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  String _getQuantityUnit(String quantity) {
    if (quantity.contains('ml')) return 'ml';
    if (quantity.contains('g')) return 'g';
    if (quantity.contains('tasse')) return ' tasse(s)';
    if (quantity.contains('cuillère')) return ' cuillère(s)';
    return 'g'; // par défaut
  }
}

// Nouvel écran pour modifier les ingrédients individuellement
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
          final name = parts[0];
          final originalQuantity = parts.length > 1 ? parts[1] : '100g';
          final estimatedCalories = (widget.recipe.calories / widget.recipe.portions / widget.recipe.ingredients.length).round();
          
          final currentQuantity = tempCustomizedIngredients.containsKey(ingredient)
            ? tempCustomizedIngredients[ingredient]!
            : (double.tryParse(originalQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0) * widget.currentPortions;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIngredientCard(ingredient, name, estimatedCalories, originalQuantity, currentQuantity),
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
                LucideIcons.edit,
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
    final quantityController = TextEditingController(
      text: currentQuantity.toStringAsFixed(currentQuantity.truncateToDouble() == currentQuantity ? 0 : 1),
    );

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
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final quantity = double.tryParse(quantityController.text) ?? currentQuantity;
              final originalQty = double.tryParse(originalQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100.0;
              final calories = (baseCalories * quantity / originalQty).round();
              
              // Calcul des macronutriments (valeurs approximatives basées sur les calories)
              final protein = (calories * 0.15 / 4); // 15% des calories en protéines
              final carbs = (calories * 0.55 / 4); // 55% des calories en glucides  
              final fat = (calories * 0.30 / 9); // 30% des calories en lipides

              return Column(
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
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Informations nutritionnelles (format standardisé)
                  Container(
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
                      children: [
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
                              '$calories kcal',
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
                              '${protein.toStringAsFixed(1)}g',
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
                              '${carbs.toStringAsFixed(1)}g',
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
                              '${fat.toStringAsFixed(1)}g',
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
                  
                  const SizedBox(height: 20),
                  
                  // Quantité (boîte séparée)
                  Container(
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
                          'Quantité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: quantityController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getQuantityUnit(originalQuantity),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Color(0xFF0B132B),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0B132B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              tempCustomizedIngredients[ingredient] = quantity;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B132B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirmer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
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