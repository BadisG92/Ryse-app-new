import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../components/ui/recipe_models.dart';
import '../components/ui/global_state_header.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart' as nutrition_models;
import '../config/supabase_config.dart';
import '../services/auth_service.dart';
import '../services/food_entries_service.dart';
import '../services/recipe_image_service.dart';

// Modèle pour un ingrédient détaillé avec ses valeurs nutritionnelles
class DetailedIngredient {
  final String id;
  final String name;
  final double baseQuantity; // Quantité pour 1 portion
  final String unit;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;

  DetailedIngredient({
    required this.id,
    required this.name,
    required this.baseQuantity,
    required this.unit,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
  });

  // Calculer les valeurs pour 1 portion (normalisé)
  double get quantity => baseQuantity;
  double get calories => (caloriesPer100g * quantity) / 100;
  double get proteins => (proteinsPer100g * quantity) / 100;
  double get carbs => (carbsPer100g * quantity) / 100;
  double get fats => (fatsPer100g * quantity) / 100;
}

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isFromDashboard;
  final Function(nutrition_models.FoodItem)? onRecipeSelected; // Callback pour ajouter au journal

  const RecipeDetailsScreen({
    super.key, 
    required this.recipe,
    this.isFromDashboard = false,
    this.onRecipeSelected,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool isCustomized = false;
  bool showMacrosUpdatedMessage = false;
  Map<String, double> customizedIngredients = {};
  
  bool isIngredientsExpanded = false;
  bool isRecipeExpanded = false;
  
  // Liste des ingrédients détaillés
  List<DetailedIngredient> detailedIngredients = [];
  bool isLoadingIngredients = true;

  @override
  void initState() {
    super.initState();
    _loadDetailedIngredients();
  }

  // Stockage de l'ID réel de la recette depuis Supabase
  String? _realRecipeId;

  // Charger les ingrédients détaillés depuis la base de données
  Future<void> _loadDetailedIngredients() async {
    try {
      setState(() => isLoadingIngredients = true);
      
      // Récupérer l'ID de la recette depuis le hash (on va chercher avec le nom)
      final recipesResponse = await SupabaseConfig.client
          .from('recipes_database')
          .select('id')
          .or('name_fr.eq.${widget.recipe.name},name_en.eq.${widget.recipe.name}')
          .limit(1);
      
      if (recipesResponse.isEmpty) {
        debugPrint('Recette non trouvée: ${widget.recipe.name}');
        setState(() => isLoadingIngredients = false);
        return;
      }
      
      final recipeId = recipesResponse.first['id']?.toString();
      _realRecipeId = recipeId; // Stocker l'ID réel
      
      if (recipeId == null) {
        debugPrint('ID de recette null pour: ${widget.recipe.name}');
        setState(() => isLoadingIngredients = false);
        return;
      }
      
      // Récupérer les ingrédients avec les données nutritionnelles
      final ingredientsResponse = await SupabaseConfig.client
          .from('recipe_ingredient_database')
          .select('id, recipe_id, food_id, quantity, display_order, unite_fr, unite_en, food_database!inner(*)')
          .eq('recipe_id', recipeId)
          .order('display_order');

      List<DetailedIngredient> ingredients = [];
      for (var ing in ingredientsResponse) {
        // Convertir les ID entiers en string
        ing['id'] = ing['id']?.toString();
        ing['recipe_id'] = ing['recipe_id']?.toString();
        ing['food_id'] = ing['food_id']?.toString();
        
        final food = ing['food_database'];
        if (food != null) {
          // Convertir l'ID de food_database aussi
          food['id'] = food['id']?.toString();
        }
        
        ingredients.add(DetailedIngredient(
          id: ing['id'].toString(),
          name: LocalizationService.instance.getTextFromColumns(food['name_fr'], food['name_en']).isEmpty 
              ? 'Aliment inconnu' 
              : LocalizationService.instance.getTextFromColumns(food['name_fr'], food['name_en']),
          baseQuantity: double.parse(ing['quantity'].toString()),
          unit: LocalizationService.instance.getTextFromColumns(ing['unite_fr'], ing['unite_en']) ?? '',
          caloriesPer100g: double.parse((food['calories'] ?? 0).toString()),
          proteinsPer100g: double.parse((food['proteins'] ?? 0).toString()),
          carbsPer100g: double.parse((food['carbs'] ?? 0).toString()),
          fatsPer100g: double.parse((food['fats'] ?? 0).toString()),
        ));
      }

      setState(() {
        detailedIngredients = ingredients;
        isLoadingIngredients = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des ingrédients: $e');
      setState(() => isLoadingIngredients = false);
    }
  }

  // Les valeurs nutritionnelles sont déjà normalisées pour 1 portion dans la base de données

  // Calculer les totaux nutritionnels actuels
  Map<String, dynamic> _calculateCurrentNutrition() {
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    bool hasModifications = false;
    
    for (final ingredient in detailedIngredients) {
      final ingredientKey = '${ingredient.baseQuantity}${ingredient.unit} - ${ingredient.name}';
      
      final displayQuantity = customizedIngredients.containsKey(ingredientKey)
          ? customizedIngredients[ingredientKey]!
          : ingredient.quantity;
      
      if (customizedIngredients.containsKey(ingredientKey)) {
        hasModifications = true;
      }
      
      final ratio = displayQuantity / ingredient.baseQuantity;
      totalCalories += ingredient.calories * ratio;
      totalProteins += ingredient.proteins * ratio;
      totalCarbs += ingredient.carbs * ratio;
      totalFats += ingredient.fats * ratio;
    }
    
    return {
      'calories': totalCalories,
      'proteins': totalProteins,
      'carbs': totalCarbs,
      'fats': totalFats,
      'hasModifications': hasModifications,
    };
  }

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
            Expanded(
              child: Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  locService.currentLanguageCode == 'fr' ? 'Détails de la recette' : 'Recipe details',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
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
      child: Row(
        children: [
          const Icon(
            LucideIcons.check,
            size: 16,
            color: Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          Consumer<LocalizationService>(
            builder: (context, locService, child) => Text(
              locService.currentLanguageCode == 'fr' ? 'Macros mises à jour' : 'Macros updated',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage() {
    return AspectRatio(
      aspectRatio: 16 / 9, // Format 16:9 pour un bel affichage
      child: Container(
        width: double.infinity,
        child: RecipeImageService.buildRecipeImage(
          imageUrl: widget.recipe.image,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
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
            child: Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' 
                  ? '1 portion • ${widget.recipe.time} min'
                  : '1 serving • ${widget.recipe.time} min',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final nutrition = _calculateCurrentNutrition();
    final totalCalories = nutrition['calories'] as double;
    final totalProteins = nutrition['proteins'] as double;
    final totalCarbs = nutrition['carbs'] as double;
    final totalFats = nutrition['fats'] as double;
    final hasModifications = nutrition['hasModifications'] as bool;
    
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
            Row(
          children: [
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Bilan nutritionnel (par portion)' : 'Nutritional facts (per serving)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
                if (hasModifications) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.check,
                    size: 14,
                    color: Color(0xFF1C2951),
                  ),
                ],
              ],
            ),
            if (hasModifications) ...[
              const SizedBox(height: 4),
              const Text(
                'Adapté aux modifications',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1C2951),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
                  '${totalCalories.round()} kcal',
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
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'proteins'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Text(
                  '${totalProteins.toStringAsFixed(1)}g',
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
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'carbs'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Text(
                  '${totalCarbs.toStringAsFixed(1)}g',
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
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'fats'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Text(
                  '${totalFats.toStringAsFixed(1)}g',
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
        title: Provider.of<LocalizationService>(context, listen: false).currentLanguageCode == 'fr' ? 'Ingrédients' : 'Ingredients',
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
        title: 'preparation_steps'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode),
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
                child: Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    locService.currentLanguageCode == 'fr' ? 'Toucher pour voir plus...' : 'Tap to see more...',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF64748B).withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
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
    if (isLoadingIngredients) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (detailedIngredients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Aucun ingrédient trouvé',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detailedIngredients.asMap().entries.map((entry) {
        final ingredient = entry.value;
        final ingredientKey = '${ingredient.baseQuantity}${ingredient.unit} - ${ingredient.name}';
        
        // Utiliser la quantité personnalisée si elle existe, sinon la quantité pour 1 portion
        final displayQuantity = customizedIngredients.containsKey(ingredientKey)
          ? customizedIngredients[ingredientKey]!
          : ingredient.quantity;
        
        final displayCalories = customizedIngredients.containsKey(ingredientKey)
          ? (ingredient.caloriesPer100g * customizedIngredients[ingredientKey]! / 100)
          : ingredient.calories;
        
        final isModified = customizedIngredients.containsKey(ingredientKey);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: isModified 
                  ? const Icon(
                      LucideIcons.check,
                      size: 10,
                      color: Color(0xFF3B82F6),
                    )
                  : Container(
                      width: 4,
                      height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF64748B),
                  shape: BoxShape.circle,
                ),
              ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ingredient.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isModified ? const Color(0xFF3B82F6) : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Text(
                '${displayQuantity.toStringAsFixed(displayQuantity.truncateToDouble() == displayQuantity ? 0 : 1)}${ingredient.unit} • ${displayCalories.round()} kcal',
                style: TextStyle(
                  fontSize: 12,
                  color: isModified ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
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
            label: Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Modifier les aliments' : 'Modify ingredients',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0B132B),
                ),
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
                      child: ElevatedButton(
              onPressed: _handleAddRecipeToMeal,
                            child: Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  widget.isFromDashboard 
                    ? (locService.currentLanguageCode == 'fr' ? 'Ajouter au repas' : 'Add to meal')
                    : (locService.currentLanguageCode == 'fr' ? 'Ajouter à un repas' : 'Add to a meal'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
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



  void _editIngredients() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditIngredientsScreen(
          recipe: widget.recipe,
          detailedIngredients: detailedIngredients,
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

  Future<void> _handleAddRecipeToMeal() async {
    debugPrint('🔵 _handleAddRecipeToMeal appelée');
    debugPrint('🔵 onRecipeSelected: ${widget.onRecipeSelected != null}');
    debugPrint('🔵 isFromDashboard: ${widget.isFromDashboard}');
    
    // Utiliser les valeurs actuelles (avec modifications si applicable)
    final nutrition = _calculateCurrentNutrition();
    final totalCalories = nutrition['calories'] as double;
    final totalProteins = nutrition['proteins'] as double;
    final totalCarbs = nutrition['carbs'] as double;
    final totalFats = nutrition['fats'] as double;
    final hasModifications = nutrition['hasModifications'] as bool;
    
    // Créer un FoodItem basé sur la recette (avec modifications si applicable)
    final foodItem = nutrition_models.FoodItem(
      id: _realRecipeId, // Utiliser l'ID réel de la recette depuis Supabase
      name: widget.recipe.name,
      calories: totalCalories.round(),
      proteins: totalProteins,
      carbs: totalCarbs,
      fats: totalFats,
      portion: '1 portion',
      isRecipe: true, // Marquer comme recette
      hasModifiedMacros: hasModifications, // Utiliser la détection automatique des modifications
    );
    
    debugPrint('🔵 FoodItem créé: ${foodItem.name}, calories: ${foodItem.calories}');
    
    if (widget.onRecipeSelected != null) {
      debugPrint('🔵 Utilisation du callback onRecipeSelected');
      // Si on a un callback (dashboard avec repas présélectionné ou journal), l'utiliser
      Navigator.pop(context); // Ferme RecipeDetailsScreen
      Navigator.pop(context); // Ferme SelectRecipeScreen
      
      // Ajouter la recette via le callback
      widget.onRecipeSelected!(foodItem);
      debugPrint('🔵 Callback appelé avec succès');
    } else {
      // Si on vient de l'onglet recettes ou dashboard sans callback, afficher la sélection de repas
      await _showMealSelectionBottomSheet(foodItem);
    }
  }

  Future<void> _showMealSelectionBottomSheet(nutrition_models.FoodItem foodItem) async {
    // Récupérer les vrais repas du jour depuis la base de données
    final user = AuthService().currentUser;
    List<nutrition_models.Meal> existingMeals = [];
    
    if (user != null) {
      try {
        final meals = await FoodEntriesService.getFoodEntriesForDate(user.id, DateTime.now());
        existingMeals = meals.where((meal) => meal.items.isNotEmpty).toList();
      } catch (e) {
        debugPrint('Erreur lors de la récupération des repas existants: $e');
      }
    }

    if (!mounted) return;

    MealSelectionBottomSheet.show(
      context,
      foodName: foodItem.name,
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) async {
        debugPrint('🍽️ Ajouter ${foodItem.name} au repas ${meal.name}');
        await _addRecipeToExistingMeal(foodItem, meal);
      },
      onCreateNewMeal: () {
        NewMealTypeBottomSheet.show(
          context,
          onMealTypeSelected: (mealType, time) async {
            debugPrint('🆕 Créer un nouveau repas $mealType avec ${foodItem.name}');
            await _addRecipeToNewMeal(foodItem, mealType);
          },
        );
      },
    );
  }

  Future<void> _addRecipeToExistingMeal(nutrition_models.FoodItem foodItem, nutrition_models.Meal meal) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_user_not_authenticated'.tr(LocalizationService.instance.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Ajouter la recette au repas existant
      await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealId: meal.id!, // Utiliser l'ID du repas existant
        foodItem: foodItem,
        mealName: meal.name,
      );

      // Fermer l'écran et afficher confirmation
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${foodItem.name} ajouté au ${meal.name}'),
            backgroundColor: const Color(0xFF0B132B),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout au repas existant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_database_add_failed'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addRecipeToNewMeal(nutrition_models.FoodItem foodItem, String mealType) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_user_not_authenticated'.tr(LocalizationService.instance.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Créer un nouveau repas avec la recette
      // FoodEntriesService.addFoodEntry créera automatiquement le repas s'il n'existe pas
      await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealId: null, // Pas d'ID spécifique, laisse le service générer
        foodItem: foodItem,
        mealName: mealType,
      );

      // Fermer l'écran et afficher confirmation
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${foodItem.name} ajouté au nouveau $mealType'),
            backgroundColor: const Color(0xFF0B132B),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erreur lors de la création du nouveau repas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_database_add_failed'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  final List<DetailedIngredient> detailedIngredients;
  final Map<String, double> customizedIngredients;
  final Function(Map<String, double>) onIngredientsUpdated;

  const EditIngredientsScreen({
    super.key,
    required this.recipe,
    required this.detailedIngredients,
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
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Modifier les aliments' : 'Modify ingredients',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              widget.onIngredientsUpdated(tempCustomizedIngredients);
              Navigator.pop(context);
            },
            child: Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Terminer' : 'Done',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.detailedIngredients.length,
        itemBuilder: (context, index) {
          final ingredient = widget.detailedIngredients[index];
          final ingredientKey = '${ingredient.baseQuantity}${ingredient.unit} - ${ingredient.name}';
          
          final currentQuantity = tempCustomizedIngredients.containsKey(ingredientKey)
            ? tempCustomizedIngredients[ingredientKey]!
            : ingredient.baseQuantity;
            
          // Calculer les nouvelles valeurs nutritionnelles si modifiées
          final ratio = currentQuantity / ingredient.baseQuantity;
          final currentCalories = (ingredient.calories * ratio).round();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIngredientCard(
              ingredientKey, 
              ingredient.name, 
              currentCalories, 
              '${ingredient.baseQuantity}${ingredient.unit}', 
              currentQuantity
            ),
          );
        },
      ),
    );
  }

  Widget _buildIngredientCard(String ingredient, String name, int baseCalories, String originalQuantity, double currentQuantity) {
    final isModified = tempCustomizedIngredients.containsKey(ingredient);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isModified ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isModified ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isModified ? const Color(0xFF3B82F6) : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentQuantity.toStringAsFixed(currentQuantity.truncateToDouble() == currentQuantity ? 0 : 1)} ${_getIngredientUnit(ingredient)} • ${baseCalories} kcal',
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
              child:               Icon(
                LucideIcons.pencil,
                size: 16,
                color: isModified ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editIngredient(String ingredientKey, String name, int baseCalories, String originalQuantity, double currentQuantity) {
    // Trouver l'ingrédient détaillé correspondant pour avoir les vraies valeurs nutritionnelles
    final detailedIngredient = widget.detailedIngredients.firstWhere(
      (ing) => '${ing.baseQuantity}${ing.unit} - ${ing.name}' == ingredientKey,
      orElse: () => widget.detailedIngredients.first,
    );
    
    // Calculer les valeurs nutritionnelles proportionnelles à la nouvelle quantité
    final ratio = currentQuantity / detailedIngredient.baseQuantity;
    final calories = (detailedIngredient.calories * ratio).round();
    final proteins = detailedIngredient.proteins * ratio;
    final carbs = detailedIngredient.carbs * ratio;
    final fats = detailedIngredient.fats * ratio;

    EditableFoodDetailsBottomSheet.show(
      context,
      name: name,
      calories: calories,
      proteins: proteins,
      glucides: carbs,
      lipides: fats,
      quantity: currentQuantity,
      referenceUnit: detailedIngredient.unit, // Utiliser l'unité de l'ingrédient de la recette
      isModified: tempCustomizedIngredients.containsKey(ingredientKey),
      // Utiliser onFoodSaved pour juste enregistrer les modifications sans ajouter au repas
      onFoodSaved: (foodItem) {
        setState(() {
          // Enlever toutes les unités possibles de la portion pour récupérer le nombre
          String portionNumber = foodItem.portion.replaceAll(RegExp(r'[a-zA-Zàâäéèêëïîôùûüÿç\s]+'), '');
          tempCustomizedIngredients[ingredientKey] = double.tryParse(portionNumber) ?? currentQuantity;
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

  // Nouvelle fonction pour récupérer l'unité réelle d'un ingrédient
  String _getIngredientUnit(String ingredientKey) {
    final detailedIngredient = widget.detailedIngredients.firstWhere(
      (ing) => '${ing.baseQuantity}${ing.unit} - ${ing.name}' == ingredientKey,
      orElse: () => widget.detailedIngredients.first,
    );
    return detailedIngredient.unit;
  }
} 
