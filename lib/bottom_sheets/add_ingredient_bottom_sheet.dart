import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../models/ai_analysis_models.dart';
import '../components/ui/numeric_text_field.dart';
import '../components/ui/snackbar_utils.dart';

class AddIngredientBottomSheet extends StatefulWidget {
  final Function(DetectedFood) onIngredientAdded;

  const AddIngredientBottomSheet({
    super.key,
    required this.onIngredientAdded,
  });

  static void show(
    BuildContext context, {
    required Function(DetectedFood) onIngredientAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddIngredientBottomSheet(
          onIngredientAdded: onIngredientAdded,
        ),
      ),
    );
  }

  @override
  State<AddIngredientBottomSheet> createState() => _AddIngredientBottomSheetState();
}

class _AddIngredientBottomSheetState extends State<AddIngredientBottomSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  String _selectedUnit = 'g';
  bool _isLoading = false;
  String? _nameError;
  String? _quantityError;
  String? _generalError;

  final Map<String, double> _unitDefaults = {
    'g': 100.0,
    'ml': 100.0,
    'portion': 1.0,
    'cuillère': 1.0,
    'unité': 1.0,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    final locService = LocalizationService.instance;

    setState(() {
      _nameError = null;
      _quantityError = null;
      _generalError = null;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'name_required'.tr(locService.currentLanguageCode);
      });
      isValid = false;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      setState(() {
        _quantityError = 'quantity_required'.tr(locService.currentLanguageCode);
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _addIngredient() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      final ingredientName = _nameController.text.trim();
      final quantity = _quantityController.text;
      final unit = _selectedUnit;

      // Construire le texte pour Gemini selon la langue
      String textToAnalyze;
      if (languageCode == 'fr') {
        if (unit == 'portion' || unit == 'cuillère' || unit == 'unité') {
          textToAnalyze = '$quantity $unit de $ingredientName';
        } else {
          textToAnalyze = '$quantity$unit de $ingredientName';
        }
      } else {
        if (unit == 'portion' || unit == 'cuillère' || unit == 'unité') {
          // Traduire les unités en anglais
          final englishUnit = unit == 'portion' ? 'portion' :
                              unit == 'cuillère' ? 'spoon' : 'unit';
          textToAnalyze = '$quantity $englishUnit of $ingredientName';
        } else {
          textToAnalyze = '$quantity$unit of $ingredientName';
        }
      }

      if (kDebugMode) debugPrint('📝 Analyzing ingredient: $textToAnalyze');

      final result = await GeminiAnalysisServiceV2.analyzeTextDescription(textToAnalyze);

      if (!mounted) return;

      if (result.success && result.detectedFoods.isNotEmpty) {
        // Prendre le premier aliment détecté
        final detectedFood = result.detectedFoods.first;

        if (kDebugMode) {
          debugPrint('✅ Ingredient detected: ${detectedFood.name}');
          debugPrint('   Calories: ${detectedFood.calories}');
          debugPrint('   Proteins: ${detectedFood.nutrition.proteins}g');
        }

        widget.onIngredientAdded(detectedFood);
        Navigator.pop(context);

        SnackBarUtils.showSuccessSnackBar(
          context,
          message: 'ingredient_added_success'.tr(languageCode),
        );
      } else {
        setState(() {
          _generalError = result.error ?? 'ingredient_not_recognized'.tr(languageCode);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error adding ingredient: $e');
      if (mounted) {
        setState(() {
          _generalError = LocalizationService.instance.currentLanguageCode == 'fr'
              ? 'Une erreur est survenue'
              : 'An error occurred';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
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
                        'add_ingredient'.tr(locService.currentLanguageCode),
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

            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de l'ingrédient
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        'ingredient_name'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'ingredient_name_placeholder'.tr(locService.currentLanguageCode),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF3B82F6)),
                          ),
                          errorBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFFDC2626)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          errorText: _nameError,
                        ),
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Quantité
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr' ? 'Quantité' : 'Quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Champ quantité
                        Expanded(
                          flex: 2,
                          child: NumericTextField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              hintText: '100',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: Color(0xFF3B82F6)),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: Color(0xFFDC2626)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              errorText: _quantityError,
                            ),
                            onChanged: (_) {
                              if (_quantityError != null) {
                                setState(() => _quantityError = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sélecteur d'unité
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: Color(0xFF3B82F6)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            items: _unitDefaults.keys.map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (String? newUnit) {
                              if (newUnit != null) {
                                setState(() {
                                  _selectedUnit = newUnit;
                                  // Mettre à jour la quantité par défaut pour cette unité
                                  _quantityController.text = _unitDefaults[newUnit]!.toStringAsFixed(
                                    _unitDefaults[newUnit]!.truncateToDouble() == _unitDefaults[newUnit]! ? 0 : 1
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Message d'erreur général
                    if (_generalError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.circleAlert,
                              size: 20,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Boutons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF0B132B),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            'cancel'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0B132B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _addIngredient,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : Consumer<LocalizationService>(
                                builder: (context, locService, child) => Text(
                                  locService.currentLanguageCode == 'fr' ? 'Ajouter' : 'Add',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
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
}
