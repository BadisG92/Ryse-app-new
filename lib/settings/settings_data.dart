import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/ui/onboarding_models.dart';
import '../providers/weight_notifier.dart';
import '../services/coach_chat_service.dart';
import '../services/global_state_manager.dart';

/// Le profil réglable, et son écriture.
///
/// Les mêmes colonnes et les mêmes clés locales que l'ancien écran — c'est
/// délibéré : la refonte ne change pas ce qui est stocké, seulement la façon
/// dont on le règle. Une seule méthode écrit, au lieu d'un `_saveSettings`
/// appelé depuis quinze endroits.
class SettingsProfile {
  SettingsProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.mainGoal,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.hasCustomMacros,
    required this.restrictions,
  });

  String gender;
  int age;
  double heightCm;
  double weightKg;
  double targetWeightKg;

  /// 'low' | 'moderate' | 'high'
  String activityLevel;

  /// 'lose' | 'maintain' | 'gain'
  String mainGoal;

  int calories;
  int protein;
  int carbs;
  int fat;
  bool hasCustomMacros;
  List<String> restrictions;

  static SettingsProfile empty() => SettingsProfile(
        gender: 'male', age: 30, heightCm: 175, weightKg: 70, targetWeightKg: 70,
        activityLevel: 'moderate', mainGoal: 'maintain',
        calories: 2000, protein: 150, carbs: 200, fat: 70,
        hasCustomMacros: false, restrictions: const [],
      );

  /// `MetabolicCalculations` prend le profil de l'onboarding, dont les champs
  /// sont des chaînes. On les lui donne dans sa langue plutôt que de dupliquer
  /// ses formules ici.
  UserProfile get userProfile => UserProfile(
        gender: gender,
        age: '$age',
        weight: '$weightKg',
        height: '$heightCm',
        activity: activityLevel,
        goal: mainGoal,
        targetWeight: '$targetWeightKg',
        obstacles: const [],
        restrictions: restrictions,
      );

  /// Ce que le métabolisme donne pour ce profil : les valeurs proposées quand
  /// l'utilisateur demande à recalculer.
  ({int calories, int protein, int carbs, int fat}) computed() {
    final kcal = MetabolicCalculations.calculateDailyGoal(userProfile);
    final macros = MetabolicCalculations.calculateMacros(userProfile);
    return (
      calories: kcal,
      protein: macros['protein'] ?? protein,
      carbs: macros['carbs'] ?? carbs,
      fat: macros['fat'] ?? fat,
    );
  }
}

class SettingsData {
  SettingsData._();

  /// Le profil que le telephone connait deja. Instantane, et juste hors
  /// ligne : c'est lui qui s'affiche, la base ne fait que le corriger.
  static Future<SettingsProfile> load() async {
    final p = SettingsProfile.empty();
    try {
      final prefs = await SharedPreferences.getInstance();
      p.gender = prefs.getString('user_gender') ?? p.gender;
      p.age = int.tryParse(prefs.getString('user_age') ?? '') ?? p.age;
      p.heightCm = double.tryParse(prefs.getString('user_height') ?? '') ?? p.heightCm;
      p.weightKg = double.tryParse(prefs.getString('user_weight') ?? '') ?? p.weightKg;
      p.targetWeightKg = double.tryParse(prefs.getString('target_weight') ?? '') ?? p.weightKg;
      p.activityLevel = prefs.getString('user_activity') ?? p.activityLevel;
      p.mainGoal = prefs.getString('user_goal') ?? p.mainGoal;
      p.calories = prefs.getInt('calories_target') ?? p.calories;
      p.protein = prefs.getInt('protein_target') ?? p.protein;
      p.carbs = prefs.getInt('carbs_target') ?? p.carbs;
      p.fat = prefs.getInt('fat_target') ?? p.fat;
      p.hasCustomMacros = prefs.getBool('has_custom_macros') ?? false;
    } catch (e) {
      debugPrint('SettingsData.load prefs: $e');
    }

    return p;
  }

