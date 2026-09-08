import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../components/ui/numeric_text_field.dart';
import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/portions.dart';
import '../services/translations.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../models/ai_analysis_models.dart';
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

  // Clés d'unités (pas les labels affichés)
  final List<String> _unitKeys = ['g', 'ml', 'portion', 'spoon', 'unit'];

  final Map<String, double> _unitDefaults = {
    'g': 100.0,
    'ml': 100.0,
    'portion': 1.0,
    'spoon': 1.0,
    'unit': 1.0,
  };

  String _getUnitLabel(String unitKey, String languageCode) {
    switch (unitKey) {
      case 'g':
        return 'g';
      case 'ml':
        return 'ml';
      case 'portion':
        return languageCode == 'fr' ? 'portion' : languageCode == 'de' ? 'Portion' : 'portion';
      case 'spoon':
        return languageCode == 'fr' ? 'cuillère' : languageCode == 'de' ? 'Löffel' : 'spoon';
      case 'unit':
        return languageCode == 'fr' ? 'unité' : languageCode == 'de' ? 'Stück' : 'unit';
      default:
        return unitKey;
    }
  }

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
        final langCode = LocalizationService.instance.currentLanguageCode;
        setState(() {
          _generalError = langCode == 'fr'
              ? 'Une erreur est survenue'
              : langCode == 'de'
                  ? 'Ein Fehler ist aufgetreten'
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
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: context.vh(90)),
      child: Container(
        decoration: BoxDecoration(
          color: RyzeColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: context.vw(2.6)),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
              ),
            ),
            SizedBox(height: context.vw(4.1)),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Row(
                children: [
                  Expanded(
                    child: Text('add_ingredient'.tr(lang), style: RyzeText.body(context, 5.1, weight: FontWeight.w600)),
                  ),
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(9.2),
                      height: context.vw(9.2),
                      decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle),
                      child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.mute),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.vw(4.6)),

            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: gutter),
                children: [
                  Text('food_name'.tr(lang), style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute)),
                  SizedBox(height: context.vw(2.1)),
                  Container(
                    decoration: BoxDecoration(
                      color: RyzeColors.surf,
                      borderRadius: BorderRadius.circular(RyzeRadius.sm),
                      border: Border.all(color: _nameError == null ? RyzeColors.line : RyzeColors.danger),
                    ),
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: RyzeText.body(context, 3.9),
                      cursorColor: RyzeColors.ink,
                      decoration: InputDecoration(
                        hintText: 'food_name_placeholder'.tr(lang),
                        hintStyle: RyzeText.body(context, 3.9, color: RyzeColors.mute2),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.6)),
                      ),
                    ),
                  ),
                  if (_nameError != null)
                    Padding(
                      padding: EdgeInsets.only(top: context.vw(1.5)),
                      child: Text(_nameError!, style: RyzeText.body(context, 3.1, color: RyzeColors.danger)),
                    ),
                  SizedBox(height: context.vw(5.6)),

                  Text('unit'.tr(lang), style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute)),
                  SizedBox(height: context.vw(2.1)),
                  Wrap(
                    spacing: context.vw(2.1),
                    runSpacing: context.vw(2.1),
                    children: [
                      for (final key in _unitKeys)
                        Pressable(
                          onTap: () {
                            RyzeFeedback.tap();
                            setState(() {
                              _selectedUnit = key;
                              _quantityController.text = RyzePortions.format(_unitDefaults[key]!);
                            });
                          },
                          child: AnimatedContainer(
                            duration: RyzeDurations.tap,
                            curve: RyzeCurves.out,
                            padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(2.6)),
                            decoration: BoxDecoration(
                              color: key == _selectedUnit ? RyzeColors.ink : RyzeColors.surf,
                              borderRadius: BorderRadius.circular(RyzeRadius.pill),
                              border: Border.all(color: key == _selectedUnit ? RyzeColors.ink : RyzeColors.line),
                            ),
                            child: Text(
                              _getUnitLabel(key, lang),
                              style: RyzeText.body(
                                context,
                                3.4,
                                weight: FontWeight.w600,
                                color: key == _selectedUnit ? RyzeColors.surf : RyzeColors.ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.vw(5.6)),

                  Text('quantity'.tr(lang), style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute)),
                  SizedBox(height: context.vw(2.3)),
                  Row(
                    children: [
                      _IngredientStep(icon: LucideIcons.minus, onTap: () => _bump(-1)),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IntrinsicWidth(
                              child: NumericTextField(
                                controller: _quantityController,
                                textAlign: TextAlign.center,
                                style: RyzeText.display(context, 9.2, weight: FontWeight.w600),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: '0',
                                ),
                              ),
                            ),
                            SizedBox(width: context.vw(1.5)),
                            Text(
                              _getUnitLabel(_selectedUnit, lang),
                              style: RyzeText.body(context, 3.9, color: RyzeColors.mute),
                            ),
                          ],
                        ),
                      ),
                      _IngredientStep(icon: LucideIcons.plus, onTap: () => _bump(1)),
                    ],
                  ),
                  if (_quantityError != null)
                    Padding(
                      padding: EdgeInsets.only(top: context.vw(2.1)),
                      child: Text(_quantityError!, textAlign: TextAlign.center, style: RyzeText.body(context, 3.1, color: RyzeColors.danger)),
                    ),
                  if (_generalError != null)
                    Padding(
                      padding: EdgeInsets.only(top: context.vw(2.6)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.info, size: context.vw(3.6), color: RyzeColors.danger),
                          SizedBox(width: context.vw(2.1)),
                          Expanded(
                            child: Text(_generalError!, style: RyzeText.body(context, 3.2, color: RyzeColors.danger)),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: context.vw(6)),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, MediaQuery.of(context).viewInsets.bottom + context.vw(4.6)),
              child: Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: _isLoading ? null : () => Navigator.pop(context),
                      child: Container(
                        height: context.vw(13.3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: RyzeColors.surf,
                          borderRadius: BorderRadius.circular(RyzeRadius.sm),
                          border: Border.all(color: RyzeColors.line),
                        ),
                        child: Text('cancel'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  SizedBox(width: context.vw(3.1)),
                  Expanded(
                    flex: 2,
                    child: Pressable(
                      onTap: _isLoading ? null : _addIngredient,
                      child: Container(
                        height: context.vw(13.3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: RyzeColors.ink,
                          borderRadius: BorderRadius.circular(RyzeRadius.sm),
                          boxShadow: RyzeShadow.soft,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: context.vw(4.6),
                                height: context.vw(4.6),
                                child: CircularProgressIndicator(strokeWidth: 2, color: RyzeColors.surf),
                              )
                            : Text(
                                'add'.tr(lang),
                                style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
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

  /// Un pas de quantité à l'échelle de l'unité choisie.
  void _bump(int direction) {
    final unit = _getUnitLabel(_selectedUnit, 'fr');
    final current = double.tryParse(_quantityController.text.isEmpty ? '0' : _quantityController.text) ?? 0;
    final step = RyzePortions.step(unit: unit, reference: _unitDefaults[_selectedUnit] ?? 100);
    RyzeFeedback.tap();
    setState(() {
      _quantityController.text = RyzePortions.format((current + direction * step).clamp(0, 5000).toDouble());
    });
  }
}

class _IngredientStep extends StatelessWidget {
  const _IngredientStep({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: context.vw(12.3),
        height: context.vw(12.3),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          shape: BoxShape.circle,
          border: Border.all(color: RyzeColors.line),
        ),
        child: Icon(icon, size: context.vw(5.1), color: RyzeColors.ink),
      ),
    );
  }
}
