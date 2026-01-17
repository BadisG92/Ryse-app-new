import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/planner_ai_service.dart';
import '../../services/meal_planner_sync_service.dart';
import '../../services/translations.dart';

/// Page de détail d'un repas planifié (depuis le planner)
/// Permet de voir et modifier les ingrédients
class PlannedMealDetailPage extends StatefulWidget {
  final PlannedActivity activity;
  final PlannedMealData mealData;
  final String langCode;
  final VoidCallback? onMealUpdated;
  final VoidCallback? onMealValidated;
  final bool isPreValidation;

  const PlannedMealDetailPage({
    super.key,
    required this.activity,
    required this.mealData,
    required this.langCode,
    this.onMealUpdated,
    this.onMealValidated,
    this.isPreValidation = false,
  });

  @override
  State<PlannedMealDetailPage> createState() => _PlannedMealDetailPageState();
}

class _PlannedMealDetailPageState extends State<PlannedMealDetailPage> {
  late List<IngredientItem> _ingredients;
  bool _isEditing = false;
  bool _isUpdating = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _parseIngredients();
    // En mode pré-validation, démarrer directement en mode édition
    if (widget.isPreValidation) {
      _isEditing = true;
    }
  }

  void _parseIngredients() {
    final sections = _parseDescription(widget.mealData.displayDescription);
    final ingredientsText = sections['ingredients'] ?? '';

    _ingredients = [];

    // Parser chaque ligne d'ingrédient
    // Format attendu: "- 25g whey" ou "• 200g poulet" ou "200g poulet"
    final lines = ingredientsText.split('\n');
    for (final line in lines) {
      final cleaned = line.trim().replaceFirst(RegExp(r'^[-•]\s*'), '');
      if (cleaned.isNotEmpty) {
        _ingredients.add(IngredientItem.parse(cleaned));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parseDescription(widget.mealData.displayDescription);
    final isValidated = widget.mealData.isValidated;

    final mealTypeKeys = {
      PlannedActivityType.breakfast: 'meal_type_breakfast',
      PlannedActivityType.lunch: 'meal_type_lunch',
      PlannedActivityType.dinner: 'meal_type_dinner',
      PlannedActivityType.snack: 'meal_type_snack',
    };
    final mealTypeName = (mealTypeKeys[widget.activity.activityType] ?? 'meal_type_snack').tr(widget.langCode);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0B132B)),
        ),
        title: Text(
          mealTypeName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
        centerTitle: true,
        actions: [
          // Bouton édition (visible si validé ou en mode pré-validation)
          if ((isValidated || widget.isPreValidation) && !_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(LucideIcons.pencil, color: Color(0xFF0B132B), size: 20),
            ),
          if (_isEditing && !widget.isPreValidation)
            IconButton(
              onPressed: _cancelEditing,
              icon: const Icon(LucideIcons.x, color: Color(0xFF64748B), size: 20),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec nom et icône
                _buildHeader(),

                const SizedBox(height: 20),

                // Macros
                _buildMacrosCard(),

                const SizedBox(height: 24),

                // Description
                if (sections['description']?.isNotEmpty == true) ...[
                  Text(
                    sections['description']!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Ingrédients (éditable si en mode édition)
                if (_ingredients.isNotEmpty || _isEditing) ...[
                  _buildIngredientsSection(),
                  const SizedBox(height: 24),
                ],

                // Recette
                if (sections['recipe']?.isNotEmpty == true) ...[
                  _buildSectionHeader(
                    icon: LucideIcons.chefHat,
                    title: 'section_recipe'.tr(widget.langCode),
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      sections['recipe']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0B132B),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Astuce
                if (sections['tip']?.isNotEmpty == true) ...[
                  _buildSectionHeader(
                    icon: LucideIcons.lightbulb,
                    title: 'section_tip'.tr(widget.langCode),
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sections['tip']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0B132B),
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // AI Reasoning
                if (widget.mealData.aiReasoning?.isNotEmpty == true) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: LucideIcons.sparkle,
                    title: 'section_why_dish'.tr(widget.langCode),
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      widget.mealData.aiReasoning!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0B132B),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                // Espace pour le bouton flottant
                SizedBox(height: (_isEditing && _hasChanges) || widget.isPreValidation ? 100 : 40),
              ],
            ),
          ),

          // Bouton flottant selon le mode
          if (widget.isPreValidation && !_isUpdating)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              child: _hasChanges ? _buildValidateWithChangesButton() : _buildValidateWithoutChangesButton(),
            )
          else if (_isEditing && _hasChanges)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              child: _buildUpdateButton(),
            ),

          // Loading overlay
          if (_isUpdating)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0B132B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.activity.activityType.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            widget.activity.activityType.icon,
            size: 32,
            color: widget.activity.activityType.color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mealData.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B132B),
                ),
              ),
              if (widget.mealData.isValidated) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'meal_status_validated'.tr(widget.langCode),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacrosCard() {
    // Calculer les calories avec la formule standard au lieu d'utiliser la valeur stockée
    final proteins = widget.mealData.proteins ?? 0.0;
    final carbs = widget.mealData.carbs ?? 0.0;
    final fats = widget.mealData.fats ?? 0.0;
    final calculatedCalories = ((proteins * 4) + (carbs * 4) + (fats * 9)).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem('$calculatedCalories', 'kcal', const Color(0xFF0B132B)),
          _buildDivider(),
          _buildMacroItem('${(widget.mealData.proteins ?? 0).toInt()}g', 'proteins'.tr(widget.langCode), const Color(0xFF3B82F6)),
          _buildDivider(),
          _buildMacroItem('${(widget.mealData.carbs ?? 0).toInt()}g', 'carbs'.tr(widget.langCode), const Color(0xFFF59E0B)),
          _buildDivider(),
          _buildMacroItem('${(widget.mealData.fats ?? 0).toInt()}g', 'fats'.tr(widget.langCode), const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader(
              icon: LucideIcons.shoppingBasket,
              title: 'section_ingredients'.tr(widget.langCode),
              color: const Color(0xFF10B981),
            ),
            const Spacer(),
            if (_isEditing)
              TextButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('planner_add'.tr(widget.langCode)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
          ),
          child: _isEditing ? _buildEditableIngredients() : _buildReadOnlyIngredients(),
        ),
      ],
    );
  }

  Widget _buildReadOnlyIngredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _ingredients.map((ingredient) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '• ${ingredient.toString()}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0B132B),
            height: 1.6,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEditableIngredients() {
    return Column(
      children: [
        ..._ingredients.asMap().entries.map((entry) => _buildEditableIngredientRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildEditableIngredientRow(int index, IngredientItem ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Quantité (éditable)
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: ingredient.quantity,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _ingredients[index] = ingredient.copyWith(quantity: value);
                  _hasChanges = true;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          // Nom de l'ingrédient (éditable)
          Expanded(
            child: TextFormField(
              initialValue: ingredient.name,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _ingredients[index] = ingredient.copyWith(name: value);
                  _hasChanges = true;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Bouton supprimer
          GestureDetector(
            onTap: () {
              setState(() {
                _ingredients.removeAt(index);
                _hasChanges = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(IngredientItem(quantity: '', name: ''));
      _hasChanges = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _hasChanges = false;
      _parseIngredients(); // Reset les ingrédients
    });
  }

  Widget _buildUpdateButton() {
    final buttonText = 'planner_update_macros'.tr(widget.langCode);

    return GestureDetector(
      onTap: _isUpdating ? null : _updateMacros,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton "Valider ce repas" (sans modifications)
  Widget _buildValidateWithoutChangesButton() {
    final buttonText = 'planner_validate_meal'.tr(widget.langCode);

    return GestureDetector(
      onTap: _validateMealWithCurrentMacros,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.check, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton "Valider avec ces macros" (après modifications, recalcul IA)
  Widget _buildValidateWithChangesButton() {
    final buttonText = 'planner_recalculate_validate'.tr(widget.langCode);

    return GestureDetector(
      onTap: _validateMealWithRecalculation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Valider le repas avec les macros actuels (sans recalcul)
  Future<void> _validateMealWithCurrentMacros() async {
    setState(() => _isUpdating = true);

    try {
      await MealPlannerSyncService.validateMealWithMacros(
        widget.activity,
        calories: widget.mealData.calories ?? 0,
        proteins: widget.mealData.proteins ?? 0.0,
        carbs: widget.mealData.carbs ?? 0.0,
        fats: widget.mealData.fats ?? 0.0,
      );

      if (mounted) {
        widget.onMealValidated?.call();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('planner_meal_validated'.tr(widget.langCode)),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
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
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  /// Valider le repas après recalcul des macros par l'IA
  Future<void> _validateMealWithRecalculation() async {
    final validIngredients = _ingredients.where((i) => i.name.isNotEmpty).toList();
    if (validIngredients.isEmpty) {
      // Si pas d'ingrédients valides, valider avec les macros actuels
      await _validateMealWithCurrentMacros();
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final ingredientsList = validIngredients.map((i) => i.toString()).join(', ');
      final dishName = widget.mealData.displayName;

      // Recalculer les macros via l'IA
      final result = await PlannerAIService.recalculateMealMacros(
        dishName: dishName,
        ingredients: ingredientsList,
        langCode: widget.langCode,
      );

      if (result != null && result['success'] == true) {
        // Valider le repas avec les nouveaux macros
        await MealPlannerSyncService.validateMealWithMacros(
          widget.activity,
          calories: result['calories'] as int,
          proteins: (result['proteins'] as num).toDouble(),
          carbs: (result['carbs'] as num).toDouble(),
          fats: (result['fats'] as num).toDouble(),
        );

        // Mettre à jour la description avec les nouveaux ingrédients
        await _updateIngredientsList(validIngredients);

        if (mounted) {
          widget.onMealValidated?.call();
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('planner_meal_validated_recalculated'.tr(widget.langCode)),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        throw Exception(result?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint('❌ Error validating meal with recalculation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('planner_recalculation_error'.tr(widget.langCode)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateMacros() async {
    // Filtrer les ingrédients vides
    final validIngredients = _ingredients.where((i) => i.name.isNotEmpty).toList();
    if (validIngredients.isEmpty) return;

    setState(() => _isUpdating = true);

    try {
      // Construire la liste des ingrédients pour l'IA
      final ingredientsList = validIngredients.map((i) => i.toString()).join(', ');
      final dishName = widget.mealData.displayName;

      // Appeler l'IA pour recalculer les macros
      final result = await PlannerAIService.recalculateMealMacros(
        dishName: dishName,
        ingredients: ingredientsList,
        langCode: widget.langCode,
      );

      if (result != null && result['success'] == true) {
        // Mettre à jour le planning et le journal
        await MealPlannerSyncService.updateMealMacros(
          widget.activity,
          calories: result['calories'] as int,
          proteins: (result['proteins'] as num).toDouble(),
          carbs: (result['carbs'] as num).toDouble(),
          fats: (result['fats'] as num).toDouble(),
        );

        // Mettre à jour la description avec les nouveaux ingrédients
        await _updateIngredientsList(validIngredients);

        if (mounted) {
          widget.onMealUpdated?.call();
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('planner_macros_updated'.tr(widget.langCode)),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        throw Exception(result?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint('❌ Error updating macros: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('planner_update_error'.tr(widget.langCode)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateIngredientsList(List<IngredientItem> ingredients) async {
    // Reconstruire la description avec les nouveaux ingrédients
    final sections = _parseDescription(widget.mealData.displayDescription);

    final newIngredientsList = ingredients.map((i) => '- ${i.toString()}').join('\n');

    // Reconstruire la description complète
    final newDescription = StringBuffer();
    if (sections['description']?.isNotEmpty == true) {
      newDescription.write(sections['description']);
    }
    newDescription.write('---INGRÉDIENTS:\n$newIngredientsList');
    if (sections['recipe']?.isNotEmpty == true) {
      newDescription.write('\n---RECETTE:\n${sections['recipe']}');
    }
    if (sections['tip']?.isNotEmpty == true) {
      newDescription.write('\n---ASTUCE: ${sections['tip']}');
    }

    // Mettre à jour dans Supabase via le service
    await MealPlannerSyncService.updateMealDescription(
      widget.activity.id,
      newDescription.toString(),
    );
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

      if (part.toUpperCase().startsWith('INGRÉDIENTS:') || part.toUpperCase().startsWith('INGREDIENTS:') || part.toUpperCase().startsWith('ZUTATEN:')) {
        result['ingredients'] = part.replaceFirst(RegExp(r'^INGRÉDIENTS:\s*|^INGREDIENTS:\s*|^ZUTATEN:\s*', caseSensitive: false), '').trim();
      } else if (part.toUpperCase().startsWith('RECETTE:') || part.toUpperCase().startsWith('RECIPE:') || part.toUpperCase().startsWith('REZEPT:')) {
        result['recipe'] = part.replaceFirst(RegExp(r'^RECETTE:\s*|^RECIPE:\s*|^REZEPT:\s*', caseSensitive: false), '').trim();
      } else if (part.toUpperCase().startsWith('ASTUCE:') || part.toUpperCase().startsWith('TIP:') || part.toUpperCase().startsWith('TIPP:')) {
        result['tip'] = part.replaceFirst(RegExp(r'^ASTUCE:\s*|^TIP:\s*|^TIPP:\s*', caseSensitive: false), '').trim();
      }
    }

    if (result['ingredients']!.isEmpty && result['recipe']!.isEmpty && result['tip']!.isEmpty) {
      result['description'] = description;
    }

    return result;
  }

  Widget _buildMacroItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
      ],
    );
  }
}

/// Représente un ingrédient avec sa quantité
class IngredientItem {
  final String quantity; // Ex: "200g", "2 cuillères", "250ml"
  final String name;     // Ex: "poulet", "huile d'olive", "eau"

  const IngredientItem({
    required this.quantity,
    required this.name,
  });

  /// Parse une ligne d'ingrédient (ex: "200g poulet" ou "2 cuillères huile")
  factory IngredientItem.parse(String line) {
    final trimmed = line.trim();

    // Regex pour extraire la quantité au début
    // Patterns: "200g", "200 g", "2 cuillères", "250ml", "1/2 tasse", etc.
    final quantityRegex = RegExp(r'^([\d.,/½¼¾]+\s*(?:g|kg|ml|l|cl|cuillères?|c\.?\s*à\s*s\.?|c\.?\s*à\s*c\.?|tasses?|portions?|tranches?|pièces?)?)\s*', caseSensitive: false);

    final match = quantityRegex.firstMatch(trimmed);
    if (match != null) {
      return IngredientItem(
        quantity: match.group(1)?.trim() ?? '',
        name: trimmed.substring(match.end).trim(),
      );
    }

    // Si pas de quantité trouvée, tout est le nom
    return IngredientItem(quantity: '', name: trimmed);
  }

  IngredientItem copyWith({String? quantity, String? name}) {
    return IngredientItem(
      quantity: quantity ?? this.quantity,
      name: name ?? this.name,
    );
  }

  @override
  String toString() {
    if (quantity.isEmpty) return name;
    return '$quantity $name'.trim();
  }
}
