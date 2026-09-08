import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../design/design.dart';
import '../services/portions.dart';
import '../models/nutrition_models.dart';
import '../components/ui/snackbar_utils.dart';
import '../components/ui/numeric_text_field.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

class EditableFoodDetailsBottomSheet {
  static Future<void> show(
    BuildContext context, {
    String? id, // Ajouter l'ID de l'aliment
    required String name,
    required int calories,
    required double proteins,
    required double glucides,
    required double lipides,
    required double quantity,
    bool isModified = false,
    bool isCustomFood = false,
    String? referenceUnit,
    Function(FoodItem)? onFoodAdded,
    Function(FoodItem)? onFoodSaved,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      isDismissible: false, // On gère manuellement
      enableDrag: false, // On gère le drag manuellement
      builder: (context) => _KeyboardAwareBottomSheet(
        child: _EditableFoodDetailsContent(
          id: id,
          name: name,
          calories: calories,
          proteins: proteins,
          glucides: glucides,
          lipides: lipides,
          quantity: quantity,
          isModified: isModified,
          isCustomFood: isCustomFood,
          referenceUnit: referenceUnit,
          onFoodAdded: onFoodAdded,
          onFoodSaved: onFoodSaved,
        ),
      ),
    );
  }

}

// Widget qui gère intelligemment le clavier et le geste de fermeture
class _KeyboardAwareBottomSheet extends StatefulWidget {
  final Widget child;

  const _KeyboardAwareBottomSheet({
    required this.child,
  });

  @override
  State<_KeyboardAwareBottomSheet> createState() => _KeyboardAwareBottomSheetState();
}

