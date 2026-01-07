import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/gemini_config.dart';
import '../models/nutrition_analysis.dart';
import '../models/nutrition_models.dart';
import 'package:intl/intl.dart';
import 'coach_personality_service.dart';

/// Service pour l'analyse nutritionnelle IA avec Coach Ryze et Gemini 2.0 Flash
class CoachRyzeNutritionService {
  static late GenerativeModel _model;
  static final _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  /// Initialise le modèle Gemini
  static void initialize() {
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1200,
      ),
    );
  }

  /// Détecte le contexte intelligent pour l'analyse
  static Future<String> detectContext({
    required List<Meal> todayMeals,
    required bool hasWorkoutToday,
    required DateTime? workoutTime,
  }) async {
    final now = DateTime.now();
    final hour = now.hour;

    // Vérifier si la journée est vide (aucun repas)
    final totalCalories = todayMeals.fold<int>(
      0,
      (sum, meal) => sum + meal.items.fold<int>(0, (s, item) => s + item.calories),
    );

    if (totalCalories == 0) {
      return 'empty_day';
    }

    // Contexte post-workout (dans les 2h après l'entraînement)
    if (hasWorkoutToday && workoutTime != null) {
      final hoursSinceWorkout = now.difference(workoutTime).inHours;
      if (hoursSinceWorkout >= 0 && hoursSinceWorkout <= 2) {
        return 'post_workout';
      }
    }

    // Contexte fin de journée (après 20h ou au moins 3 repas)
    final mealCount = todayMeals
        .where((meal) => meal.items.isNotEmpty)
        .length;

    if (hour >= 22 || mealCount >= 3) {
      return 'end_of_day';
    }

    // Par défaut : journée en cours
    return 'in_progress';
  }

  /// Récupère la dernière analyse pour une date donnée
  static Future<NutritionAnalysis?> getAnalysisForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final response = await _supabase
          .from('nutrition_analyses')
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return NutritionAnalysis.fromJson(response);
    } catch (e) {
      debugPrint('❌ Erreur récupération analyse: $e');
      return null;
    }
  }

  /// Génère une nouvelle analyse nutritionnelle
  static Future<NutritionAnalysis> generateAnalysis({
    required String userId,
    required DateTime date,
    required List<Meal> todayMeals,
    required int calorieTarget,
    required double proteinTarget,
    required double carbsTarget,
    required double fatsTarget,
    required int waterIntake,
    required bool hasWorkoutToday,
    String? workoutType,
    int? caloriesBurned,
    DateTime? workoutTime,
    required String languageCode,
  }) async {
    // Détection du contexte
    final context = await detectContext(
      todayMeals: todayMeals,
      hasWorkoutToday: hasWorkoutToday,
      workoutTime: workoutTime,
    );

    // Calculer les métriques nutritionnelles
    final metadata = _calculateMetadata(
      todayMeals: todayMeals,
      calorieTarget: calorieTarget,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatsTarget: fatsTarget,
      waterIntake: waterIntake,
      hasWorkoutToday: hasWorkoutToday,
      workoutType: workoutType,
      caloriesBurned: caloriesBurned,
      workoutTime: workoutTime,
    );

    // Construire le prompt adaptatif
    final prompt = await _buildPrompt(
      context: context,
      metadata: metadata,
      todayMeals: todayMeals,
      languageCode: languageCode,
    );

    // LOG: Afficher le prompt
    debugPrint('🍎 ========== GEMINI NUTRITION PROMPT ==========');
    debugPrint('📅 Date: ${DateFormat('yyyy-MM-dd').format(date)}');
    debugPrint('🌍 Langue: $languageCode');
    debugPrint('🎯 Contexte: $context');
    debugPrint('📊 Calories: ${metadata.totalCalories}/${metadata.calorieTarget}');
    debugPrint('');
    debugPrint('📄 PROMPT COMPLET:');
    debugPrint('─' * 50);
    debugPrint(prompt);
    debugPrint('─' * 50);
    debugPrint('');

    // Appeler Gemini
    final content = [Content.text(prompt)];
    debugPrint('⏳ Envoi de la requête à Gemini...');
    final response = await _model.generateContent(content);

    // LOG: Afficher la réponse
    debugPrint('');
    debugPrint('✅ ========== GEMINI NUTRITION RESPONSE ==========');
    if (response.text != null && response.text!.isNotEmpty) {
      debugPrint('📝 Réponse reçue (${response.text!.length} caractères):');
      debugPrint('─' * 50);
      debugPrint(response.text);
      debugPrint('─' * 50);
    } else {
      debugPrint('❌ Aucune réponse reçue de Gemini');
    }
    debugPrint('');

    if (response.text == null || response.text!.isEmpty) {
      throw Exception(
        languageCode == 'fr'
            ? 'Impossible de générer l\'analyse'
            : 'Failed to generate analysis',
      );
    }

    // Parser le JSON de Gemini
    String analysisText = '';
    List<String> insights = [];
    List<String> recommendations = [];

    try {
      // Nettoyer la réponse (enlever les backticks markdown si présents)
      String cleanedResponse = response.text!.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      debugPrint('🔍 Parsing JSON response...');
      final jsonData = json.decode(cleanedResponse) as Map<String, dynamic>;

      // Extraire l'analyse
      analysisText = jsonData['analysis'] as String? ?? '';
      debugPrint('✅ Analysis extracted: ${analysisText.length} characters');

      // Extraire les recommandations
      if (jsonData['recommendations'] is List) {
        final recosList = jsonData['recommendations'] as List<dynamic>;
        for (final reco in recosList) {
          if (reco is Map<String, dynamic>) {
            final title = reco['title'] as String? ?? '';
            final description = reco['description'] as String? ?? '';
            if (title.isNotEmpty) {
              // Format: **Titre**\nDescription
              recommendations.add('**$title**\n$description');
            }
          }
        }
        debugPrint('✅ ${recommendations.length} recommendations extracted');
      }

      // Extraire les insights (premières phrases de l'analyse)
      insights = analysisText
          .split(RegExp(r'[.!?]\s+'))
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.trim())
          .take(3)
          .toList();

    } catch (e) {
      debugPrint('❌ Erreur parsing JSON: $e');
      debugPrint('📝 Réponse brute: ${response.text}');
      // Fallback: utiliser l'ancien système de parsing
      analysisText = response.text!;
      insights = _extractInsights(response.text!);
      recommendations = _extractRecommendations(response.text!);
    }

    // Créer l'analyse
    final analysis = NutritionAnalysis(
      id: _uuid.v4(),
      userId: userId,
      date: date,
      timestamp: DateTime.now(),
      context: context,
      analysisText: analysisText,
      score: _calculateScore(metadata),
      insights: insights,
      recommendations: recommendations,
      metadata: metadata,
    );

    // Sauvegarder dans Supabase
    await _saveAnalysis(analysis);

    return analysis;
  }

  /// Calcule les métadonnées nutritionnelles
  static NutritionMetadata _calculateMetadata({
    required List<Meal> todayMeals,
    required int calorieTarget,
    required double proteinTarget,
    required double carbsTarget,
    required double fatsTarget,
    required int waterIntake,
    required bool hasWorkoutToday,
    String? workoutType,
    int? caloriesBurned,
    DateTime? workoutTime,
  }) {
    int totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    int breakfastCal = 0;
    int lunchCal = 0;
    int dinnerCal = 0;
    int snacksCal = 0;

    for (final meal in todayMeals) {
      final mealCalories = meal.items.fold<int>(0, (sum, item) => sum + item.calories);
      final mealProteins = meal.items.fold<double>(0, (sum, item) => sum + item.proteins);
      final mealCarbs = meal.items.fold<double>(0, (sum, item) => sum + item.carbs);
      final mealFats = meal.items.fold<double>(0, (sum, item) => sum + item.fats);

      totalCalories += mealCalories;
      totalProteins += mealProteins;
      totalCarbs += mealCarbs;
      totalFats += mealFats;

      if (meal.mealType != null) {
        switch (meal.mealType) {
          case 'breakfast':
            breakfastCal += mealCalories;
            break;
          case 'lunch':
            lunchCal += mealCalories;
            break;
          case 'dinner':
            dinnerCal += mealCalories;
            break;
          case 'snack':
            snacksCal += mealCalories;
            break;
        }
      }
    }

    final caloriesRemaining = calorieTarget - totalCalories;
    final proteinPercentage = proteinTarget > 0 ? ((totalProteins / proteinTarget) * 100).toDouble() : 0.0;
    final carbsPercentage = carbsTarget > 0 ? ((totalCarbs / carbsTarget) * 100).toDouble() : 0.0;
    final fatsPercentage = fatsTarget > 0 ? ((totalFats / fatsTarget) * 100).toDouble() : 0.0;

    // Déterminer le moment de la journée
    final hour = DateTime.now().hour;
    String timeOfDay;
    if (hour < 12) {
      timeOfDay = 'morning';
    } else if (hour < 18) {
      timeOfDay = 'afternoon';
    } else if (hour < 22) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }

    return NutritionMetadata(
      totalCalories: totalCalories,
      totalProteins: totalProteins,
      totalCarbs: totalCarbs,
      totalFats: totalFats,
      waterIntake: waterIntake,
      calorieTarget: calorieTarget,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatsTarget: fatsTarget,
      caloriesRemaining: caloriesRemaining,
      proteinPercentage: proteinPercentage,
      carbsPercentage: carbsPercentage,
      fatsPercentage: fatsPercentage,
      breakfastCalories: breakfastCal,
      lunchCalories: lunchCal,
      dinnerCalories: dinnerCal,
      snacksCalories: snacksCal,
      hasWorkoutToday: hasWorkoutToday,
      workoutType: workoutType,
      caloriesBurned: caloriesBurned,
      workoutTime: workoutTime,
      timeOfDay: timeOfDay,
    );
  }

  /// Construit le prompt adaptatif selon le contexte
  static Future<String> _buildPrompt({
    required String context,
    required NutritionMetadata metadata,
    required List<Meal> todayMeals,
    required String languageCode,
  }) async {
    // Get user's personality preference
    final personalityInstruction = await CoachPersonalityService.instance.buildPersonalityInstruction(languageCode);

    if (languageCode == 'de') {
      return _buildGermanPrompt(context, metadata, todayMeals, personalityInstruction);
    } else if (languageCode == 'fr') {
      return _buildFrenchPrompt(context, metadata, todayMeals, personalityInstruction);
    } else {
      return _buildEnglishPrompt(context, metadata, todayMeals, personalityInstruction);
    }
  }

  static String _buildFrenchPrompt(
    String context,
    NutritionMetadata metadata,
    List<Meal> todayMeals,
    String personalityInstruction,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Tu es Coach Ryze, un coach nutrition expert en fitness et alimentation saine.');
    buffer.writeln('');
    buffer.writeln(personalityInstruction);
    buffer.writeln('');

    // Contexte adaptatif
    switch (context) {
      case 'empty_day':
        buffer.writeln('CONTEXTE: Journée alimentaire vide - Il est ${_getTimeLabel(metadata.timeOfDay, true)} et l\'utilisateur n\'a encore rien mangé.');
        buffer.writeln('MISSION: Motive l\'utilisateur à commencer sa journée alimentaire.');
        break;

      case 'post_workout':
        buffer.writeln('CONTEXTE: Post-entraînement - L\'utilisateur vient de terminer une séance ${metadata.workoutType ?? 'de sport'} (${metadata.caloriesBurned ?? 0} kcal brûlées).');
        buffer.writeln('MISSION: Optimise la récupération avec des recommandations nutrition post-workout.');
        break;

      case 'end_of_day':
        buffer.writeln('CONTEXTE: Fin de journée - Bilan complet de la journée alimentaire.');
        buffer.writeln('MISSION: Analyse globale et conseils pour demain.');
        break;

      case 'in_progress':
      default:
        buffer.writeln('CONTEXTE: Journée en cours - Il est ${_getTimeLabel(metadata.timeOfDay, true)} et la journée alimentaire est en progression.');
        buffer.writeln('MISSION: Analyse l\'avancement et guide pour la suite de la journée.');
        break;
    }

    buffer.writeln('');
    buffer.writeln('⚠️ CONTRAINTES ABSOLUES:');
    buffer.writeln('- LONGUEUR: 120 mots MAXIMUM');
    buffer.writeln('- ANALYSE: 50-60 mots (2-3 phrases)');
    buffer.writeln('- RECOMMANDATIONS: 2 conseils × 30 mots max chacun');
    buffer.writeln('');

    // Données nutritionnelles
    buffer.writeln('DONNÉES NUTRITIONNELLES (${DateFormat('dd/MM/yyyy').format(DateTime.now())}):');
    buffer.writeln('');
    buffer.writeln('Calories: ${metadata.totalCalories} / ${metadata.calorieTarget} kcal (reste: ${metadata.caloriesRemaining})');
    buffer.writeln('Protéines: ${metadata.totalProteins.toStringAsFixed(1)}g / ${metadata.proteinTarget.toStringAsFixed(0)}g (${metadata.proteinPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Glucides: ${metadata.totalCarbs.toStringAsFixed(1)}g / ${metadata.carbsTarget.toStringAsFixed(0)}g (${metadata.carbsPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Lipides: ${metadata.totalFats.toStringAsFixed(1)}g / ${metadata.fatsTarget.toStringAsFixed(0)}g (${metadata.fatsPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Eau: ${metadata.waterIntake}ml');
    buffer.writeln('');

    // Répartition des repas
    buffer.writeln('RÉPARTITION:');
    if (metadata.breakfastCalories > 0) buffer.writeln('- Petit-déjeuner: ${metadata.breakfastCalories} kcal');
    if (metadata.lunchCalories > 0) buffer.writeln('- Déjeuner: ${metadata.lunchCalories} kcal');
    if (metadata.dinnerCalories > 0) buffer.writeln('- Dîner: ${metadata.dinnerCalories} kcal');
    if (metadata.snacksCalories > 0) buffer.writeln('- Collations: ${metadata.snacksCalories} kcal');
    buffer.writeln('');

    // Contexte sport si pertinent
    if (metadata.hasWorkoutToday) {
      buffer.writeln('SPORT AUJOURD\'HUI:');
      buffer.writeln('- Type: ${metadata.workoutType ?? 'Non spécifié'}');
      if (metadata.caloriesBurned != null) {
        buffer.writeln('- Dépense: ${metadata.caloriesBurned} kcal');
      }
      buffer.writeln('');
    }

    buffer.writeln('FORMAT DE RÉPONSE OBLIGATOIRE (JSON):');
    buffer.writeln('Réponds UNIQUEMENT avec ce format JSON exact:');
    buffer.writeln('');
    buffer.writeln('{');
    buffer.writeln('  "analysis": "Ton analyse en 50-60 mots",');
    buffer.writeln('  "recommendations": [');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Titre court (3-5 mots)",');
    buffer.writeln('      "description": "Description en 20-30 mots"');
    buffer.writeln('    },');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Titre court (3-5 mots)",');
    buffer.writeln('      "description": "Description en 20-30 mots"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('RÈGLES POUR L\'ANALYSE:');
    buffer.writeln('- 50-60 mots maximum');
    buffer.writeln('- Commence DIRECTEMENT par le constat principal');
    buffer.writeln('- Pas de préambule type "Analyse de ta journée..."');
    buffer.writeln('- Évalue l\'équilibre calorique et macros');
    buffer.writeln('- Adapte ton ton au contexte (motivation si vide, félicitations si bon, constructif si à améliorer)');
    buffer.writeln('');
    buffer.writeln('RÈGLES POUR LES RECOMMANDATIONS:');
    buffer.writeln('- Exactement 2 recommandations');
    buffer.writeln('- Titre: 3-5 mots');
    buffer.writeln('- Description: 20-30 mots avec action concrète et chiffres précis');
    buffer.writeln('');
    buffer.writeln('   Exemples selon contexte:');
    if (context == 'empty_day') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Démarre avec un petit-déjeuner",');
      buffer.writeln('     "description": "Prépare un petit-déjeuner équilibré de 400-500 kcal avec protéines, glucides complexes et fruits pour bien commencer la journée."');
      buffer.writeln('   }');
    } else if (context == 'post_workout') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Recharge en protéines",');
      buffer.writeln('     "description": "Consomme 20-30g de protéines dans les 2h post-workout avec un shaker ou du yaourt grec pour optimiser la récupération musculaire."');
      buffer.writeln('   }');
    } else if (context == 'end_of_day') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Dîner léger ce soir",');
      buffer.writeln('     "description": "Privilégie des protéines légères comme le poisson et des légumes pour un repas de 300-400 kcal qui favorise le sommeil."');
      buffer.writeln('   }');
    } else {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Booste tes légumes",');
      buffer.writeln('     "description": "Ajoute 150g de légumes variés à ton prochain repas pour augmenter l\'apport en fibres et micronutriments essentiels."');
      buffer.writeln('   }');
    }
    buffer.writeln('');
    buffer.writeln('STYLE:');
    buffer.writeln('- Ton bienveillant, encourageant et positif (jamais alarmiste)');
    buffer.writeln('- Tutoiement');
    buffer.writeln('- Phrases courtes et percutantes');
    buffer.writeln('- Chiffres précis');
    buffer.writeln('- AUCUN emoji');
    buffer.writeln('- Évite les points d\'exclamation agressifs');
    buffer.writeln('');
    buffer.writeln('⚠️ IMPORTANT: Réponds UNIQUEMENT avec le JSON, aucun autre texte avant ou après.');

    return buffer.toString();
  }

  static String _buildEnglishPrompt(
    String context,
    NutritionMetadata metadata,
    List<Meal> todayMeals,
    String personalityInstruction,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('You are Coach Ryze, an expert nutrition coach in fitness and healthy eating.');
    buffer.writeln('');
    buffer.writeln(personalityInstruction);
    buffer.writeln('');

    // Contexte adaptatif
    switch (context) {
      case 'empty_day':
        buffer.writeln('CONTEXT: Empty food day - It\'s ${_getTimeLabel(metadata.timeOfDay, false)} and the user hasn\'t eaten anything yet.');
        buffer.writeln('MISSION: Motivate the user to start their food day.');
        break;

      case 'post_workout':
        buffer.writeln('CONTEXT: Post-workout - User just finished a ${metadata.workoutType ?? 'workout'} session (${metadata.caloriesBurned ?? 0} kcal burned).');
        buffer.writeln('MISSION: Optimize recovery with post-workout nutrition recommendations.');
        break;

      case 'end_of_day':
        buffer.writeln('CONTEXT: End of day - Complete overview of the food day.');
        buffer.writeln('MISSION: Overall analysis and tips for tomorrow.');
        break;

      case 'in_progress':
      default:
        buffer.writeln('CONTEXT: Day in progress - It\'s ${_getTimeLabel(metadata.timeOfDay, false)} and the food day is progressing.');
        buffer.writeln('MISSION: Analyze progress and guide for the rest of the day.');
        break;
    }

    buffer.writeln('');
    buffer.writeln('⚠️ ABSOLUTE CONSTRAINTS:');
    buffer.writeln('- LENGTH: 120 words MAXIMUM');
    buffer.writeln('- ANALYSIS: 50-60 words (2-3 sentences)');
    buffer.writeln('- RECOMMENDATIONS: 2 tips × 30 words max each');
    buffer.writeln('');

    // Données nutritionnelles
    buffer.writeln('NUTRITION DATA (${DateFormat('MM/dd/yyyy').format(DateTime.now())}):');
    buffer.writeln('');
    buffer.writeln('Calories: ${metadata.totalCalories} / ${metadata.calorieTarget} kcal (remaining: ${metadata.caloriesRemaining})');
    buffer.writeln('Protein: ${metadata.totalProteins.toStringAsFixed(1)}g / ${metadata.proteinTarget.toStringAsFixed(0)}g (${metadata.proteinPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Carbs: ${metadata.totalCarbs.toStringAsFixed(1)}g / ${metadata.carbsTarget.toStringAsFixed(0)}g (${metadata.carbsPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Fats: ${metadata.totalFats.toStringAsFixed(1)}g / ${metadata.fatsTarget.toStringAsFixed(0)}g (${metadata.fatsPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Water: ${metadata.waterIntake}ml');
    buffer.writeln('');

    // Répartition des repas
    buffer.writeln('DISTRIBUTION:');
    if (metadata.breakfastCalories > 0) buffer.writeln('- Breakfast: ${metadata.breakfastCalories} kcal');
    if (metadata.lunchCalories > 0) buffer.writeln('- Lunch: ${metadata.lunchCalories} kcal');
    if (metadata.dinnerCalories > 0) buffer.writeln('- Dinner: ${metadata.dinnerCalories} kcal');
    if (metadata.snacksCalories > 0) buffer.writeln('- Snacks: ${metadata.snacksCalories} kcal');
    buffer.writeln('');

    // Contexte sport si pertinent
    if (metadata.hasWorkoutToday) {
      buffer.writeln('WORKOUT TODAY:');
      buffer.writeln('- Type: ${metadata.workoutType ?? 'Not specified'}');
      if (metadata.caloriesBurned != null) {
        buffer.writeln('- Burn: ${metadata.caloriesBurned} kcal');
      }
      buffer.writeln('');
    }

    buffer.writeln('MANDATORY RESPONSE FORMAT (JSON):');
    buffer.writeln('Respond ONLY with this exact JSON format:');
    buffer.writeln('');
    buffer.writeln('{');
    buffer.writeln('  "analysis": "Your analysis in 50-60 words",');
    buffer.writeln('  "recommendations": [');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Short title (3-5 words)",');
    buffer.writeln('      "description": "Description in 20-30 words"');
    buffer.writeln('    },');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Short title (3-5 words)",');
    buffer.writeln('      "description": "Description in 20-30 words"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('ANALYSIS RULES:');
    buffer.writeln('- 50-60 words maximum');
    buffer.writeln('- Start DIRECTLY with main observation');
    buffer.writeln('- No preamble like "Analysis of your day..."');
    buffer.writeln('- Evaluate caloric balance and macros');
    buffer.writeln('- Adapt tone to context (motivating if empty, congratulating if good, constructive if needs improvement)');
    buffer.writeln('');
    buffer.writeln('RECOMMENDATIONS RULES:');
    buffer.writeln('- Exactly 2 recommendations');
    buffer.writeln('- Title: 3-5 words');
    buffer.writeln('- Description: 20-30 words with concrete action and precise numbers');
    buffer.writeln('');
    buffer.writeln('   Examples by context:');
    if (context == 'empty_day') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Start with breakfast",');
      buffer.writeln('     "description": "Prepare a balanced 400-500 kcal breakfast with protein, complex carbs and fruits to start your day right."');
      buffer.writeln('   }');
    } else if (context == 'post_workout') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Protein recharge",');
      buffer.writeln('     "description": "Consume 20-30g protein within 2h post-workout with a shake or greek yogurt to optimize muscle recovery."');
      buffer.writeln('   }');
    } else if (context == 'end_of_day') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Light dinner tonight",');
      buffer.writeln('     "description": "Prioritize light proteins like fish and vegetables for a 300-400 kcal meal that promotes good sleep."');
      buffer.writeln('   }');
    } else {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Boost your vegetables",');
      buffer.writeln('     "description": "Add 150g of varied vegetables to your next meal to increase fiber and essential micronutrients intake."');
      buffer.writeln('   }');
    }
    buffer.writeln('');
    buffer.writeln('STYLE:');
    buffer.writeln('- Caring, encouraging and positive tone (never alarmist)');
    buffer.writeln('- Short and impactful sentences');
    buffer.writeln('- Precise numbers');
    buffer.writeln('- NO emojis');
    buffer.writeln('- Avoid aggressive exclamation marks');
    buffer.writeln('');
    buffer.writeln('⚠️ IMPORTANT: Respond ONLY with JSON, no other text before or after.');

    return buffer.toString();
  }

  static String _buildGermanPrompt(
    String context,
    NutritionMetadata metadata,
    List<Meal> todayMeals,
    String personalityInstruction,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Du bist Coach Ryze, ein Experte für Ernährungscoaching im Bereich Fitness und gesunde Ernährung.');
    buffer.writeln('');
    buffer.writeln(personalityInstruction);
    buffer.writeln('');

    // Kontextabhängig
    switch (context) {
      case 'empty_day':
        buffer.writeln('KONTEXT: Leerer Ernährungstag - Es ist ${_getTimeLabelGerman(metadata.timeOfDay)} und der Nutzer hat noch nichts gegessen.');
        buffer.writeln('MISSION: Motiviere den Nutzer, seinen Ernährungstag zu beginnen.');
        break;

      case 'post_workout':
        buffer.writeln('KONTEXT: Nach dem Training - Der Nutzer hat gerade ein ${metadata.workoutType ?? 'Training'} absolviert (${metadata.caloriesBurned ?? 0} kcal verbrannt).');
        buffer.writeln('MISSION: Optimiere die Erholung mit Ernährungsempfehlungen nach dem Training.');
        break;

      case 'end_of_day':
        buffer.writeln('KONTEXT: Tagesende - Komplette Übersicht des Ernährungstages.');
        buffer.writeln('MISSION: Gesamtanalyse und Tipps für morgen.');
        break;

      case 'in_progress':
      default:
        buffer.writeln('KONTEXT: Tag im Verlauf - Es ist ${_getTimeLabelGerman(metadata.timeOfDay)} und der Ernährungstag schreitet voran.');
        buffer.writeln('MISSION: Analysiere den Fortschritt und gib Hinweise für den Rest des Tages.');
        break;
    }

    buffer.writeln('');
    buffer.writeln('⚠️ ABSOLUTE EINSCHRÄNKUNGEN:');
    buffer.writeln('- LÄNGE: 120 Wörter MAXIMUM');
    buffer.writeln('- ANALYSE: 50-60 Wörter (2-3 Sätze)');
    buffer.writeln('- EMPFEHLUNGEN: 2 Tipps × max. 30 Wörter jeweils');
    buffer.writeln('');

    // Ernährungsdaten
    buffer.writeln('ERNÄHRUNGSDATEN (${DateFormat('dd.MM.yyyy').format(DateTime.now())}):');
    buffer.writeln('');
    buffer.writeln('Kalorien: ${metadata.totalCalories} / ${metadata.calorieTarget} kcal (verbleibend: ${metadata.caloriesRemaining})');
    buffer.writeln('Protein: ${metadata.totalProteins.toStringAsFixed(1)}g / ${metadata.proteinTarget.toStringAsFixed(0)}g (${metadata.proteinPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Kohlenhydrate: ${metadata.totalCarbs.toStringAsFixed(1)}g / ${metadata.carbsTarget.toStringAsFixed(0)}g (${metadata.carbsPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Fette: ${metadata.totalFats.toStringAsFixed(1)}g / ${metadata.fatsTarget.toStringAsFixed(0)}g (${metadata.fatsPercentage.toStringAsFixed(0)}%)');
    buffer.writeln('Wasser: ${metadata.waterIntake}ml');
    buffer.writeln('');

    // Mahlzeitenverteilung
    buffer.writeln('VERTEILUNG:');
    if (metadata.breakfastCalories > 0) buffer.writeln('- Frühstück: ${metadata.breakfastCalories} kcal');
    if (metadata.lunchCalories > 0) buffer.writeln('- Mittagessen: ${metadata.lunchCalories} kcal');
    if (metadata.dinnerCalories > 0) buffer.writeln('- Abendessen: ${metadata.dinnerCalories} kcal');
    if (metadata.snacksCalories > 0) buffer.writeln('- Snacks: ${metadata.snacksCalories} kcal');
    buffer.writeln('');

    // Sport-Kontext wenn relevant
    if (metadata.hasWorkoutToday) {
      buffer.writeln('TRAINING HEUTE:');
      buffer.writeln('- Art: ${metadata.workoutType ?? 'Nicht angegeben'}');
      if (metadata.caloriesBurned != null) {
        buffer.writeln('- Verbrauch: ${metadata.caloriesBurned} kcal');
      }
      buffer.writeln('');
    }

    buffer.writeln('PFLICHT-ANTWORTFORMAT (JSON):');
    buffer.writeln('Antworte NUR mit diesem exakten JSON-Format:');
    buffer.writeln('');
    buffer.writeln('{');
    buffer.writeln('  "analysis": "Deine Analyse in 50-60 Wörtern",');
    buffer.writeln('  "recommendations": [');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Kurzer Titel (3-5 Wörter)",');
    buffer.writeln('      "description": "Beschreibung in 20-30 Wörtern"');
    buffer.writeln('    },');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Kurzer Titel (3-5 Wörter)",');
    buffer.writeln('      "description": "Beschreibung in 20-30 Wörtern"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('REGELN FÜR DIE ANALYSE:');
    buffer.writeln('- Maximal 50-60 Wörter');
    buffer.writeln('- Beginne DIREKT mit der Hauptbeobachtung');
    buffer.writeln('- Keine Einleitung wie "Analyse deines Tages..."');
    buffer.writeln('- Bewerte Kalorienbilanz und Makros');
    buffer.writeln('- Passe den Ton dem Kontext an (motivierend wenn leer, gratulierend wenn gut, konstruktiv wenn verbesserungswürdig)');
    buffer.writeln('');
    buffer.writeln('REGELN FÜR EMPFEHLUNGEN:');
    buffer.writeln('- Genau 2 Empfehlungen');
    buffer.writeln('- Titel: 3-5 Wörter');
    buffer.writeln('- Beschreibung: 20-30 Wörter mit konkreter Aktion und genauen Zahlen');
    buffer.writeln('');
    buffer.writeln('   Beispiele je nach Kontext:');
    if (context == 'empty_day') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Starte mit dem Frühstück",');
      buffer.writeln('     "description": "Bereite ein ausgewogenes Frühstück mit 400-500 kcal mit Protein, komplexen Kohlenhydraten und Obst vor, um gut in den Tag zu starten."');
      buffer.writeln('   }');
    } else if (context == 'post_workout') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Protein auftanken",');
      buffer.writeln('     "description": "Nimm innerhalb von 2 Stunden nach dem Training 20-30g Protein mit einem Shake oder griechischem Joghurt zu dir, um die Muskelregeneration zu optimieren."');
      buffer.writeln('   }');
    } else if (context == 'end_of_day') {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Leichtes Abendessen heute",');
      buffer.writeln('     "description": "Bevorzuge leichte Proteine wie Fisch und Gemüse für eine Mahlzeit mit 300-400 kcal, die einen guten Schlaf fördert."');
      buffer.writeln('   }');
    } else {
      buffer.writeln('   {');
      buffer.writeln('     "title": "Mehr Gemüse essen",');
      buffer.writeln('     "description": "Füge deiner nächsten Mahlzeit 150g verschiedenes Gemüse hinzu, um die Ballaststoff- und Mikronährstoffzufuhr zu erhöhen."');
      buffer.writeln('   }');
    }
    buffer.writeln('');
    buffer.writeln('STIL:');
    buffer.writeln('- Fürsorglicher, ermutigender und positiver Ton (niemals alarmistisch)');
    buffer.writeln('- Duzen');
    buffer.writeln('- Kurze und wirkungsvolle Sätze');
    buffer.writeln('- Genaue Zahlen');
    buffer.writeln('- KEINE Emojis');
    buffer.writeln('- Vermeide aggressive Ausrufezeichen');
    buffer.writeln('');
    buffer.writeln('⚠️ WICHTIG: Antworte NUR mit dem JSON, kein anderer Text davor oder danach.');

    return buffer.toString();
  }

  /// Helper für deutsche Zeit-Labels
  static String _getTimeLabelGerman(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning': return 'Morgen';
      case 'afternoon': return 'Nachmittag';
      case 'evening': return 'Abend';
      case 'night': return 'Nacht';
      default: return '';
    }
  }

  /// Helper pour les labels de temps
  static String _getTimeLabel(String timeOfDay, bool isFrench) {
    if (isFrench) {
      switch (timeOfDay) {
        case 'morning': return 'le matin';
        case 'afternoon': return 'l\'après-midi';
        case 'evening': return 'le soir';
        case 'night': return 'la nuit';
        default: return '';
      }
    } else {
      switch (timeOfDay) {
        case 'morning': return 'morning';
        case 'afternoon': return 'afternoon';
        case 'evening': return 'evening';
        case 'night': return 'night';
        default: return '';
      }
    }
  }

  /// Extrait les insights du texte d'analyse
  static List<String> _extractInsights(String analysisText) {
    // Parsing simple : prendre les phrases avant "Recommandations"
    final parts = analysisText.split('**Recommandations**');
    if (parts.isEmpty) return [];

    final analysisPart = parts[0].trim();
    final sentences = analysisPart
        .split(RegExp(r'[.!?]\s+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .take(3)
        .toList();

    return sentences;
  }

  /// Extrait les recommandations du texte d'analyse
  static List<String> _extractRecommendations(String analysisText) {
    // Parsing simple : prendre ce qui est après "Recommandations"
    final parts = analysisText.split('**Recommandations**');
    if (parts.length < 2) return [];

    final recoPart = parts[1].trim();
    final recos = recoPart
        .split(RegExp(r'\n\n+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .take(2)
        .toList();

    return recos;
  }

  /// Calcule un score nutritionnel (0-100)
  static double? _calculateScore(NutritionMetadata metadata) {
    // Score basé sur l'atteinte des objectifs
    double score = 0;

    // Calories (40 points) : pénalité si trop bas ou trop haut
    final calorieRatio = metadata.totalCalories / metadata.calorieTarget;
    if (calorieRatio >= 0.9 && calorieRatio <= 1.1) {
      score += 40; // Dans la cible ±10%
    } else if (calorieRatio >= 0.8 && calorieRatio <= 1.2) {
      score += 30; // Acceptable ±20%
    } else if (calorieRatio >= 0.7 && calorieRatio <= 1.3) {
      score += 20; // Loin ±30%
    } else {
      score += 10; // Très loin
    }

    // Protéines (20 points)
    if (metadata.proteinPercentage >= 90) {
      score += 20;
    } else if (metadata.proteinPercentage >= 70) {
      score += 15;
    } else if (metadata.proteinPercentage >= 50) {
      score += 10;
    } else {
      score += 5;
    }

    // Glucides (20 points)
    if (metadata.carbsPercentage >= 80 && metadata.carbsPercentage <= 120) {
      score += 20;
    } else if (metadata.carbsPercentage >= 60 && metadata.carbsPercentage <= 140) {
      score += 15;
    } else {
      score += 10;
    }

    // Lipides (20 points)
    if (metadata.fatsPercentage >= 80 && metadata.fatsPercentage <= 120) {
      score += 20;
    } else if (metadata.fatsPercentage >= 60 && metadata.fatsPercentage <= 140) {
      score += 15;
    } else {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Sauvegarde l'analyse dans Supabase
  static Future<void> _saveAnalysis(NutritionAnalysis analysis) async {
    try {
      await _supabase
          .from('nutrition_analyses')
          .insert(analysis.toJson());

      debugPrint('✅ Analyse sauvegardée: ${analysis.id}');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde analyse: $e');
      rethrow;
    }
  }

  /// Supprime une analyse
  static Future<void> deleteAnalysis(String analysisId) async {
    try {
      await _supabase
          .from('nutrition_analyses')
          .delete()
          .eq('id', analysisId);

      debugPrint('✅ Analyse supprimée: $analysisId');
    } catch (e) {
      debugPrint('❌ Erreur suppression analyse: $e');
      rethrow;
    }
  }

  /// Récupère toutes les analyses d'un utilisateur (historique)
  static Future<List<NutritionAnalysis>> getUserAnalyses({
    required String userId,
    int limit = 30,
  }) async {
    try {
      final response = await _supabase
          .from('nutrition_analyses')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => NutritionAnalysis.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération analyses: $e');
      return [];
    }
  }
}
