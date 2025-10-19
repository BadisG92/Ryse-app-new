import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
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

  static Future<void> showCreateFood(
    BuildContext context, {
    Function(FoodItem)? onFoodCreated,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      isDismissible: false, // On gère manuellement
      enableDrag: false, // On gère le drag manuellement
      builder: (context) => _KeyboardAwareBottomSheet(
        child: _CreateFoodContent(
          onFoodCreated: onFoodCreated,
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
    final screenHeight = MediaQuery.of(context).size.height;

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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
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
            
            // Header avec symbole de modification si nécessaire
            Row(
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      // Symbole de modification manuelle si modifié
                      if (_isModified || widget.isModified)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            LucideIcons.pencil,
                            size: 12,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Informations nutritionnelles
            Container(
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
                children: [
                  // Ligne Calories avec bouton d'édition
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Consumer<LocalizationService>(
                            builder: (context, locService, child) => Text(
                              'calories'.tr(locService.currentLanguageCode),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          if (!_isEditing && !widget.isCustomFood)
                            GestureDetector(
                              onTap: _toggleEditMode,
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  LucideIcons.pencil,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          if (_isEditing)
                            GestureDetector(
                              onTap: _confirmEdit,
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${_calculatedCalories} kcal',
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
                      _isEditing
                          ? Container(
                              width: 60,
                              height: 32,
                              child: NumericTextField(
                                controller: _proteinsController,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(
                              '${_proteinsController.text}g',
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
                      _isEditing
                          ? Container(
                              width: 60,
                              height: 32,
                              child: NumericTextField(
                                controller: _glucidesController,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(
                              '${_glucidesController.text}g',
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
                      _isEditing
                          ? Container(
                              width: 60,
                              height: 32,
                              child: NumericTextField(
                                controller: _lipidesController,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(
                              '${_lipidesController.text}g',
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
            
            const SizedBox(height: 20),
            
            // Quantité
            Container(
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
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      'quantity'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: NumericTextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          widget.referenceUnit ?? (locService.currentLanguageCode == 'fr' ? 'grammes' : 'grams'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Boutons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    onTap: () {
                      // Traiter la quantité vide comme 0
                      final quantity = _quantityController.text.isEmpty ? '0' : _quantityController.text;
                      
                      // Récupérer les valeurs actuelles des macronutriments depuis les contrôleurs
                      final proteins = double.tryParse(_proteinsController.text.isEmpty ? '0' : _proteinsController.text) ?? 0.0;
                      final carbs = double.tryParse(_glucidesController.text.isEmpty ? '0' : _glucidesController.text) ?? 0.0;
                      final fats = double.tryParse(_lipidesController.text.isEmpty ? '0' : _lipidesController.text) ?? 0.0;
                      
                      // Créer l'aliment avec les valeurs actuelles (vues par l'utilisateur)
                      final foodItem = FoodItem(
                        id: widget.id, // Ajouter l'ID
                        name: widget.name,
                        calories: _calculatedCalories,
                        proteins: proteins,
                        carbs: carbs,
                        fats: fats,
                        portion: '$quantity ${widget.referenceUnit ?? 'g'}',
                        isModified: _isModified,
                        hasModifiedMacros: _hasModifiedMacros, // Nouvelle propriété
                        isCustom: widget.isCustomFood, // Marquer si c'est un aliment personnalisé
                        isRecipe: false, // Ce n'est pas une recette
                      );
                      
                      // Si c'est depuis le scanner IA (modification), utiliser onFoodSaved pour juste enregistrer
                      // Sinon, utiliser onFoodAdded pour ajouter directement (flux classique)
                      if (widget.onFoodSaved != null) {
                        final locService = Provider.of<LocalizationService>(context, listen: false);
                        widget.onFoodSaved?.call(foodItem);
                        Navigator.pop(context);
                        SnackBarUtils.showSuccessSnackBar(
                          context,
                          message: locService.currentLanguageCode == 'fr' 
                            ? '${widget.name} enregistré${_isModified ? ' (modifié)' : ''}' 
                            : '${widget.name} saved${_isModified ? ' (modified)' : ''}',
                        );
                      } else {
                        // Flux classique - ajouter directement au repas
                        Navigator.pop(context); // Fermer le bottom sheet AVANT d'appeler le callback
                        widget.onFoodAdded?.call(foodItem);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          widget.onFoodSaved != null ? 'save'.tr(locService.currentLanguageCode) : (_isModified ? 'confirm'.tr(locService.currentLanguageCode) : 'add'.tr(locService.currentLanguageCode)),
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
          ],
        ),
      ),
    );
  }
}

class _CreateFoodContent extends StatefulWidget {
  final Function(FoodItem)? onFoodCreated;

  const _CreateFoodContent({
    required this.onFoodCreated,
  });

  @override
  State<_CreateFoodContent> createState() => _CreateFoodContentState();
}

class _CreateFoodContentState extends State<_CreateFoodContent> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _proteinsController = TextEditingController(text: '0');
  final TextEditingController _glucidesController = TextEditingController(text: '0');
  final TextEditingController _lipidesController = TextEditingController(text: '0');
  final TextEditingController _quantityController = TextEditingController(text: '100');
  int _calculatedCalories = 0;

  @override
  void initState() {
    super.initState();
    // Écouter les changements pour recalculer automatiquement
    _proteinsController.addListener(_calculateCalories);
    _glucidesController.addListener(_calculateCalories);
    _lipidesController.addListener(_calculateCalories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinsController.dispose();
    _glucidesController.dispose();
    _lipidesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateCalories() {
    final proteins = double.tryParse(_proteinsController.text) ?? 0;
    final glucides = double.tryParse(_glucidesController.text) ?? 0;
    final lipides = double.tryParse(_lipidesController.text) ?? 0;
    
    setState(() {
      _calculatedCalories = ((proteins * 4) + (glucides * 4) + (lipides * 9)).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
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
                      'create_food'.tr(locService.currentLanguageCode),
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
            
            const SizedBox(height: 24),
            
            // Nom de l'aliment
            Container(
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
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      'food_name'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'food_name_placeholder'.tr(locService.currentLanguageCode),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Informations nutritionnelles pour 100g
            Container(
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
                children: [
                  // Calories (calculées automatiquement)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          locService.currentLanguageCode == 'fr' ? 'Calories (calculées auto)' : 'Calories (auto calculated)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_calculatedCalories kcal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
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
                      Container(
                        width: 80,
                        height: 32,
                        child: NumericTextField(
                          controller: _proteinsController,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            isDense: true,
                            suffixText: 'g',
                            suffixStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
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
                      Container(
                        width: 80,
                        height: 32,
                        child: NumericTextField(
                          controller: _glucidesController,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            isDense: true,
                            suffixText: 'g',
                            suffixStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
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
                      Container(
                        width: 80,
                        height: 32,
                        child: NumericTextField(
                          controller: _lipidesController,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            isDense: true,
                            suffixText: 'g',
                            suffixStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Boutons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    onTap: () async {
                      if (_nameController.text.trim().isEmpty) {
                        final locService = Provider.of<LocalizationService>(context, listen: false);
                        SnackBarUtils.showErrorSnackBar(
                          context,
                          message: locService.currentLanguageCode == 'fr' ? 'Veuillez saisir un nom d\'aliment' : 'Please enter a food name',
                        );
                        return;
                      }
                      
                      // Récupérer les valeurs actuelles des macronutriments depuis les contrôleurs
                      final proteins = double.tryParse(_proteinsController.text.isEmpty ? '0' : _proteinsController.text) ?? 0.0;
                      final carbs = double.tryParse(_glucidesController.text.isEmpty ? '0' : _glucidesController.text) ?? 0.0;
                      final fats = double.tryParse(_lipidesController.text.isEmpty ? '0' : _lipidesController.text) ?? 0.0;
                      
                      // Créer l'aliment personnalisé
                      final foodItem = FoodItem(
                        name: _nameController.text,
                        calories: _calculatedCalories,
                        proteins: proteins,
                        carbs: carbs,
                        fats: fats,
                        portion: '${_quantityController.text} g',
                        isModified: false, // Nouvel aliment = pas de modification
                        hasModifiedMacros: false, // Nouvel aliment = pas de modification de macros
                        isCustom: true, // Aliment créé manuellement
                        isRecipe: false, // Ce n'est pas une recette
                      );
                      
                      final itemName = _nameController.text;
                      final locService = Provider.of<LocalizationService>(context, listen: false);
                      
                      // Appeler le callback pour ajouter l'aliment
                      widget.onFoodCreated?.call(foodItem);
                      
                      // Fermer seulement le bottom sheet de création
                      Navigator.pop(context);
                      
                      // Afficher le message de confirmation
                      SnackBarUtils.showSuccessSnackBar(
                        context,
                        message: locService.currentLanguageCode == 'fr' ? '$itemName créé et ajouté au repas' : '$itemName created and added to meal',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          locService.currentLanguageCode == 'fr' ? 'Créer' : 'Create',
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
          ],
        ),
      ),
    );
  }
} 
