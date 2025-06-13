import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/nutrition_models.dart';

class EditableFoodDetailsBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String name,
    required int calories,
    required double proteins,
    required double glucides,
    required double lipides,
    required double quantity,
    bool isModified = false,
    Function(FoodItem)? onFoodAdded,
    Function(FoodItem)? onFoodSaved,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditableFoodDetailsContent(
        name: name,
        calories: calories,
        proteins: proteins,
        glucides: glucides,
        lipides: lipides,
        quantity: quantity,
        isModified: isModified,
        onFoodAdded: onFoodAdded,
        onFoodSaved: onFoodSaved,
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
      builder: (context) => _CreateFoodContent(
        onFoodCreated: onFoodCreated,
      ),
    );
  }
}

class _EditableFoodDetailsContent extends StatefulWidget {
  final String name;
  final int calories;
  final double proteins;
  final double glucides;
  final double lipides;
  final double quantity;
  final bool isModified;
  final Function(FoodItem)? onFoodAdded;
  final Function(FoodItem)? onFoodSaved; // Nouveau callback pour enregistrer seulement

  const _EditableFoodDetailsContent({
    required this.name,
    required this.calories,
    required this.proteins,
    required this.glucides,
    required this.lipides,
    required this.quantity,
    required this.isModified,
    this.onFoodAdded,
    this.onFoodSaved,
  });

  @override
  State<_EditableFoodDetailsContent> createState() => _EditableFoodDetailsContentState();
}

class _EditableFoodDetailsContentState extends State<_EditableFoodDetailsContent> {
  bool _isEditing = false;
  late TextEditingController _proteinsController;
  late TextEditingController _glucidesController;
  late TextEditingController _lipidesController;
  late TextEditingController _quantityController;
  late int _calculatedCalories;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    // Calcul initial des macros à partir des calories (approximation)
    final proteins = (widget.calories * 0.1 / 4);
    final glucides = (widget.calories * 0.6 / 4);
    final lipides = (widget.calories * 0.3 / 9);
    
    _proteinsController = TextEditingController(text: proteins.toStringAsFixed(1));
    _glucidesController = TextEditingController(text: glucides.toStringAsFixed(1));
    _lipidesController = TextEditingController(text: lipides.toStringAsFixed(1));
    _quantityController = TextEditingController(text: '100');
    _calculatedCalories = widget.calories;
    
    // Écouter les changements pour recalculer automatiquement
    _proteinsController.addListener(_calculateCalories);
    _glucidesController.addListener(_calculateCalories);
    _lipidesController.addListener(_calculateCalories);
  }

  @override
  void dispose() {
    _proteinsController.dispose();
    _glucidesController.dispose();
    _lipidesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateCalories() {
    if (!_isEditing) return;
    
    final proteins = double.tryParse(_proteinsController.text) ?? 0;
    final glucides = double.tryParse(_glucidesController.text) ?? 0;
    final lipides = double.tryParse(_lipidesController.text) ?? 0;
    
    setState(() {
      _calculatedCalories = ((proteins * 4) + (glucides * 4) + (lipides * 9)).round();
      _isModified = true;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
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
                          const Text(
                            'Calories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          if (!_isEditing)
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
                        '${_isEditing ? _calculatedCalories : widget.calories} kcal',
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
                      const Text(
                        'Protéines',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      _isEditing
                          ? Container(
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
                            )
                          : Text(
                              '${_isModified ? _proteinsController.text : (widget.calories * 0.1 / 4).toStringAsFixed(1)}g',
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
                      const Text(
                        'Glucides',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      _isEditing
                          ? Container(
                              width: 60,
                              height: 32,
                              child: TextField(
                                controller: _glucidesController,
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
                            )
                          : Text(
                              '${_isModified ? _glucidesController.text : (widget.calories * 0.6 / 4).toStringAsFixed(1)}g',
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
                      const Text(
                        'Lipides',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      _isEditing
                          ? Container(
                              width: 60,
                              height: 32,
                              child: TextField(
                                controller: _lipidesController,
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
                            )
                          : Text(
                              '${_isModified ? _lipidesController.text : (widget.calories * 0.3 / 9).toStringAsFixed(1)}g',
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
                  const Text(
                    'Quantité',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            hintText: '100',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'grammes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
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
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B132B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Créer l'aliment avec les valeurs actuelles
                      final foodItem = FoodItem(
                        name: widget.name,
                        calories: _calculatedCalories,
                        portion: '${_quantityController.text}g',
                      );
                      
                      // Si c'est depuis le scanner IA (modification), utiliser onFoodSaved pour juste enregistrer
                      // Sinon, utiliser onFoodAdded pour ajouter directement (flux classique)
                      if (widget.onFoodSaved != null) {
                        widget.onFoodSaved?.call(foodItem);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.name} enregistré${_isModified ? ' (modifié)' : ''}'),
                            backgroundColor: const Color(0xFF0B132B),
                          ),
                        );
                      } else {
                        // Flux classique - ajouter directement au repas
                        widget.onFoodAdded?.call(foodItem);
                        // Note: Navigator.pop et SnackBar sont maintenant gérés dans le callback onFoodAdded
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.onFoodSaved != null ? 'Enregistrer' : (_isModified ? 'Confirmer' : 'Ajouter'),
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
                const Expanded(
                  child: Text(
                    'Créer un aliment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
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
                  const Text(
                    'Nom de l\'aliment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Mon plat spécial',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                      const Text(
                        'Calories (calculées auto)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
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
                      const Text(
                        'Protéines',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        width: 80,
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
                      const Text(
                        'Glucides',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 32,
                        child: TextField(
                          controller: _glucidesController,
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
                      const Text(
                        'Lipides',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 32,
                        child: TextField(
                          controller: _lipidesController,
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
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B132B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez saisir un nom d\'aliment'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Créer l'aliment personnalisé
                      final foodItem = FoodItem(
                        name: _nameController.text,
                        calories: _calculatedCalories,
                        portion: '${_quantityController.text}g',
                      );
                      
                      final itemName = _nameController.text;
                      
                      // Appeler le callback pour ajouter l'aliment
                      widget.onFoodCreated?.call(foodItem);
                      
                      // Fermer seulement le bottom sheet de création
                      Navigator.pop(context);
                      
                      // Afficher le message de confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$itemName créé et ajouté au repas'),
                          backgroundColor: const Color(0xFF0B132B),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Créer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
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
