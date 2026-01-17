import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/planner_ai_service.dart';
import '../../services/meal_planner_sync_service.dart';
import '../../services/celebration_service.dart';
import '../../services/translations.dart';

/// Bottom sheet pour valider un repas planifié
/// Design inspiré du bloc ingrédients des recettes
class MealValidationBottomSheet extends StatefulWidget {
  final PlannedActivity activity;
  final PlannedMealData mealData;
  final String langCode;
  final VoidCallback onValidated;

  const MealValidationBottomSheet({
    super.key,
    required this.activity,
    required this.mealData,
    required this.langCode,
    required this.onValidated,
  });

  static Future<void> show({
    required BuildContext context,
    required PlannedActivity activity,
    required PlannedMealData mealData,
    required String langCode,
    required VoidCallback onValidated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MealValidationBottomSheet(
        activity: activity,
        mealData: mealData,
        langCode: langCode,
        onValidated: onValidated,
      ),
    );
  }

  @override
  State<MealValidationBottomSheet> createState() => _MealValidationBottomSheetState();
}

class _MealValidationBottomSheetState extends State<MealValidationBottomSheet> {
  late List<_IngredientItem> _ingredients;
  late Map<int, double> _modifiedQuantities; // index -> new quantity
  int _originalIngredientCount = 0; // Pour détecter les ajouts
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isAddingIngredient = false;

  // Pour ajouter un nouvel ingrédient
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newQuantityController = TextEditingController();
  String _selectedUnit = 'g';

  final List<String> _units = ['g', 'kg', 'ml', 'cl', 'l', 'c. à s.', 'c. à c.', 'pièce', 'tranche', 'portion'];

  @override
  void initState() {
    super.initState();
    _parseIngredients();
    _originalIngredientCount = _ingredients.length;
    _modifiedQuantities = {};
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newQuantityController.dispose();
    super.dispose();
  }

  void _parseIngredients() {
    final sections = _parseDescription(widget.mealData.displayDescription);
    final ingredientsText = sections['ingredients'] ?? '';

    _ingredients = [];

    final lines = ingredientsText.split('\n');
    for (final line in lines) {
      final cleaned = line.trim().replaceFirst(RegExp(r'^[-•]\s*'), '');
      if (cleaned.isNotEmpty) {
        _ingredients.add(_IngredientItem.parse(cleaned));
      }
    }
  }

  Map<String, String> _parseDescription(String description) {
    final result = <String, String>{
      'description': '',
      'ingredients': '',
      'recipe': '',
      'tip': '',
    };

    if (description.isEmpty) return result;

    final parts = description.split('---');

    if (parts.isNotEmpty) {
      result['description'] = parts[0].trim();
    }

    for (int i = 1; i < parts.length; i++) {
      final part = parts[i].trim();

      if (part.toUpperCase().startsWith('INGRÉDIENTS:') ||
          part.toUpperCase().startsWith('INGREDIENTS:') ||
          part.toUpperCase().startsWith('ZUTATEN:')) {
        result['ingredients'] = part.replaceFirst(
          RegExp(r'^INGRÉDIENTS:\s*|^INGREDIENTS:\s*|^ZUTATEN:\s*', caseSensitive: false),
          ''
        ).trim();
      } else if (part.toUpperCase().startsWith('RECETTE:') ||
                 part.toUpperCase().startsWith('RECIPE:') ||
                 part.toUpperCase().startsWith('REZEPT:')) {
        result['recipe'] = part.replaceFirst(
          RegExp(r'^RECETTE:\s*|^RECIPE:\s*|^REZEPT:\s*', caseSensitive: false),
          ''
        ).trim();
      } else if (part.toUpperCase().startsWith('ASTUCE:') ||
                 part.toUpperCase().startsWith('TIP:') ||
                 part.toUpperCase().startsWith('TIPP:')) {
        result['tip'] = part.replaceFirst(
          RegExp(r'^ASTUCE:\s*|^TIP:\s*|^TIPP:\s*', caseSensitive: false),
          ''
        ).trim();
      }
    }

    return result;
  }

