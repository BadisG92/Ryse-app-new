import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../models/ai_analysis_models.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../services/food_entries_service.dart';
import '../services/global_state_manager.dart';
import '../services/dashboard_service.dart';

class AIAnalysisScreen extends StatefulWidget {
  final String? imagePath; // Nullable pour le mode texte
  final String? note;
  final bool isFromDashboard;
  final String? mealName;
  final String? mealId;
  final bool isFromTextInput; // Nouveau flag
  final AIAnalysisResult? analysisResult; // Résultats pré-calculés pour le mode texte

  const AIAnalysisScreen({
    super.key,
    this.imagePath, // Changé en optionnel
    this.note,
    this.isFromDashboard = false,
    this.mealName,
    this.mealId,
    this.isFromTextInput = false,
    this.analysisResult,
  });

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> with SingleTickerProviderStateMixin {
  late AIAnalysisResult _analysisResult;
  final TextEditingController _mealNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  // Valeurs animées pour le repas détecté uniquement
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _animatedCalories = 0;
  int _animatedProtein = 0;
  int _animatedCarbs = 0;
  int _animatedFat = 0;

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    if (widget.analysisResult != null) {
      // Mode texte : résultats déjà fournis
      _analysisResult = widget.analysisResult!;
      _mealNameController.text = _analysisResult.mealName ?? 'Repas';
      _isLoading = false;
      // Démarrer l'animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startAnimation();
      });
    } else if (widget.imagePath != null) {
      // Mode photo : analyser l'image
      _analyzeImage();
    } else {
      // Erreur : ni texte ni image
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    // Calculer les totaux du repas détecté
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (final food in _analysisResult.detectedFoods) {
      totalCalories += food.calories;
      totalProteins += food.nutrition.proteins;
      totalCarbs += food.nutrition.carbs;
      totalFats += food.nutrition.fats;
    }

    // Animer de 0 aux valeurs du repas
    _animation.addListener(() {
      setState(() {
        _animatedCalories = (totalCalories * _animation.value).round();
        _animatedProtein = (totalProteins * _animation.value).round();
        _animatedCarbs = (totalCarbs * _animation.value).round();
        _animatedFat = (totalFats * _animation.value).round();
      });
    });

    _animationController.forward();
  }

  Future<void> _analyzeImage() async {
    if (widget.imagePath == null) return;

    try {
      final file = File(widget.imagePath!);
      final result = await GeminiAnalysisServiceV2.analyzeImageWithFallback(
        file,
        userNote: widget.note,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _mealNameController.text = result.mealName ?? 'Plat';
          _isLoading = false;
        });
        // Démarrer l'animation des barres
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _startAnimation();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisResult = AIAnalysisResult.error(
            error: 'Erreur d\'analyse: $e',
            processingTime: 0,
          );
          _isLoading = false;
        });
      }
    }
  }

  void _editFood(DetectedFood food) {
    EditableFoodDetailsBottomSheet.show(
      context,
      name: food.name,
      calories: food.calories,
      proteins: food.nutrition.proteins,
      glucides: food.nutrition.carbs,
      lipides: food.nutrition.fats,
      quantity: food.estimatedQuantity,
      isModified: false,
      onFoodSaved: (foodItem) {
        // Mettre à jour l'aliment dans la liste
        setState(() {
          final index = _analysisResult.detectedFoods.indexOf(food);
          if (index != -1) {
            final updatedFood = DetectedFood.fromAIResponse(
              name: foodItem.name,
              confidence: food.confidence,
              portionGrams: foodItem.referenceQuantity ?? 100.0,
              proteins: foodItem.proteins,
              carbs: foodItem.carbs,
              fats: foodItem.fats,
              isLiquid: food.isLiquid,
            );
            _analysisResult.detectedFoods[index] = updatedFood;
          }
        });
        // Redémarrer l'animation avec les nouvelles valeurs
        _restartAnimation();
      },
    );
  }

  void _deleteFood(DetectedFood food) {
    setState(() {
      _analysisResult.detectedFoods.remove(food);
    });

    // Si plus d'aliments, rediriger vers l'accueil
    if (_analysisResult.detectedFoods.isEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      final locService = LocalizationService.instance;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locService.currentLanguageCode == 'fr'
              ? 'Tous les aliments ont été supprimés'
              : 'All foods have been removed'
          ),
          backgroundColor: const Color(0xFF888888),
        ),
      );
    } else {
      // Redémarrer l'animation avec les nouvelles valeurs
      _restartAnimation();
    }
  }

  void _restartAnimation() {
    // Réinitialiser l'animation
    _animationController.reset();

    // Calculer les nouveaux totaux
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (final food in _analysisResult.detectedFoods) {
      totalCalories += food.calories;
      totalProteins += food.nutrition.proteins;
      totalCarbs += food.nutrition.carbs;
      totalFats += food.nutrition.fats;
    }

    // Animer de 0 aux nouvelles valeurs
    _animation.addListener(() {
      setState(() {
        _animatedCalories = (totalCalories * _animation.value).round();
        _animatedProtein = (totalProteins * _animation.value).round();
        _animatedCarbs = (totalCarbs * _animation.value).round();
        _animatedFat = (totalFats * _animation.value).round();
      });
    });

    _animationController.forward();
  }

  Future<void> _saveAllFoods() async {
    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (widget.mealName != null && widget.mealId != null) {
        // Ajouter directement au repas existant
        await _addToMeal(widget.mealName!, widget.mealId!);
      } else {
        // Afficher le sélecteur de repas
        if (!mounted) return;
        MealSelectionBottomSheet.show(
          context,
          foodName: _mealNameController.text,
          existingMeals: [], // TODO: Charger les repas existants si nécessaire
          onExistingMealSelected: (meal) async {
            await _addToMeal(meal.name, meal.id ?? '');
          },
          onCreateNewMeal: () {
            NewMealTypeBottomSheet.show(
              context,
              onMealTypeSelected: (mealType, time) async {
                await _createNewMealAndAdd(mealType, time);
              },
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_generic'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addToMeal(String mealName, String mealId) async {
    final user = Supabase.instance.client.auth.currentUser!;

    await FoodEntriesService.addAIFoodEntry(
      userId: user.id,
      mealName: mealName,
      detectedFoods: _analysisResult.detectedFoods,
      aiMealName: _mealNameController.text,
      mealId: mealId,
      consumedAt: DateTime.now(),
    );

    // Refresh global state
    await GlobalStateManager.instance.refreshMealsCount();
    await DashboardService.invalidateAndRefreshGoals();

    if (mounted) {
      // Retourner au dashboard
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Aliments ajoutés avec succès'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
  }

  Future<void> _createNewMealAndAdd(String mealType, String time) async {
    // Logique pour créer un nouveau repas
    final user = Supabase.instance.client.auth.currentUser!;
    final mealId = await FoodEntriesService.generateMealId(
      userId: user.id,
      mealName: mealType,
      forDate: DateTime.now(),
    );

    // Traduire le type de repas en nom
    final mealName = mealType; // Utiliser directement le type comme nom

    await _addToMeal(mealName, mealId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isFromTextInput
            ? 'ai_chat_results'.tr(locService.currentLanguageCode)
            : 'ai_analysis_results'.tr(locService.currentLanguageCode),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B132B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF0B132B),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analyse en cours...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : !_analysisResult.success
              ? _buildErrorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Champ nom du plat
                      _buildMealNameField(),

                      const SizedBox(height: 16),

                      // Titre "Votre repas" si mode texte
                      if (widget.isFromTextInput && widget.note != null) ...[
                        Text(
                          'your_meal'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildUserTextCard(),
                        const SizedBox(height: 16),
                      ],

                      // Image si mode photo
                      if (widget.imagePath != null) ...[
                        _buildImagePreview(),
                        const SizedBox(height: 16),
                      ],

                      // Résumé nutritionnel EN PREMIER
                      _buildNutritionalSummary(),

                      const SizedBox(height: 24),

                      // Liste des aliments détectés APRÈS
                      _buildFoodsList(),

                      const SizedBox(height: 80), // Espace pour le bouton flottant
                    ],
                  ),
                ),
      floatingActionButton: _analysisResult.success && !_isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAllFoods,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.plus, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'add_all_foods'.tr(locService.currentLanguageCode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMealNameField() {
    final locService = LocalizationService.instance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec icône crayon à droite
          Row(
            children: [
              Expanded(
                child: Text(
                  'meal_name'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Icon(
                LucideIcons.pencil,
                size: 16,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _mealNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF0B132B), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: FileImage(File(widget.imagePath!)),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  // Card simple pour afficher le texte de l'utilisateur (sans gradient)
  Widget _buildUserTextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        widget.note ?? '',
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFoodsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aliments détectés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_analysisResult.detectedFoods.length} aliments',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _analysisResult.detectedFoods.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFoodItem(_analysisResult.detectedFoods[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItem(DetectedFood food) {
    final confidence = (food.confidence * 100).round();

    // EXACTEMENT le même design que ai_scanner_screen.dart (_buildDetectedFood)
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
                    Expanded(
                      child: Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        overflow: TextOverflow.ellipsis,
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
                  '${food.calories} kcal • ${food.estimatedQuantity.round()}${food.isLiquid ? 'ml' : 'g'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton édition
              GestureDetector(
                onTap: () => _editFood(food),
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
              const SizedBox(width: 4),
              // Bouton suppression (croix comme dans le journal)
              GestureDetector(
                onTap: () => _deleteFood(food),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionalSummary() {
    final locService = LocalizationService.instance;

    // Design hybride : Barre calories + 3 cercles macros
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                size: 16,
                color: Color(0xFF0B132B),
              ),
              const SizedBox(width: 8),
              Text(
                'nutritional_summary'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cercle avec gradient pour les calories (comme tableau de bord)
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_animatedCalories',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3 valeurs de macros sans cercle (comme dans le journal)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroValue(
                name: 'proteins'.tr(locService.currentLanguageCode),
                value: _animatedProtein,
                unit: 'g',
              ),
              _buildMacroValue(
                name: 'carbohydrates'.tr(locService.currentLanguageCode),
                value: _animatedCarbs,
                unit: 'g',
              ),
              _buildMacroValue(
                name: 'fats'.tr(locService.currentLanguageCode),
                value: _animatedFat,
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroValue({
    required String name,
    required int value,
    required String unit,
  }) {
    return Column(
      children: [
        // Valeur (comme dans le journal)
        Text(
          '$value$unit',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B132B),
          ),
        ),
        const SizedBox(height: 4),
        // Nom du macro
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.info,
            size: 64,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          const Text(
            'Erreur d\'analyse',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _analysisResult.error ?? 'Une erreur est survenue',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}