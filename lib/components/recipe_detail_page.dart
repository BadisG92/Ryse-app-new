import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ui/recipe_models.dart';
import '../services/recipe_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  bool _isIngredientsExpanded = false;
  bool _isStepsExpanded = false;
  RecipeDetailModel? _recipeModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetail();
  }

  Future<void> _loadRecipeDetail() async {
    try {
      // Récupérer toutes les recettes et trouver celle qui correspond
      final allRecipes = await RecipeService.getAllRecipes();
      final matchingRecipe = allRecipes.firstWhere(
        (r) => r.name == widget.recipe.name,
        orElse: () => widget.recipe,
      );
      
      // Pour l'instant, créer un modèle simple avec les données existantes
      setState(() {
        _recipeModel = RecipeDetailModel(
          baseRecipe: matchingRecipe,
          ingredients: [], // Sera rempli plus tard avec les vrais ingrédients
          currentPortions: matchingRecipe.servings,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement du détail: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.recipe.name,
            style: const TextStyle(
              color: Color(0xFF0B132B),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recipeModel == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.recipe.name,
            style: const TextStyle(
              color: Color(0xFF0B132B),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: Text('Erreur lors du chargement de la recette'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _recipeModel!.baseRecipe.name,
          style: const TextStyle(
            color: Color(0xFF0B132B),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Contenu principal scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image de la recette
                  _buildRecipeImage(),
                  
                  // Contenu principal avec padding
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom de la recette
                        _buildRecipeTitle(),
                        
                        const SizedBox(height: 16),
                        
                        // Résumé nutritionnel (TOUJOURS pour 1 portion)
                        _buildNutritionalSummary(),
                        
                        const SizedBox(height: 24),
                        
                        // Section Ingrédients (avec quantités pour currentPortions)
                        _buildIngredientsSection(),
                        
                        const SizedBox(height: 16),
                        
                        // Section Étapes de préparation
                        _buildRecipeStepsSection(),
                        
                        // Espace pour éviter que le contenu soit caché par le bouton
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bouton fixe en bas
          _buildBottomCTA(),
        ],
      ),
    );
  }

  Widget _buildRecipeImage() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        image: DecorationImage(
          image: NetworkImage(_recipeModel!.baseRecipe.image),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Fallback si l'image ne charge pas
          },
        ),
      ),
      child: _recipeModel!.baseRecipe.image.contains('placeholder')
          ? const Center(
              child: Icon(
                LucideIcons.image,
                size: 48,
                color: Color(0xFF888888),
              ),
            )
          : null,
    );
  }

  Widget _buildRecipeTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _recipeModel!.baseRecipe.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              LucideIcons.clock,
              size: 16,
              color: Color(0xFF888888),
            ),
            const SizedBox(width: 4),
            Text(
              _recipeModel!.baseRecipe.duration,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              LucideIcons.users,
              size: 16,
              color: Color(0xFF888888),
            ),
            const SizedBox(width: 4),
            Text(
              '${_recipeModel!.currentPortions} ${_recipeModel!.currentPortions > 1 ? 'portions' : 'portion'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionalSummary() {
    // TOUJOURS afficher les valeurs pour 1 portion
    final nutrition = _recipeModel!.nutritionPer1Portion;
    
    return Row(
      children: [
        _buildNutritionChip(
          '${nutrition['calories']} kcal',
          const Color(0xFF10B981),
          LucideIcons.zap,
        ),
        const SizedBox(width: 8),
        _buildNutritionChip(
          '${nutrition['proteins']}g protéines',
          const Color(0xFF3B82F6),
          LucideIcons.dumbbell,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNutritionChip(
            '${nutrition['carbs']}g glucides',
            const Color(0xFFF59E0B),
            LucideIcons.wheat,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header cliquable
          InkWell(
            onTap: () {
              setState(() {
                _isIngredientsExpanded = !_isIngredientsExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.shoppingCart,
                    size: 20,
                    color: Color(0xFF0B132B),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ingrédients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Icon(
                    _isIngredientsExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 20,
                    color: const Color(0xFF888888),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu des ingrédients
          if (_isIngredientsExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildExpandedIngredients(),
          ] else
            _buildCollapsedIngredients(),
        ],
      ),
    );
  }

  Widget _buildExpandedIngredients() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Liste des ingrédients (utiliser les données de base en attendant)
          ..._recipeModel!.baseRecipe.ingredients.map((ingredient) => 
            _buildIngredientItem(ingredient)
          ).toList(),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPortionDialog(),
                  icon: const Icon(LucideIcons.users, size: 16),
                  label: Text('${_recipeModel!.currentPortions} portions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter modifier les aliments
                  },
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Modifier aliments'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedIngredients() {
    return Container(
      height: 120,
      child: Stack(
        children: [
          // Liste tronquée des ingrédients
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _recipeModel!.baseRecipe.ingredients
                  .take(3)
                  .map((ingredient) => _buildIngredientItem(ingredient))
                  .toList(),
            ),
          ),
          
          // Gradient de masquage
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(String ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circle,
            size: 8,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeStepsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header cliquable
          InkWell(
            onTap: () {
              setState(() {
                _isStepsExpanded = !_isStepsExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.chefHat,
                    size: 20,
                    color: Color(0xFF0B132B),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Recette',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Icon(
                    _isStepsExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 20,
                    color: const Color(0xFF888888),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu des étapes
          if (_isStepsExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildExpandedSteps(),
          ] else
            _buildCollapsedSteps(),
        ],
      ),
    );
  }

  Widget _buildExpandedSteps() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _recipeModel!.baseRecipe.steps
            .map((step) => _buildStepItem(step))
            .toList(),
      ),
    );
  }

  Widget _buildCollapsedSteps() {
    return Container(
      height: 80,
      child: Stack(
        children: [
          // Premières étapes tronquées
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _recipeModel!.baseRecipe.steps
                  .take(2)
                  .map((step) => _buildStepItem(step))
                  .toList(),
            ),
          ),
          
          // Gradient de masquage
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step) {
    final stepIndex = _recipeModel!.baseRecipe.steps.indexOf(step) + 1;
    
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
                '$stepIndex',
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
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _showAddToMealBottomSheet();
            },
            child: const Text(
              'Ajouter au repas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToMealBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ajouter au repas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            
            // Contenu placeholder
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.utensils,
                      size: 48,
                      color: Color(0xFF888888),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Sélection du repas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cette fonctionnalité sera implémentée',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPortionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nombre de portions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Portions actuelles : ${_recipeModel!.currentPortions}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 6, 8].map((portions) => 
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _recipeModel!.updatePortions(portions);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _recipeModel!.currentPortions == portions 
                        ? const Color(0xFF0B132B) 
                        : Colors.grey[200],
                    foregroundColor: _recipeModel!.currentPortions == portions 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  child: Text('$portions'),
                ),
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
} 