  // Détecte si des changements ont été faits (quantités modifiées OU ingrédients ajoutés)
  bool get _hasChanges => _modifiedQuantities.isNotEmpty || _ingredients.length != _originalIngredientCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Padding(
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

                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.mealData.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section ingrédients (style recette)
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header de la section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'section_ingredients'.tr(widget.langCode),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              Icon(
                                _isEditMode ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                size: 20,
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(height: 1, color: const Color(0xFFE5E7EB)),

                        // Liste des ingrédients (scrollable)
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _ingredients.isEmpty
                                ? _buildNoIngredients()
                                : _buildIngredientsList(),
                          ),
                        ),

                        // Actions si en mode édition
                        if (_isEditMode) ...[
                          Container(height: 1, color: const Color(0xFFE5E7EB)),
                          _buildEditActions(),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Boutons
                _buildButtons(),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0B132B)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoIngredients() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'planner_no_ingredients'.tr(widget.langCode),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildIngredientsList() {
    // Couleurs pour différencier les états
    const colorAdded = Color(0xFF22C55E);    // Vert pour ajouté
    const colorModified = Color(0xFF3B82F6); // Bleu pour modifié
    const colorDefault = Color(0xFF64748B);  // Gris pour inchangé
    const colorText = Color(0xFF1A1A1A);     // Noir pour texte normal

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: _ingredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;
        final isAdded = index >= _originalIngredientCount;
        final isModified = !isAdded && _modifiedQuantities.containsKey(index);

        // Quantité à afficher
        final displayQuantity = _modifiedQuantities[index] ?? ingredient.numericQuantity;

        // Couleur selon l'état
        final bulletColor = isAdded ? colorAdded : (isModified ? colorModified : colorDefault);
        final textColor = isAdded ? colorAdded : (isModified ? colorModified : colorText);
        final quantityColor = isAdded ? colorAdded : (isModified ? colorModified : colorDefault);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Bullet point - cercle de couleur différente selon l'état
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: bulletColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Nom
              Expanded(
                child: Text(
                  ingredient.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              // Quantité + unité (ou champ éditable)
              if (_isEditMode)
                _buildEditableQuantity(index, ingredient, displayQuantity)
              else
                Text(
                  '${_formatQuantity(displayQuantity)} ${_abbreviateUnit(ingredient.unit)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: quantityColor,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Abrège les unités longues pour l'affichage
  String _abbreviateUnit(String unit) {
    final abbreviations = {
      'cuillère': 'c.',
      'cuillères': 'c.',
      'c. à s.': 'c.s.',
      'c. à c.': 'c.c.',
      'c. à soupe': 'c.s.',
      'c. à café': 'c.c.',
      'gramme': 'g',
      'grammes': 'g',
      'kilogramme': 'kg',
      'kilogrammes': 'kg',
      'millilitre': 'ml',
      'millilitres': 'ml',
      'centilitre': 'cl',
      'centilitres': 'cl',
      'litre': 'l',
      'litres': 'l',
      'pièce': 'pce',
      'pièces': 'pce',
      'tranche': 'tr.',
      'tranches': 'tr.',
      'portion': 'port.',
      'portions': 'port.',
      'gousse': 'gsse',
      'gousses': 'gsse',
    };

    final lower = unit.toLowerCase().trim();
    return abbreviations[lower] ?? unit;
  }

  Widget _buildEditableQuantity(int index, _IngredientItem ingredient, double currentQuantity) {
    final abbreviatedUnit = _abbreviateUnit(ingredient.unit);

    // Largeur fixe totale pour garantir l'alignement
    return SizedBox(
      width: 95, // 50 (input) + 4 (spacing) + 41 (unit)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 50,
            child: TextFormField(
              initialValue: _formatQuantity(currentQuantity),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
              ),
              onChanged: (value) {
                final newQty = double.tryParse(value);
                if (newQty != null && newQty > 0) {
                  setState(() {
                    if (newQty != ingredient.numericQuantity) {
                      _modifiedQuantities[index] = newQty;
                    } else {
                      _modifiedQuantities.remove(index);
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 41,
            child: Text(
              abbreviatedUnit,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isAddingIngredient)
            _buildAddIngredientForm()
          else
            GestureDetector(
              onTap: () => setState(() => _isAddingIngredient = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.plus, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      'planner_add_ingredient'.tr(widget.langCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddIngredientForm() {
    return Column(
      children: [
        // Ligne 1 : Nom de l'ingrédient
        TextField(
          controller: _newNameController,
          decoration: InputDecoration(
            hintText: 'planner_ingredient_name_hint'.tr(widget.langCode),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0B132B)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Ligne 2 : Quantité + Unité
        Row(
          children: [
            // Quantité
            Expanded(
              flex: 2,
              child: TextField(
                controller: _newQuantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'planner_quantity_hint'.tr(widget.langCode),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0B132B)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Dropdown unité
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    isExpanded: true,
                    items: _units.map((unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit, style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnit = value);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Boutons Annuler / Ajouter
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _newNameController.clear();
                  _newQuantityController.clear();
                  setState(() => _isAddingIngredient = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'planner_cancel'.tr(widget.langCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _addNewIngredient,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'planner_add'.tr(widget.langCode),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addNewIngredient() {
    final name = _newNameController.text.trim();
    final quantity = double.tryParse(_newQuantityController.text);

    if (name.isEmpty || quantity == null || quantity <= 0) return;

    setState(() {
      _ingredients.add(_IngredientItem(
        name: name,
        numericQuantity: quantity,
        unit: _selectedUnit,
      ));
      _newNameController.clear();
      _newQuantityController.clear();
      _isAddingIngredient = false;
    });
  }

  Widget _buildButtons() {
    if (_isEditMode) {
      return GestureDetector(
        onTap: _hasChanges ? _validateWithRecalculation : _validateMeal,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _hasChanges
                  ? 'planner_recalculate_validate'.tr(widget.langCode)
                  : 'planner_validate'.tr(widget.langCode),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        // Modifier
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isEditMode = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0B132B)),
              ),
              child: Center(
                child: Text(
                  'planner_edit'.tr(widget.langCode),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Valider
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _validateMeal,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'planner_validate'.tr(widget.langCode),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatQuantity(double qty) {
    return qty.truncateToDouble() == qty ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }

  Future<void> _validateMeal() async {
    setState(() => _isLoading = true);

    try {
      final foodEntryId = await MealPlannerSyncService.validateMealWithMacros(
        widget.activity,
        calories: widget.mealData.calories ?? 0,
        proteins: widget.mealData.proteins ?? 0.0,
        carbs: widget.mealData.carbs ?? 0.0,
        fats: widget.mealData.fats ?? 0.0,
      );

      if (foodEntryId == null) {
        throw Exception('Failed to validate meal - no food entry created');
      }

      // Afficher le popup de célébration après fermeture du bottom sheet
      final mealName = widget.mealData.displayName;
      CelebrationService().celebrateFoodEntryGlobal(
        foodName: mealName,
      );

      if (mounted) {
        widget.onValidated();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error validating meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('planner_validation_error'.tr(widget.langCode)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateWithRecalculation() async {
    setState(() => _isLoading = true);

    try {
      // Construire la liste des ingrédients avec les nouvelles quantités
      final updatedIngredients = <String>[];
      for (int i = 0; i < _ingredients.length; i++) {
        final ing = _ingredients[i];
        final qty = _modifiedQuantities[i] ?? ing.numericQuantity;
        updatedIngredients.add('${_formatQuantity(qty)}${ing.unit} ${ing.name}');
      }

      final ingredientsList = updatedIngredients.join(', ');
      final dishName = widget.mealData.displayName;

      // Recalculate via AI - retourne les données complètes
      final result = await PlannerAIService.recalculateMealMacros(
        dishName: dishName,
        ingredients: ingredientsList,
        langCode: widget.langCode,
        originalDescription: widget.mealData.displayDescription,
      );

      if (result != null && result['success'] == true) {
        // Valider avec les nouvelles données complètes (nom, description, macros)
        final foodEntryId = await MealPlannerSyncService.validateMealWithMacros(
          widget.activity,
          calories: result['calories'] as int,
          proteins: (result['proteins'] as num).toDouble(),
          carbs: (result['carbs'] as num).toDouble(),
          fats: (result['fats'] as num).toDouble(),
          dishName: result['dish_name'] as String?,
          dishDescription: result['dish_description'] as String?,
        );

        if (foodEntryId == null) {
          throw Exception('Failed to validate meal - no food entry created');
        }

        // Afficher le popup de célébration après fermeture du bottom sheet
        final mealName = result['dish_name'] as String? ?? widget.mealData.displayName;
        CelebrationService().celebrateFoodEntryGlobal(
          foodName: mealName,
        );

        if (mounted) {
          widget.onValidated();
          Navigator.pop(context);
        }
      } else {
        throw Exception(result?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint('❌ Error recalculating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('planner_recalculation_error'.tr(widget.langCode)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

}

/// Classe pour représenter un ingrédient
class _IngredientItem {
  final String name;
  final double numericQuantity;
  final String unit;

  const _IngredientItem({
    required this.name,
    required this.numericQuantity,
    required this.unit,
  });

  factory _IngredientItem.parse(String line) {
    final trimmed = line.trim();

    // Liste des unités connues (ordonnées par longueur décroissante pour éviter les matches partiels)
    final knownUnits = [
      // Unités longues en premier
      'cuillères à soupe', 'cuillère à soupe', 'cuillères à café', 'cuillère à café',
      'c. à soupe', 'c. à café', 'c. à s.', 'c. à c.',
      'c.à.s.', 'c.à.c.', 'cas', 'cac',
      // Unités moyennes
      'gousses', 'gousse', 'pincées', 'pincée',
      'tranches', 'tranche', 'portions', 'portion',
      'pièces', 'pièce', 'cuillères', 'cuillère',
      'tasses', 'tasse', 'verres', 'verre',
      'poignées', 'poignée', 'filets', 'filet',
      // Unités courtes
      'kg', 'ml', 'cl', 'g', 'l',
    ];

    // Construire le pattern d'unités
    final unitPattern = knownUnits.map((u) => RegExp.escape(u)).join('|');

    // Regex pour extraire quantité + unité + nom
    // Gère aussi les prépositions "de", "d'" après l'unité
    final regex = RegExp(
      r"^([\d.,/½¼¾]+)\s*(" + unitPattern + r")?\s*(?:de\s+|d['''])?(.+)$",
      caseSensitive: false,
    );

    final match = regex.firstMatch(trimmed);
    if (match != null) {
      final qtyStr = match.group(1)?.replaceAll(',', '.') ?? '1';
      var qty = double.tryParse(qtyStr) ?? 1.0;

      // Handle fractions
      if (qtyStr.contains('/')) {
        final parts = qtyStr.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]) ?? 1;
          final den = double.tryParse(parts[1]) ?? 1;
          qty = num / den;
        }
      } else if (qtyStr.contains('½')) {
        qty = 0.5;
      } else if (qtyStr.contains('¼')) {
        qty = 0.25;
      } else if (qtyStr.contains('¾')) {
        qty = 0.75;
      }

      // Normaliser l'unité
      var unit = match.group(2)?.trim() ?? '';
      unit = _normalizeUnit(unit);

      return _IngredientItem(
        numericQuantity: qty,
        unit: unit,
        name: match.group(3)?.trim() ?? trimmed,
      );
    }

    return _IngredientItem(numericQuantity: 1, unit: '', name: trimmed);
  }

  /// Normalise les différentes écritures d'unités
  static String _normalizeUnit(String unit) {
    final lower = unit.toLowerCase();

    // Cuillères à soupe
    if (lower.contains('soupe') || lower == 'cas' || lower == 'c.à.s.' || lower == 'c. à s.') {
      return 'c. à s.';
    }
    // Cuillères à café
    if (lower.contains('café') || lower == 'cac' || lower == 'c.à.c.' || lower == 'c. à c.') {
      return 'c. à c.';
    }
    // Cuillères génériques
    if (lower.startsWith('cuillère')) {
      return 'c.';
    }
    // Gousses
    if (lower.startsWith('gousse')) {
      return 'gousse';
    }
    // Pincées
    if (lower.startsWith('pincée')) {
      return 'pincée';
    }
    // Tranches
    if (lower.startsWith('tranche')) {
      return 'tranche';
    }
    // Portions
    if (lower.startsWith('portion')) {
      return 'portion';
    }
    // Pièces
    if (lower.startsWith('pièce')) {
      return 'pièce';
    }

    return unit;
  }

  @override
  String toString() => '${numericQuantity.toStringAsFixed(numericQuantity.truncateToDouble() == numericQuantity ? 0 : 1)}$unit $name';
}
