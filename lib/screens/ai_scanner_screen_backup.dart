import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../models/nutrition_models.dart';

class AIScannerScreen extends StatefulWidget {
  const AIScannerScreen({super.key});

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> {
  bool isAnalyzing = false;
  bool hasResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: hasResult ? _buildResultScreen() : _buildCameraScreen(),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Stack(
      children: [
        // Simulation de la vue caméra
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Vue caméra simulée',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        
        // Header
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  LucideIcons.flashlight,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        
        // Instructions
        Positioned(
          top: 100,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  LucideIcons.camera,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Prenez une photo de votre plat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Assurez-vous que le plat soit bien visible et éclairé',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        // Bouton de capture
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _takePicture,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isAnalyzing ? Colors.grey : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: isAnalyzing
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0B132B),
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(
                        LucideIcons.camera,
                        color: Colors.black,
                        size: 32,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
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
                const Expanded(
                  child: Text(
                    'Aliments détectés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Photo analysée
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.image,
                    size: 48,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Photo analysée',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Résultats de l'analyse
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text(
                  'Aliments détectés :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Aliments détectés (mockés)
                _buildDetectedFood(
                  name: 'Saumon grillé',
                  confidence: 95,
                  calories: 206,
                  quantity: '150g',
                ),
                const SizedBox(height: 12),
                _buildDetectedFood(
                  name: 'Riz basmati',
                  confidence: 88,
                  calories: 130,
                  quantity: '100g',
                ),
                const SizedBox(height: 12),
                _buildDetectedFood(
                  name: 'Brocolis',
                  confidence: 92,
                  calories: 25,
                  quantity: '80g',
                ),
              ],
            ),
          ),
          
          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aliments ajoutés au repas'),
                          backgroundColor: Color(0xFF0B132B),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajouter tous les aliments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        hasResult = false;
                        isAnalyzing = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFF0B132B),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reprendre une photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B132B),
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

  Widget _buildDetectedFood({
    required String name,
    required int confidence,
    required int calories,
    required String quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: confidence >= 90
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$confidence%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: confidence >= 90
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCA8A04),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal • $quantity',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _editDetectedFood(name, calories, quantity),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              child: const Icon(
                LucideIcons.edit,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editDetectedFood(String name, int baseCalories, String currentQuantity) {
    final quantity = double.tryParse(currentQuantity.replaceAll('g', '')) ?? 100;
    final calories = (baseCalories * quantity / 100).round();
    
    // Calcul des macronutriments (valeurs approximatives basées sur les calories)
    final protein = (calories * 0.15 / 4); // 15% des calories en protéines
    final carbs = (calories * 0.55 / 4); // 55% des calories en glucides  
    final fat = (calories * 0.30 / 9); // 30% des calories en lipides

    EditableFoodDetailsBottomSheet.show(
      context,
      name: name,
      calories: calories,
      proteins: protein,
      glucides: carbs,
      lipides: fat,
      quantity: quantity,
      isModified: false,
      onFoodAdded: (foodItem) {
        // TODO: Ajouter l'aliment au repas sélectionné (nécessite la sélection du repas)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${foodItem.name} ajouté au repas'),
            backgroundColor: const Color(0xFF0B132B),
          ),
        );
      },
    );
  }

  void _editDetectedFood_OLD(String name, int baseCalories, String currentQuantity) {
    final quantity = double.tryParse(currentQuantity.replaceAll('g', '')) ?? 100;
    final calories = (baseCalories * quantity / 100).round();
    
    // Calcul des macronutriments (valeurs approximatives basées sur les calories)
    final protein = (calories * 0.15 / 4); // 15% des calories en protéines
    final carbs = (calories * 0.55 / 4); // 55% des calories en glucides  
    final fat = (calories * 0.30 / 9); // 30% des calories en lipides

    EditableFoodDetailsBottomSheet.show(
      context,
      name: name,
      calories: calories,
      proteins: protein,
      glucides: carbs,
      lipides: fat,
      quantity: quantity,
      isModified: false,
      onFoodAdded: (foodItem) {
        // TODO: Ajouter l'aliment au repas sélectionné (nécessite la sélection du repas)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${foodItem.name} ajouté au repas'),
            backgroundColor: const Color(0xFF0B132B),
          ),
        );
      },
    );
  }

  void _takePicture() async {
    setState(() {
      isAnalyzing = true;
    });

    // Simulation de l'analyse
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isAnalyzing = false;
      hasResult = true;
    });
  }
} 