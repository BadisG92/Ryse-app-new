import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/supabase_config.dart';
import '../models/coach_chat_models.dart';
import 'global_state_manager.dart';
import 'localization_service.dart';
import 'coach_personality_service.dart';

/// Builds rich user context for Coach Ryze AI
/// Aggregates data from multiple sources to create a comprehensive context
class CoachContextBuilder {
  static final CoachContextBuilder _instance = CoachContextBuilder._internal();
  static CoachContextBuilder get instance => _instance;

  CoachContextBuilder._internal();

  /// Build the complete system prompt with user context
  Future<String> buildSystemPrompt({
    UserCoachPreferences? preferences,
  }) async {
    final context = await buildUserContext();
    final prefsString = preferences?.toPromptString() ?? 'Aucune préférence enregistrée';

    final lang = LocalizationService.instance.currentLanguageCode;
    final isEnglish = lang == 'en';
    final isGerman = lang == 'de';

    // Get user's personality preference with gender context
    final userGender = context['userGender'] as String?;
    final personalityInstruction = await CoachPersonalityService.instance.buildPersonalityInstruction(lang, gender: userGender);

    return '''
Tu es Coach Ryze, le coach panda fitness et nutrition de ${context['userName']} dans l'app Ryse.

## TA MISSION
Tu connais tout de son parcours : ses repas, ses entraînements, sa progression. Tu es son allié au quotidien.

## TA PERSONNALITÉ (PRIORITÉ ABSOLUE)
$personalityInstruction

**RÈGLES DE BASE :**
- JAMAIS corporate ou robotique - tu parles comme un vrai coach, pas comme un assistant IA
- Jamais culpabilisant, même si les macros sont explosées
- Adapte ton ton à l'âge de l'utilisateur :
  - Ado/jeune (< 25 ans) : plus casual, vocabulaire jeune
  - Adulte (25-45 ans) : équilibré, pro mais détendu
  - Senior (> 45 ans) : respectueux, moins d'argot, plus posé

**ADAPTATION AU MESSAGE :**
- Message court de l'user → réponse courte
- Emojis dans le message → tu peux en mettre
- Question précise → réponse précise, pas de blabla

**ENGAGEMENT :**
- Pose des questions plutôt que des monologues
- Fais référence à ce que tu sais de l'utilisateur (ses préférences, son historique, ses motivations)

## CE QUE TU SAIS DE ${context['userName']} (MÉMOIRE IMPORTANTE)
$prefsString

## CONTEXTE TEMPS RÉEL
Heure actuelle: ${context['currentTime']}
Date: ${context['currentDate']}
Jour de la semaine: ${context['dayOfWeek']}

## BILAN DU JOUR DE ${context['userName']}
- Objectif calories: ${context['calorieGoal']} kcal
- Calories consommées: ${context['caloriesEaten']} kcal
- Calories restantes: ${context['caloriesRemaining']} kcal
- Protéines: ${context['proteinsEaten']}g / ${context['proteinsGoal']}g
- Glucides: ${context['carbsEaten']}g / ${context['carbsGoal']}g
- Lipides: ${context['fatsEaten']}g / ${context['fatsGoal']}g
- Eau: ${context['waterDrunk']}L / ${context['waterGoal']}L

## REPAS AUJOURD'HUI
${context['mealsToday']}

## PROFIL UTILISATEUR
- Sexe: ${context['userGender'] == 'female' ? 'Femme' : context['userGender'] == 'male' ? 'Homme' : 'Non renseigné'}
- Âge: ${context['userAge'] != null ? '${context['userAge']} ans' : 'Non renseigné'}
- Objectif: ${context['fitnessGoal']}
- Poids actuel: ${context['currentWeight']} kg → Objectif: ${context['targetWeight']} kg
- Niveau activité: ${context['activityLevel']}
- Streak actuel: ${context['streak']} jours 🔥

**IMPORTANT - GENRE**: ${context['userGender'] == 'female' ? 'L\'utilisateur est une FEMME. Utilise des accords féminins et un langage approprié (pas de "mec", "gars", etc.)' : context['userGender'] == 'male' ? 'L\'utilisateur est un HOMME. Tu peux utiliser un langage masculin casual si approprié.' : 'Genre non spécifié, utilise un langage neutre.'}

## HISTORIQUE REPAS (14 derniers jours)
${context['mealHistory14Days']}

## DERNIERS ENTRAÎNEMENTS (2 mois glissants)
**7 derniers workouts musculation:**
${context['recentWorkouts']}

**7 dernières activités cardio:**
${context['recentCardio']}

## FORMAT DE RÉPONSE - REPAS
Quand l'utilisateur demande une idée repas:

**ÉTAPE 1: Proposition courte** (TOUJOURS commencer par ça)
- Donne un conseil contextuel court basé sur son bilan
- Propose 1-2 idées de plats avec juste le nom et les macros approximatifs
- Demande s'il veut la recette détaillée

Exemple: "${isEnglish ? 'You have 450 kcal left and need protein. How about a **Greek chicken salad** (~380 kcal, 35g protein)? Want the recipe?' : isGerman ? 'Du hast noch 450 kcal übrig und brauchst Protein. Wie wäre es mit einem **Griechischen Hähnchensalat** (~380 kcal, 35g Protein)? Willst du das Rezept?' : 'Il te reste 450 kcal et tu manques de protéines. Que dis-tu d\'une **salade grecque au poulet** (~380 kcal, 35g prot) ? Tu veux la recette ?'}"

**ÉTAPE 2: Recette détaillée** (SEULEMENT si l'utilisateur dit oui)
🍳 [Nom]
📊 ~XXX kcal | P: Xg | G: Xg | L: Xg

${isEnglish ? 'Ingredients' : isGerman ? 'Zutaten' : 'Ingrédients'}: [liste courte]
${isEnglish ? 'Steps' : isGerman ? 'Schritte' : 'Étapes'}: [3-4 étapes max]

## FORMAT DE RÉPONSE - WORKOUT
Quand l'utilisateur demande un entraînement:

**Conseil contextuel court** puis propose un workout:

Exemple:
"${isEnglish ? 'Perfect timing! Here\'s a quick workout:' : isGerman ? 'Perfektes Timing! Hier ist ein schnelles Workout:' : 'Parfait timing ! Voici un workout rapide :'}"

💪 **[Nom du workout]** (~XX min)
- Exercice 1: 3x12
- Exercice 2: 3x10
- Exercice 3: 3x15

${isEnglish ? 'Go to the Sport tab to start!' : isGerman ? 'Gehe zum Sport-Tab, um zu starten!' : 'Va dans l\'onglet Sport pour le lancer !'}

## CE QUE TU NE FAIS PAS
- Sujets hors fitness/nutrition → "${isEnglish ? 'I\'m your fitness coach 💪 I stay focused on your goals! What can I help you with regarding training or nutrition?' : isGerman ? 'Ich bin dein Fitness-Coach 💪 Ich bleibe auf deine Ziele fokussiert! Was kann ich dir bei Training oder Ernährung helfen?' : 'Je suis ton coach fitness 💪 Je reste focus sur tes objectifs ! Qu\'est-ce que je peux faire pour toi côté entraînement ou nutrition ?'}"
- Conseils médicaux → "${isEnglish ? 'For that, consult a healthcare professional. I can help you with [related fitness/nutrition topic]' : isGerman ? 'Dafür wende dich an einen Arzt. Ich kann dir bei [Fitness/Ernährungsthema] helfen.' : 'Pour ça, consulte un professionnel de santé. Moi je peux t\'aider sur [sujet fitness/nutrition lié]'}"
- Jamais de jugement négatif

## RÈGLES DE LONGUEUR (TRÈS IMPORTANT)
- Réponses COURTES et CONCISES (max 150 mots)
- Pas de longs paragraphes, va droit au but
- Une idée par message, pas de surcharge d'infos
- Pose des questions pour engager plutôt que de tout donner d'un coup
- Utilise des listes courtes plutôt que des paragraphes

## LANGUE
${isEnglish ? 'Respond in English.' : isGerman ? 'Antworte auf Deutsch.' : 'Réponds en français.'}
''';
  }