  /// La base, qui fait foi quand elle repond. Rend nul si elle ne repond pas :
  /// l'appelant garde alors ce qu'il affiche deja.
  ///
  /// C'etait la meme methode que `load`, qui attendait donc le reseau avant de
  /// rendre quoi que ce soit : sans reseau, la page des reglages restait huit
  /// secondes sur un tourniquet alors qu'elle avait tout ce qu'il fallait.
  static Future<SettingsProfile?> refresh(SettingsProfile local) async {
    final p = local;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        final row = await client
            .from('users')
            .select('gender, age, height, weight, target_weight, activity_level, fitness_goal, '
                'daily_calories, daily_protein, daily_carbs, daily_fat, dietary_restrictions')
            .eq('id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 4));
        if (row != null) {
          p.gender = (row['gender'] as String?) ?? p.gender;
          p.age = (row['age'] as num?)?.toInt() ?? p.age;
          p.heightCm = (row['height'] as num?)?.toDouble() ?? p.heightCm;
          p.weightKg = (row['weight'] as num?)?.toDouble() ?? p.weightKg;
          p.targetWeightKg = (row['target_weight'] as num?)?.toDouble() ?? p.targetWeightKg;
          p.activityLevel = (row['activity_level'] as String?) ?? p.activityLevel;
          p.mainGoal = (row['fitness_goal'] as String?) ?? p.mainGoal;
          p.calories = (row['daily_calories'] as num?)?.toInt() ?? p.calories;
          p.protein = (row['daily_protein'] as num?)?.toInt() ?? p.protein;
          p.carbs = (row['daily_carbs'] as num?)?.toInt() ?? p.carbs;
          p.fat = (row['daily_fat'] as num?)?.toInt() ?? p.fat;
          final r = row['dietary_restrictions'];
          if (r is List) p.restrictions = r.map((e) => '$e').toList();
        }
      }
    } catch (e) {
      debugPrint('SettingsData.refresh: $e');
      return null;
    }
    return p;
  }

  /// Écrit le profil : Supabase, les préférences locales, l'état global, et
  /// les caches qui en dépendent. Rend faux si la base a refusé — le local
  /// est écrit dans tous les cas, donc rien n'est perdu.
  static Future<bool> save(SettingsProfile p) async {
    var online = true;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('users').update({
          'gender': p.gender,
          'age': p.age,
          'height': p.heightCm,
          'weight': p.weightKg,
          'target_weight': p.targetWeightKg,
          'activity_level': p.activityLevel,
          'fitness_goal': p.mainGoal,
          'daily_calories': p.calories,
          'daily_protein': p.protein,
          'daily_carbs': p.carbs,
          'daily_fat': p.fat,
          'bmr': MetabolicCalculations.calculateBMR(p.userProfile),
          'dietary_restrictions': p.restrictions,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId).timeout(const Duration(seconds: 10));

        if (p.hasCustomMacros) {
          final total = p.calories <= 0 ? 1 : p.calories;
          await client.from('user_profile_history').update({
            'has_custom_macros': true,
            'protein_percentage': p.protein * 4 / total,
            'carbs_percentage': p.carbs * 4 / total,
            'fat_percentage': p.fat * 9 / total,
          }).eq('user_id', userId).eq('is_current', true);
        }
      }
    } catch (e) {
      debugPrint('SettingsData.save: $e');
      online = false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_gender', p.gender);
      await prefs.setString('user_age', '${p.age}');
      await prefs.setString('user_height', '${p.heightCm}');
      await prefs.setString('user_weight', '${p.weightKg}');
      await prefs.setString('target_weight', '${p.targetWeightKg}');
      await prefs.setString('user_activity', p.activityLevel);
      await prefs.setString('user_goal', p.mainGoal);
      await prefs.setInt('calories_target', p.calories);
      await prefs.setInt('protein_target', p.protein);
      await prefs.setInt('carbs_target', p.carbs);
      await prefs.setInt('fat_target', p.fat);
      await prefs.setBool('has_custom_macros', p.hasCustomMacros);
    } catch (e) {
      debugPrint('SettingsData.save prefs: $e');
    }

    try {
      GlobalStateManager.instance.updateGoals(
        calorieGoal: p.calories.toDouble(),
        proteinGoal: p.protein,
        carbsGoal: p.carbs,
        fatGoal: p.fat,
      );
    } catch (_) {}
    // Le poids cible a pu changer : la courbe de Progression doit la relire.
    try {
      WeightNotifier.instance.notifyWeightChanged();
    } catch (_) {}
    try {
      CoachChatService.instance.refreshChatSession();
    } catch (_) {}
    return online;
  }
}
