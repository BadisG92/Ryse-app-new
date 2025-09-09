import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../models/ai_analysis_models.dart';
import 'dart:io';

class AIScannerScreen extends StatefulWidget {
  const AIScannerScreen({super.key});

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> {
  bool isAnalyzing = false;
  bool hasResult = false;
  bool showNoteInput = false;
  final TextEditingController _noteController = TextEditingController();
  String _aiNote = '';
  
  static const int maxNoteLength = 140; // Limite de caractères

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
        
        // Interface de saisie de note (si activée)
        if (showNoteInput)
          _buildNoteInputOverlay(),
        
        // Bouton de capture
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: showNoteInput ? null : _takePicture, // Désactiver si saisie de note
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (isAnalyzing || showNoteInput) ? Colors.grey : Colors.white,
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
                LucideIcons.pencil,
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

  Widget _buildNoteInputOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre
                const Text(
                  'Ajouter une note pour l\'IA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Décrivez votre plat pour améliorer la précision de l\'analyse',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Champ de saisie
                TextField(
                  controller: _noteController,
                  maxLength: maxNoteLength,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ex: Assiette de saumon 150g avec quinoa et haricots verts',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Boutons
                Row(
                  children: [
                    // Bouton Ignorer
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipNote,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ignorer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton Analyser
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _analyzeWithNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Analyser',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
      ),
    );
  }

  void _takePicture() async {
    setState(() {
      showNoteInput = true;
    });
  }

  void _skipNote() {
    setState(() {
      showNoteInput = false;
      _aiNote = '';
      _noteController.clear();
    });
    _analyzeImage();
  }

  void _analyzeWithNote() {
    setState(() {
      _aiNote = _noteController.text.trim();
      showNoteInput = false;
    });
    _analyzeImage();
  }

  void _analyzeImage() async {
    setState(() {
      isAnalyzing = true;
    });

    try {
      // Pour la simulation, on utilise un fichier fictif
      // Dans une vraie implémentation, on passerait le fichier image réel
      print('🤖 Analyse IA avec note: "$_aiNote"');
      
      // Utiliser le service d'analyse avec la note utilisateur
      final result = await GeminiAnalysisServiceV2.createMockAnalysisResult(
        userNote: _aiNote.isNotEmpty ? _aiNote : null,
      );
      
      if (result.success && result.detectedFoods.isNotEmpty) {
        // Traiter les résultats d'analyse
        _processAnalysisResults(result.detectedFoods);
      } else {
        // Afficher erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur d\'analyse: ${result.error}'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }

    } catch (e) {
      print('❌ Erreur lors de l\'analyse: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue lors de l\'analyse'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      isAnalyzing = false;
      hasResult = true;
    });
  }
  
  void _processAnalysisResults(List<DetectedFood> foods) {
    // Convertir les DetectedFood en données affichables
    // Pour l'instant on garde la logique mockée existante
    print('📊 Aliments détectés avec note utilisateur:');
    for (final food in foods) {
      print('  - ${food.name}: ${food.quantity}g (${food.confidence.toStringAsFixed(0)}%)');
    }
  }
} 
