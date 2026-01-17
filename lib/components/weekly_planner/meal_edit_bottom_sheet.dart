import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/meal_planner_sync_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

/// Bottom sheet pour éditer les macros d'un repas planifié
class MealEditBottomSheet extends StatefulWidget {
  final PlannedActivity activity;
  final VoidCallback onSaved;

  const MealEditBottomSheet({
    super.key,
    required this.activity,
    required this.onSaved,
  });

  @override
  State<MealEditBottomSheet> createState() => _MealEditBottomSheetState();
}

class _MealEditBottomSheetState extends State<MealEditBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinsController;
  late TextEditingController _carbsController;
  late TextEditingController _fatsController;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final mealData = widget.activity.mealData;

    _nameController = TextEditingController(text: mealData?.displayName ?? '');
    _descriptionController = TextEditingController(text: mealData?.displayDescription ?? '');
    _caloriesController = TextEditingController(text: (mealData?.calories ?? 0).toString());
    _proteinsController = TextEditingController(text: (mealData?.proteins ?? 0).toStringAsFixed(1));
    _carbsController = TextEditingController(text: (mealData?.carbs ?? 0).toStringAsFixed(1));
    _fatsController = TextEditingController(text: (mealData?.fats ?? 0).toStringAsFixed(1));

    // Écouter les changements
    _nameController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
    _caloriesController.addListener(_onChanged);
    _proteinsController.addListener(_onChanged);
    _carbsController.addListener(_onChanged);
    _fatsController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.pencil,
                      size: 20,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'planner_edit_meal'.tr(langCode),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 24),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nom du plat
              _buildTextField(
                controller: _nameController,
                label: 'planner_dish_name'.tr(langCode),
                icon: LucideIcons.utensils,
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'planner_dish_description'.tr(langCode),
                icon: LucideIcons.alignLeft,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Section Macros
              Text(
                'planner_nutritional_values'.tr(langCode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
              const SizedBox(height: 12),

              // Grille de macros
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField(
                      controller: _caloriesController,
                      label: 'kcal',
                      color: const Color(0xFFF59E0B),
                      langCode: langCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMacroField(
                      controller: _proteinsController,
                      label: 'planner_proteins_short'.tr(langCode),
                      color: const Color(0xFFEF4444),
                      langCode: langCode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField(
                      controller: _carbsController,
                      label: 'planner_carbs_short'.tr(langCode),
                      color: const Color(0xFF3B82F6),
                      langCode: langCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMacroField(
                      controller: _fatsController,
                      label: 'planner_fats_short'.tr(langCode),
                      color: const Color(0xFF10B981),
                      langCode: langCode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasChanges && !_isLoading ? _saveMeal : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'planner_save'.tr(langCode),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }

  Widget _buildMacroField({
    required TextEditingController controller,
    required String label,
    required Color color,
    required String langCode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        color: color.withOpacity(0.05),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final calories = int.tryParse(_caloriesController.text) ?? 0;
      final proteins = double.tryParse(_proteinsController.text) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text) ?? 0.0;
      final fats = double.tryParse(_fatsController.text) ?? 0.0;

      final success = await MealPlannerSyncService.updateMealMacros(
        widget.activity,
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        dishName: _nameController.text.isNotEmpty ? _nameController.text : null,
        dishDescription: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );

      if (success && mounted) {
        widget.onSaved();
        Navigator.pop(context, true);
      } else if (mounted) {
        final langCode = LocalizationService.instance.currentLanguageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('planner_error_saving'.tr(langCode)),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Save meal error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
