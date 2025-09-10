import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../models/nutrition_models.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../components/ui/snackbar_utils.dart';

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
    return Container(
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
          ),

          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de l'aliment
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
                  const SizedBox(height: 8),
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'food_name_placeholder'.tr(locService.currentLanguageCode),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: Color(0xFF3B82F6)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quantité de référence
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Quantité de référence' : 'Reference quantity',
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
                      // Quantité (non modifiable)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            _referenceQuantity.toStringAsFixed(_referenceQuantity.truncateToDouble() == _referenceQuantity ? 0 : 1),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Unité
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: _unitDefaults.keys.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: _onUnitChanged,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Texte explicatif
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' 
                        ? 'Les valeurs nutritionnelles ci-dessous doivent correspondre à cette quantité.' 
                        : 'The nutritional values below must correspond to this quantity.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
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
                        // Calories
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                          Text(
                                '${_getCalculatedCalories()} kcal',
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
                            SizedBox(
                              width: 60,
                              height: 32,
                              child: TextField(
                                controller: _proteinsController,
                                keyboardType: TextInputType.number,
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
                            SizedBox(
                              width: 60,
                              height: 32,
                              child: TextField(
                                controller: _carbsController,
                                keyboardType: TextInputType.number,
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
                            SizedBox(
                              width: 60,
                              height: 32,
                              child: TextField(
                                controller: _fatsController,
                                keyboardType: TextInputType.number,
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                    onTap: _isLoading ? null : _createCustomFood,
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
          ),
        ],
      ),
    );
  }
} 