  /// Build user context data from all sources
  Future<Map<String, dynamic>> buildUserContext() async {
    final globalState = GlobalStateManager.instance;
    final now = DateTime.now();
    final lang = LocalizationService.instance.currentLanguageCode;

    // Get user profile from Supabase
    final userProfile = await _getUserProfile();

    // Get today's meals
    final mealsToday = await _getMealsToday();

    // Get 14 days meal history
    final mealHistory = await _getMealHistory14Days();

    // Get recent workouts (7 last, 2 months)
    final recentWorkouts = await _getRecentWorkouts();

    // Get recent cardio (7 last, 2 months)
    final recentCardio = await _getRecentCardio();

    // Format day of week
    final dayOfWeek = _getDayOfWeek(now.weekday, lang);

    return {
      // Time context
      'currentTime': DateFormat('HH:mm').format(now),
      'currentDate': DateFormat('dd/MM/yyyy').format(now),
      'dayOfWeek': dayOfWeek,

      // User info
      'userName': globalState.userName,

      // Today's nutrition
      'calorieGoal': globalState.calorieGoal.toInt(),
      'caloriesEaten': globalState.currentCalories.toInt(),
      'caloriesRemaining': (globalState.calorieGoal - globalState.currentCalories).toInt(),
      'proteinsEaten': globalState.currentProteins.toInt(),
      'proteinsGoal': globalState.proteinGoal,
      'carbsEaten': globalState.currentCarbs.toInt(),
      'carbsGoal': globalState.carbsGoal,
      'fatsEaten': globalState.currentFats.toInt(),
      'fatsGoal': globalState.fatGoal,
      'waterDrunk': globalState.currentWaterL.toStringAsFixed(1),
      'waterGoal': globalState.waterGoalL.toStringAsFixed(1),

      // Today's meals
      'mealsToday': mealsToday,

      // Profile
      'fitnessGoal': userProfile['fitness_goal'] ?? 'maintain_weight',
      'currentWeight': userProfile['weight'] ?? 0,
      'targetWeight': userProfile['target_weight'] ?? userProfile['weight'] ?? 0,
      'activityLevel': userProfile['activity_level'] ?? 'moderate',
      'streak': globalState.currentStreak,
      'userAge': userProfile['age'],
      'userGender': userProfile['gender'],

      // History
      'mealHistory14Days': mealHistory,
      'recentWorkouts': recentWorkouts,
      'recentCardio': recentCardio,
    };
  }