class _KeyboardAwareBottomSheetState extends State<_KeyboardAwareBottomSheet> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  DateTime? _lastKeyboardDismissTime;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Vérifier si le clavier a été fermé récemment (dans les 500ms)
    final recentlyDismissedKeyboard = _lastKeyboardDismissTime != null &&
        DateTime.now().difference(_lastKeyboardDismissTime!) < const Duration(milliseconds: 500);

    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() {
          _isDragging = true;
          _dragOffset = 0;
        });
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          // Seulement permettre le drag vers le bas
          _dragOffset += details.delta.dy;
          if (_dragOffset < 0) _dragOffset = 0;
        });
      },
      onVerticalDragEnd: (details) {
        final shouldDismiss = _dragOffset > 100 ||
            (details.primaryVelocity != null && details.primaryVelocity! > 700);

        setState(() {
          _isDragging = false;
        });

        if (keyboardVisible) {
          // Si le clavier est visible, toujours le fermer en premier
          FocusScope.of(context).unfocus();
          _lastKeyboardDismissTime = DateTime.now();
          setState(() {
            _dragOffset = 0;
          });
        } else if (!recentlyDismissedKeyboard && shouldDismiss) {
          // Si le clavier n'est pas visible ET n'a pas été fermé récemment,
          // et que le drag est suffisant, fermer le bottom sheet
          Navigator.pop(context);
        } else {
          // Sinon, revenir à la position initiale
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      onVerticalDragCancel: () {
        setState(() {
          _isDragging = false;
          _dragOffset = 0;
        });
      },
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GestureDetector(
            onTap: () {
              if (keyboardVisible) {
                FocusScope.of(context).unfocus();
                _lastKeyboardDismissTime = DateTime.now();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _EditableFoodDetailsContent extends StatefulWidget {
  final String? id; // Ajouter l'ID
  final String name;
  final int calories;
  final double proteins;
  final double glucides;
  final double lipides;
  final double quantity;
  final bool isModified;
  final bool isCustomFood;
  final String? referenceUnit;
  final Function(FoodItem)? onFoodAdded;
  final Function(FoodItem)? onFoodSaved; // Nouveau callback pour enregistrer seulement

  const _EditableFoodDetailsContent({
    this.id, // Ajouter l'ID
    required this.name,
    required this.calories,
    required this.proteins,
    required this.glucides,
    required this.lipides,
    required this.quantity,
    required this.isModified,
    required this.isCustomFood,
    this.referenceUnit,
    this.onFoodAdded,
    this.onFoodSaved,
  });

  @override
  State<_EditableFoodDetailsContent> createState() => _EditableFoodDetailsContentState();
}

class _EditableFoodDetailsContentState extends State<_EditableFoodDetailsContent> {
  late TextEditingController _quantityController;
  late TextEditingController _proteinsController;
  late TextEditingController _glucidesController;
  late TextEditingController _lipidesController;
  
  late double _baseQuantity;
  late double _baseProteins;
  late double _baseGlucides;
  late double _baseLipides;
  
  late int _calculatedCalories;
  
  bool _isModified = false;
  bool _hasModifiedMacros = false; // Nouvelle variable pour suivre les modifications de macronutriments
  bool _isEditing = false;
  bool _macrosManuallyEdited = false;
  
  String _initialProteinsText = '';
  String _initialGlucidesText = '';
  String _initialLipidesText = '';
  String _initialQuantityText = '';

  @override
  void initState() {
    super.initState();
    // Sauvegarder les valeurs de base
    _baseProteins = widget.proteins;
    _baseGlucides = widget.glucides;
    _baseLipides = widget.lipides;
    _baseQuantity = widget.quantity;
    
    // Initialiser les contrôleurs avec les valeurs
    _initialProteinsText = widget.proteins.toStringAsFixed(1);
    _initialGlucidesText = widget.glucides.toStringAsFixed(1);
    _initialLipidesText = widget.lipides.toStringAsFixed(1);
    _initialQuantityText = widget.quantity.toStringAsFixed(widget.quantity.truncateToDouble() == widget.quantity ? 0 : 1);
    
    _proteinsController = TextEditingController(text: _initialProteinsText);
    _glucidesController = TextEditingController(text: _initialGlucidesText);
    _lipidesController = TextEditingController(text: _initialLipidesText);
    _quantityController = TextEditingController(text: _initialQuantityText);
    _calculatedCalories = widget.calories;
    _isModified = widget.isModified;
    
    // Ajouter les listeners qui détectent les vrais changements
    _proteinsController.addListener(_onProteinsChanged);
    _glucidesController.addListener(_onGlucidesChanged);
    _lipidesController.addListener(_onLipidesChanged);
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _proteinsController.removeListener(_onProteinsChanged);
    _glucidesController.removeListener(_onGlucidesChanged);
    _lipidesController.removeListener(_onLipidesChanged);
    _quantityController.removeListener(_onQuantityChanged);
    _proteinsController.dispose();
    _glucidesController.dispose();
    _lipidesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onProteinsChanged() {
    if (_proteinsController.text != _initialProteinsText) {
      _macrosManuallyEdited = true;
      _calculateCaloriesFromMacros();
    }
  }

  void _onGlucidesChanged() {
    if (_glucidesController.text != _initialGlucidesText) {
      _macrosManuallyEdited = true;
      _calculateCaloriesFromMacros();
    }
  }

  void _onLipidesChanged() {
    if (_lipidesController.text != _initialLipidesText) {
      _macrosManuallyEdited = true;
      _calculateCaloriesFromMacros();
    }
  }

  void _onQuantityChanged() {
    if (_quantityController.text != _initialQuantityText) {
      _calculateMacrosFromQuantity();
    }
  }

  void _calculateCaloriesFromMacros() {
    final proteins = double.tryParse(_proteinsController.text.isEmpty ? '0' : _proteinsController.text) ?? 0;
    final glucides = double.tryParse(_glucidesController.text.isEmpty ? '0' : _glucidesController.text) ?? 0;
    final lipides = double.tryParse(_lipidesController.text.isEmpty ? '0' : _lipidesController.text) ?? 0;
    
    setState(() {
      _calculatedCalories = ((proteins * 4) + (glucides * 4) + (lipides * 9)).round();
      _isModified = true;
      _hasModifiedMacros = true; // Marquer que les macronutriments ont été modifiés
    });
  }

  void _calculateMacrosFromQuantity() {
    // Ne pas recalculer si les macros ont été modifiées manuellement
    if (_macrosManuallyEdited) return;
    
    final newQuantity = double.tryParse(_quantityController.text.isEmpty ? '0' : _quantityController.text) ?? _baseQuantity;
    final ratio = newQuantity / _baseQuantity;
    
    setState(() {
      // Recalculer toutes les valeurs proportionnellement à partir des valeurs de base
      final newProteins = _baseProteins * ratio;
      final newGlucides = _baseGlucides * ratio;
      final newLipides = _baseLipides * ratio;
      final newCalories = (widget.calories * ratio).round();
      
      // Mettre à jour les contrôleurs sans déclencher les listeners
      _proteinsController.removeListener(_onProteinsChanged);
      _glucidesController.removeListener(_onGlucidesChanged);
      _lipidesController.removeListener(_onLipidesChanged);
      
      _proteinsController.text = newProteins.toStringAsFixed(1);
      _glucidesController.text = newGlucides.toStringAsFixed(1);
      _lipidesController.text = newLipides.toStringAsFixed(1);
      _calculatedCalories = newCalories;
      
      // Remettre les listeners
      _proteinsController.addListener(_onProteinsChanged);
      _glucidesController.addListener(_onGlucidesChanged);
      _lipidesController.addListener(_onLipidesChanged);
      
      _isModified = true;
      // Ne pas marquer _hasModifiedMacros = true ici car c'est juste un changement de quantité
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        // Sauvegarder les valeurs actuelles comme référence
        _initialProteinsText = _proteinsController.text;
        _initialGlucidesText = _glucidesController.text;
        _initialLipidesText = _lipidesController.text;
        _initialQuantityText = _quantityController.text;
        
        // Réinitialiser le flag de modification manuelle des macros
        // pour permettre le recalcul proportionnel quand on change la quantité
        _macrosManuallyEdited = false;
      }
    });
  }

  void _confirmEdit() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final unit = widget.referenceUnit ?? 'g';
    final gutter = context.vw(5.1);

    return Container(
      decoration: const BoxDecoration(
        color: RyzeColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, context.vw(2.6), gutter, context.vw(4.1)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: RyzeColors.idle,
                    borderRadius: BorderRadius.circular(RyzeRadius.pill),
                  ),
                ),
              ),
              SizedBox(height: context.vw(4.1)),

              // Le nom, et le signe discret d'une valeur retouchée à la main.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 5.1, weight: FontWeight.w600),
                    ),
                  ),
                  if (_isModified || widget.isModified)
                    Padding(
                      padding: EdgeInsets.only(left: context.vw(2.1), top: context.vw(1)),
                      child: const Icon(LucideIcons.pencil, size: 14, color: RyzeColors.mute2),
                    ),
                ],
              ),
              SizedBox(height: context.vw(5.1)),

              // La quantité est le geste principal : elle est écrite en grand,
              // encadrée par deux pas, avec quelques portions courantes dessous.
              _PortionControl(
                controller: _quantityController,
                unit: unit,
                lang: lang,
                presets: RyzePortions.presets(unit: widget.referenceUnit, reference: _baseQuantity),
                onStep: _step,
                onPreset: _setQuantity,
              ),
              SizedBox(height: context.vw(5.1)),

              // Ce que la portion vaut. Les calories mènent, les trois macros
              // suivent en encre ; le crayon ouvre la correction.
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'calories'.tr(lang),
                            style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                          ),
                        ),
                        RollingNumber(
                          '$_calculatedCalories',
                          style: RyzeText.display(context, 6.9, weight: FontWeight.w600),
                        ),
                        SizedBox(width: context.vw(1.5)),
                        Padding(
                          padding: EdgeInsets.only(top: context.vw(1.5)),
                          child: Text('kcal', style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
                        ),
                        if (!widget.isCustomFood) ...[
                          SizedBox(width: context.vw(2.6)),
                          Pressable(
                            onTap: () {
                              RyzeFeedback.tap();
                              _isEditing ? _confirmEdit() : _toggleEditMode();
                            },
                            child: Container(
                              width: context.vw(8.7),
                              height: context.vw(8.7),
                              decoration: BoxDecoration(
                                color: _isEditing ? RyzeColors.ink : RyzeColors.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: _isEditing ? RyzeColors.ink : RyzeColors.line),
                              ),
                              child: Icon(
                                _isEditing ? LucideIcons.check : LucideIcons.pencil,
                                size: context.vw(4.1),
                                color: _isEditing ? RyzeColors.surf : RyzeColors.mute,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: context.vw(3.6)),
                    Divider(height: 1, color: RyzeColors.line),
                    SizedBox(height: context.vw(3.1)),
                    _MacroLine(label: 'proteins'.tr(lang), controller: _proteinsController, editing: _isEditing),
                    SizedBox(height: context.vw(2.6)),
                    _MacroLine(label: 'carbs'.tr(lang), controller: _glucidesController, editing: _isEditing),
                    SizedBox(height: context.vw(2.6)),
                    _MacroLine(label: 'fats'.tr(lang), controller: _lipidesController, editing: _isEditing),
                  ],
                ),
              ),
              SizedBox(height: context.vw(5.1)),

              Row(
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
                      onTap: _submit,
                      child: Container(
                        height: context.vw(13.3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: RyzeColors.ink,
                          borderRadius: BorderRadius.circular(RyzeRadius.sm),
                          boxShadow: RyzeShadow.soft,
                        ),
                        child: Text(
                          widget.onFoodSaved != null
                              ? 'save'.tr(lang)
                              : (_isModified ? 'confirm'.tr(lang) : 'add'.tr(lang)),
                          style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Un pas de portion, à l'échelle de l'aliment : dix grammes pour du riz,
  /// une pièce pour un œuf, cinq grammes pour une épice.
  void _step(int direction) {
    final current = double.tryParse(_quantityController.text.isEmpty ? '0' : _quantityController.text) ?? 0;
    final step = RyzePortions.step(unit: widget.referenceUnit, reference: _baseQuantity);
    _setQuantity((current + direction * step).clamp(0, 5000));
  }

  void _setQuantity(double value) {
    RyzeFeedback.tap();
    _quantityController.text = RyzePortions.format(value);
  }

  /// Ce que valide le bouton : l'aliment tel qu'il est affiché, puis le
  /// chemin d'origine, inchangé.
  void _submit() {
    RyzeFeedback.confirm();
    final quantity = _quantityController.text.isEmpty ? '0' : _quantityController.text;
    final proteins = double.tryParse(_proteinsController.text.isEmpty ? '0' : _proteinsController.text) ?? 0.0;
    final carbs = double.tryParse(_glucidesController.text.isEmpty ? '0' : _glucidesController.text) ?? 0.0;
    final fats = double.tryParse(_lipidesController.text.isEmpty ? '0' : _lipidesController.text) ?? 0.0;

    final foodItem = FoodItem(
      id: widget.id,
      name: widget.name,
      calories: _calculatedCalories,
      proteins: proteins,
      carbs: carbs,
      fats: fats,
      portion: '$quantity ${widget.referenceUnit ?? 'g'}',
      isModified: _isModified,
      hasModifiedMacros: _hasModifiedMacros,
      isCustom: widget.isCustomFood,
      isRecipe: false,
    );

    if (widget.onFoodSaved != null) {
      final lang = LocalizationService.instance.currentLanguageCode;
      widget.onFoodSaved?.call(foodItem);
      Navigator.pop(context);
      SnackBarUtils.show(
        context,
        message: (_isModified ? 'food_saved_modified' : 'food_saved').tr(lang).replaceAll('{name}', widget.name),
      );
      return;
    }

    // Flux classique : le callback écrit, puis la feuille se retire. Le délai
    // laisse l'écriture partir avant que la route disparaisse.
    final bottomSheetRoute = ModalRoute.of(context);
    widget.onFoodAdded?.call(foodItem);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (bottomSheetRoute != null) {
        final navigator = bottomSheetRoute.navigator;
        if (bottomSheetRoute.isCurrent) {
          navigator?.pop();
        } else {
          navigator?.removeRoute(bottomSheetRoute);
        }
      } else {
        Navigator.pop(context);
      }
    });
  }
}

