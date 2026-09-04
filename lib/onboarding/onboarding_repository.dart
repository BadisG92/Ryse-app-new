import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/ui/onboarding_models.dart';
import '../models/weekly_planner_models.dart';
import '../services/coach_personality_service.dart';
import '../services/localization_service.dart';
import '../services/planner_ai_service.dart';
import '../services/unit_service.dart';
import '../services/weekly_bilan_service.dart';
import 'onboarding_state.dart';
import 'onboarding_strings.dart';

/// Persists the onboarding exactly like the legacy flow did:
/// same tables, same columns, same local preferences.
class OnboardingRepository {
  OnboardingRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Port of `OnboardingGamifiedHybrid._saveUserData`.
  /// Writes `users`, `user_profile_history`, the daily macro prefs,
  /// `onboarding_completed`, the measurement unit and `UnitService`.
  Future<void> saveProfile(OnbAnswers a) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = a.toProfile();

    final calories = MetabolicCalculations.calculateDailyGoal(profile);
    final macros = MetabolicCalculations.calculateMacros(profile);
    final bmr = MetabolicCalculations.calculateBMR(profile);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté - impossible de sauvegarder');
      }

      // Legacy flow derived the birth date from the age: 1st of January.
      final birthYear = DateTime.now().year - a.age;
      final birthDate = '$birthYear-01-01';

      // Storage is always metric (kg, cm); the ruler already converts.
      final double heightValue = a.heightCm.toDouble();
      final double weightValue = a.weightKg.toDouble();
      final double targetWeightValue = (a.hasTarget ? a.targetKg : a.weightKg).toDouble();
      final now = DateTime.now().toIso8601String();

      final updateData = {
        'gender': a.gender,
        'birth_date': birthDate,
        'age': a.age,
        'height': heightValue,
        'weight': weightValue,
        'target_weight': targetWeightValue,
        'is_metric': a.isMetric,
        'activity_level': a.activity,
        'fitness_goal': a.goal,
        'dietary_restrictions': a.restrictions,
        'daily_calories': calories,
        'daily_protein': macros['protein'],
        'daily_carbs': macros['carbs'],
        'daily_fat': macros['fat'],
        'bmr': bmr,
        'is_onboarded': true,
        'updated_at': now,
      };

      await _supabase.from('users').update(updateData).eq('id', userId).select();

      if (weightValue > 0) {
        final historyData = {
          'gender': a.gender,
          'birth_date': birthDate,
          'age': a.age,
          'height': heightValue,
          'weight': weightValue,
          'activity_level': a.activity,
          'fitness_goal': a.goal,
          'dietary_restrictions': a.restrictions,
          'daily_calories': calories,
          'daily_protein': macros['protein'],
          'daily_carbs': macros['carbs'],
          'daily_fat': macros['fat'],
          'bmr': bmr,
          'valid_from': now,
          'change_source': 'onboarding_completion',
          'weight_modified': true,
        };

        final existingProfile = await _supabase.from('user_profile_history').select('id').eq('user_id', userId).eq('is_current', true).maybeSingle();

        if (existingProfile != null) {
          await _supabase.from('user_profile_history').update(historyData).eq('id', existingProfile['id']).select();
        } else {
          await _supabase.from('user_profile_history').insert({
            'user_id': userId,
            ...historyData,
            'is_current': true,
          }).select();
        }
      }

      await _saveLocalMacros(prefs, calories, macros);
      await prefs.setString('measurement_unit', a.isMetric ? 'Métrique' : 'Impérial');
      await UnitService.instance.setImperial(!a.isMetric);
      await OnbProgressStore.markProfileSaved();
    } catch (e) {
      debugPrint('❌ Onboarding saveProfile: $e');
      try {
        await _saveLocalMacros(prefs, calories, macros);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _saveLocalMacros(SharedPreferences prefs, int calories, Map<String, int> macros) async {
    await prefs.setInt('daily_calories', calories);
    await prefs.setInt('daily_protein', macros['protein'] ?? 0);
    await prefs.setInt('daily_carbs', macros['carbs'] ?? 0);
    await prefs.setInt('daily_fat', macros['fat'] ?? 0);
    await prefs.setBool('onboarding_completed', true);
  }

  /// Port of `WeeklyContractScreen._saveAndComplete`.
  Future<void> saveBilanDay(int day) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('users').update({
          'weekly_bilan_day': day,
          'weekly_bilan_enabled': true,
        }).eq('id', user.id);
        await WeeklyBilanService.instance.setBilanDay(day);
      }
    } catch (e) {
      debugPrint('❌ Onboarding saveBilanDay: $e');
    }
  }

  Future<void> savePersonality(String key) async {
    try {
      final type = CoachPersonalityType.values.firstWhere((t) => t.name == key, orElse: () => CoachPersonalityType.friendly);
      await CoachPersonalityService.instance.setPersonality(type);
    } catch (e) {
      debugPrint('❌ Onboarding savePersonality: $e');
    }
  }

  /// Port of `OnboardingChatScreen._extractAndSaveInsights`, without the
  /// Gemini round trip: the answers are already structured, so the summary is
  /// written in the same categories the coach memory expects.
  Future<void> saveCoachInsights(OnbAnswers a, OnbStrings s) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final lines = <String>[];
      final goalLabel = a.goal == null ? null : s.t('goal_${a.goal}');
      if (a.motivation != null) {
        lines.add('- **Motivation principale**: ${s.t(a.motivation!)}${a.motivationText.trim().isNotEmpty ? ' ("${a.motivationText.trim()}")' : ''}');
      }
      if (goalLabel != null) {
        final target = a.hasTarget ? ' (${a.weightKg} kg → ${a.targetKg} kg)' : '';
        lines.add('- **Objectif concret**: $goalLabel$target');
      }
      if (a.obstacles.isNotEmpty && !(a.obstacles.length == 1 && a.obstacles.first == 'obs_none')) {
        lines.add('- **Blocages passés**: ${a.obstacles.where((o) => o != 'obs_none').map((o) => s.t(o)).join(', ')}');
      }
      if (a.restrictions.isNotEmpty) {
        lines.add('- **Contraintes**: ${a.restrictions.join(', ')}');
      }
      if (a.personality != null) {
        lines.add(
            '- **Ton du coach choisi**: ${CoachPersonalityService.getLocalizedLabel(CoachPersonalityType.values.firstWhere((t) => t.name == a.personality, orElse: () => CoachPersonalityType.friendly), s.lang)}');
      }
      if (lines.isEmpty) return;
      final insights = lines.join('\n');

      final existingResponse = await _supabase.from('user_coach_preferences').select('preferences').eq('user_id', user.id).maybeSingle();

      Map<String, dynamic> existingPrefs = {};
      if (existingResponse != null && existingResponse['preferences'] != null) {
        existingPrefs = Map<String, dynamic>.from(existingResponse['preferences'] as Map);
      }
      existingPrefs['onboarding_insights'] = insights;

      await _supabase.from('user_coach_preferences').upsert(
        {
          'user_id': user.id,
          'preferences': existingPrefs,
          'last_extraction_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('❌ Onboarding saveCoachInsights: $e');
    }
  }

  /// Port of `RyzeApp._completeOnboarding` (the persistence part).
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);
    await prefs.setBool('is_onboarded', true);

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('users').update({
          'is_onboarded': true,
          'ai_onboarding_completed': true,
        }).eq('id', user.id);
        await LocalizationService.instance.syncLanguageToSupabase();
      } catch (e) {
        debugPrint('❌ Onboarding markCompleted: $e');
      }
    }
    await OnbProgressStore.clear();
  }

  /// Port of `OnboardingPlannerDemo` post-purchase save.
  Future<bool> saveDemoPlan(List<PendingMeal> meals, List<PendingWorkout> workouts, List<PendingSession> sessions) async {
    try {
      for (final meal in meals) {
        await PlannerAIService.confirmMeals([meal]);
      }
      if (workouts.isNotEmpty) {
        await PlannerAIService.confirmWorkouts(workouts);
      }
      for (final session in sessions) {
        await PlannerAIService.confirmSingleSession(session);
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ Onboarding saveDemoPlan: $e');
      return false;
    }
  }
}