  /// Get day of week in user's language
  String _getDayOfWeek(int weekday, String lang) {
    final days = lang == 'fr'
        ? ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche']
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Calculate age from date of birth
  int? _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return null;
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  /// Get user profile from Supabase
  Future<Map<String, dynamic>> _getUserProfile() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return {};

      final response = await client
          .from('users')
          .select('weight, fitness_goal, activity_level, target_weight, age, gender')
          .eq('id', user.id)
          .maybeSingle();

      if (kDebugMode) {
        debugPrint('👤 CoachContextBuilder: User profile loaded - gender: ${response?['gender']}');
      }

      return response ?? {};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachContextBuilder: Error getting user profile: $e');
      return {};
    }
  }

  /// Get today's meals formatted for context
  Future<String> _getMealsToday() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return 'Aucun repas enregistré aujourd\'hui';

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Récupérer les entrées avec les noms des aliments (via jointures)
      final response = await client
          .from('food_entries')
          .select('''
            meal_type, calories, proteins, carbs, fats, consumed_at, scanned_food_name,
            food_database:food_id(name_fr, name_en),
            custom_foods:custom_food_id(name)
          ''')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String())
          .order('consumed_at', ascending: true);

      if (response.isEmpty) {
        return 'Aucun repas enregistré aujourd\'hui';
      }

      // Group by meal type
      final mealGroups = <String, List<Map<String, dynamic>>>{};
      for (var entry in response) {
        final mealType = entry['meal_type'] as String? ?? 'snack';
        mealGroups.putIfAbsent(mealType, () => []);
        mealGroups[mealType]!.add(entry);
      }

      final buffer = StringBuffer();
      final mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
      final mealNames = {
        'breakfast': '🌅 Petit-déjeuner',
        'lunch': '☀️ Déjeuner',
        'dinner': '🌙 Dîner',
        'snack': '🍎 Snack',
      };

      for (var mealType in mealOrder) {
        if (mealGroups.containsKey(mealType)) {
          final foods = mealGroups[mealType]!;
          final totalCals = foods.fold<int>(0, (sum, f) => sum + ((f['calories'] as num?)?.toInt() ?? 0));
          buffer.writeln('${mealNames[mealType]} (~$totalCals kcal):');

          for (var food in foods) {
            // Récupérer le nom depuis food_database, custom_foods ou scanned_food_name
            String foodName = 'Aliment';
            if (food['food_database'] != null) {
              final db = food['food_database'];
              foodName = (db['name_fr'] as String?) ?? (db['name_en'] as String?) ?? 'Aliment';
            } else if (food['custom_foods'] != null && food['custom_foods']['name'] != null) {
              foodName = food['custom_foods']['name'] as String;
            } else if (food['scanned_food_name'] != null) {
              foodName = food['scanned_food_name'] as String;
            }
            final time = DateTime.parse(food['consumed_at'] as String);
            final timeStr = DateFormat('HH:mm').format(time);
            final cals = (food['calories'] as num?)?.toInt() ?? 0;
            buffer.writeln('  - $foodName ($cals kcal, $timeStr)');
          }
          buffer.writeln();
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachContextBuilder: Error getting today\'s meals: $e');
      return 'Erreur lors du chargement des repas';
    }
  }

  /// Get 14 days meal history to identify patterns
  Future<String> _getMealHistory14Days() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return 'Pas d\'historique disponible';

      final now = DateTime.now();
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      final response = await client
          .from('food_entries')
          .select('meal_type, calories, consumed_at')
          .eq('user_id', user.id)
          .gte('consumed_at', twoWeeksAgo.toIso8601String())
          .order('consumed_at', ascending: false)
          .limit(100);

      if (response.isEmpty) {
        return 'Pas d\'historique disponible';
      }

      // Calculate average daily calories and meal distribution
      final dailyCalories = <String, int>{};
      final mealCounts = <String, int>{};

      for (var entry in response) {
        final date = (entry['consumed_at'] as String).substring(0, 10);
        final calories = (entry['calories'] as num?)?.toInt() ?? 0;
        final mealType = entry['meal_type'] as String? ?? 'snack';

        dailyCalories[date] = (dailyCalories[date] ?? 0) + calories;
        mealCounts[mealType] = (mealCounts[mealType] ?? 0) + 1;
      }

      final avgCalories = dailyCalories.values.isNotEmpty
          ? (dailyCalories.values.reduce((a, b) => a + b) / dailyCalories.length).round()
          : 0;

      final buffer = StringBuffer();
      buffer.writeln('Derniers 14 jours:');
      buffer.writeln('- Moyenne: ~$avgCalories kcal/jour sur ${dailyCalories.length} jours trackés');
      buffer.writeln('- Petit-déj: ${mealCounts['breakfast'] ?? 0}x, Déj: ${mealCounts['lunch'] ?? 0}x, Dîner: ${mealCounts['dinner'] ?? 0}x, Snacks: ${mealCounts['snack'] ?? 0}x');

      return buffer.toString().trim();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachContextBuilder: Error getting meal history: $e');
      return 'Pas d\'historique disponible';
    }
  }

  /// Get 7 recent workouts from the last 2 months
  Future<String> _getRecentWorkouts() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return 'Aucun entraînement récent';

      final now = DateTime.now();
      final twoMonthsAgo = now.subtract(const Duration(days: 60));

      final response = await client
          .from('workout_session_summaries')
          .select('session_name, session_date, duration_minutes, calories_burned')
          .eq('user_id', user.id)
          .gte('session_date', twoMonthsAgo.toIso8601String().split('T')[0])
          .order('session_date', ascending: false)
          .limit(7);

      if (response.isEmpty) {
        return 'Aucun entraînement récent';
      }

      final buffer = StringBuffer();
      for (var workout in response) {
        final date = workout['session_date'] as String? ?? '';
        final name = workout['session_name'] as String? ?? 'Workout';
        final duration = workout['duration_minutes'] as int? ?? 0;
        final calories = workout['calories_burned'] as int? ?? 0;

        buffer.writeln('- $date: $name ($duration min, $calories kcal)');
      }

      return buffer.toString().trim();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachContextBuilder: Error getting recent workouts: $e');
      return 'Aucun entraînement récent';
    }
  }

  /// Get 7 recent cardio sessions from the last 2 months
  Future<String> _getRecentCardio() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return 'Aucune activité cardio récente';

      final now = DateTime.now();
      final twoMonthsAgo = now.subtract(const Duration(days: 60));

      final response = await client
          .from('cardio_sessions')
          .select('activity_title, session_date, duration_seconds, distance_km, calories')
          .eq('user_id', user.id)
          .eq('is_completed', true)
          .gte('start_time', twoMonthsAgo.toIso8601String())
          .order('start_time', ascending: false)
          .limit(7);

      if (response.isEmpty) {
        return 'Aucune activité cardio récente';
      }

      final buffer = StringBuffer();
      for (var cardio in response) {
        final date = cardio['session_date'] as String? ?? '';
        final activity = cardio['activity_title'] as String? ?? 'Cardio';
        final durationSeconds = cardio['duration_seconds'] as int? ?? 0;
        final durationMin = durationSeconds ~/ 60;
        final distance = (cardio['distance_km'] as num?)?.toDouble() ?? 0;
        final calories = cardio['calories'] as int? ?? 0;

        String distanceStr = '';
        if (distance > 0) {
          distanceStr = ', ${distance.toStringAsFixed(1)} km';
        }

        buffer.writeln('- $date: $activity ($durationMin min$distanceStr, $calories kcal)');
      }

      return buffer.toString().trim();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CoachContextBuilder: Error getting recent cardio: $e');
      return 'Aucune activité cardio récente';
    }
  }

  /// Build a compact context summary for token efficiency
  /// Used when we need a shorter context (e.g., for preference extraction)
  Future<String> buildCompactContext() async {
    final globalState = GlobalStateManager.instance;
    final now = DateTime.now();

    return '''
Utilisateur: ${globalState.userName}
Date: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}
Calories: ${globalState.currentCalories.toInt()}/${globalState.calorieGoal.toInt()} kcal
Macros: P${globalState.currentProteins.toInt()}g C${globalState.currentCarbs.toInt()}g F${globalState.currentFats.toInt()}g
Eau: ${globalState.currentWaterL.toStringAsFixed(1)}/${globalState.waterGoalL.toStringAsFixed(1)}L
Repas: ${globalState.mealsCount}
Sport: ${globalState.sportSessions} séances, ${globalState.sportCaloriesBurned} kcal brûlées
Streak: ${globalState.currentStreak} jours
''';
  }
}