/// La quantité : un grand nombre qu'on écrit, deux pas de part et d'autre, et
/// les portions qu'on prend le plus souvent en dessous.
class _PortionControl extends StatelessWidget {
  const _PortionControl({
    required this.controller,
    required this.unit,
    required this.lang,
    required this.presets,
    required this.onStep,
    required this.onPreset,
  });

  final TextEditingController controller;
  final String unit;
  final String lang;

  /// Ce qu'on propose pour cet aliment-là, pas une échelle universelle.
  final List<double> presets;

  final void Function(int direction) onStep;
  final void Function(double value) onPreset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'quantity'.tr(lang),
          style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
        ),
        SizedBox(height: context.vw(2.3)),
        Row(
          children: [
            _Step(icon: LucideIcons.minus, onTap: () => onStep(-1)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IntrinsicWidth(
                    child: NumericTextField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      style: RyzeText.display(context, 9.2, weight: FontWeight.w600),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0',
                      ),
                    ),
                  ),
                  SizedBox(width: context.vw(1.5)),
                  Text(unit, style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
                ],
              ),
            ),
            _Step(icon: LucideIcons.plus, onTap: () => onStep(1)),
          ],
        ),
        SizedBox(height: context.vw(3.1)),
        SizedBox(
          height: context.vw(9.2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: presets.length,
            separatorBuilder: (_, __) => SizedBox(width: context.vw(2.1)),
            itemBuilder: (_, i) {
              final value = presets[i];
              final selected = (double.tryParse(controller.text) ?? -1) == value;
              return Pressable(
                onTap: () => onPreset(value),
                child: AnimatedContainer(
                  duration: RyzeDurations.tap,
                  curve: RyzeCurves.out,
                  padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? RyzeColors.ink : RyzeColors.surf,
                    borderRadius: BorderRadius.circular(RyzeRadius.pill),
                    border: Border.all(color: selected ? RyzeColors.ink : RyzeColors.line),
                  ),
                  child: Text(
                    RyzePortions.label(value, unit, lang),
                    style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: selected ? RyzeColors.surf : RyzeColors.ink),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

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

/// Une macro : son nom, sa valeur. Elle devient un champ quand la correction
/// est ouverte, et reste du texte le reste du temps.
class _MacroLine extends StatelessWidget {
  const _MacroLine({required this.label, required this.controller, required this.editing});

  final String label;
  final TextEditingController controller;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: RyzeText.body(context, 3.6, color: RyzeColors.mute)),
        if (editing)
          SizedBox(
            width: context.vw(20),
            height: context.vw(9.2),
            child: NumericTextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: context.vw(2.1), vertical: context.vw(1.5)),
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
          )
        else
          Text(
            '${controller.text} g',
            style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
          ),
      ],
    );
  }
}
