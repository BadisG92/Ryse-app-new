import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../components/ui/snackbar_utils.dart';
import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/portions.dart';
import '../services/translations.dart';
import '../components/ui/recipe_models.dart';
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
          .or('name_fr.eq.${widget.recipe.name},name_en.eq.${widget.recipe.name},name_de.eq.${widget.recipe.name}')
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
          .select('id, recipe_id, food_id, quantity, display_order, unite_fr, unite_en, unite_de, food_database!inner(*)')
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
          name: LocalizationService.instance.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']).isEmpty
              ? 'Aliment inconnu'
              : LocalizationService.instance.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']),
          baseQuantity: double.parse(ing['quantity'].toString()),
          unit: LocalizationService.instance.getTextFromColumns(ing['unite_fr'], ing['unite_en'], ing['unite_de']),
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
      backgroundColor: RyzeColors.paper,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildRecipeImage(),
              Transform.translate(
                offset: const Offset(0, -RyzeRadius.lg),
                child: Container(
                  decoration: const BoxDecoration(
                    color: RyzeColors.paper,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
                  ),
                  padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(5.1), context.vw(5.1), context.vw(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRecipeTitle(),
                      if (showMacrosUpdatedMessage) ...[
                        SizedBox(height: context.vw(3.6)),
                        _buildMacrosUpdatedMessage(),
                      ],
                      SizedBox(height: context.vw(5.1)),
                      _buildNutritionSummary(),
                      SizedBox(height: context.vw(5.6)),
                      _buildIngredientSection(),
                      SizedBox(height: context.vw(3.1)),
                      _buildRecipeSteps(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // La sortie, posée sur la photo : sur une image, un disque d'encre
          // se voit toujours, quel que soit le plat.
          Positioned(
            top: MediaQuery.of(context).padding.top + context.vw(2.1),
            left: context.vw(4.1),
            child: Pressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: context.vw(10.8),
                height: context.vw(10.8),
                decoration: BoxDecoration(
                  color: RyzeColors.ink.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: RyzeColors.surf.withValues(alpha: 0.22)),
                ),
                child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.surf),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  /// Une quantité vient d'être changée : les macros ne sont plus celles de la
  /// recette. Une ligne, pas un panneau vert.
  Widget _buildMacrosUpdatedMessage() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Row(
      children: [
        Icon(LucideIcons.check, size: context.vw(3.6), color: RyzeColors.accInk),
        SizedBox(width: context.vw(2.1)),
        Expanded(
          child: Text(
            'recipe_macros_updated'.tr(lang),
            style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.accInk),
          ),
        ),
      ],
    );
  }

  /// La photo tient le haut de l'écran : c'est le seul endroit de l'app où
  /// l'image est le sujet, et elle mérite toute la largeur.
  Widget _buildRecipeImage() {
    return SizedBox(
      height: context.vw(64),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RecipeImageService.buildRecipeImage(
            imageUrl: widget.recipe.image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [RyzeColors.ink.withValues(alpha: 0.42), RyzeColors.ink.withValues(alpha: 0)],
                  stops: const [0, 0.45],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeTitle() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.recipe.name,
          style: RyzeText.display(context, 6.4, weight: FontWeight.w600),
        ),
        SizedBox(height: context.vw(1.5)),
        Text(
          '1 ${'serving'.tr(lang)} · ${widget.recipe.time} ${'recipe_minutes'.tr(lang)}',
          style: RyzeText.body(context, 3.4, color: RyzeColors.mute),
        ),
      ],
    );
  }



  /// Ce que vaut une portion. Même langage que le reste : le chiffre en
  /// grand, les trois macros en rails d'encre.
  Widget _buildNutritionSummary() {
    final lang = LocalizationService.instance.currentLanguageCode;
    final nutrition = _calculateCurrentNutrition();
    final calories = (nutrition['calories'] as double).round();
    final proteins = (nutrition['proteins'] as double).round();
    final carbs = (nutrition['carbs'] as double).round();
    final fats = (nutrition['fats'] as double).round();
    final biggest = [proteins, carbs, fats].reduce((x, y) => x > y ? x : y);

    return Container(
      padding: EdgeInsets.all(context.vw(4.6)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'nutritional_facts_per_serving'.tr(lang),
            style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
          ),
          SizedBox(height: context.vw(1.5)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RollingNumber('$calories', style: RyzeText.display(context, 11.5, weight: FontWeight.w600)),
              SizedBox(width: context.vw(2.1)),
              Text('kcal', style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
            ],
          ),
          SizedBox(height: context.vw(4.6)),
          _RecipeMacro(label: 'proteins'.tr(lang), grams: proteins, total: biggest),
          SizedBox(height: context.vw(2.6)),
          _RecipeMacro(label: 'carbs'.tr(lang), grams: carbs, total: biggest),
          SizedBox(height: context.vw(2.6)),
          _RecipeMacro(label: 'fats'.tr(lang), grams: fats, total: biggest),
        ],
      ),
    );
  }

  Widget _buildIngredientSection() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return _buildExpandableSection(
      title: 'ingredients_title'.tr(lang),
      count: detailedIngredients.isEmpty ? null : '${detailedIngredients.length}',
      isExpanded: isIngredientsExpanded,
      onTap: () => setState(() => isIngredientsExpanded = !isIngredientsExpanded),
      content: _buildIngredientsContent(),
      actions: isIngredientsExpanded ? _buildIngredientActions() : null,
    );
  }

  Widget _buildRecipeSteps() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return _buildExpandableSection(
      title: 'preparation_steps'.tr(lang),
      count: widget.recipe.steps.isEmpty ? null : '${widget.recipe.steps.length}',
      isExpanded: isRecipeExpanded,
      onTap: () => setState(() => isRecipeExpanded = !isRecipeExpanded),
      content: _buildStepsContent(),
    );
  }

  /// Une section qui s'ouvre. Le chevron dit qu'il y a quelque chose dessous ;
  /// le dégradé et son « Toucher pour voir plus… » en italique disaient la
  /// même chose en trois fois plus de place.
  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
    String? count,
    Widget? actions,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(
        children: [
          Pressable(
            onTap: () {
              RyzeFeedback.select();
              onTap();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.6)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                  ),
                  if (count != null) ...[
                    Text(count, style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
                    SizedBox(width: context.vw(2.6)),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: RyzeDurations.tap,
                    curve: RyzeCurves.out,
                    child: Icon(LucideIcons.chevronDown, size: context.vw(4.6), color: RyzeColors.mute),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: RyzeDurations.enter,
            curve: RyzeCurves.out,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1, color: RyzeColors.line),
                      Padding(padding: EdgeInsets.all(context.vw(4.1)), child: content),
                      if (actions != null) ...[
                        const Divider(height: 1, color: RyzeColors.line),
                        Padding(padding: EdgeInsets.all(context.vw(4.1)), child: actions),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }



  Widget _buildIngredientsContent() {
    final lang = LocalizationService.instance.currentLanguageCode;

    if (isLoadingIngredients) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(5.1)),
        child: const Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
      );
    }

    if (detailedIngredients.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(4.1)),
        child: Center(
          child: Text(
            'recipe_no_ingredients'.tr(lang),
            style: RyzeText.body(context, 3.4, color: RyzeColors.mute),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ingredient in detailedIngredients) ...[
          Builder(
            builder: (context) {
              final key = '${ingredient.baseQuantity}${ingredient.unit} - ${ingredient.name}';
              final changed = customizedIngredients.containsKey(key);
              final quantity = changed ? customizedIngredients[key]! : ingredient.quantity;
              final calories = changed
                  ? (ingredient.caloriesPer100g * customizedIngredients[key]! / 100)
                  : ingredient.calories;

              return Padding(
                padding: EdgeInsets.only(bottom: context.vw(2.6)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Un ingrédient dont on a changé la quantité porte un
                    // crayon, pas une autre couleur de texte.
                    Padding(
                      padding: EdgeInsets.only(top: context.vw(1.3)),
                      child: changed
                          ? Icon(LucideIcons.pencil, size: context.vw(3.1), color: RyzeColors.accInk)
                          : Container(
                              width: 4,
                              height: 4,
                              margin: EdgeInsets.symmetric(horizontal: context.vw(0.6)),
                              decoration: const BoxDecoration(color: RyzeColors.mute2, shape: BoxShape.circle),
                            ),
                    ),
                    SizedBox(width: context.vw(2.6)),
                    Expanded(
                      child: Text(ingredient.name, style: RyzeText.body(context, 3.6)),
                    ),
                    SizedBox(width: context.vw(2.6)),
                    Text(
                      '${RyzePortions.format(quantity)}${ingredient.unit} · ${calories.round()} kcal',
                      style: RyzeText.body(context, 3.1, color: changed ? RyzeColors.accInk : RyzeColors.mute),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildIngredientActions() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Pressable(
      onTap: _editIngredients,
      child: Container(
        height: context.vw(12.3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RyzeRadius.sm),
          border: Border.all(color: RyzeColors.idle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.pencil, size: context.vw(4.1), color: RyzeColors.ink),
            SizedBox(width: context.vw(2.1)),
            Text('edit_ingredients'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// Les étapes, numérotées parce qu'elles se suivent vraiment.
  Widget _buildStepsContent() {
    final steps = widget.recipe.steps;
    if (steps.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(4.1)),
        child: Center(
          child: Text(
            'recipe_no_steps'.tr(LocalizationService.instance.currentLanguageCode),
            style: RyzeText.body(context, 3.4, color: RyzeColors.mute),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : context.vw(3.6)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.vw(6.4),
                  height: context.vw(6.4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RyzeColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: RyzeColors.line),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: RyzeText.body(context, 2.9, weight: FontWeight.w700, color: RyzeColors.mute),
                  ),
                ),
                SizedBox(width: context.vw(3.1)),
                Expanded(
                  child: Text(steps[i], style: RyzeText.body(context, 3.6, height: 1.5)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomCTA() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Container(
      padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(3.1), context.vw(5.1), context.vw(3.1)),
      decoration: const BoxDecoration(
        color: RyzeColors.paper,
        border: Border(top: BorderSide(color: RyzeColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Pressable(
          onTap: _handleAddRecipeToMeal,
          child: Container(
            height: context.vw(13.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RyzeColors.ink,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              boxShadow: RyzeShadow.soft,
            ),
            child: Text(
              'add_to_meal'.tr(lang),
              style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
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
      // La recette part d'abord, puis les deux écrans du choix se retirent :
      // le détail, et la liste qui l'a ouvert. Appeler le callback avant les
      // pop laisse au chemin d'écriture un contexte encore vivant.
      final navigator = Navigator.of(context);
      widget.onRecipeSelected!(foodItem);
      if (navigator.canPop()) navigator.pop(); // le détail
      if (navigator.canPop()) navigator.pop(); // la liste
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
          SnackBarUtils.show(context, message: 'error_user_not_authenticated'.tr(LocalizationService.instance.currentLanguageCode));
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

        final lang = LocalizationService.instance.currentLanguageCode;
        String snackText;
        if (lang == 'fr') {
          snackText = '${foodItem.name} ajouté au ${meal.name}';
        } else if (lang == 'de') {
          snackText = '${foodItem.name} zu ${meal.name} hinzugefügt';
        } else {
          snackText = '${foodItem.name} added to ${meal.name}';
        }

        SnackBarUtils.show(context, message: snackText);
      }

    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout au repas existant: $e');
      if (mounted) {
        SnackBarUtils.show(context, message: 'error_database_add_failed'.tr(LocalizationService.instance.currentLanguageCode));
      }
    }
  }

  Future<void> _addRecipeToNewMeal(nutrition_models.FoodItem foodItem, String mealType) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          SnackBarUtils.show(context, message: 'error_user_not_authenticated'.tr(LocalizationService.instance.currentLanguageCode));
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

        final lang = LocalizationService.instance.currentLanguageCode;
        String snackText;
        if (lang == 'fr') {
          snackText = '${foodItem.name} ajouté au nouveau $mealType';
        } else if (lang == 'de') {
          snackText = '${foodItem.name} zu neuem $mealType hinzugefügt';
        } else {
          snackText = '${foodItem.name} added to new $mealType';
        }

        SnackBarUtils.show(context, message: snackText);
      }

    } catch (e) {
      debugPrint('❌ Erreur lors de la création du nouveau repas: $e');
      if (mounted) {
        SnackBarUtils.show(context, message: 'error_database_add_failed'.tr(LocalizationService.instance.currentLanguageCode));
      }
    }
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
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);

    return Scaffold(
      backgroundColor: RyzeColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, context.vw(3.1)),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(9.7),
                      height: context.vw(9.7),
                      decoration: BoxDecoration(
                        color: RyzeColors.surf,
                        shape: BoxShape.circle,
                        border: Border.all(color: RyzeColors.line),
                      ),
                      child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.ink),
                    ),
                  ),
                  SizedBox(width: context.vw(3.6)),
                  Expanded(
                    child: Text(
                      'edit_ingredients'.tr(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 4.6, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(6)),
                itemCount: widget.detailedIngredients.length,
                separatorBuilder: (_, __) => SizedBox(height: context.vw(2.1)),
                itemBuilder: (context, index) {
                  final ingredient = widget.detailedIngredients[index];
                  final key = '${ingredient.baseQuantity}${ingredient.unit} - ${ingredient.name}';
                  final quantity = tempCustomizedIngredients[key] ?? ingredient.baseQuantity;
                  final calories = (ingredient.calories * quantity / ingredient.baseQuantity).round();
                  return _buildIngredientCard(
                    key,
                    ingredient.name,
                    calories,
                    '${ingredient.baseQuantity}${ingredient.unit}',
                    quantity,
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(gutter, context.vw(3.1), gutter, context.vw(4.1)),
              decoration: const BoxDecoration(
                color: RyzeColors.paper,
                border: Border(top: BorderSide(color: RyzeColors.line)),
              ),
              child: Pressable(
                onTap: () {
                  RyzeFeedback.confirm();
                  widget.onIngredientsUpdated(tempCustomizedIngredients);
                  Navigator.pop(context);
                },
                child: Container(
                  height: context.vw(13.3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RyzeColors.ink,
                    borderRadius: BorderRadius.circular(RyzeRadius.sm),
                    boxShadow: RyzeShadow.soft,
                  ),
                  child: Text(
                    'done'.tr(lang),
                    style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Un ingrédient : ce qu'il pèse maintenant, ce qu'il pesait dans la recette
  /// si on l'a changé, et ses calories. Toute la ligne se tape.
  Widget _buildIngredientCard(String key, String name, int calories, String original, double quantity) {
    final changed = tempCustomizedIngredients.containsKey(key);
    final unit = _getIngredientUnit(key);

    return Pressable(
      onTap: () {
        RyzeFeedback.select();
        _editIngredient(key, name, calories, original, quantity);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: changed ? RyzeColors.ink : RyzeColors.line, width: changed ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                  SizedBox(height: context.vw(0.5)),
                  Row(
                    children: [
                      Text(
                        '${RyzePortions.format(quantity)}$unit',
                        style: RyzeText.body(context, 3.1, weight: changed ? FontWeight.w600 : FontWeight.w400, color: changed ? RyzeColors.accInk : RyzeColors.mute),
                      ),
                      if (changed) ...[
                        Text(' · ', style: RyzeText.body(context, 3.1, color: RyzeColors.mute2)),
                        Text(
                          original,
                          style: RyzeText.body(context, 3.1, color: RyzeColors.mute2).copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: context.vw(2.6)),
            Text.rich(
              TextSpan(
                style: RyzeText.body(context, 3.6, weight: FontWeight.w600).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(text: '$calories'),
                  TextSpan(text: ' kcal', style: RyzeText.body(context, 3.0, color: RyzeColors.mute)),
                ],
              ),
            ),
            SizedBox(width: context.vw(1.5)),
            const Icon(Icons.chevron_right_rounded, size: 20, color: RyzeColors.mute2),
          ],
        ),
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

        RyzeFeedback.confirm();
      },
    );
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

/// Une macro d'une portion de recette : son nom, son rail en encre, ses
/// grammes. La proportion suffit, il n'y a pas d'objectif à atteindre ici.
class _RecipeMacro extends StatelessWidget {
  const _RecipeMacro({required this.label, required this.grams, required this.total});

  final String label;
  final int grams;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: context.vw(21),
          child: Text(label, style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: RyzeColors.mute)),
        ),
        Expanded(
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: total == 0 ? 0 : (grams / total).clamp(0.0, 1.0),
                  child: Container(decoration: BoxDecoration(color: RyzeColors.ink, borderRadius: BorderRadius.circular(3))),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.vw(3.1)),
        SizedBox(
          width: context.vw(13),
          child: Text(
            '$grams g',
            textAlign: TextAlign.right,
            style: RyzeText.body(context, 3.3, weight: FontWeight.w600).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
