import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../design/design.dart';
import '../models/nutrition_models.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../components/ui/snackbar_utils.dart';
import '../components/ui/numeric_text_field.dart';

class CreateCustomFoodBottomSheet extends StatefulWidget {
  final Function(FoodItem) onFoodSelected;

  const CreateCustomFoodBottomSheet({
    super.key,
    required this.onFoodSelected,
  });

  @override
  State<CreateCustomFoodBottomSheet> createState() => _CreateCustomFoodBottomSheetState();
}

class _CreateCustomFoodBottomSheetState extends State<CreateCustomFoodBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _proteinsController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();

  String _selectedUnit = 'g';
  double _referenceQuantity = 100.0;
  bool _isLoading = false;

  // Unités disponibles avec leurs quantités par défaut
  final Map<String, double> _unitDefaults = {
    'g': 100.0,
    'ml': 100.0,
    'portion': 1.0,
    'cuillère': 1.0,
    'unité': 1.0,
  };

  // Méthode pour obtenir la traduction anglaise de l'unité
  String _getEnglishUnit(String frenchUnit) {
    switch (frenchUnit) {
      case 'g': return 'g';
      case 'ml': return 'ml';
      case 'portion': return 'serving';
      case 'cuillère': return 'spoon';
      case 'unité': return 'unit';
      default: return frenchUnit;
    }
  }

  @override
  void initState() {
    super.initState();
    _proteinsController.addListener(_updateCalories);
    _carbsController.addListener(_updateCalories);
    _fatsController.addListener(_updateCalories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _onUnitChanged(String? newUnit) {
    if (newUnit != null) {
      setState(() {
        _selectedUnit = newUnit;
        _referenceQuantity = _unitDefaults[newUnit]!;
      });
    }
  }

  void _updateCalories() {
    if (mounted) {
      setState(() {
        // Les calories sont calculées automatiquement
      });
    }
  }

  int _getCalculatedCalories() {
    final proteins = double.tryParse(_proteinsController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fats = double.tryParse(_fatsController.text) ?? 0;
    
    return ((proteins * 4) + (carbs * 4) + (fats * 9)).round();
  }

  Future<void> _createCustomFood() async {
    if (_nameController.text.trim().isEmpty) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      _showError(locService.currentLanguageCode == 'fr' ? 'Veuillez entrer un nom pour l\'aliment.' : 'Please enter a name for the food.');
      return;
    }

    final proteins = double.tryParse(_proteinsController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fats = double.tryParse(_fatsController.text) ?? 0;
    final calories = _getCalculatedCalories();

    if (calories == 0 && proteins == 0 && carbs == 0 && fats == 0) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      _showError(locService.currentLanguageCode == 'fr' ? 'Veuillez entrer au moins une valeur nutritionnelle.' : 'Please enter at least one nutritional value.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        _showError(locService.currentLanguageCode == 'fr' ? 'Vous devez être connecté pour créer un aliment.' : 'You must be logged in to create a food.');
        return;
      }

      // Vérifier si l'aliment existe déjà
      final exists = await DatabaseService.checkCustomFoodExists(user.id, _nameController.text.trim());
      if (exists) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        _showError(locService.currentLanguageCode == 'fr' ? 'Un aliment avec ce nom existe déjà.' : 'A food with this name already exists.');
        return;
      }

      // Créer l'aliment personnalisé dans la base de données
      final createdFood = await DatabaseService.createCustomFoodFromData(
        userId: user.id,
        name: _nameController.text.trim(),
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        referenceUnitFr: _selectedUnit,
        referenceUnitEn: _getEnglishUnit(_selectedUnit),
        referenceQuantity: _referenceQuantity,
      );
      
      if (createdFood == null) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        _showError(locService.currentLanguageCode == 'fr' ? 'Erreur lors de la sauvegarde en base de données.' : 'Error saving to database.');
        return;
      }

      // Créer le FoodItem pour la sélection de quantité
      final customFood = FoodItem(
        id: createdFood.id, // Ajouter l'ID de l'aliment créé
        name: _nameController.text.trim(),
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
                                portion: '${_referenceQuantity.toStringAsFixed(_referenceQuantity.truncateToDouble() == _referenceQuantity ? 0 : 1)} $_selectedUnit',
        isCustom: true,
        referenceUnitFr: _selectedUnit,
        referenceUnitEn: _getEnglishUnit(_selectedUnit),
        referenceQuantity: _referenceQuantity,
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        // Ouvrir le bottom sheet de sélection de quantité
        EditableFoodDetailsBottomSheet.show(
          context,
          id: createdFood.id, // Transmettre l'ID de l'aliment créé
          name: customFood.name,
          calories: customFood.calories,
          proteins: customFood.proteins,
          glucides: customFood.carbs,
          lipides: customFood.fats,
          quantity: _referenceQuantity,
          isModified: false,
          isCustomFood: true,
          referenceUnit: _selectedUnit,
          onFoodAdded: widget.onFoodSelected,
        );
      }
    } catch (e) {
      // Erreur lors de la création: $e
      final locService = Provider.of<LocalizationService>(context, listen: false);
      _showError(locService.currentLanguageCode == 'fr' ? 'Erreur lors de la création de l\'aliment.' : 'Error creating the food.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    SnackBarUtils.showErrorSnackBar(
      context,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final calories = _getCalculatedCalories();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: context.vh(92)),
      child: Container(
        decoration: const BoxDecoration(
          color: RyzeColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: context.vw(2.6)),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
            ),
            SizedBox(height: context.vw(4.1)),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Row(
                children: [
                  Expanded(
                    child: Text('create_food'.tr(lang), style: RyzeText.body(context, 5.1, weight: FontWeight.w600)),
                  ),
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(9.2),
                      height: context.vw(9.2),
                      decoration: const BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle),
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
                  _FieldLabel('food_name'.tr(lang)),
                  SizedBox(height: context.vw(2.1)),
                  _Field(
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
                  SizedBox(height: context.vw(5.6)),

                  // L'unité décide de la quantité de référence : on la choisit
                  // d'un tap plutôt que dans un menu qui cache ses options.
                  _FieldLabel('reference_quantity'.tr(lang)),
                  SizedBox(height: context.vw(2.1)),
                  Wrap(
                    spacing: context.vw(2.1),
                    runSpacing: context.vw(2.1),
                    children: [
                      for (final unit in _unitDefaults.keys)
                        Pressable(
                          onTap: () {
                            RyzeFeedback.tap();
                            _onUnitChanged(unit);
                          },
                          child: AnimatedContainer(
                            duration: RyzeDurations.tap,
                            curve: RyzeCurves.out,
                            padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(2.6)),
                            decoration: BoxDecoration(
                              color: unit == _selectedUnit ? RyzeColors.ink : RyzeColors.surf,
                              borderRadius: BorderRadius.circular(RyzeRadius.pill),
                              border: Border.all(color: unit == _selectedUnit ? RyzeColors.ink : RyzeColors.line),
                            ),
                            child: Text(
                              '${_unitDefaults[unit]!.toStringAsFixed(0)} $unit',
                              style: RyzeText.body(
                                context,
                                3.4,
                                weight: FontWeight.w600,
                                color: unit == _selectedUnit ? RyzeColors.surf : RyzeColors.ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.vw(5.6)),

                  // Les trois macros écrivent les calories : le chiffre du haut
                  // suit ce qu'on tape, il ne se saisit pas.
                  _FieldLabel(
                    'macros_per'.tr(lang).replaceAll(
                          '{q}',
                          '${_referenceQuantity.toStringAsFixed(_referenceQuantity.truncateToDouble() == _referenceQuantity ? 0 : 1)} $_selectedUnit',
                        ),
                  ),
                  SizedBox(height: context.vw(2.1)),
                  Container(
                    padding: EdgeInsets.all(context.vw(4.1)),
                    decoration: BoxDecoration(
                      color: RyzeColors.surf,
                      borderRadius: BorderRadius.circular(RyzeRadius.md),
                      border: Border.all(color: RyzeColors.line),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('calories'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
                            ),
                            RollingNumber('$calories', style: RyzeText.display(context, 6.9, weight: FontWeight.w600)),
                            SizedBox(width: context.vw(1.5)),
                            Padding(
                              padding: EdgeInsets.only(top: context.vw(1.5)),
                              child: Text('kcal', style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
                            ),
                          ],
                        ),
                        SizedBox(height: context.vw(3.6)),
                        Divider(height: 1, color: RyzeColors.line),
                        SizedBox(height: context.vw(3.1)),
                        _MacroField(label: 'proteins'.tr(lang), controller: _proteinsController),
                        SizedBox(height: context.vw(2.6)),
                        _MacroField(label: 'carbs'.tr(lang), controller: _carbsController),
                        SizedBox(height: context.vw(2.6)),
                        _MacroField(label: 'fats'.tr(lang), controller: _fatsController),
                      ],
                    ),
                  ),
                  SizedBox(height: context.vw(6)),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(4.1) + MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => Navigator.pop(context),
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
                      onTap: _isLoading ? null : _createCustomFood,
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
                                child: const CircularProgressIndicator(strokeWidth: 2, color: RyzeColors.surf),
                              )
                            : Text(
                                'create'.tr(lang),
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
}

/// Le nom d'un champ, au-dessus de lui.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute));
  }
}

/// La surface blanche d'un champ de saisie.
class _Field extends StatelessWidget {
  const _Field({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.sm),
        border: Border.all(color: RyzeColors.line),
      ),
      child: child,
    );
  }
}

/// Une macro qu'on saisit : son nom à gauche, ses grammes à droite.
class _MacroField extends StatelessWidget {
  const _MacroField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: RyzeText.body(context, 3.6, color: RyzeColors.mute))),
        SizedBox(
          width: context.vw(22),
          height: context.vw(10.2),
          child: NumericTextField(
            controller: controller,
            textAlign: TextAlign.right,
            style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'g',
              suffixStyle: RyzeText.body(context, 3.3, color: RyzeColors.mute),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: context.vw(2.6), vertical: context.vw(2.1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RyzeRadius.xs),
                borderSide: BorderSide(color: RyzeColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RyzeRadius.xs),
                borderSide: BorderSide(color: RyzeColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RyzeRadius.xs),
                borderSide: BorderSide(color: RyzeColors.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}