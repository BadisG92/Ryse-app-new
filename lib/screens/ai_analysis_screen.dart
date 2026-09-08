import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design/design.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/gemini_analysis_service_v2.dart';
import '../models/ai_analysis_models.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../bottom_sheets/add_ingredient_bottom_sheet.dart';
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

  /// Le vol de la photo : plein cadre pendant l'attente, puis elle rejoint sa
  /// place en haut du résultat. À 1, elle y est, et c'est la vignette de la
  /// liste qui la porte.
  late final AnimationController _land = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  bool _landed = false;

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
      _land.value = 1;
      _landed = true;
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
      _land.value = 1;
      _landed = true;
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _animationController.dispose();
    _land.dispose();
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
        _startLanding();
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
        _startLanding();
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
          backgroundColor: RyzeColors.mute2,
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

      // Si on connaît déjà le repas (via widget/dashboard) mais sans meal_id, en générer un avant d'ajouter
      if (widget.mealName != null) {
        String? targetMealId = widget.mealId;
        if (targetMealId == null) {
          targetMealId = await FoodEntriesService.generateMealId(
            userId: user.id,
            mealName: widget.mealName!,
            forDate: DateTime.now(),
          );
        }

        if (targetMealId != null) {
          await _addToMeal(widget.mealName!, targetMealId);
          return;
        }
      }

      // Sinon, on retombe sur la sélection classique
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_generic'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: RyzeColors.danger,
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
      final detectedMealName = _analysisResult.mealName?.isNotEmpty == true
          ? _analysisResult.mealName!
          : (_mealNameController.text.isNotEmpty ? _mealNameController.text : null);
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

  /// La photo rejoint sa place. Sans photo, il n'y a rien à faire voler :
  /// l'écran s'ouvre directement sur le résultat.
  void _startLanding() {
    if (!mounted) return;
    if (widget.imagePath == null) {
      _land.value = 1;
      setState(() => _landed = true);
      return;
    }
    _land.forward().whenComplete(() {
      if (mounted) setState(() => _landed = true);
    });
  }

  /// La photo pendant l'attente, puis en vol.
  ///
  /// Elle tient l'écran entier, et c'est elle qui porte la ligne d'attente :
  /// un carré d'encre par-dessus le plat valait moins que le plat. Quand la
  /// réponse arrive, elle va se poser exactement où le résultat la montre —
  /// même rectangle, même rayon — puis la vignette de la liste prend le relais.
  Widget _flight(BuildContext context, String lang, double gutter) {
    final size = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    // Sa place dans le résultat : sous l'en-tête, en haut de la liste.
    final target = Rect.fromLTWH(
      gutter,
      safeTop + context.vw(2.1) + context.vw(9.7) + context.vw(2.6) + context.vw(2.1),
      size.width - gutter * 2,
      context.vw(46),
    );
    final full = Rect.fromLTWH(0, 0, size.width, size.height);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _land,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_land.value);
          final rect = Rect.lerp(full, target, t)!;
          final veil = 1 - t;
          return Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RyzeRadius.md * t),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(widget.imagePath!), fit: BoxFit.cover),
                      if (veil > 0.02)
                        Opacity(
                          opacity: veil,
                          child: RyzeBusy(
                            message: 'ai_reading_plate'.tr(lang),
                            background: RyzeColors.ink.withValues(alpha: 0.62),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final flying = widget.imagePath != null && !_landed;

    return Scaffold(
      backgroundColor: _isLoading ? RyzeColors.ink : RyzeColors.paper,
      body: Stack(
        children: [
          if (!_isLoading) Positioned.fill(child: _results(context, lang, gutter)),
          if (flying) _flight(context, lang, gutter),
          // Sans photo, l'attente n'a rien sur quoi s'incruster : elle reprend
          // le plein cadre sur l'encre.
          if (_isLoading && widget.imagePath == null)
            Positioned.fill(child: RyzeBusy(message: 'ai_reading_plate'.tr(lang), background: RyzeColors.ink)),
          if (_isLoading)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(9.7),
                      height: context.vw(9.7),
                      decoration: BoxDecoration(
                        color: RyzeColors.ink.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.surf),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Le résultat : l'en-tête, la vignette à sa place, puis ce que Ryze a lu.
  Widget _results(BuildContext context, String lang, double gutter) {
    return SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, context.vw(2.6)),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(9.7),
                      height: context.vw(9.7),
                      decoration: BoxDecoration(
                        color: RyzeColors.surf,
                        shape: BoxShape.circle,
                        border: Border.all(color: RyzeColors.line),
                      ),
                      child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.ink),
                    ),
                  ),
                  SizedBox(width: context.vw(3.6)),
                  Expanded(
                    child: Text(
                      widget.isFromTextInput ? 'ai_chat_results'.tr(lang) : 'ai_analysis_results'.tr(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 4.6, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_analysisResult.success
                  ? _buildErrorView()
                  : ListView(
                          padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, context.vw(6)),
                          children: [
                            if (widget.imagePath != null) ...[
                              // Tant que la photo vole, sa place est gardée vide :
                              // c'est elle qui vient s'y poser.
                              _landed ? _buildImagePreview() : SizedBox(height: context.vw(46)),
                              SizedBox(height: context.vw(4.6)),
                            ],
                            if (widget.isFromTextInput && widget.note != null) ...[
                              _buildUserTextCard(),
                              SizedBox(height: context.vw(4.6)),
                            ],
                            _buildMealNameField(),
                            SizedBox(height: context.vw(4.6)),
                            _buildNutritionalSummary(),
                            SizedBox(height: context.vw(6.2)),
                            _buildFoodsList(),
                          ],
                        ),
            ),
            if (_analysisResult.success)
              Container(
                padding: EdgeInsets.fromLTRB(gutter, context.vw(3.1), gutter, context.vw(4.6)),
                decoration: BoxDecoration(
                  color: RyzeColors.paper,
                  border: Border(top: BorderSide(color: RyzeColors.line)),
                ),
                child: Pressable(
                  onTap: _isSaving ? null : _saveAllFoods,
                  child: Container(
                    height: context.vw(13.3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RyzeColors.ink,
                      borderRadius: BorderRadius.circular(RyzeRadius.sm),
                      boxShadow: RyzeShadow.soft,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: context.vw(4.6),
                            height: context.vw(4.6),
                            child: CircularProgressIndicator(strokeWidth: 2, color: RyzeColors.surf),
                          )
                        : Text(
                            'save_meal'.tr(lang),
                            style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                          ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  /// Le nom du plat, modifiable sans qu'on ait à chercher comment.
  Widget _buildMealNameField() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('meal_name'.tr(lang), style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Container(
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.sm),
            border: Border.all(color: RyzeColors.line),
          ),
          child: TextField(
            controller: _mealNameController,
            textCapitalization: TextCapitalization.sentences,
            style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
            cursorColor: RyzeColors.ink,
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: Icon(LucideIcons.pencil, size: context.vw(4.1), color: RyzeColors.mute2),
              contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(RyzeRadius.md),
      child: SizedBox(
        height: context.vw(46),
        width: double.infinity,
        child: Image.file(File(widget.imagePath!), fit: BoxFit.cover),
      ),
    );
  }

  /// Ce que l'utilisateur a écrit au coach, rendu comme une citation.
  Widget _buildUserTextCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.6), context.vw(4.1), context.vw(3.6)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 3, height: context.vw(8), color: RyzeColors.idle),
          SizedBox(width: context.vw(3.1)),
          Expanded(
            child: Text(widget.note ?? '', style: RyzeText.body(context, 3.6, height: 1.5)),
          ),
        ],
      ),
    );
  }

  /// Ce qui compose le repas. Une ligne se tape pour la corriger, se balaie
  /// pour la retirer : plus de menu à trois points sur chacune.
  Widget _buildFoodsList() {
    final lang = LocalizationService.instance.currentLanguageCode;
    final foods = _analysisResult.detectedFoods;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('detected_foods'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
            Text('${foods.length}', style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
          ],
        ),
        SizedBox(height: context.vw(2.6)),
        for (final food in foods) ...[
          _buildFoodItem(food),
          SizedBox(height: context.vw(2.1)),
        ],
        Pressable(
          onTap: _showAddIngredientBottomSheet,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: context.vw(3.6)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: RyzeColors.idle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, size: context.vw(4.6), color: RyzeColors.ink),
                SizedBox(width: context.vw(2.1)),
                Text('add_ingredient'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }


  void _showAddIngredientBottomSheet() {
    AddIngredientBottomSheet.show(
      context,
      onIngredientAdded: (DetectedFood newFood) {
        setState(() {
          _analysisResult.detectedFoods.add(newFood);
        });
        // Redémarrer l'animation avec les nouvelles valeurs
        _restartAnimation();
        debugPrint('Nouvel ingrédient ajouté: ${newFood.name}');
      },
    );
  }

  Widget _buildFoodItem(DetectedFood food) {
    final lang = LocalizationService.instance.currentLanguageCode;
    // Ce que le coach n'est pas sûr d'avoir reconnu se dit en un mot, pas en
    // un pourcentage vert ou jaune que personne ne sait interpréter.
    final unsure = food.confidence < 0.9;

    return Dismissible(
      key: ValueKey('${food.name}-${food.calories}-${food.estimatedQuantity}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteFood(food),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: context.vw(5.1)),
        decoration: BoxDecoration(
          color: RyzeColors.danger,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
        ),
        child: Icon(LucideIcons.trash2, size: context.vw(4.6), color: RyzeColors.surf),
      ),
      child: Pressable(
        onTap: () {
          RyzeFeedback.select();
          _editFood(food);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                    ),
                    SizedBox(height: context.vw(0.5)),
                    Row(
                      children: [
                        Text(
                          '${food.estimatedQuantity.round()} ${food.isLiquid ? 'ml' : 'g'}',
                          style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                        ),
                        if (unsure) ...[
                          Text(' · ', style: RyzeText.body(context, 3.1, color: RyzeColors.mute2)),
                          Text(
                            'ai_to_confirm'.tr(lang),
                            style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.accInk),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.vw(2.6)),
              Text.rich(
                TextSpan(
                  style: RyzeText.body(context, 3.9, weight: FontWeight.w600).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: '${food.calories}'),
                    TextSpan(text: ' kcal', style: RyzeText.body(context, 3.0, color: RyzeColors.mute)),
                  ],
                ),
              ),
              SizedBox(width: context.vw(1.5)),
              Icon(Icons.chevron_right_rounded, size: 20, color: RyzeColors.mute2),
            ],
          ),
        ),
      ),
    );
  }

  /// Ce que pèse le repas, en un chiffre et trois rails. Les valeurs montent
  /// depuis zéro : c'est la seule animation de l'écran, et elle porte le
  /// résultat de l'analyse.
  Widget _buildNutritionalSummary() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Container(
      padding: EdgeInsets.all(context.vw(4.6)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'nutritional_summary'.tr(lang),
            style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
          ),
          SizedBox(height: context.vw(1.5)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RollingNumber('$_totalCalories', style: RyzeText.display(context, 11.5, weight: FontWeight.w600)),
              SizedBox(width: context.vw(2.1)),
              Text('kcal', style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
            ],
          ),
          SizedBox(height: context.vw(4.6)),
          _MealMacro(label: 'proteins'.tr(lang), grams: _animatedProtein, total: _macroTotal),
          SizedBox(height: context.vw(2.6)),
          _MealMacro(label: 'carbs'.tr(lang), grams: _animatedCarbs, total: _macroTotal),
          SizedBox(height: context.vw(2.6)),
          _MealMacro(label: 'fats'.tr(lang), grams: _animatedFat, total: _macroTotal),
        ],
      ),
    );
  }

  /// Le total du repas, tel quel : l'odomètre s'occupe de le faire monter.
  int get _totalCalories =>
      _analysisResult.detectedFoods.fold<double>(0, (sum, f) => sum + f.calories).round();

  /// La plus grosse des trois macros donne l'échelle : sans objectif à
  /// atteindre, un rail plein n'a pas de sens, mais la proportion en a.
  int get _macroTotal {
    final biggest = [_animatedProtein, _animatedCarbs, _animatedFat].reduce((a, b) => a > b ? a : b);
    return biggest == 0 ? 1 : biggest;
  }


  /// L'analyse n'a rien donné. Trois phrases codées en dur en français
  /// remplacées par le dictionnaire, et une sortie qui n'est pas juste un
  /// retour en arrière : décrire le plat au coach marche toujours.
  Widget _buildErrorView() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.vw(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.imageOff, size: context.vw(12.3), color: RyzeColors.mute2),
            SizedBox(height: context.vw(4.1)),
            Text(
              'ai_analysis_failed'.tr(lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 4.1, weight: FontWeight.w600, color: RyzeColors.mute),
            ),
            SizedBox(height: context.vw(1.5)),
            Text(
              _analysisResult.error ?? 'ai_analysis_failed_hint'.tr(lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 3.4, color: RyzeColors.mute2),
            ),
            SizedBox(height: context.vw(6.2)),
            Pressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: context.vw(13.3),
                padding: EdgeInsets.symmetric(horizontal: context.vw(8)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RyzeColors.ink,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  boxShadow: RyzeShadow.soft,
                ),
                child: Text(
                  'retake'.tr(lang),
                  style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une macro du repas : son nom, son rail en encre, ses grammes. Pas de
/// couleur par macro, comme partout ailleurs depuis la refonte.
class _MealMacro extends StatelessWidget {
  const _MealMacro({required this.label, required this.grams, required this.total});

  final String label;
  final int grams;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: context.vw(21),
          child: Text(label, style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: RyzeColors.mute)),
        ),
        Expanded(
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(3)),
                ),
                FractionallySizedBox(
                  widthFactor: (grams / total).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(color: RyzeColors.ink, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.vw(3.1)),
        SizedBox(
          width: context.vw(13),
          child: Text(
            '$grams g',
            textAlign: TextAlign.right,
            style: RyzeText.body(context, 3.3, weight: FontWeight.w600).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
